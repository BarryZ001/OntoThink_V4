#!/usr/bin/env python3
"""
OntoThink数据格式适配燧原T20训练
将OntoThink数据转换为燧原ChatGLM3训练所需的格式
"""

import json
import argparse
from pathlib import Path
from typing import List, Dict, Any

def convert_to_enflame_format(ontothink_data: List[Dict]) -> List[Dict]:
    """
    将OntoThink训练数据转换为燧原ChatGLM3所需的多轮对话格式
    
    燧原ChatGLM3期望的数据格式:
    {
        "conversations": [
            {
                "from": "human", 
                "value": "用户输入"
            },
            {
                "from": "gpt", 
                "value": "助手回复"
            }
        ]
    }
    """
    enflame_data = []
    
    for item in ontothink_data:
        instruction = item.get("instruction", "")
        input_text = item.get("input", "")
        output = item.get("output", "")
        category = item.get("category", "")
        
        # 构建用户输入
        if input_text:
            user_input = f"{instruction}\n\n{input_text}"
        else:
            user_input = instruction
        
        # 添加OntoThink系统身份
        system_prompt = "你是OntoThink专业思辨助手，擅长分析哲学问题并生成多维度思辨图谱。"
        user_input = f"{system_prompt}\n\n{user_input}"
        
        # 构建对话格式
        conversation = {
            "conversations": [
                {
                    "from": "human",
                    "value": user_input
                },
                {
                    "from": "gpt", 
                    "value": output
                }
            ]
        }
        
        # 添加元数据
        if category:
            conversation["category"] = category
            
        enflame_data.append(conversation)
    
    return enflame_data

def create_summary_format_data(ontothink_data: List[Dict]) -> List[Dict]:
    """
    创建摘要格式的数据（适配燧原的summary训练脚本）
    """
    summary_data = []
    
    for item in ontothink_data:
        instruction = item.get("instruction", "")
        input_text = item.get("input", "")
        output = item.get("output", "")
        
        # 将instruction作为content，output作为summary
        if input_text:
            content = f"{instruction} {input_text}"
        else:
            content = instruction
            
        summary_item = {
            "content": content,
            "summary": output
        }
        
        summary_data.append(summary_item)
    
    return summary_data

def split_data_for_enflame(data: List[Dict], train_ratio: float = 0.8, val_ratio: float = 0.1):
    """
    按燧原要求分割数据集
    """
    total_size = len(data)
    train_size = int(total_size * train_ratio)
    val_size = int(total_size * val_ratio)
    
    train_data = data[:train_size]
    val_data = data[train_size:train_size + val_size]
    test_data = data[train_size + val_size:]
    
    return train_data, val_data, test_data

def save_for_enflame_training(data: List[Dict], output_dir: Path, format_type: str = "multiturn"):
    """
    保存为燧原训练所需的格式
    """
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # 分割数据
    train_data, val_data, test_data = split_data_for_enflame(data)
    
    if format_type == "multiturn":
        # 多轮对话格式 (JSONL)
        datasets = {
            "train": train_data,
            "dev": val_data,
            "test": test_data
        }
        
        for split_name, split_data in datasets.items():
            output_file = output_dir / f"{split_name}.jsonl"
            with open(output_file, 'w', encoding='utf-8') as f:
                for item in split_data:
                    f.write(json.dumps(item, ensure_ascii=False) + '\n')
            print(f"💾 保存 {split_name} 数据: {len(split_data)} 条 -> {output_file}")
    
    elif format_type == "summary":
        # 摘要格式 (JSONL)
        summary_train = create_summary_format_data(train_data)
        summary_val = create_summary_format_data(val_data)
        
        train_file = output_dir / "train.jsonl"
        val_file = output_dir / "dev.jsonl"
        
        with open(train_file, 'w', encoding='utf-8') as f:
            for item in summary_train:
                f.write(json.dumps(item, ensure_ascii=False) + '\n')
        
        with open(val_file, 'w', encoding='utf-8') as f:
            for item in summary_val:
                f.write(json.dumps(item, ensure_ascii=False) + '\n')
        
        print(f"💾 保存摘要格式训练数据: {len(summary_train)} 条 -> {train_file}")
        print(f"💾 保存摘要格式验证数据: {len(summary_val)} 条 -> {val_file}")

def load_ontothink_data(data_dir: str) -> List[Dict]:
    """加载OntoThink原始训练数据"""
    all_data = []
    
    for file_name in ["train.jsonl", "val.jsonl", "test.jsonl"]:
        file_path = Path(data_dir) / file_name
        if file_path.exists():
            with open(file_path, 'r', encoding='utf-8') as f:
                for line in f:
                    all_data.append(json.loads(line))
    
    print(f"📊 加载OntoThink数据: {len(all_data)} 条")
    return all_data

def main():
    parser = argparse.ArgumentParser(description="准备燧原T20 ChatGLM3训练数据")
    parser.add_argument("--input_dir", required=True, help="OntoThink数据目录")
    parser.add_argument("--output_dir", required=True, help="燧原格式输出目录")
    parser.add_argument("--format", choices=["multiturn", "summary"], default="multiturn", 
                       help="数据格式: multiturn(多轮对话) 或 summary(摘要)")
    
    args = parser.parse_args()
    
    print("🚀 开始准备燧原T20训练数据...")
    
    # 加载OntoThink数据
    ontothink_data = load_ontothink_data(args.input_dir)
    
    if not ontothink_data:
        print("❌ 未找到OntoThink数据")
        return
    
    # 转换为燧原格式
    if args.format == "multiturn":
        enflame_data = convert_to_enflame_format(ontothink_data)
    else:
        enflame_data = ontothink_data  # summary格式在保存时转换
    
    # 保存燧原格式数据
    save_for_enflame_training(enflame_data, Path(args.output_dir), args.format)
    
    print(f"✅ 燧原T20数据准备完成！")
    print(f"📁 输出目录: {args.output_dir}")
    print(f"📝 数据格式: {args.format}")

if __name__ == "__main__":
    main()
