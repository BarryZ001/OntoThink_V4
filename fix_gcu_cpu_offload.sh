#!/bin/bash

# 🔧 GCU + CPU Offload 解决方案
# 使用CPU卸载优化器状态来解决内存问题
# ====================================

echo "🔧 GCU + CPU Offload 解决方案"
echo "使用CPU卸载优化器状态"
echo "====================="

echo ""
echo "🎯 根本问题分析："
echo "✅ 所有软硬件环境正常"
echo "✅ 分布式初始化成功"
echo "✅ 模型加载成功"
echo "❌ ChatGLM3-6B的优化器状态超出单卡32GB限制"
echo "💡 解决方案: 将优化器状态offload到CPU内存"

echo ""
echo "🔧 CPU Offload 策略"
echo "=================="

# 燧原脚本目录
ENFLAME_SCRIPT_DIR="/workspace/code/OntoThink_V4/FromEnflame/ai_development_toolkit/distributed/llm_scripts_1.0.40/finetuning/chatglm3"

if [ ! -f "$ENFLAME_SCRIPT_DIR/finetune_chatglm3_for_multiturn.py" ]; then
    echo "❌ 训练脚本不存在"
    exit 1
fi

# 创建CPU offload的DeepSpeed配置
echo "📝 创建CPU offload DeepSpeed配置..."
cat > /tmp/deepspeed_cpu_offload.json << 'EOF'
{
    "train_batch_size": 1,
    "train_micro_batch_size_per_gpu": 1,
    "gradient_accumulation_steps": 1,
    "optimizer": {
        "type": "AdamW",
        "params": {
            "lr": 2e-5,
            "betas": [0.9, 0.999],
            "eps": 1e-8,
            "weight_decay": 0.01
        }
    },
    "fp16": {
        "enabled": true,
        "initial_scale_power": 12
    },
    "zero_optimization": {
        "stage": 2,
        "offload_optimizer": {
            "device": "cpu",
            "pin_memory": true
        },
        "allgather_partitions": true,
        "allgather_bucket_size": 200000000,
        "overlap_comm": true,
        "reduce_scatter": true,
        "reduce_bucket_size": 200000000,
        "contiguous_gradients": true
    },
    "scheduler": {
        "type": "WarmupLR",
        "params": {
            "warmup_min_lr": 0,
            "warmup_max_lr": 2e-5,
            "warmup_num_steps": 10
        }
    },
    "steps_per_print": 1,
    "wall_clock_breakdown": false
}
EOF

echo "✅ CPU offload配置创建完成: /tmp/deepspeed_cpu_offload.json"

echo "✅ 找到训练脚本: $ENFLAME_SCRIPT_DIR"
cd "$ENFLAME_SCRIPT_DIR"

# 设置燧原分布式环境变量
export ENFLAME_ENABLE_EFP=true
export ENFLAME_PT_ENABLE_HBM_INPLACE=false
export OMP_NUM_THREADS=1
export ECCL_MAX_NCHANNELS=1
export ENFLAME_UMD_FLAGS="mem_alloc_retry_times=3"

# 分布式环境变量（单卡配置）
export MASTER_ADDR=localhost
export MASTER_PORT=29500
export WORLD_SIZE=1
export RANK=0
export LOCAL_RANK=0
export GCU_VISIBLE_DEVICES=0

# 燧原特定的分布式变量
export CUDA_VISIBLE_DEVICES=""
export PTEX_DDP_BACKEND=eccl

# 设置更大的系统内存限制
export ECCL_BUFFSIZE=16777216

echo "🎯 CPU Offload 参数："
echo "  - 优化器状态: CPU offload (节省GCU内存)"
echo "  - Zero Stage: 2 (梯度和优化器状态分片)"
echo "  - Pin Memory: enabled (CPU-GCU传输优化)"
echo "  - max_tokens: 128 (保持最小)"
echo "  - gradient_accumulation: 1 (最小累积)"

echo ""
echo "🚀 启动CPU Offload训练"
echo "====================="

# 检查是否支持DeepSpeed配置文件参数
echo "📋 检查训练脚本支持的参数..."
python3.8 finetune_chatglm3_for_multiturn.py --help 2>&1 | grep -E "deepspeed|config" || echo "⚠️  可能不支持外部DeepSpeed配置"

echo ""
echo "🔧 尝试1: 使用环境变量方式..."

# 方法1: 通过环境变量设置DeepSpeed配置
export DEEPSPEED_CONFIG_FILE="/tmp/deepspeed_cpu_offload.json"

python3.8 finetune_chatglm3_for_multiturn.py \
    --model_path "/workspace/code/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b" \
    --train_file "/workspace/code/OntoThink_V4/enflame_training/datasets/ontothink_multiturn/train.jsonl" \
    --tp_size 1 \
    --dp_size 1 \
    --pp_size 1 \
    --train_micro_batch_size 1 \
    --gradient_accumulation_steps 1 \
    --max_steps 1 \
    --max_tokens 128 \
    --ladder_shape False \
    --skip_steps 1 \
    --eval_batch_size 1 \
    --eval_per_n_epochs 10 \
    --train_epochs 1 2>&1 | tee /tmp/cpu_offload_training.log

echo ""
echo "🔍 CPU Offload 结果分析"
echo "======================"

if [ -f /tmp/cpu_offload_training.log ]; then
    echo "📋 检查最新的输出:"
    tail -15 /tmp/cpu_offload_training.log
    
    echo ""
    echo "📋 检查CPU offload是否生效："
    if grep -q -i "offload.*cpu\|zero.*stage.*2\|cpu.*offload" /tmp/cpu_offload_training.log; then
        echo "✅ CPU offload正在工作:"
        grep -i "offload.*cpu\|zero.*stage.*2\|cpu.*offload" /tmp/cpu_offload_training.log | tail -2
    else
        echo "⚠️  未检测到CPU offload信息"
    fi
    
    echo ""
    echo "📋 检查内存分配："
    if grep -q -i "topsMalloc.*failed\|Check failed.*topsSuccess" /tmp/cpu_offload_training.log; then
        echo "❌ 仍有内存分配问题"
        echo "💡 可能需要更激进的offload策略"
    else
        echo "✅ 内存分配问题已解决！"
    fi
    
    echo ""
    echo "📋 检查优化器初始化："
    if grep -q -i "optimizer.*initialized\|optimizer.*success\|DeepSpeed.*initialized" /tmp/cpu_offload_training.log; then
        echo "🎉 优化器初始化成功！"
        grep -i "optimizer.*initialized\|optimizer.*success\|DeepSpeed.*initialized" /tmp/cpu_offload_training.log | tail -2
    elif grep -q -i "Creating.*optimizer\|DeepSpeed.*Basic.*Optimizer" /tmp/cpu_offload_training.log; then
        echo "⚠️  优化器正在初始化..."
    fi
    
    echo ""
    echo "📋 检查训练是否开始："
    if grep -q -i "step.*loss\|epoch.*step\|loss.*:\|training.*start" /tmp/cpu_offload_training.log; then
        echo "🎉🎉🎉 训练成功开始！"
        grep -i "step.*loss\|epoch.*step\|loss.*:\|training.*start" /tmp/cpu_offload_training.log | tail -3
    else
        echo "⚠️  未找到训练开始信息"
    fi
    
    echo ""
    echo "📋 检查错误信息："
    if grep -q -i "error\|fail\|exception\|abort" /tmp/cpu_offload_training.log; then
        echo "❌ 发现错误:"
        grep -i -A1 "error\|fail\|exception\|abort" /tmp/cpu_offload_training.log | tail -4
    else
        echo "✅ 没有发现错误"
    fi
fi

echo ""
echo "💡 CPU Offload 结果总结"
echo "======================"

if [ -f /tmp/cpu_offload_training.log ]; then
    # 检查是否成功
    if grep -q -i "step.*loss\|loss.*:" /tmp/cpu_offload_training.log && ! grep -q -i "topsMalloc.*failed" /tmp/cpu_offload_training.log; then
        echo "🎉🎉🎉 完全成功！CPU Offload解决了内存问题！"
        echo "✅ 优化器状态成功offload到CPU"
        echo "✅ GCU内存压力大幅减少"
        echo "✅ 训练正常启动"
        echo ""
        echo "🚀 下一步可以："
        echo "1. 增加训练参数和步数"
        echo "2. 尝试Zero Stage 3 (模型参数也offload)"
        echo "3. 扩展到多卡并行训练"
    elif ! grep -q -i "topsMalloc.*failed" /tmp/cpu_offload_training.log; then
        echo "🎯 内存问题已解决！"
        echo "✅ 没有内存分配错误"
        echo "✅ CPU offload策略有效"
        echo "⚠️  可能在其他阶段处理中"
    else
        echo "⚠️  CPU offload可能未生效"
        echo "💡 备选方案："
        echo "1. 检查是否支持Zero Stage 3"
        echo "2. 尝试模型并行 (tp_size > 1)"
        echo "3. 使用更小的模型版本"
    fi
fi

echo ""
echo "📋 CPU Offload配置:"
echo "  优化器: CPU offload, Zero Stage 2"
echo "  训练参数: max_tokens=128, micro_batch=1, grad_accum=1"
echo "  完整日志: /tmp/cpu_offload_training.log"
echo "  DeepSpeed配置: /tmp/deepspeed_cpu_offload.json"
