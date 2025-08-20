import os
import torch
from datasets import load_dataset
from transformers import (
    AutoModelForCausalLM,
    AutoTokenizer,
    BitsAndBytesConfig,
    TrainingArguments,
    pipeline,
    logging,
)
from peft import LoraConfig, get_peft_model
from trl import SFTTrainer

# Model and dataset paths
MODEL_NAME = "01-ai/Yi-6B"
DATASET_PATH = "/content/OntoThink_V4/backend/data/processed"
OUTPUT_DIR = "/content/OntoThink_V4/models/yi6b-ontothink"

# QLoRA configuration
bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_quant_type="nf4",
    bnb_4bit_compute_dtype=torch.bfloat16,
    bnb_4bit_use_double_quant=True,
)

# Load model and tokenizer
model = AutoModelForCausalLM.from_pretrained(
    MODEL_NAME,
    quantization_config=bnb_config,
    device_map="auto",
    trust_remote_code=True
)
model.config.use_cache = False
model.config.pretraining_tp = 1

tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME, trust_remote_code=True)
tokenizer.pad_token = tokenizer.eos_token

# LoRA configuration
peft_config = LoraConfig(
    r=16,
    lora_alpha=32,
    lora_dropout=0.05,
    bias="none",
    task_type="CAUSAL_LM",
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"]
)

# Load dataset
train_dataset = load_dataset('json', data_files=os.path.join(DATASET_PATH, 'train.jsonl'), split='train')
val_dataset = load_dataset('json', data_files=os.path.join(DATASET_PATH, 'val.jsonl'), split='train')

# Formatting function for the dataset
def format_instruction(example):
    return {"text": f"{example['instruction']}{example['input']}{example['output']}"}

train_dataset = train_dataset.map(format_instruction)
val_dataset = val_dataset.map(format_instruction)

# Training arguments
training_arguments = TrainingArguments(
    output_dir=OUTPUT_DIR,
    num_train_epochs=3,
    per_device_train_batch_size=4,
    gradient_accumulation_steps=4,
    gradient_checkpointing=True,
    optim="paged_adamw_32bit",
    save_steps=100,
    logging_steps=10,
    learning_rate=2e-4,
    weight_decay=0.001,
    fp16=True,
    bf16=False,
    max_grad_norm=0.3,
    warmup_ratio=0.03,
    group_by_length=True,
    lr_scheduler_type="cosine",
    evaluation_strategy="steps",
    eval_steps=50,
    load_best_model_at_end=True,
    report_to="tensorboard"
)

# Initialize trainer
trainer = SFTTrainer(
    model=model,
    train_dataset=train_dataset,
    eval_dataset=val_dataset,
    peft_config=peft_config,
    dataset_text_field="text",
    max_seq_length=1024,
    tokenizer=tokenizer,
    args=training_arguments,
)

# Start training
trainer.train()

# Save the final model
trainer.model.save_pretrained(OUTPUT_DIR)
tokenizer.save_pretrained(OUTPUT_DIR)

print("Training completed successfully!")
