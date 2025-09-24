#!/usr/bin/env python3
"""
OntoThink ChatGLM3-6B 专业训练脚本
针对8卡GCU环境优化的分布式训练方案
"""

import os
import torch
import json
from dataclasses import dataclass, field
from typing import Dict, Optional, Sequence
import transformers
from transformers import (
    AutoConfig,
    AutoModelForCausalLM,
    AutoTokenizer,
    HfArgumentParser,
    Trainer,
    TrainingArguments,
    set_seed,
)
from datasets import Dataset
from peft import LoraConfig, get_peft_model, prepare_model_for_kbit_training
import bitsandbytes as bnb
from transformers import BitsAndBytesConfig

# 模型和数据配置
MODEL_NAME = "THUDM/chatglm3-6b"
IGNORE_INDEX = -100

@dataclass
class ModelArguments:
    model_name_or_path: Optional[str] = field(
        default=MODEL_NAME,
        metadata={"help": "Path to pretrained model or model identifier from huggingface.co/models"}
    )
    trust_remote_code: bool = field(
        default=True,
        metadata={"help": "Whether to trust remote code when loading a model from a hub or a local directory"}
    )

@dataclass
class DataArguments:
    data_path: str = field(
        default="/workspace/code/OntoThink_V4/backend/data/processed",
        metadata={"help": "Path to the training data"}
    )
    max_seq_length: int = field(
        default=2048,
        metadata={"help": "Maximum sequence length for training"}
    )

@dataclass
class TrainingArguments(transformers.TrainingArguments):
    cache_dir: Optional[str] = field(default=None)
    optim: str = field(default="adamw_torch")
    model_max_length: int = field(
        default=2048,
        metadata={"help": "Maximum sequence length"}
    )
    use_lora: bool = field(default=True)

@dataclass
class LoraArguments:
    lora_r: int = 64
    lora_alpha: int = 128
    lora_dropout: float = 0.05
    lora_target_modules: str = "query_key_value,dense,dense_h_to_4h,dense_4h_to_h"
    lora_weight_path: str = ""
    lora_bias: str = "none"
    q_lora: bool = False

def safe_save_model_for_hf_trainer(trainer: transformers.Trainer, output_dir: str):
    """保存模型的安全方法"""
    state_dict = trainer.model.state_dict()
    if trainer.args.should_save:
        cpu_state_dict = {key: value.cpu() for key, value in state_dict.items()}
        del state_dict
        trainer._save(output_dir, state_dict=cpu_state_dict)

def preprocess_function_train(examples, tokenizer, max_seq_length):
    """预处理训练数据"""
    model_inputs = {"input_ids": [], "labels": []}
    
    for i in range(len(examples["instruction"])):
        instruction = examples["instruction"][i]
        input_text = examples.get("input", [""])[i] if "input" in examples else ""
        output = examples["output"][i]
        
        # 构建ChatGLM3的对话格式
        if input_text:
            prompt = f"<|system|>\n你是OntoThink思辨助手，专门分析哲学问题，生成多维度思辨图谱。\n<|user|>\n{instruction}\n{input_text}\n<|assistant|>\n{output}"
        else:
            prompt = f"<|system|>\n你是OntoThink思辨助手，专门分析哲学问题，生成多维度思辨图谱。\n<|user|>\n{instruction}\n<|assistant|>\n{output}"
        
        # 编码
        tokenized = tokenizer(
            prompt,
            max_length=max_seq_length,
            truncation=True,
            padding=False,
            return_tensors=None,
        )
        
        input_ids = tokenized["input_ids"]
        
        # 为ChatGLM3创建labels
        # 找到assistant部分的开始位置
        assistant_start = prompt.find("<|assistant|>\n") + len("<|assistant|>\n")
        assistant_part = prompt[assistant_start:]
        assistant_tokens = tokenizer(assistant_part, add_special_tokens=False)["input_ids"]
        
        labels = [-100] * (len(input_ids) - len(assistant_tokens)) + assistant_tokens
        
        model_inputs["input_ids"].append(input_ids)
        model_inputs["labels"].append(labels)
    
    return model_inputs

def create_ontothink_dataset(data_path: str, tokenizer, max_seq_length: int):
    """创建OntoThink专用数据集"""
    # 加载训练数据
    train_file = os.path.join(data_path, "train.jsonl")
    val_file = os.path.join(data_path, "val.jsonl")
    
    # 读取JSONL文件
    def load_jsonl(file_path):
        data = []
        with open(file_path, 'r', encoding='utf-8') as f:
            for line in f:
                data.append(json.loads(line))
        return data
    
    train_data = load_jsonl(train_file)
    val_data = load_jsonl(val_file)
    
    # 转换为datasets格式
    train_dataset = Dataset.from_list(train_data)
    val_dataset = Dataset.from_list(val_data)
    
    # 预处理
    train_dataset = train_dataset.map(
        lambda examples: preprocess_function_train(examples, tokenizer, max_seq_length),
        batched=True,
        remove_columns=train_dataset.column_names,
        desc="Processing training data"
    )
    
    val_dataset = val_dataset.map(
        lambda examples: preprocess_function_train(examples, tokenizer, max_seq_length),
        batched=True,
        remove_columns=val_dataset.column_names,
        desc="Processing validation data"
    )
    
    return train_dataset, val_dataset

def main():
    # 解析参数
    parser = HfArgumentParser((ModelArguments, DataArguments, TrainingArguments, LoraArguments))
    model_args, data_args, training_args, lora_args = parser.parse_args_into_dataclasses()
    
    # 设置随机种子
    set_seed(training_args.seed)
    
    # 配置量化
    if lora_args.q_lora:
        bnb_config = BitsAndBytesConfig(
            load_in_4bit=True,
            bnb_4bit_use_double_quant=True,
            bnb_4bit_quant_type="nf4",
            bnb_4bit_compute_dtype=torch.bfloat16,
        )
    else:
        bnb_config = None
    
    # 加载模型和tokenizer
    config = AutoConfig.from_pretrained(
        model_args.model_name_or_path,
        trust_remote_code=model_args.trust_remote_code
    )
    
    tokenizer = AutoTokenizer.from_pretrained(
        model_args.model_name_or_path,
        trust_remote_code=model_args.trust_remote_code,
        use_fast=False,
    )
    
    model = AutoModelForCausalLM.from_pretrained(
        model_args.model_name_or_path,
        config=config,
        quantization_config=bnb_config,
        device_map="auto" if not lora_args.q_lora else None,
        trust_remote_code=model_args.trust_remote_code,
        torch_dtype=torch.bfloat16,
    )
    
    # 配置LoRA
    if training_args.use_lora:
        if lora_args.q_lora:
            model = prepare_model_for_kbit_training(model, use_gradient_checkpointing=training_args.gradient_checkpointing)
        
        lora_config = LoraConfig(
            r=lora_args.lora_r,
            lora_alpha=lora_args.lora_alpha,
            target_modules=lora_args.lora_target_modules.split(","),
            lora_dropout=lora_args.lora_dropout,
            bias=lora_args.lora_bias,
            task_type="CAUSAL_LM",
        )
        model = get_peft_model(model, lora_config)
        model.print_trainable_parameters()
    
    # 准备数据
    train_dataset, eval_dataset = create_ontothink_dataset(
        data_args.data_path, 
        tokenizer, 
        data_args.max_seq_length
    )
    
    print(f"训练集大小: {len(train_dataset)}")
    print(f"验证集大小: {len(eval_dataset)}")
    
    # 数据整理器
    data_collator = transformers.DataCollatorForSeq2Seq(
        tokenizer,
        model=model,
        label_pad_token_id=IGNORE_INDEX,
        pad_to_multiple_of=8,
        return_tensors="pt",
        padding=True,
    )
    
    # 训练器
    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=train_dataset,
        eval_dataset=eval_dataset,
        tokenizer=tokenizer,
        data_collator=data_collator,
    )
    
    # 开始训练
    print("🚀 开始训练OntoThink模型...")
    trainer.train()
    
    # 保存模型
    trainer.save_state()
    safe_save_model_for_hf_trainer(trainer=trainer, output_dir=training_args.output_dir)
    
    print(f"✅ 训练完成！模型保存至: {training_args.output_dir}")

if __name__ == "__main__":
    main()
