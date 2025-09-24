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
export PP_SIZE=${PP_SIZE:-"8"}           # 流水线并行大小(8卡)
export LADDER_SHAPE=${LADDER_SHAPE:-"False"}
export SKIP_STEPS=${SKIP_STEPS:-"50"}    # 跳过步数(减少日志)
export MAX_STEPS=${MAX_STEPS:-"-1"}      # 最大训练步数(-1表示按epoch)
export MICRO_BATCH_SIZE=${MICRO_BATCH_SIZE:-"1"}           # 微批次大小
export GRADIENT_ACCUMULATION_STEPS=${GRADIENT_ACCUMULATION_STEPS:-"64"}  # 梯度累积
export EVAL_BATCH_SIZE=${EVAL_BATCH_SIZE:-"1"}             # 评估批次大小
export EVAL_PER_N_EPOCHS=${EVAL_PER_N_EPOCHS:-"1"}         # 每几个epoch评估一次
export TRAIN_EPOCHS=${TRAIN_EPOCHS:-"3"}                   # 训练轮数

# 输出目录
export OUTPUT_DIR=${OUTPUT_DIR:-"${ENFLAME_ROOT}/models/ontothink-chatglm3-6b"}
export LOG_DIR=${LOG_DIR:-"${ENFLAME_ROOT}/logs"}

# 创建必要目录
mkdir -p $OUTPUT_DIR
mkdir -p $LOG_DIR

# ============================== 训练信息显示 ================================
echo "🚀 OntoThink ChatGLM3-6B 燧原T20训练"
echo "==============================================="
echo "📋 训练配置:"
echo "   - 基础模型: $PRETRAINED_MODEL_PATH"
echo "   - 训练数据: $TRAIN_FILE"
echo "   - 最大序列长度: $MAX_TOKENS"
echo "   - 并行配置: TP=$TP_SIZE, DP=$DP_SIZE, PP=$PP_SIZE"
echo "   - 批次配置: micro_batch=$MICRO_BATCH_SIZE, grad_accum=$GRADIENT_ACCUMULATION_STEPS"
echo "   - 训练轮数: $TRAIN_EPOCHS"
echo "   - 输出目录: $OUTPUT_DIR"
echo "==============================================="

# 检查模型是否存在
if [ ! -d "$PRETRAINED_MODEL_PATH" ]; then
    echo "❌ 错误: 未找到ChatGLM3-6B模型，请先下载到: $PRETRAINED_MODEL_PATH"
    echo "💡 下载命令:"
    echo "   cd ${ENFLAME_ROOT}/models"
    echo "   git clone https://huggingface.co/THUDM/chatglm3-6b"
    exit 1
fi

# 检查训练数据是否存在
if [ ! -f "$TRAIN_FILE" ]; then
    echo "❌ 错误: 未找到训练数据，请先运行数据准备脚本"
    echo "💡 准备数据命令:"
    echo "   python ${ENFLAME_ROOT}/scripts/prepare_enflame_data.py \\"
    echo "     --input_dir ${ONTOTHINK_ROOT}/backend/data/processed \\"
    echo "     --output_dir ${ENFLAME_ROOT}/datasets/ontothink_multiturn \\"
    echo "     --format multiturn"
    exit 1
fi

# ============================== 启动训练 ================================
echo "🔥 启动OntoThink ChatGLM3训练..."

# 切换到燧原脚本目录
cd ${ENFLAME_ROOT}/llm_scripts/finetuning/chatglm3

# 备份原始训练脚本
if [ ! -f "finetune_chatglm3_for_multiturn_original.py" ]; then
    cp finetune_chatglm3_for_multiturn.py finetune_chatglm3_for_multiturn_original.py
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
    --gradient_accumulation_steps $GRADIENT_ACCUMULATION_STEPS \
    --max_steps $MAX_STEPS \
    --max_tokens $MAX_TOKENS \
    --ladder_shape $LADDER_SHAPE \
    --skip_steps $SKIP_STEPS \
    --eval_batch_size $EVAL_BATCH_SIZE \
    --eval_per_n_epochs $EVAL_PER_N_EPOCHS \
    --train_epochs $TRAIN_EPOCHS \
    2>&1 | tee "$LOG_FILE"

# ============================== 训练完成处理 ================================
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✅ OntoThink ChatGLM3训练完成！"
    echo "📁 模型保存位置: $OUTPUT_DIR"
    echo "📊 训练日志: $LOG_FILE"
    
    # 保存训练配置
    cat > "${OUTPUT_DIR}/training_config.json" << EOF
{
    "model_name": "OntoThink-ChatGLM3-6B",
    "base_model": "$PRETRAINED_MODEL_PATH",
    "training_data": "$TRAIN_FILE",
    "max_tokens": $MAX_TOKENS,
    "parallel_config": {
        "tp_size": $TP_SIZE,
        "dp_size": $DP_SIZE,
        "pp_size": $PP_SIZE
    },
    "batch_config": {
        "micro_batch_size": $MICRO_BATCH_SIZE,
        "gradient_accumulation_steps": $GRADIENT_ACCUMULATION_STEPS
    },
    "training_epochs": $TRAIN_EPOCHS,
    "training_date": "$(date)",
    "hardware": "Enflame T20 8-cards"
}
EOF
    
    echo "💾 训练配置已保存: ${OUTPUT_DIR}/training_config.json"
    
    # 运行简单验证
    echo "🔍 开始模型验证..."
    $PYTHON_CMD ${ENFLAME_ROOT}/scripts/validate_enflame_model.py \
        --model_path $OUTPUT_DIR \
        --output_path "${OUTPUT_DIR}/validation_results.json"
else
    echo "❌ 训练失败，请检查日志: $LOG_FILE"
    exit 1
fi

echo "🎉 OntoThink 燧原T20训练流程完成！"
