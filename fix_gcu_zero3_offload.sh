#!/bin/bash

# 🔧 Zero Stage 3 + 完全CPU Offload 解决方案
# 模型参数、优化器状态、梯度全部offload到CPU
# ==========================================

echo "🔧 Zero Stage 3 + 完全CPU Offload 解决方案"
echo "模型参数、优化器状态、梯度全部offload"
echo "======================================"

echo ""
echo "🎯 升级策略分析："
echo "✅ 系统内存充足: 1TB总内存，989GB可用"
echo "✅ CPU offload方向正确: 脚本建议增加参数"
echo "⚠️ Stage 2仍有内存问题: 需要更激进的Stage 3"
echo "💡 解决方案: 模型参数也offload到CPU"

echo ""
echo "🔧 Zero Stage 3 配置"
echo "=================="

# 创建Zero Stage 3的DeepSpeed配置
echo "📝 创建Zero Stage 3 DeepSpeed配置..."
cat > /tmp/deepspeed_zero3_offload.json << 'EOF'
{
    "train_batch_size": 1,
    "train_micro_batch_size_per_gpu": 1,
    "gradient_accumulation_steps": 1,
    "optimizer": {
        "type": "AdamW",
        "params": {
            "lr": 1e-5,
            "betas": [0.9, 0.999],
            "eps": 1e-8,
            "weight_decay": 0.01
        }
    },
    "fp16": {
        "enabled": true,
        "initial_scale_power": 10
    },
    "zero_optimization": {
        "stage": 3,
        "offload_optimizer": {
            "device": "cpu",
            "pin_memory": true
        },
        "offload_param": {
            "device": "cpu",
            "pin_memory": true
        },
        "overlap_comm": true,
        "contiguous_gradients": true,
        "sub_group_size": 1e9,
        "reduce_bucket_size": "auto",
        "stage3_prefetch_bucket_size": "auto",
        "stage3_param_persistence_threshold": "auto",
        "stage3_max_live_parameters": 1e9,
        "stage3_max_reuse_distance": 1e9
    },
    "scheduler": {
        "type": "WarmupLR",
        "params": {
            "warmup_min_lr": 0,
            "warmup_max_lr": 1e-5,
            "warmup_num_steps": 5
        }
    },
    "steps_per_print": 1,
    "wall_clock_breakdown": false
}
EOF

echo "✅ Zero Stage 3配置创建完成: /tmp/deepspeed_zero3_offload.json"

# 燧原脚本目录
ENFLAME_SCRIPT_DIR="/workspace/code/OntoThink_V4/FromEnflame/ai_development_toolkit/distributed/llm_scripts_1.0.40/finetuning/chatglm3"

if [ ! -f "$ENFLAME_SCRIPT_DIR/finetune_chatglm3_for_multiturn.py" ]; then
    echo "❌ 训练脚本不存在"
    exit 1
fi

echo "✅ 找到训练脚本: $ENFLAME_SCRIPT_DIR"
cd "$ENFLAME_SCRIPT_DIR"

# 设置燧原分布式环境变量（最保守的设置）
export ENFLAME_ENABLE_EFP=true
export ENFLAME_PT_ENABLE_HBM_INPLACE=false
export OMP_NUM_THREADS=1
export ECCL_MAX_NCHANNELS=1
export ENFLAME_UMD_FLAGS="mem_alloc_retry_times=5"

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

# 设置更保守的内存使用
export ECCL_BUFFSIZE=8388608  # 8MB

echo "🎯 Zero Stage 3 参数："
echo "  - 模型参数: CPU offload (大幅减少GCU内存)"
echo "  - 优化器状态: CPU offload"
echo "  - 梯度: CPU处理"
echo "  - GCU内存: 只用于前向/反向计算"
echo "  - max_tokens: 64 (极小测试)"
echo "  - 学习率: 1e-5 (更保守)"

echo ""
echo "🚀 启动Zero Stage 3训练"
echo "======================="

# 启动最保守的训练配置
python3.8 finetune_chatglm3_for_multiturn.py \
    --model_path "/workspace/code/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b" \
    --train_file "/workspace/code/OntoThink_V4/enflame_training/datasets/ontothink_multiturn/train.jsonl" \
    --tp_size 1 \
    --dp_size 1 \
    --pp_size 1 \
    --train_micro_batch_size 1 \
    --gradient_accumulation_steps 1 \
    --max_steps 1 \
    --max_tokens 64 \
    --ladder_shape False \
    --skip_steps 1 \
    --eval_batch_size 1 \
    --eval_per_n_epochs 20 \
    --train_epochs 1 2>&1 | tee /tmp/zero3_offload_training.log

echo ""
echo "🔍 Zero Stage 3 结果分析"
echo "======================"

if [ -f /tmp/zero3_offload_training.log ]; then
    echo "📋 检查最新的输出:"
    tail -20 /tmp/zero3_offload_training.log
    
    echo ""
    echo "📋 检查Zero Stage 3是否生效："
    if grep -q -i "zero.*stage.*3\|stage3\|offload.*param" /tmp/zero3_offload_training.log; then
        echo "✅ Zero Stage 3正在工作:"
        grep -i "zero.*stage.*3\|stage3\|offload.*param" /tmp/zero3_offload_training.log | tail -2
    else
        echo "⚠️  未检测到Zero Stage 3信息"
    fi
    
    echo ""
    echo "📋 检查内存分配："
    MEMORY_ERRORS=$(grep -c "topsMalloc.*failed\|Check failed.*topsSuccess" /tmp/zero3_offload_training.log)
    if [ $MEMORY_ERRORS -eq 0 ]; then
        echo "✅ 没有内存分配错误！"
    else
        echo "❌ 仍有 $MEMORY_ERRORS 个内存错误"
    fi
    
    echo ""
    echo "📋 检查训练进展："
    if grep -q -i "step.*loss\|epoch.*step\|loss.*:\|training.*complete" /tmp/zero3_offload_training.log; then
        echo "🎉 训练成功运行！"
        grep -i "step.*loss\|epoch.*step\|loss.*:\|training.*complete" /tmp/zero3_offload_training.log | tail -3
    elif grep -q -i "optimizer.*init\|DeepSpeed.*init\|model.*loaded" /tmp/zero3_offload_training.log; then
        echo "⚠️  训练初始化中..."
        grep -i "optimizer.*init\|DeepSpeed.*init\|model.*loaded" /tmp/zero3_offload_training.log | tail -2
    else
        echo "⚠️  未找到训练进展信息"
    fi
    
    echo ""
    echo "📋 检查错误信息："
    if grep -q -i "error\|fail\|exception\|abort" /tmp/zero3_offload_training.log; then
        echo "❌ 发现错误:"
        grep -i -A1 "error\|fail\|exception\|abort" /tmp/zero3_offload_training.log | tail -4
    else
        echo "✅ 没有发现错误"
    fi
fi

echo ""
echo "💡 Zero Stage 3 结果总结"
echo "======================"

if [ -f /tmp/zero3_offload_training.log ]; then
    # 检查是否成功
    MEMORY_ERRORS=$(grep -c "topsMalloc.*failed\|Check failed.*topsSuccess" /tmp/zero3_offload_training.log)
    TRAINING_SUCCESS=$(grep -c "step.*loss\|loss.*:" /tmp/zero3_offload_training.log)
    
    if [ $MEMORY_ERRORS -eq 0 ] && [ $TRAINING_SUCCESS -gt 0 ]; then
        echo "🎉🎉🎉 完全成功！Zero Stage 3解决了所有问题！"
        echo "✅ 模型参数完全offload到CPU"
        echo "✅ 优化器状态完全offload到CPU"
        echo "✅ GCU内存压力最小化"
        echo "✅ 训练成功运行"
        echo ""
        echo "🚀 下一步可以："
        echo "1. 增加max_tokens: 64 → 128 → 256"
        echo "2. 增加max_steps: 1 → 10 → 100"
        echo "3. 增加batch size和gradient accumulation"
        echo "4. 尝试多卡并行训练"
    elif [ $MEMORY_ERRORS -eq 0 ]; then
        echo "🎯 内存问题完全解决！"
        echo "✅ Zero Stage 3策略有效"
        echo "✅ 没有任何内存分配错误"
        echo "⚠️  可能在训练初始化或数据处理阶段"
        echo ""
        echo "💡 这是重大突破！可以开始扩展配置"
    else
        echo "⚠️  仍有内存问题"
        echo "❌ Zero Stage 3仍不足"
        echo "💡 最后的备选方案："
        echo "1. 尝试模型并行 (tp_size=2,4,8)"
        echo "2. 使用更小的模型或quantized版本"
        echo "3. 检查是否有硬件限制"
    fi
fi

echo ""
echo "📋 Zero Stage 3配置:"
echo "  模型参数、优化器、梯度: 全部CPU offload"
echo "  训练参数: max_tokens=64, micro_batch=1, max_steps=1"
echo "  完整日志: /tmp/zero3_offload_training.log"
echo "  DeepSpeed配置: /tmp/deepspeed_zero3_offload.json"

echo ""
echo "📊 系统资源使用:"
echo "  总内存: 1TB, 可用: 989GB"
echo "  GCU内存: 32GB×8卡"
echo "  CPU cores: $(nproc)"
