#!/usr/bin/env python3
"""
OntoThink训练数据扩展脚本
使用现有种子数据生成更多高质量的训练样本
"""

import json
import random
import asyncio
import aiohttp
from typing import List, Dict
import argparse
from pathlib import Path

# 哲学领域和问题模板
PHILOSOPHY_DOMAINS = {
    "形而上学": [
        "存在的本质是什么？",
        "时间是真实存在的还是人类认知的产物？",
        "空间是无限的吗？",
        "因果关系是必然的吗？",
        "个体性的原则是什么？"
    ],
    "认识论": [
        "知识的界限在哪里？",
        "感性经验能否提供可靠的知识？",
        "理性与经验哪个更重要？",
        "怀疑主义是否有道理？",
        "真理的标准是什么？"
    ],
    "伦理学": [
        "道德的基础是什么？",
        "个人幸福与社会利益如何平衡？",
        "善恶的标准是普遍的吗？",
        "道德责任的前提是什么？",
        "美德与规则哪个更重要？"
    ],
    "美学": [
        "美的标准是客观的吗？",
        "艺术的本质是模仿还是创造？",
        "审美经验的独特性何在？",
        "艺术与现实的关系如何？",
        "美与善、真的关系是什么？"
    ],
    "心灵哲学": [
        "意识的本质是什么？",
        "心灵与身体的关系如何？",
        "人工智能能否产生真正的意识？",
        "自我认同的标准是什么？",
        "情感在认知中的作用是什么？"
    ],
    "政治哲学": [
        "理想的政治制度是什么？",
        "个人自由与社会秩序如何平衡？",
        "正义的原则是什么？",
        "权力的合法性来源何在？",
        "公民不服从在什么情况下是正当的？"
    ]
}

def generate_philosophical_questions(num_questions: int = 50) -> List[str]:
    """生成多样化的哲学问题"""
    questions = []
    
    # 从现有模板生成
    for domain, domain_questions in PHILOSOPHY_DOMAINS.items():
        questions.extend(domain_questions)
    
    # 生成组合问题
    combined_questions = [
        "如果{}，那么{}？".format(
            random.choice(["自由意志不存在", "道德是相对的", "知识是有限的", "美是主观的"]),
            random.choice(["责任如何定义", "价值如何衡量", "真理如何追求", "创造如何可能"])
        )
        for _ in range(10)
    ]
    
    questions.extend(combined_questions)
    
    # 生成对比问题
    contrast_questions = [
        "{}与{}：哪个更根本？".format(
            random.choice(["理性", "感性", "个体", "集体", "自由", "秩序"]),
            random.choice(["情感", "直觉", "社会", "个人", "安全", "创新"])
        )
        for _ in range(10)
    ]
    
    questions.extend(contrast_questions)
    
    return random.sample(questions, min(num_questions, len(questions)))

async def generate_with_deepseek(session: aiohttp.ClientSession, question: str, api_key: str) -> Dict:
    """使用DeepSeek API生成思辨数据"""
    
    prompt = f"""请基于以下哲学问题，生成包含不同立场、支持论据和反问的思辨图谱数据。请严格按照以下JSON格式输出：

{{
  "question": "{question}",
  "standpoints": [
    {{
      "id": "standpoint_1",
      "text": "[立场1的陈述]",
      "arguments": [
        {{
          "id": "argument_1_1",
          "text": "[支持立场1的论据1]"
        }},
        {{
          "id": "argument_1_2",
          "text": "[支持立场1的论据2]"
        }}
      ]
    }},
    {{
      "id": "standpoint_2",
      "text": "[立场2的陈述]",
      "arguments": [
        {{
          "id": "argument_2_1",
          "text": "[支持立场2的论据1]"
        }},
        {{
          "id": "argument_2_2",
          "text": "[支持立场2的论据2]"
        }}
      ]
    }}
  ],
  "counter_questions": [
    {{
      "id": "counter_question_1",
      "text": "[针对上述立场或论据的反问1]"
    }},
    {{
      "id": "counter_question_2",
      "text": "[针对上述立场或论据的反问2]"
    }}
  ]
}}

要求：
1. 立场应该对立或互补，体现问题的复杂性
2. 论据要有哲学深度，避免常识性表述
3. 反问要能引发深层思考，挑战现有观点
4. 确保JSON格式正确，所有字段完整

问题：{question}"""

    payload = {
        "model": "deepseek-chat",
        "messages": [
            {"role": "user", "content": prompt}
        ],
        "temperature": 0.7,
        "max_tokens": 2000
    }
    
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    
    try:
        async with session.post(
            "https://api.deepseek.com/v1/chat/completions",
            json=payload,
            headers=headers
        ) as response:
            if response.status == 200:
                result = await response.json()
                content = result["choices"][0]["message"]["content"].strip()
                
                # 尝试解析JSON
                try:
                    # 提取JSON部分
                    start = content.find('{')
                    end = content.rfind('}') + 1
                    if start != -1 and end != 0:
                        json_content = content[start:end]
                        data = json.loads(json_content)
                        return data
                    else:
                        print(f"⚠️  无法提取JSON: {question}")
                        return None
                except json.JSONDecodeError as e:
                    print(f"⚠️  JSON解析失败: {question} - {e}")
                    return None
            else:
                print(f"❌ API请求失败: {response.status}")
                return None
    except Exception as e:
        print(f"❌ 请求异常: {e}")
        return None

def convert_to_training_format(data: Dict) -> List[Dict]:
    """将思辨数据转换为训练格式"""
    training_samples = []
    
    question = data["question"]
    
    # 生成立场+论据的训练样本
    for standpoint in data.get("standpoints", []):
        instruction = f"请基于以下哲学问题，提出一个明确的立场并给出支持论据：\n\n问题：{question}\n\n立场：{standpoint['text']}"
        
        arguments_text = "\n".join([
            f"- {arg['text']}" for arg in standpoint.get("arguments", [])
        ])
        
        output = f"论据：\n{arguments_text}"
        
        training_samples.append({
            "instruction": instruction,
            "input": "",
            "output": output,
            "category": "哲学思辨-立场论据"
        })
    
    # 生成反问的训练样本
    for i, cq in enumerate(data.get("counter_questions", [])):
        # 随机选择一个立场作为反问的对象
        if data.get("standpoints"):
            target_standpoint = random.choice(data["standpoints"])
            
            instruction = f"请针对以下哲学立场，提出一个具有挑战性的反问：\n\n问题：{question}\n立场：{target_standpoint['text']}\n"
            
            output = f"反问：{cq['text']}"
            
            training_samples.append({
                "instruction": instruction,
                "input": "",
                "output": output,
                "category": "哲学思辨-反问"
            })
    
    return training_samples

async def generate_training_data(api_key: str, num_samples: int = 100, output_path: str = None):
    """批量生成训练数据"""
    
    print(f"🚀 开始生成 {num_samples} 个训练样本...")
    
    # 生成问题
    questions = generate_philosophical_questions(num_samples)
    
    all_training_samples = []
    successful_generations = 0
    
    async with aiohttp.ClientSession() as session:
        # 限制并发数量以避免API限制
        semaphore = asyncio.Semaphore(3)
        
        async def process_question(question):
            async with semaphore:
                print(f"📝 处理问题: {question}")
                data = await generate_with_deepseek(session, question, api_key)
                
                if data:
                    training_samples = convert_to_training_format(data)
                    return training_samples
                return []
        
        # 并发处理所有问题
        tasks = [process_question(q) for q in questions]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        for result in results:
            if isinstance(result, list) and result:
                all_training_samples.extend(result)
                successful_generations += 1
            elif isinstance(result, Exception):
                print(f"❌ 处理异常: {result}")
    
    print(f"✅ 成功生成 {len(all_training_samples)} 个训练样本 (成功率: {successful_generations}/{len(questions)})")
    
    # 保存结果
    if output_path:
        output_file = Path(output_path)
        output_file.parent.mkdir(parents=True, exist_ok=True)
        
        with open(output_file, 'w', encoding='utf-8') as f:
            for sample in all_training_samples:
                f.write(json.dumps(sample, ensure_ascii=False) + '\n')
        
        print(f"💾 训练数据已保存至: {output_file}")
    
    return all_training_samples

def main():
    parser = argparse.ArgumentParser(description="扩展OntoThink训练数据")
    parser.add_argument("--api_key", required=True, help="DeepSeek API密钥")
    parser.add_argument("--num_samples", type=int, default=100, help="生成样本数量")
    parser.add_argument("--output_path", required=True, help="输出文件路径")
    
    args = parser.parse_args()
    
    # 运行数据生成
    asyncio.run(generate_training_data(
        api_key=args.api_key,
        num_samples=args.num_samples,
        output_path=args.output_path
    ))

if __name__ == "__main__":
    main()
