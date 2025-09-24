#!/bin/bash
# 手动修复燧原训练脚本的路径问题

echo "🔧 手动修复燧原训练脚本路径问题"
echo "========================================"

SCRIPT_FILE="enflame_training/scripts/ontothink_chatglm3_enflame.sh"

if [ ! -f "$SCRIPT_FILE" ]; then
    echo "❌ 训练脚本文件不存在: $SCRIPT_FILE"
    exit 1
fi

echo "📝 备份原始脚本..."
cp "$SCRIPT_FILE" "${SCRIPT_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

echo "🔧 应用路径修复..."

# 检查脚本是否已经包含多路径查找逻辑
if grep -q "CHATGLM3_SCRIPT_DIRS" "$SCRIPT_FILE"; then
    echo "✅ 脚本已包含多路径查找逻辑"
else
    echo "⚠️  脚本需要手动修复"
    
    # 创建修复后的脚本内容
    cat > temp_fixed_script.sh << 'EOF'
#!/bin/bash
#
# OntoThink ChatGLM3-6B 燧原T20训练脚本
# 基于燧原官方ChatGLM3微调脚本优化
#
# Copyright (c) 2024 OntoThink Project. All rights reserved.
#

set -eu -o pipefail

# ============================== 燧原T20环境配置 ================================
export ENFLAME_ENABLE_EFP=true
export ENFLAME_PT_ENABLE_HBM_INPLACE=true
export OMP_NUM_THREADS=5
export ECCL_MAX_NCHANNELS=2
export ENFLAME_UMD_FLAGS="mem_alloc_retry_times=1"

# ============================== OntoThink训练配置 ================================
# 基础路径 - 自动检测
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENFLAME_ROOT="$(dirname "$SCRIPT_DIR")"
ONTOTHINK_ROOT="$(dirname "$ENFLAME_ROOT")"

echo "📁 项目根目录: $ONTOTHINK_ROOT"
echo "📁 燧原目录: $ENFLAME_ROOT"

# 模型配置
export PRETRAINED_MODEL_PATH=${PRETRAINED_MODEL_PATH:-"${ENFLAME_ROOT}/models/THUDM/chatglm3-6b"}
export TRAIN_FILE=${TRAIN_FILE:-"${ENFLAME_ROOT}/datasets/ontothink_multiturn/train.jsonl"}

# 训练参数配置
export MAX_TOKENS=${MAX_TOKENS:-"2048"}  # OntoThink需要较长上下文
export TP_SIZE=${TP_SIZE:-"1"}           # 张量并行大小
export DP_SIZE=${DP_SIZE:-"1"}           # 数据并行大小  
export PP_SIZE=${PP_SIZE:-"8"}           # 流水线并行大小
export MICRO_BATCH_SIZE=${MICRO_BATCH_SIZE:-"1"}           # 微批次大小
export GARDIENT_ACCUMULATION_STEPS=${GARDIENT_ACCUMULATION_STEPS:-"64"}  # 梯度累积步数
export MAX_STEPS=${MAX_STEPS:-"1000"}    # 最大训练步数
export LADDER_SHAPE=${LADDER_SHAPE:-"false"}  # 是否使用阶梯形状
export SKIP_STEPS=${SKIP_STEPS:-"0"}     # 跳过步数
export EVAL_BATCH_SIZE=${EVAL_BATCH_SIZE:-"1"}     # 评估批次大小
export EVAL_PER_N_EPOCHS=${EVAL_PER_N_EPOCHS:-"1"} # 每N个epoch评估一次
export TRAIN_EPOCHS=${TRAIN_EPOCHS:-"3"} # 训练轮数

# 输出目录配置
export OUTPUT_DIR=${OUTPUT_DIR:-"${ENFLAME_ROOT}/models/ontothink-chatglm3-6b"}
export LOG_DIR=${LOG_DIR:-"${ENFLAME_ROOT}/logs"}

# 创建必要目录
mkdir -p $OUTPUT_DIR
mkdir -p $LOG_DIR

# ============================== 环境检查 ================================
echo "🚀 OntoThink ChatGLM3-6B 燧原T20训练"
echo "==============================================="
echo "📋 训练配置:"
echo "   - 基础模型: $PRETRAINED_MODEL_PATH"
echo "   - 训练数据: $TRAIN_FILE"
echo "   - 最大序列长度: $MAX_TOKENS"
echo "   - 并行配置: TP=$TP_SIZE, DP=$DP_SIZE, PP=$PP_SIZE"
echo "   - 批次配置: micro_batch=$MICRO_BATCH_SIZE, grad_accum=$GARDIENT_ACCUMULATION_STEPS"
echo "   - 训练轮数: $TRAIN_EPOCHS"
echo "   - 输出目录: $OUTPUT_DIR"
echo "==============================================="

# 检查模型是否存在
if [ ! -d "$PRETRAINED_MODEL_PATH" ]; then
    echo "❌ 错误: 未找到ChatGLM3-6B模型，请先下载到: $PRETRAINED_MODEL_PATH"
    echo "💡 下载命令:"
    echo "   cd $ENFLAME_ROOT/models"
    echo "   git clone https://huggingface.co/THUDM/chatglm3-6b"
    exit 1
fi

# 检查训练数据是否存在
if [ ! -f "$TRAIN_FILE" ]; then
    echo "❌ 错误: 未找到训练数据文件: $TRAIN_FILE"
    echo "💡 请先准备训练数据"
    exit 1
fi

# ============================== 启动训练 ================================
echo "🔥 启动OntoThink ChatGLM3训练..."

# 查找并切换到燧原ChatGLM3脚本目录
CHATGLM3_SCRIPT_DIRS=(
    "${ONTOTHINK_ROOT}/FromEnflame/ai_development_toolkit/distributed/llm_scripts_1.0.40/finetuning/chatglm3"
    "/installer/topsrider_extracted/TopsRider_installer/ai_development_toolkit/distributed/llm_scripts_1.0.40/finetuning/chatglm3"
    "${ONTOTHINK_ROOT}/FromEnflame/distributed/llm_scripts_1.0.40/finetuning/chatglm3"
    "${ENFLAME_ROOT}/llm_scripts/finetuning/chatglm3"
)

SCRIPT_DIR_FOUND=""
for dir in "${CHATGLM3_SCRIPT_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        SCRIPT_DIR_FOUND="$dir"
        echo "✅ 找到ChatGLM3脚本目录: $dir"
        break
    fi
done

if [ -z "$SCRIPT_DIR_FOUND" ]; then
    echo "❌ 未找到ChatGLM3脚本目录，请检查燧原工具包安装"
    echo "🔍 查找燧原工具包目录结构:"
    find "${ONTOTHINK_ROOT}/FromEnflame" -name "*chatglm*" -type d 2>/dev/null | head -5
    exit 1
fi

cd "$SCRIPT_DIR_FOUND"

# 检查训练脚本是否存在
TRAIN_SCRIPT="finetune_chatglm3_for_multiturn.py"
if [ ! -f "$TRAIN_SCRIPT" ]; then
    echo "❌ 未找到训练脚本: $TRAIN_SCRIPT"
    echo "📂 当前目录内容:"
    ls -la
    echo "🔍 查找ChatGLM3相关脚本:"
    find . -name "*chatglm*" -name "*.py" 2>/dev/null
    exit 1
fi

# 备份原始训练脚本
if [ ! -f "finetune_chatglm3_for_multiturn_original.py" ]; then
    cp "$TRAIN_SCRIPT" "finetune_chatglm3_for_multiturn_original.py"
    echo "💾 已备份原始训练脚本"
fi

# 检测Python命令
PYTHON_CMD="python3"
if command -v python3.8 &> /dev/null; then
    PYTHON_CMD="python3.8"
fi

# 启动分布式训练
LOG_FILE="${LOG_DIR}/ontothink_training_$(date +%Y%m%d_%H%M%S).log"

$PYTHON_CMD -u -m torch.distributed.launch \
    --nproc_per_node=8 \
    --standalone \
    --use_env finetune_chatglm3_for_multiturn.py \
    --model_path $PRETRAINED_MODEL_PATH \
    --train_file $TRAIN_FILE \
    --tp_size $TP_SIZE \
    --dp_size $DP_SIZE \
    --pp_size $PP_SIZE \
    --train_micro_batch_size $MICRO_BATCH_SIZE \
    --gradient_accumulation_steps $GARDIENT_ACCUMULATION_STEPS \
    --max_steps $MAX_STEPS \
    --max_tokens $MAX_TOKENS \
    --ladder_shape $LADDER_SHAPE \
    --skip_steps  $SKIP_STEPS \
    --eval_batch_size $EVAL_BATCH_SIZE \
    --eval_per_n_epochs $EVAL_PER_N_EPOCHS \
    --train_epochs $TRAIN_EPOCHS \
    2>&1 | tee "$LOG_FILE"

# 检查训练是否成功
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "🎉 OntoThink ChatGLM3训练完成！"
    echo "📁 模型输出目录: $OUTPUT_DIR"
    echo "📊 训练日志: $LOG_FILE"
    
    # 创建模型信息文件
    cat > "$OUTPUT_DIR/model_info.json" << EOF
{
    "model_name": "OntoThink-ChatGLM3-6B",
    "base_model": "THUDM/chatglm3-6b",
    "training_data": "$TRAIN_FILE",
    "training_config": {
        "max_tokens": $MAX_TOKENS,
        "tp_size": $TP_SIZE,
        "dp_size": $DP_SIZE,
        "pp_size": $PP_SIZE,
        "micro_batch_size": $MICRO_BATCH_SIZE,
        "gradient_accumulation_steps": $GARDIENT_ACCUMULATION_STEPS,
        "max_steps": $MAX_STEPS,
        "train_epochs": $TRAIN_EPOCHS
    },
    "training_completed": "$(date -Iseconds)",
    "output_directory": "$OUTPUT_DIR"
}
EOF
    
    echo "✅ 训练信息已保存到: $OUTPUT_DIR/model_info.json"
    
else
    echo "❌ OntoThink ChatGLM3训练失败，请检查日志: $LOG_FILE"
    exit 1
fi
EOF

    # 替换原始脚本
    mv temp_fixed_script.sh "$SCRIPT_FILE"
    chmod +x "$SCRIPT_FILE"
    
    echo "✅ 脚本修复完成！"
fi

echo ""
echo "🎉 修复完成！现在可以运行训练了："
echo "   python3 enflame_training/scripts/train_ontothink_enflame.py --step full"
