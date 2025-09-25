#!/bin/bash

# 🔧 超级内存优化版本
# 使用最激进的内存节省策略
# ============================

echo "🔧 超级内存优化版本"
echo "使用最激进的内存节省策略"
echo "========================"

echo ""
echo "🎯 当前进展："
echo "✅ 参数错误已解决"
echo "✅ ECCL初始化成功"
echo "✅ DeepSpeed启动正常"
echo "❌ 优化器状态内存分配失败"

echo ""
echo "🔧 超激进内存优化策略"
echo "===================="

# 燧原脚本目录
ENFLAME_SCRIPT_DIR="/workspace/code/OntoThink_V4/FromEnflame/ai_development_toolkit/distributed/llm_scripts_1.0.40/finetuning/chatglm3"

if [ ! -f "$ENFLAME_SCRIPT_DIR/finetune_chatglm3_for_multiturn.py" ]; then
    echo "❌ 训练脚本不存在"
    exit 1
fi

echo "✅ 找到训练脚本: $ENFLAME_SCRIPT_DIR"
cd "$ENFLAME_SCRIPT_DIR"

# 设置燧原分布式环境变量（更保守的设置）
export ENFLAME_ENABLE_EFP=true
export ENFLAME_PT_ENABLE_HBM_INPLACE=false  # 禁用原地操作以节省内存
export OMP_NUM_THREADS=1  # 最小线程数
export ECCL_MAX_NCHANNELS=1
export ENFLAME_UMD_FLAGS="mem_alloc_retry_times=3"  # 增加重试次数

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

# 设置更小的内存池
export ECCL_BUFFSIZE=16777216  # 16MB instead of default 32MB

echo "🎯 超激进内存优化参数："
echo "  - max_tokens: 256 → 128 (极小序列长度)"
echo "  - gradient_accumulation: 2 → 1 (最小累积)"
echo "  - max_steps: 3 → 1 (单步测试)"
echo "  - OMP_NUM_THREADS: 2 → 1 (单线程)"
echo "  - ENFLAME_PT_ENABLE_HBM_INPLACE: false (禁用原地操作)"
echo "  - ECCL_BUFFSIZE: 16MB (减少通信缓冲)"

echo ""
echo "🚀 启动超级内存优化训练"
echo "======================="

# 启动最小内存配置训练
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
    --train_epochs 1 2>&1 | tee /tmp/memory_ultra_optimized.log

echo ""
echo "🔍 超级优化结果分析"
echo "=================="

if [ -f /tmp/memory_ultra_optimized.log ]; then
    echo "📋 检查最新的输出:"
    tail -15 /tmp/memory_ultra_optimized.log
    
    echo ""
    echo "📋 检查内存分配："
    if grep -q -i "topsMalloc.*failed\|Check failed.*topsSuccess" /tmp/memory_ultra_optimized.log; then
        echo "❌ 仍有内存分配问题 - 需要更激进的方案"
        # 检查具体的内存大小
        if grep -q -i "nbytes" /tmp/memory_ultra_optimized.log; then
            echo "📊 尝试分配的内存大小:"
            grep -i "nbytes\|topsMalloc" /tmp/memory_ultra_optimized.log | tail -3
        fi
    else
        echo "✅ 内存分配问题已解决！"
    fi
    
    echo ""
    echo "📋 检查训练是否开始："
    if grep -q -i "step.*loss\|epoch.*step\|loss.*:\|training.*start" /tmp/memory_ultra_optimized.log; then
        echo "🎉 训练成功开始！"
        grep -i "step.*loss\|epoch.*step\|loss.*:\|training.*start" /tmp/memory_ultra_optimized.log | tail -3
    elif grep -q -i "loading.*data\|processing.*data\|dataset" /tmp/memory_ultra_optimized.log; then
        echo "⚠️  正在处理数据..."
        grep -i "loading.*data\|processing.*data\|dataset" /tmp/memory_ultra_optimized.log | tail -2
    else
        echo "⚠️  未找到训练开始信息"
    fi
    
    echo ""
    echo "📋 检查优化器状态："
    if grep -q -i "optimizer.*success\|optimizer.*complete\|DeepSpeed.*initialized" /tmp/memory_ultra_optimized.log; then
        echo "✅ 优化器初始化成功"
    elif grep -q -i "Creating.*optimizer\|DeepSpeed.*Basic.*Optimizer" /tmp/memory_ultra_optimized.log; then
        echo "⚠️  优化器正在初始化..."
    fi
    
    echo ""
    echo "📋 检查ECCL状态："
    ECCL_COUNT=$(grep -c "ecclCommInitRank.*success" /tmp/memory_ultra_optimized.log)
    echo "✅ ECCL初始化次数: $ECCL_COUNT"
    
    echo ""
    echo "📋 检查错误信息："
    if grep -q -i "error\|fail\|exception\|abort" /tmp/memory_ultra_optimized.log; then
        echo "❌ 发现错误:"
        grep -i -A1 "error\|fail\|exception\|abort" /tmp/memory_ultra_optimized.log | tail -4
    else
        echo "✅ 没有发现错误"
    fi
fi

echo ""
echo "💡 超级优化结果总结"
echo "=================="

if [ -f /tmp/memory_ultra_optimized.log ]; then
    # 检查是否彻底成功
    if grep -q -i "step.*loss\|loss.*:" /tmp/memory_ultra_optimized.log && ! grep -q -i "topsMalloc.*failed\|Check failed.*topsSuccess" /tmp/memory_ultra_optimized.log; then
        echo "🎉🎉🎉 完全成功！训练正常运行！"
        echo "✅ 内存优化成功"
        echo "✅ 优化器初始化成功"
        echo "✅ 训练步骤正常"
        echo ""
        echo "🚀 下一步可以逐步增加配置："
        echo "1. max_tokens: 128 → 256 → 512"
        echo "2. gradient_accumulation: 1 → 2 → 4"
        echo "3. max_steps: 1 → 10 → 100"
        echo "4. 尝试多卡并行"
    elif ! grep -q -i "topsMalloc.*failed\|Check failed.*topsSuccess" /tmp/memory_ultra_optimized.log; then
        echo "🎯 内存问题已解决！"
        echo "✅ 没有内存分配错误"
        echo "⚠️  可能在其他阶段（数据处理/训练循环）"
        echo "💡 这是重大进步！内存瓶颈已突破"
    else
        echo "⚠️  内存问题仍然存在"
        echo "🔧 可能需要："
        echo "1. 使用更小的模型或量化版本"
        echo "2. 检查系统内存和交换空间"
        echo "3. 尝试CPU offload策略"
    fi
fi

echo ""
echo "📋 超级优化配置:"
echo "  max_tokens=128, micro_batch=1, grad_accum=1, max_steps=1"
echo "  OMP_NUM_THREADS=1, ECCL_BUFFSIZE=16MB"
echo "  完整日志: /tmp/memory_ultra_optimized.log"
