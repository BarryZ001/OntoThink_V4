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
