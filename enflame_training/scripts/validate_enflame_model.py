#!/usr/bin/env python3
"""
OntoThink 燧原T20训练模型验证脚本
"""

import json
import argparse
import sys
import os
from pathlib import Path
from typing import List, Dict

# 添加燧原collie路径
sys.path.append("../llm_scripts")

try:
    import torch
    import ptex
    from transformers import AutoTokenizer
    from collie import ChatGLM2ForCausalLM, CollieConfig
except ImportError as e:
    print(f"❌ 导入燧原库失败: {e}")
    print("💡 请确保已安装燧原T20环境和依赖库")
    sys.exit(1)

class OntoThinkEnflameValidator:
    def __init__(self, model_path: str):
        self.model_path = model_path
        self.model = None
        self.tokenizer = None
        
    def load_model(self):
        """加载燧原训练的模型"""
        print(f"🔄 加载燧原T20训练的模型: {self.model_path}")
        
        try:
            # 加载配置
            config = CollieConfig.from_pretrained(self.model_path, trust_remote_code=True)
            
            # 加载tokenizer
            self.tokenizer = AutoTokenizer.from_pretrained(
                self.model_path, 
                trust_remote_code=True
            )
            
            # 加载模型
            self.model = ChatGLM2ForCausalLM.from_pretrained(
                self.model_path,
                config=config,
                trust_remote_code=True
            )
            
            print("✅ 模型加载成功")
            return True
            
        except Exception as e:
            print(f"❌ 模型加载失败: {e}")
            return False
    
    def generate_response(self, question: str, max_length: int = 2048) -> str:
        """生成OntoThink回答"""
        if not self.model or not self.tokenizer:
            return "模型未加载"
        
        # 构建OntoThink格式的prompt
        prompt = f"""你是OntoThink专业思辨助手，擅长分析哲学问题并生成多维度思辨图谱。

请为以下哲学问题生成完整的思辨图谱，包含不同立场、支持论据和反问。输出必须是有效的JSON格式。

问题：{question}

请生成符合以下格式的思辨图谱：
```json
{{
  "question": "问题",
  "standpoints": [
    {{
      "id": "standpoint_1",
      "text": "立场1",
      "arguments": [
        {{"id": "argument_1_1", "text": "论据1"}},
        {{"id": "argument_1_2", "text": "论据2"}}
      ]
    }}
  ],
  "counter_questions": [
    {{"id": "counter_question_1", "text": "反问1"}}
  ]
}}
```"""
        
        try:
            # 编码输入
            inputs = self.tokenizer(prompt, return_tensors="pt")
            
            # 生成回答
            with torch.no_grad():
                outputs = self.model.generate(
                    **inputs,
                    max_length=max_length,
                    temperature=0.7,
                    top_p=0.8,
                    do_sample=True,
                    pad_token_id=self.tokenizer.eos_token_id
                )
            
            # 解码输出
            response = self.tokenizer.decode(
                outputs[0][inputs['input_ids'].shape[1]:], 
                skip_special_tokens=True
            )
            
            return response.strip()
            
        except Exception as e:
            return f"生成失败: {e}"
    
    def validate_json_format(self, response: str) -> Dict:
        """验证生成的JSON格式"""
        try:
            # 提取JSON部分
            start = response.find('{')
            end = response.rfind('}') + 1
            
            if start == -1 or end == 0:
                return {"valid": False, "error": "未找到JSON格式"}
            
            json_content = response[start:end]
            data = json.loads(json_content)
            
            # 检查必要字段
            required_fields = ["question", "standpoints", "counter_questions"]
            missing_fields = [field for field in required_fields if field not in data]
            
            if missing_fields:
                return {
                    "valid": False, 
                    "error": f"缺少字段: {missing_fields}"
                }
            
            # 统计内容
            standpoints_count = len(data.get("standpoints", []))
            counter_questions_count = len(data.get("counter_questions", []))
            
            return {
                "valid": True,
                "standpoints_count": standpoints_count,
                "counter_questions_count": counter_questions_count,
                "json_data": data
            }
            
        except json.JSONDecodeError as e:
            return {"valid": False, "error": f"JSON解析错误: {e}"}
        except Exception as e:
            return {"valid": False, "error": f"验证错误: {e}"}
    
    def run_validation(self, test_questions: List[str]) -> Dict:
        """运行完整验证"""
        results = {
            "model_path": self.model_path,
            "total_questions": len(test_questions),
            "successful_generations": 0,
            "valid_json_count": 0,
            "average_standpoints": 0,
            "average_counter_questions": 0,
            "test_results": []
        }
        
        total_standpoints = 0
        total_counter_questions = 0
        
        for i, question in enumerate(test_questions):
            print(f"🔍 测试问题 {i+1}/{len(test_questions)}: {question[:30]}...")
            
            # 生成回答
            response = self.generate_response(question)
            
            # 验证格式
            validation = self.validate_json_format(response)
            
            test_result = {
                "question": question,
                "response": response,
                "validation": validation
            }
            
            if response and "生成失败" not in response:
                results["successful_generations"] += 1
            
            if validation["valid"]:
                results["valid_json_count"] += 1
                total_standpoints += validation["standpoints_count"]
                total_counter_questions += validation["counter_questions_count"]
            
            results["test_results"].append(test_result)
        
        # 计算平均值
        if results["valid_json_count"] > 0:
            results["average_standpoints"] = total_standpoints / results["valid_json_count"]
            results["average_counter_questions"] = total_counter_questions / results["valid_json_count"]
        
        return results

def main():
    parser = argparse.ArgumentParser(description="验证燧原T20训练的OntoThink模型")
    parser.add_argument("--model_path", required=True, help="训练后的模型路径")
    parser.add_argument("--output_path", required=True, help="验证结果输出路径")
    
    args = parser.parse_args()
    
    # 测试问题
    test_questions = [
        "人工智能是否能够拥有真正的创造力？",
        "在数字时代，隐私权的边界应该如何定义？",
        "艺术的价值是由创作者决定还是由观众决定？",
        "科学进步是否总是促进人类福祉？",
        "个人自由与集体利益之间的平衡点在哪里？"
    ]
    
    print("🚀 开始验证OntoThink燧原T20训练模型")
    
    # 初始化验证器
    validator = OntoThinkEnflameValidator(args.model_path)
    
    # 加载模型
    if not validator.load_model():
        print("❌ 模型加载失败，终止验证")
        return
    
    # 运行验证
    results = validator.run_validation(test_questions)
    
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
