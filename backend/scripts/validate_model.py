#!/usr/bin/env python3
"""
OntoThink模型验证脚本
用于测试训练后的模型生成思辨图谱的能力
"""

import json
import argparse
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM
from peft import PeftModel
import time
from typing import Dict, List

def load_model_and_tokenizer(model_path: str, base_model: str = "THUDM/chatglm3-6b"):
    """加载训练后的模型和tokenizer"""
    print(f"🔄 正在加载模型: {model_path}")
    
    # 加载tokenizer
    tokenizer = AutoTokenizer.from_pretrained(
        base_model,
        trust_remote_code=True,
        use_fast=False
    )
    
    # 加载基础模型
    base_model = AutoModelForCausalLM.from_pretrained(
        base_model,
        torch_dtype=torch.bfloat16,
        device_map="auto",
        trust_remote_code=True
    )
    
    # 加载PEFT适配器
    model = PeftModel.from_pretrained(base_model, model_path)
    model = model.merge_and_unload()
    model.eval()
    
    print("✅ 模型加载完成")
    return model, tokenizer

def generate_ontothink_response(model, tokenizer, question: str, max_length: int = 2048):
    """生成OntoThink思辨回答"""
    prompt = f"""<|system|>
你是OntoThink思辨助手，专门分析哲学问题，生成多维度思辨图谱。
<|user|>
请基于以下哲学问题，生成包含不同立场、支持论据和反问的思辨图谱数据。请严格按照JSON格式输出：

问题：{question}
<|assistant|>
"""
    
    inputs = tokenizer(prompt, return_tensors="pt").to(model.device)
    
    with torch.no_grad():
        outputs = model.generate(
            **inputs,
            max_new_tokens=max_length,
            temperature=0.7,
            top_p=0.8,
            do_sample=True,
            repetition_penalty=1.1,
            eos_token_id=tokenizer.eos_token_id,
            pad_token_id=tokenizer.pad_token_id
        )
    
    response = tokenizer.decode(outputs[0][inputs['input_ids'].shape[1]:], skip_special_tokens=True)
    return response.strip()

def validate_json_structure(response: str) -> Dict:
    """验证生成的JSON结构是否符合OntoThink格式"""
    try:
        data = json.loads(response)
        required_keys = ["question", "standpoints", "counter_questions"]
        
        validation_result = {
            "valid_json": True,
            "has_required_keys": all(key in data for key in required_keys),
            "standpoints_count": len(data.get("standpoints", [])),
            "counter_questions_count": len(data.get("counter_questions", [])),
            "detailed_structure": {}
        }
        
        # 验证standpoints结构
        if "standpoints" in data:
            standpoints_valid = all(
                "id" in sp and "text" in sp and "arguments" in sp
                for sp in data["standpoints"]
            )
            validation_result["detailed_structure"]["standpoints_valid"] = standpoints_valid
        
        # 验证counter_questions结构
        if "counter_questions" in data:
            cq_valid = all(
                "id" in cq and "text" in cq
                for cq in data["counter_questions"]
            )
            validation_result["detailed_structure"]["counter_questions_valid"] = cq_valid
        
        return validation_result
    
    except json.JSONDecodeError:
        return {
            "valid_json": False,
            "has_required_keys": False,
            "standpoints_count": 0,
            "counter_questions_count": 0,
            "detailed_structure": {}
        }

def run_validation(model, tokenizer, test_questions: List[str]) -> Dict:
    """运行完整的模型验证"""
    results = {
        "total_questions": len(test_questions),
        "successful_generations": 0,
        "valid_json_count": 0,
        "average_standpoints": 0,
        "average_counter_questions": 0,
        "detailed_results": []
    }
    
    total_standpoints = 0
    total_counter_questions = 0
    
    for i, question in enumerate(test_questions):
        print(f"🔍 验证问题 {i+1}/{len(test_questions)}: {question[:50]}...")
        
        start_time = time.time()
        
        try:
            response = generate_ontothink_response(model, tokenizer, question)
            generation_time = time.time() - start_time
            
            validation = validate_json_structure(response)
            
            result = {
                "question": question,
                "response": response,
                "generation_time": generation_time,
                "validation": validation
            }
            
            if response:
                results["successful_generations"] += 1
            
            if validation["valid_json"]:
                results["valid_json_count"] += 1
                total_standpoints += validation["standpoints_count"]
                total_counter_questions += validation["counter_questions_count"]
            
            results["detailed_results"].append(result)
            
        except Exception as e:
            print(f"❌ 生成失败: {str(e)}")
            results["detailed_results"].append({
                "question": question,
                "response": "",
                "generation_time": 0,
                "validation": {"valid_json": False, "error": str(e)}
            })
    
    # 计算平均值
    if results["valid_json_count"] > 0:
        results["average_standpoints"] = total_standpoints / results["valid_json_count"]
        results["average_counter_questions"] = total_counter_questions / results["valid_json_count"]
    
    return results

def main():
    parser = argparse.ArgumentParser(description="验证OntoThink模型")
    parser.add_argument("--model_path", required=True, help="训练后的模型路径")
    parser.add_argument("--test_data_path", help="测试数据路径")
    parser.add_argument("--output_path", required=True, help="验证结果输出路径")
    parser.add_argument("--base_model", default="THUDM/chatglm3-6b", help="基础模型名称")
    
    args = parser.parse_args()
    
    # 加载模型
    model, tokenizer = load_model_and_tokenizer(args.model_path, args.base_model)
    
    # 准备测试问题
    if args.test_data_path:
        with open(args.test_data_path, 'r', encoding='utf-8') as f:
            test_data = [json.loads(line) for line in f]
            test_questions = [item.get("question", item.get("instruction", "")) for item in test_data[:10]]  # 取前10个
    else:
        # 使用默认测试问题
        test_questions = [
            "人工智能是否能够拥有真正的意识？",
            "艺术的价值是主观的还是客观的？",
            "个人自由与社会秩序之间应该如何平衡？",
            "科学能否解释所有的自然现象？",
            "道德判断是绝对的还是相对的？"
        ]
    
    print(f"🎯 开始验证，共 {len(test_questions)} 个测试问题")
    
    # 运行验证
    results = run_validation(model, tokenizer, test_questions)
    
    # 保存结果
    with open(args.output_path, 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
    
    # 打印摘要
    print("\n📊 验证结果摘要:")
    print(f"   - 总问题数: {results['total_questions']}")
    print(f"   - 成功生成: {results['successful_generations']}")
    print(f"   - 有效JSON: {results['valid_json_count']}")
    print(f"   - 平均立场数: {results['average_standpoints']:.1f}")
    print(f"   - 平均反问数: {results['average_counter_questions']:.1f}")
    print(f"   - 成功率: {results['valid_json_count']/results['total_questions']*100:.1f}%")
    
    print(f"\n✅ 验证完成！详细结果保存至: {args.output_path}")

if __name__ == "__main__":
    main()
