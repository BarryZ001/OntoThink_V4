#!/bin/bash

# 🔥 燧原T20官方标准训练修复脚本
# 基于燧原官方文档和示例脚本
# ========================================

echo "🔥 燧原T20官方标准训练修复"
echo "基于燧原官方文档和llm_scripts"
echo "========================================"

# 确定项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

echo "📁 项目根目录: $PROJECT_ROOT"

# 1. 设置燧原T20环境变量（来自官方脚本）
echo ""
echo "🔧 1. 设置燧原T20环境变量"
echo "----------------------------------------"

cat << 'EOF' > /tmp/enflame_env.sh
#!/bin/bash
# 燧原T20官方环境变量设置

# 燧原EFP加速
export ENFLAME_ENABLE_EFP=true
export ENFLAME_PT_ENABLE_HBM_INPLACE=true

# OpenMP设置
export OMP_NUM_THREADS=5

# ECCL分布式通信设置
export ECCL_MAX_NCHANNELS=2

# 燧原内存管理
export ENFLAME_UMD_FLAGS="mem_alloc_retry_times=1"

# GCU设备可见性
export GCU_VISIBLE_DEVICES=0,1,2,3,4,5,6,7

echo "✅ 燧原T20环境变量已设置"
EOF

echo "✅ 燧原环境变量脚本已创建: /tmp/enflame_env.sh"

# 2. 创建基于燧原官方的OntoThink训练脚本
echo ""
echo "🚀 2. 创建燧原官方标准训练脚本"
echo "----------------------------------------"

cat << 'EOF' > "$PROJECT_ROOT/train_ontothink_enflame_official.sh"
#!/bin/bash
#
# 🔥 OntoThink燧原T20官方标准训练脚本
# 基于燧原官方chatglm3_6b_1h8c_multiturn.sh
#
set -eu -o pipefail

# 动态确定项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

echo "🔥 OntoThink 燧原T20官方标准训练"
echo "基于燧原官方chatglm3_6b_1h8c_multiturn.sh"
echo "============================================"

# ============================== 燧原环境设置 ================================
echo "🔧 设置燧原T20环境变量..."

export ENFLAME_ENABLE_EFP=true
export ENFLAME_PT_ENABLE_HBM_INPLACE=true
export OMP_NUM_THREADS=5
export ECCL_MAX_NCHANNELS=2
export ENFLAME_UMD_FLAGS="mem_alloc_retry_times=1"
export GCU_VISIBLE_DEVICES=0,1,2,3,4,5,6,7

echo "✅ 燧原环境变量设置完成"

# ============================== 训练参数配置 ================================
echo "📋 配置训练参数..."

# 模型路径
export PRETRAINED_MODEL_PATH="$PROJECT_ROOT/enflame_training/models/THUDM/chatglm3-6b"

# 训练数据路径
export TRAIN_FILE="$PROJECT_ROOT/enflame_training/datasets/ontothink_multiturn/train.jsonl"

# 训练参数（使用燧原官方推荐值）
export MAX_TOKENS="2048"
export TP_SIZE="1"
export DP_SIZE="1"
export PP_SIZE="8"
export LADDER_SHAPE="False"
export SKIP_STEPS="10"
export MAX_STEPS="-1"
export MICRO_BATCH_SIZE="1"
export GARDIENT_ACCUMULATION_STEPS="64"
export EVAL_BATCH_SIZE="1"
export EVAL_PER_N_EPOCHS="1"
export TRAIN_EPOCHS="3"

echo "✅ 训练参数配置完成"

# ============================== 检查依赖 ================================
echo "🔍 检查燧原训练环境..."

# 检查模型
if [ ! -d "$PRETRAINED_MODEL_PATH" ]; then
    echo "❌ 模型目录不存在: $PRETRAINED_MODEL_PATH"
    exit 1
fi

# 检查训练数据
if [ ! -f "$TRAIN_FILE" ]; then
    echo "❌ 训练数据不存在: $TRAIN_FILE"
    exit 1
fi

# 检查燧原训练脚本
ENFLAME_SCRIPT_DIR=""
for potential_dir in \
    "$PROJECT_ROOT/FromEnflame/ai_development_toolkit/distributed/llm_scripts_1.0.40/finetuning/chatglm3" \
    "/installer/topsrider_extracted/TopsRider_installer/ai_development_toolkit/distributed/llm_scripts_1.0.40/finetuning/chatglm3" \
    "/usr/local/topsrider/ai_development_toolkit/distributed/llm_scripts_1.0.40/finetuning/chatglm3"; do
    if [ -d "$potential_dir" ] && [ -f "$potential_dir/finetune_chatglm3_for_multiturn.py" ]; then
        ENFLAME_SCRIPT_DIR="$potential_dir"
        break
    fi
done

if [ -z "$ENFLAME_SCRIPT_DIR" ]; then
    echo "❌ 未找到燧原ChatGLM3训练脚本"
    exit 1
fi

echo "✅ 燧原脚本目录: $ENFLAME_SCRIPT_DIR"

# ============================== 输出目录设置 ================================
OUTPUT_DIR="$PROJECT_ROOT/enflame_training/models/ontothink-chatglm3-6b"
mkdir -p "$OUTPUT_DIR"

echo "📁 输出目录: $OUTPUT_DIR"

# ============================== 启动训练 ================================
echo ""
echo "🚀 启动OntoThink燧原T20训练..."
echo "训练配置："
echo "  模型: $PRETRAINED_MODEL_PATH"
echo "  数据: $TRAIN_FILE"
echo "  最大长度: $MAX_TOKENS"
echo "  并行: TP=$TP_SIZE, DP=$DP_SIZE, PP=$PP_SIZE"
echo "  批次: micro=$MICRO_BATCH_SIZE, accum=$GARDIENT_ACCUMULATION_STEPS"
echo "  轮数: $TRAIN_EPOCHS"
echo "  输出: $OUTPUT_DIR"
echo ""

# 切换到燧原脚本目录
cd "$ENFLAME_SCRIPT_DIR"

# 使用燧原官方启动方式
python3.8 -u -m torch.distributed.launch \
    --nproc_per_node=8 \
    --standalone \
    --use_env finetune_chatglm3_for_multiturn.py \
    --model_path "$PRETRAINED_MODEL_PATH" \
    --train_file "$TRAIN_FILE" \
    --tp_size $TP_SIZE \
    --dp_size $DP_SIZE \
    --pp_size $PP_SIZE \
    --train_micro_batch_size $MICRO_BATCH_SIZE \
    --gradient_accumulation_steps $GARDIENT_ACCUMULATION_STEPS \
    --max_steps $MAX_STEPS \
    --max_tokens $MAX_TOKENS \
    --ladder_shape $LADDER_SHAPE \
    --skip_steps $SKIP_STEPS \
    --eval_batch_size $EVAL_BATCH_SIZE \
    --eval_per_n_epochs $EVAL_PER_N_EPOCHS \
    --train_epochs $TRAIN_EPOCHS

echo "🎉 训练完成！"
EOF

chmod +x "$PROJECT_ROOT/train_ontothink_enflame_official.sh"
echo "✅ 燧原官方标准训练脚本已创建"

# 3. 创建燧原依赖安装脚本
echo ""
echo "📦 3. 创建燧原依赖安装脚本"
echo "----------------------------------------"

cat << 'EOF' > "$PROJECT_ROOT/install_enflame_official.sh"
#!/bin/bash

# 🔥 燧原T20官方依赖安装脚本
# 基于燧原官方install_for_llm_scripts.sh
# ========================================

echo "🔥 燧原T20官方依赖安装"
echo "基于燧原官方install_for_llm_scripts.sh"
echo "=================================="

# 确定项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# 查找燧原工具包
ENFLAME_ROOT=""
for potential_root in \
    "$PROJECT_ROOT/FromEnflame/ai_development_toolkit" \
    "/installer/topsrider_extracted/TopsRider_installer/ai_development_toolkit" \
    "/usr/local/topsrider/ai_development_toolkit"; do
    if [ -d "$potential_root/distributed" ] && [ -d "$potential_root/huggingface-gcu" ]; then
        ENFLAME_ROOT="$potential_root"
        break
    fi
done

if [ -z "$ENFLAME_ROOT" ]; then
    echo "❌ 未找到燧原工具包"
    exit 1
fi

echo "✅ 燧原工具包: $ENFLAME_ROOT"

DIST_PATH="$ENFLAME_ROOT/distributed"
HF_PATH="$ENFLAME_ROOT/huggingface-gcu"
LLM_SCRIPTS_PATH="$DIST_PATH/llm_scripts_1.0.40"

# 检查燧原install脚本
if [ ! -f "$LLM_SCRIPTS_PATH/install_for_llm_scripts.sh" ]; then
    echo "❌ 未找到燧原官方安装脚本"
    exit 1
fi

echo "🚀 运行燧原官方依赖安装..."

# 切换到燧原脚本目录并运行官方安装
cd "$LLM_SCRIPTS_PATH"
bash install_for_llm_scripts.sh

echo "✅ 燧原官方依赖安装完成"

# 额外安装一些可能需要的包
echo "📦 安装额外依赖..."
pip3 install sentencepiece==0.1.99 --no-deps
pip3 install einops==0.6.1 --no-deps
pip3 install rich --no-deps

echo "🎉 所有依赖安装完成！"
EOF

chmod +x "$PROJECT_ROOT/install_enflame_official.sh"
echo "✅ 燧原官方依赖安装脚本已创建"

# 4. 创建使用说明
echo ""
echo "📖 4. 创建使用说明"
echo "----------------------------------------"

cat << 'EOF' > "$PROJECT_ROOT/ENFLAME_TRAINING_GUIDE.md"
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
EOF

echo "✅ 使用说明已创建: ENFLAME_TRAINING_GUIDE.md"

echo ""
echo "🎉 燧原T20官方标准修复完成！"
echo ""
echo "📋 接下来请在服务器上运行："
echo "1. git pull origin main"
echo "2. bash install_enflame_official.sh"
echo "3. bash train_ontothink_enflame_official.sh"
echo ""
echo "这个脚本完全基于燧原官方标准，应该能解决训练问题！"
