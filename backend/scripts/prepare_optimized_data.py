#!/usr/bin/env python3
"""
OntoThink优化数据准备脚本
针对ChatGLM3训练进行数据格式优化
"""

import json
import random
from pathlib import Path
from typing import List, Dict
import argparse
from sklearn.model_selection import train_test_split

def load_existing_data(data_dir: str) -> List[Dict]:
    """加载现有的训练数据"""
    all_data = []
    
    # 加载现有的JSONL文件
    for file_path in ["train.jsonl", "val.jsonl", "test.jsonl"]:
        full_path = Path(data_dir) / file_path
        if full_path.exists():
            with open(full_path, 'r', encoding='utf-8') as f:
                for line in f:
                    all_data.append(json.loads(line))
    
    print(f"📊 加载现有数据: {len(all_data)} 条")
    return all_data

def optimize_instruction_format(data: List[Dict]) -> List[Dict]:
    """优化指令格式，使其更适合ChatGLM3训练"""
    
    optimized_data = []
    
    for item in data:
        # 原始格式
        instruction = item.get("instruction", "")
        input_text = item.get("input", "")
        output = item.get("output", "")
        category = item.get("category", "通用")
        
        # 创建ChatGLM3格式的优化指令
        if "立场" in instruction and "论据" in instruction:
            # 立场+论据类型
            new_instruction = "你是OntoThink思辨助手。请根据给定的哲学问题和立场，提供深入的论证支持。"
            new_input = instruction.replace("请基于以下哲学问题，提出一个明确的立场并给出支持论据：", "").strip()
            new_output = output
            
        elif "反问" in instruction:
            # 反问类型
            new_instruction = "你是OntoThink思辨助手。请针对给定的哲学立场，提出具有启发性和挑战性的反问。"
            new_input = instruction.replace("请针对以下哲学立场，提出一个具有挑战性的反问：", "").strip()
            new_output = output
            
        elif "思辨图谱" in instruction:
            # 完整图谱生成类型
            new_instruction = "你是OntoThink思辨助手。请为给定的哲学问题生成完整的思辨图谱，包含多个立场、论据和反问。输出必须是有效的JSON格式。"
            new_input = instruction.replace("请基于以下哲学问题，生成包含不同立场、支持论据和反问的思辨图谱数据。请严格按照JSON格式输出：", "").strip()
            new_output = output
            
        else:
            # 保持原格式
            new_instruction = instruction
            new_input = input_text
            new_output = output
        
        optimized_data.append({
            "instruction": new_instruction,
            "input": new_input,
            "output": new_output,
            "category": category,
            "task_type": classify_task_type(new_instruction, new_output)
        })
    
    return optimized_data

def classify_task_type(instruction: str, output: str) -> str:
    """分类任务类型"""
    if "JSON" in output or "{" in output:
        return "graph_generation"
    elif "论据" in output or "argument" in output.lower():
        return "argument_generation"
    elif "反问" in output or "counter" in output.lower():
        return "counter_question"
    else:
        return "general_reasoning"

def balance_dataset(data: List[Dict]) -> List[Dict]:
    """平衡数据集，确保各类任务分布合理"""
    
    # 按任务类型分组
    task_groups = {}
    for item in data:
        task_type = item.get("task_type", "general_reasoning")
        if task_type not in task_groups:
            task_groups[task_type] = []
        task_groups[task_type].append(item)
    
    print("📊 任务类型分布:")
    for task_type, items in task_groups.items():
        print(f"   - {task_type}: {len(items)} 条")
    
    # 确保每种任务类型至少有一定数量的样本
    min_samples_per_type = 50
    balanced_data = []
    
    for task_type, items in task_groups.items():
        if len(items) < min_samples_per_type:
            # 如果样本不足，进行重复采样
            repeated_items = []
            while len(repeated_items) < min_samples_per_type:
                repeated_items.extend(items)
            balanced_data.extend(repeated_items[:min_samples_per_type])
        else:
            balanced_data.extend(items)
    
    # 随机打乱
    random.shuffle(balanced_data)
    
    print(f"⚖️  平衡后数据集大小: {len(balanced_data)} 条")
    return balanced_data

def add_system_prompts(data: List[Dict]) -> List[Dict]:
    """为数据添加系统提示，增强模型的角色认知"""
    
    system_prompts = {
        "graph_generation": "你是OntoThink专业思辨图谱生成助手，擅长将复杂哲学问题转化为结构化的多维度分析。",
        "argument_generation": "你是OntoThink论证分析专家，专门为各种哲学立场提供深入、严谨的论证支持。",
        "counter_question": "你是OntoThink苏格拉底式提问专家，擅长通过巧妙的反问引导更深层次的思辨。",
        "general_reasoning": "你是OntoThink通用思辨助手，能够进行各种形式的哲学推理和分析。"
    }
    
    enhanced_data = []
    for item in data:
        task_type = item.get("task_type", "general_reasoning")
        system_prompt = system_prompts.get(task_type, system_prompts["general_reasoning"])
        
        # 将系统提示整合到instruction中
        enhanced_instruction = f"{system_prompt}\n\n{item['instruction']}"
        
        enhanced_data.append({
            "instruction": enhanced_instruction,
            "input": item["input"],
            "output": item["output"],
            "category": item["category"],
            "task_type": task_type
        })
    
    return enhanced_data

def create_test_samples() -> List[Dict]:
    """创建专门的测试样本"""
    test_questions = [
        "人工智能是否能够真正理解语言？",
        "艺术创作中的情感与技巧哪个更重要？",
        "在多元文化社会中，如何定义共同价值观？",
        "科学进步是否总是带来道德进步？",
        "个人隐私与社会安全之间的界限在哪里？"
    ]
    
    test_samples = []
    for question in test_questions:
        test_samples.append({
            "instruction": "你是OntoThink专业思辨图谱生成助手，擅长将复杂哲学问题转化为结构化的多维度分析。\n\n请为给定的哲学问题生成完整的思辨图谱，包含多个立场、论据和反问。输出必须是有效的JSON格式。",
            "input": f"问题：{question}",
            "output": "请生成符合OntoThink格式的思辨图谱JSON数据。",
            "category": "测试样本",
            "task_type": "graph_generation"
        })
    
    return test_samples

def split_and_save_data(data: List[Dict], output_dir: str, test_size: float = 0.1, val_size: float = 0.1):
    """分割并保存数据"""
    
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    
    # 添加专门的测试样本
    test_samples = create_test_samples()
    
    # 先分出测试集
    train_val_data, test_data = train_test_split(
        data, 
        test_size=test_size, 
        random_state=42,
        stratify=[item["task_type"] for item in data]
    )
    
    # 再分出验证集
    train_data, val_data = train_test_split(
        train_val_data,
        test_size=val_size/(1-test_size),
        random_state=42,
        stratify=[item["task_type"] for item in train_val_data]
    )
    
    # 添加专门的测试样本到测试集
    test_data.extend(test_samples)
    
    # 保存各个数据集
    datasets = {
        "train": train_data,
        "val": val_data,
        "test": test_data
    }
    
    for split_name, split_data in datasets.items():
        output_file = output_path / f"{split_name}.jsonl"
        with open(output_file, 'w', encoding='utf-8') as f:
            for item in split_data:
                f.write(json.dumps(item, ensure_ascii=False) + '\n')
        
        print(f"💾 保存 {split_name} 数据: {len(split_data)} 条 -> {output_file}")
    
    # 保存数据统计信息
    stats = {
        "total_samples": len(data) + len(test_samples),
        "train_samples": len(train_data),
        "val_samples": len(val_data),
        "test_samples": len(test_data),
        "task_type_distribution": {}
    }
    
    all_data = train_data + val_data + test_data
    for item in all_data:
        task_type = item["task_type"]
        if task_type not in stats["task_type_distribution"]:
            stats["task_type_distribution"][task_type] = 0
        stats["task_type_distribution"][task_type] += 1
    
    with open(output_path / "data_stats.json", 'w', encoding='utf-8') as f:
        json.dump(stats, f, ensure_ascii=False, indent=2)
    
    print(f"📊 数据统计信息保存至: {output_path / 'data_stats.json'}")

def main():
    parser = argparse.ArgumentParser(description="准备优化的OntoThink训练数据")
    parser.add_argument("--input_dir", required=True, help="输入数据目录")
    parser.add_argument("--output_dir", required=True, help="输出数据目录")
    parser.add_argument("--test_size", type=float, default=0.1, help="测试集比例")
    parser.add_argument("--val_size", type=float, default=0.1, help="验证集比例")
    
    args = parser.parse_args()
    
    print("🚀 开始准备优化的训练数据...")
    
    # 加载现有数据
    raw_data = load_existing_data(args.input_dir)
    
    if not raw_data:
        print("❌ 未找到现有数据，请先运行数据生成脚本")
        return
    
    # 优化指令格式
    optimized_data = optimize_instruction_format(raw_data)
    
    # 平衡数据集
    balanced_data = balance_dataset(optimized_data)
    
    # 添加系统提示
    enhanced_data = add_system_prompts(balanced_data)
    
    # 分割并保存数据
    split_and_save_data(enhanced_data, args.output_dir, args.test_size, args.val_size)
    
    print("✅ 数据准备完成！")
    print(f"📁 优化后的数据保存在: {args.output_dir}")

if __name__ == "__main__":
    main()
