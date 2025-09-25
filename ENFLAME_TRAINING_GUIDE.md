# 🔥 燧原T20官方标准训练指南

基于燧原官方文档和llm_scripts示例

## 🚀 快速开始

### 1. 安装燧原依赖（服务器上运行）

```bash
cd /workspace/code/OntoThink_V4
bash install_enflame_official.sh
```

### 2. 运行燧原官方标准训练（服务器上运行）

```bash
cd /workspace/code/OntoThink_V4
bash train_ontothink_enflame_official.sh
```

## 📋 关键特性

### 🔧 燧原T20环境变量
- `ENFLAME_ENABLE_EFP=true`: 启用燧原EFP加速
- `ENFLAME_PT_ENABLE_HBM_INPLACE=true`: 启用HBM原地操作
- `ECCL_MAX_NCHANNELS=2`: ECCL通信通道数
- `ENFLAME_UMD_FLAGS="mem_alloc_retry_times=1"`: 内存分配重试

### 🚀 燧原分布式启动
- 使用 `python3.8 -u -m torch.distributed.launch`
- `--nproc_per_node=8`: 8卡GCU
- `--standalone`: 单机模式
- `--use_env`: 使用环境变量

### 📦 燧原官方依赖
- 使用燧原官方 `install_for_llm_scripts.sh`
- 燧原优化版本：ptex, collie_lm, deepspeed, transformers, accelerate, peft

## 🔍 问题排查

如果训练仍然失败，请检查：

1. **GCU设备状态**:
   ```bash
   ls -la /dev/gcu*
   ```

2. **燧原Python包**:
   ```bash
   python3 -c "import ptex, collie_lm; print('燧原包正常')"
   ```

3. **燧原torch_gcu**:
   ```bash
   python3 -c "import torch; print('PyTorch:', torch.__version__)"
   ```

## 📚 参考文档

- 燧原LLM微调用户指南: `FromEnflame/.../documents/Enflame_llm_finetuning_user_guide.md`
- 燧原官方示例: `FromEnflame/.../llm_scripts_1.0.40/finetuning/chatglm3/`
