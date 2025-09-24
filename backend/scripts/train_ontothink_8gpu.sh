#!/bin/bash
# OntoThink ChatGLM3-6B 8卡GCU分布式训练脚本

# 设置环境变量
export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export NCCL_DEBUG=INFO
export NCCL_IB_DISABLE=1
export NCCL_P2P_DISABLE=1

# 模型和数据路径
MODEL_NAME="THUDM/chatglm3-6b"
DATA_PATH="/Users/barryzhang/myDev3/OntoThink_V4/backend/data/processed"
OUTPUT_DIR="/Users/barryzhang/myDev3/OntoThink_V4/models/chatglm3-ontothink"
LOG_DIR="/Users/barryzhang/myDev3/OntoThink_V4/logs/training"

# 创建必要目录
mkdir -p $OUTPUT_DIR
mkdir -p $LOG_DIR

# 训练参数
NUM_GPUS=8
BATCH_SIZE_PER_GPU=2
GRADIENT_ACCUMULATION_STEPS=4
EFFECTIVE_BATCH_SIZE=$((NUM_GPUS * BATCH_SIZE_PER_GPU * GRADIENT_ACCUMULATION_STEPS))

echo "🚀 开始OntoThink模型训练"
echo "📊 训练配置:"
echo "   - 基础模型: $MODEL_NAME"
echo "   - GPU数量: $NUM_GPUS"
echo "   - 每GPU批次大小: $BATCH_SIZE_PER_GPU"
echo "   - 梯度累积步数: $GRADIENT_ACCUMULATION_STEPS"
echo "   - 有效批次大小: $EFFECTIVE_BATCH_SIZE"
echo "   - 输出目录: $OUTPUT_DIR"

# 使用torchrun进行分布式训练
torchrun --nproc_per_node=$NUM_GPUS \
    --master_port=29500 \
    /Users/barryzhang/myDev3/OntoThink_V4/backend/app/training/chatglm3_ontothink_training.py \
    --model_name_or_path $MODEL_NAME \
    --data_path $DATA_PATH \
    --output_dir $OUTPUT_DIR \
    --num_train_epochs 3 \
    --per_device_train_batch_size $BATCH_SIZE_PER_GPU \
    --per_device_eval_batch_size $BATCH_SIZE_PER_GPU \
    --gradient_accumulation_steps $GRADIENT_ACCUMULATION_STEPS \
    --evaluation_strategy "steps" \
    --eval_steps 100 \
    --save_strategy "steps" \
    --save_steps 200 \
    --save_total_limit 3 \
    --learning_rate 5e-5 \
    --weight_decay 0.01 \
    --warmup_ratio 0.03 \
    --lr_scheduler_type "cosine" \
    --logging_steps 10 \
    --bf16 True \
    --tf32 True \
    --gradient_checkpointing True \
    --dataloader_pin_memory False \
    --ddp_find_unused_parameters False \
    --use_lora True \
    --lora_r 64 \
    --lora_alpha 128 \
    --lora_dropout 0.05 \
    --q_lora True \
    --max_seq_length 2048 \
    --report_to "tensorboard" \
    --logging_dir "$LOG_DIR" \
    --seed 42 \
    --remove_unused_columns False \
    2>&1 | tee "$LOG_DIR/training_$(date +%Y%m%d_%H%M%S).log"

echo "✅ 训练完成！"
echo "📁 模型保存位置: $OUTPUT_DIR"
echo "📊 训练日志位置: $LOG_DIR"

# 训练完成后的验证
echo "🔍 开始模型验证..."
python /Users/barryzhang/myDev3/OntoThink_V4/backend/scripts/validate_model.py \
    --model_path $OUTPUT_DIR \
    --test_data_path "$DATA_PATH/test.jsonl" \
    --output_path "$OUTPUT_DIR/validation_results.json"

echo "🎉 OntoThink模型训练和验证完成！"
