#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
OntoThink数据格式转换器
将OntoThink原始格式转换为燧原ChatGLM3要求的conversation格式

原始格式：
{"instruction": "...", "input": "...", "output": "...", "category": "..."}

燧原格式：
{"conversation": [{"role": "user", "content": "..."}, {"role": "assistant", "content": "..."}]}
"""

import json
import os
import sys
from typing import Dict, List, Any

def convert_ontothink_to_enflame(input_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    将单条OntoThink数据转换为燧原ChatGLM3格式
    
    Args:
        input_data: OntoThink格式的数据
        
    Returns:
        燧原ChatGLM3格式的数据
    """
    instruction = input_data.get('instruction', '').strip()
    input_text = input_data.get('input', '').strip()
    output = input_data.get('output', '').strip()
    category = input_data.get('category', '')
    
    # 构建用户消息内容
    if input_text:
        # 如果有input字段，将其与instruction合并
        user_content = f"{instruction}\n\n{input_text}"
    else:
        # 如果没有input字段，直接使用instruction
        user_content = instruction
    
    # 构建对话格式
    conversation = [
        {
            "role": "user",
            "content": user_content
        },
        {
            "role": "assistant", 
            "content": output
        }
    ]
    
    # 燧原格式
    result = {
        "conversation": conversation
    }
    
    # 可选：保留类别信息作为元数据
    if category:
        result["category"] = category
        
    return result

def convert_file(input_file: str, output_file: str) -> None:
    """
    转换整个文件
    
    Args:
        input_file: 输入文件路径 (OntoThink JSONL格式)
        output_file: 输出文件路径 (燧原ChatGLM3格式)
    """
    print(f"🔄 转换文件: {input_file} → {output_file}")
    
    converted_count = 0
    error_count = 0
    
    with open(input_file, 'r', encoding='utf-8') as f_in, \
         open(output_file, 'w', encoding='utf-8') as f_out:
        
        for line_num, line in enumerate(f_in, 1):
            line = line.strip()
            if not line:
                continue
                
            try:
                # 解析原始数据
                input_data = json.loads(line)
                
                # 转换格式
                converted_data = convert_ontothink_to_enflame(input_data)
                
                # 写入转换后的数据
                json.dump(converted_data, f_out, ensure_ascii=False)
                f_out.write('\n')
                
                converted_count += 1
                
                if converted_count % 100 == 0:
                    print(f"  已转换 {converted_count} 条数据...")
                    
            except Exception as e:
                print(f"  ❌ 第{line_num}行转换失败: {e}")
                error_count += 1
                continue
    
    print(f"✅ 转换完成:")
    print(f"  - 成功转换: {converted_count} 条")
    print(f"  - 转换失败: {error_count} 条")
    print(f"  - 输出文件: {output_file}")

def preview_conversion(input_file: str, num_samples: int = 3) -> None:
    """
    预览转换结果
    
    Args:
        input_file: 输入文件路径
        num_samples: 预览样本数量
    """
    print(f"🔍 预览转换结果 (前{num_samples}条):")
    print("=" * 60)
    
    with open(input_file, 'r', encoding='utf-8') as f:
        for i, line in enumerate(f):
            if i >= num_samples:
                break
                
            line = line.strip()
            if not line:
                continue
                
            try:
                # 原始数据
                input_data = json.loads(line)
                print(f"📋 样本 {i+1} - 原始格式:")
                print(f"  instruction: {input_data.get('instruction', '')[:100]}...")
                print(f"  input: {input_data.get('input', '')[:50]}...")
                print(f"  output: {input_data.get('output', '')[:100]}...")
                print(f"  category: {input_data.get('category', '')}")
                
                # 转换后数据
                converted_data = convert_ontothink_to_enflame(input_data)
                print(f"🔄 转换后格式:")
                print(f"  user: {converted_data['conversation'][0]['content'][:100]}...")
                print(f"  assistant: {converted_data['conversation'][1]['content'][:100]}...")
                print("-" * 40)
                
            except Exception as e:
                print(f"  ❌ 样本{i+1}解析失败: {e}")

def main():
    """主函数"""
    print("🔧 OntoThink → 燧原ChatGLM3 数据格式转换器")
    print("=" * 50)
    
    # 定义文件路径
    base_dir = "/workspace/code/OntoThink_V4"
    input_dir = f"{base_dir}/backend/data/processed"
    output_dir = f"{base_dir}/enflame_training/datasets/ontothink_multiturn"
    
    # 确保输出目录存在
    os.makedirs(output_dir, exist_ok=True)
    
    # 文件映射
    file_mappings = [
        ("train.jsonl", "train.jsonl"),
        ("val.jsonl", "val.jsonl"), 
        ("test.jsonl", "test.jsonl")
    ]
    
    for input_filename, output_filename in file_mappings:
        input_file = f"{input_dir}/{input_filename}"
        output_file = f"{output_dir}/{output_filename}"
        
        if os.path.exists(input_file):
            print(f"\n📂 处理文件: {input_filename}")
            
            # 预览转换
            preview_conversion(input_file, num_samples=2)
            
            # 执行转换
            convert_file(input_file, output_file)
            
        else:
            print(f"⚠️  文件不存在: {input_file}")
    
    print(f"\n🎉 所有文件转换完成！")
    print(f"📁 输出目录: {output_dir}")
    
    # 验证转换结果
    print(f"\n🔍 验证转换结果:")
    for _, output_filename in file_mappings:
        output_file = f"{output_dir}/{output_filename}"
        if os.path.exists(output_file):
            with open(output_file, 'r', encoding='utf-8') as f:
                lines = f.readlines()
                print(f"  {output_filename}: {len(lines)} 条数据")
                
                # 验证第一条数据格式
                if lines:
                    try:
                        first_data = json.loads(lines[0])
                        if 'conversation' in first_data and len(first_data['conversation']) >= 2:
                            first_conv = first_data['conversation'][0]
                            if 'role' in first_conv and 'content' in first_conv:
                                print(f"    ✅ 格式正确，包含role和content字段")
                            else:
                                print(f"    ❌ 格式错误，缺少role或content字段")
                        else:
                            print(f"    ❌ 格式错误，缺少conversation字段或对话不完整")
                    except Exception as e:
                        print(f"    ❌ 格式验证失败: {e}")

if __name__ == "__main__":
    main()
