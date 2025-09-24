# OntoThink 模型训练指南

## 🎯 概述

本指南详细介绍如何使用8卡GCU资源训练OntoThink专用的ChatGLM3-6B模型，该模型专门用于生成中文哲学思辨图谱。

## 📋 训练方案

### 🔧 技术栈
- **基础模型**: ChatGLM3-6B (针对中文优化)
- **训练方法**: QLoRA + 分布式训练
- **硬件要求**: 8卡 GCU
- **训练框架**: PyTorch + Transformers + PEFT

### 📊 资源配置
- **GPU配置**: 8卡并行训练
- **内存需求**: 每卡约12GB显存
- **预计训练时间**: 3-5天
- **数据规模**: 2000+ 高质量样本

## 🚀 快速开始

### 1. 环境准备

```bash
# 激活Python环境
cd /Users/barryzhang/myDev3/OntoThink_V4
source backend/venv/bin/activate

# 安装训练依赖
pip install torch torchvision torchaudio
pip install transformers>=4.35.0
pip install peft>=0.6.0
pip install datasets
pip install bitsandbytes
pip install accelerate
pip install tensorboard
pip install scikit-learn
pip install aiohttp
```

### 2. 配置API密钥

```bash
# 设置DeepSeek API密钥（用于数据扩展）
export DEEPSEEK_API_KEY="your_deepseek_api_key"
```

### 3. 一键训练

```bash
# 运行完整训练流程
python backend/scripts/train_manager.py --step full --config backend/config/training_config.json
```

## 📝 详细步骤

### 步骤1: 数据扩展
```bash
# 使用DeepSeek API扩展训练数据
python backend/scripts/expand_training_data.py \
    --api_key $DEEPSEEK_API_KEY \
    --num_samples 300 \
    --output_path backend/data/expanded_data.jsonl
```

### 步骤2: 数据优化
```bash
# 优化数据格式，适配ChatGLM3训练
python backend/scripts/prepare_optimized_data.py \
    --input_dir backend/data/processed \
    --output_dir backend/data/optimized
```

### 步骤3: 启动训练
```bash
# 8卡分布式训练
bash backend/scripts/train_ontothink_8gpu.sh
```

### 步骤4: 模型验证
```bash
# 验证训练后的模型
python backend/scripts/validate_model.py \
    --model_path models/chatglm3-ontothink \
    --test_data_path backend/data/optimized/test.jsonl \
    --output_path models/chatglm3-ontothink/validation_results.json
```

## ⚙️ 训练配置说明

### 模型配置
```json
{
  "model": {
    "base_model": "THUDM/chatglm3-6b",
    "max_seq_length": 2048,
    "output_dir": "models/chatglm3-ontothink"
  }
}
```

### 训练参数
```json
{
  "training": {
    "num_gpus": 8,
    "batch_size_per_gpu": 2,
    "gradient_accumulation_steps": 4,
    "num_epochs": 3,
    "learning_rate": 5e-5,
    "use_lora": true,
    "lora_r": 64,
    "lora_alpha": 128,
    "q_lora": true
  }
}
```

### 数据配置
```json
{
  "data": {
    "expand_samples": 300,
    "test_size": 0.1,
    "val_size": 0.1
  }
}
```

## 📊 数据格式说明

### 输入格式 (JSONL)
```json
{
  "instruction": "你是OntoThink思辨助手...",
  "input": "问题：人工智能是否能够真正理解语言？",
  "output": "论据：\n- 人工智能通过深度学习...",
  "category": "哲学思辨-立场论据",
  "task_type": "argument_generation"
}
```

### 输出格式 (思辨图谱JSON)
```json
{
  "question": "人工智能是否能够真正理解语言？",
  "standpoints": [
    {
      "id": "standpoint_1",
      "text": "人工智能能够真正理解语言",
      "arguments": [
        {
          "id": "argument_1_1",
          "text": "深度学习模型能够捕捉语言的语义结构"
        }
      ]
    }
  ],
  "counter_questions": [
    {
      "id": "counter_question_1",
      "text": "理解语言是否需要意识的参与？"
    }
  ]
}
```

## 🔍 训练监控

### TensorBoard监控
```bash
# 启动TensorBoard
tensorboard --logdir logs/training --port 6006
```

### 关键指标
- **训练损失**: 应逐步下降至 < 1.0
- **验证损失**: 不应出现明显过拟合
- **生成质量**: JSON格式正确率 > 85%
- **思辨深度**: 立场对立性和论证严谨性

## 🎯 优化建议

### 1. 数据质量优化
- 确保立场对立性明确
- 论据具有哲学深度
- 反问具有启发性
- JSON格式严格正确

### 2. 训练参数调优
- **学习率**: 5e-5 (可调整至 3e-5 或 1e-4)
- **LoRA rank**: 64 (可调整至 32 或 128)
- **批次大小**: 根据显存调整
- **训练轮数**: 3轮 (可根据收敛情况调整)

### 3. 硬件优化
- 使用bf16精度训练
- 启用梯度检查点
- 优化数据加载pipeline
- 合理设置并行策略

## 📈 预期效果

### 训练指标
- **收敛时间**: 2-3天
- **最终损失**: < 0.8
- **验证准确率**: > 90%
- **JSON格式正确率**: > 95%

### 生成质量
- 能够生成结构化思辨图谱
- 立场观点具有哲学深度
- 论据支撑逻辑严谨
- 反问具有启发性

## 🔧 故障排除

### 常见问题

**1. 显存不足**
```bash
# 减少批次大小
--per_device_train_batch_size 1
--gradient_accumulation_steps 8
```

**2. 训练速度慢**
```bash
# 检查NCCL配置
export NCCL_DEBUG=INFO
export NCCL_IB_DISABLE=1
```

**3. 数据格式错误**
```bash
# 重新运行数据优化
python backend/scripts/prepare_optimized_data.py
```

**4. 模型不收敛**
```bash
# 调整学习率
--learning_rate 3e-5
```

## 📚 参考资源

- [ChatGLM3 官方文档](https://github.com/THUDM/ChatGLM3)
- [PEFT 训练指南](https://github.com/huggingface/peft)
- [QLoRA 论文](https://arxiv.org/abs/2305.14314)
- [分布式训练最佳实践](https://pytorch.org/tutorials/distributed/ddp_tutorial.html)

## 🎉 训练完成后

### 1. 模型集成到后端
```python
# 在FastAPI中集成训练好的模型
from peft import PeftModel
from transformers import AutoModelForCausalLM, AutoTokenizer

model = AutoModelForCausalLM.from_pretrained("THUDM/chatglm3-6b")
model = PeftModel.from_pretrained(model, "models/chatglm3-ontothink")
```

### 2. 部署测试
```bash
# 启动后端服务
cd backend
python -m uvicorn app.main:app --reload
```

### 3. 性能评估
- 思辨图谱生成速度
- JSON格式正确率
- 哲学内容质量
- 用户体验满意度

---

🚀 **祝您训练成功！如有问题，请参考故障排除部分或查看训练日志。**
