# OntoThink 燧原T20训练方案

## 🎯 概述

本目录包含了OntoThink项目在燧原T20硬件上进行ChatGLM3-6B模型训练的完整解决方案。

## 🚀 快速开始

### 前提条件

1. **燧原T20硬件环境**：8卡GCU
2. **燧原工具包**：将燧原提供的`TopsRider_t2x_2.5.136_deb_amd64`放置在项目根目录的`FromEnflame/`文件夹中
3. **ChatGLM3-6B模型**：需要下载到指定目录

### 一键启动训练

```bash
# 1. 确保燧原工具包就位
ls FromEnflame/TopsRider_t2x_2.5.136_deb_amd64/

# 2. 运行完整训练流程
python enflame_training/scripts/train_ontothink_enflame.py --step full

# 或者分步执行
python enflame_training/scripts/train_ontothink_enflame.py --step check    # 检查环境
python enflame_training/scripts/train_ontothink_enflame.py --step prepare  # 准备数据
python enflame_training/scripts/train_ontothink_enflame.py --step train    # 开始训练
```

## 📁 目录结构

```
enflame_training/
├── README.md                           # 本文档
├── setup_enflame_env.sh               # 环境配置脚本
└── scripts/
    ├── train_ontothink_enflame.py      # 一键训练管理器
    ├── prepare_enflame_data.py         # 数据格式转换
    ├── ontothink_chatglm3_enflame.sh   # 燧原训练脚本
    └── validate_enflame_model.py       # 模型验证工具
```

## ⚙️ 训练配置

- **基础模型**: ChatGLM3-6B
- **训练方法**: 基于燧原collie_lm + deepspeed
- **并行策略**: PP=8 (8卡流水线并行)
- **序列长度**: 2048 tokens
- **训练轮数**: 3 epochs
- **批次配置**: micro_batch=1, grad_accum=64

## 📊 预期效果

- **训练时间**: 3-5天 (根据数据量)
- **模型质量**: 支持OntoThink思辨图谱生成
- **输出格式**: 结构化JSON思辨数据

## 🔧 故障排除

1. **环境问题**: 确保燧原工具包路径正确
2. **模型下载**: 手动下载ChatGLM3-6B到指定路径
3. **训练监控**: 查看`enflame_training/logs/`目录下的日志

## 📚 相关文档

- [OntoThink模型训练指南](../docs/OntoThink模型训练指南.md)
- [燧原T20官方文档](FromEnflame/TopsRider_t2x_2.5.136_deb_amd64/ai_development_toolkit/distributed/documents/)

---

🚀 **开始您的OntoThink燧原T20训练之旅！**
