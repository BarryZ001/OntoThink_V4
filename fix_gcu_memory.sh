#!/bin/bash

# 🔧 修复GCU内存分配问题
# 通过减少模型大小和优化器状态来解决内存不足
# =============================================

echo "🔧 修复GCU内存分配问题"
echo "通过减少模型大小和优化器状态"
echo "==========================="

echo ""
echo "🎯 问题分析："
echo "✅ 分布式初始化成功"
echo "✅ 模型加载成功"
echo "✅ DeepSpeed配置正确"
echo "❌ GCU内存不足: topsMalloc failed"
echo "💡 问题出现在优化器状态初始化阶段"

echo ""
echo "🔧 内存优化策略"
echo "================"

# 燧原脚本目录
ENFLAME_SCRIPT_DIR="/workspace/code/OntoThink_V4/FromEnflame/ai_development_toolkit/distributed/llm_scripts_1.0.40/finetuning/chatglm3"

if [ ! -f "$ENFLAME_SCRIPT_DIR/finetune_chatglm3_for_multiturn.py" ]; then
    echo "❌ 训练脚本不存在"
    exit 1
fi

echo "✅ 找到训练脚本: $ENFLAME_SCRIPT_DIR"
cd "$ENFLAME_SCRIPT_DIR"

# 设置燧原分布式环境变量（从之前修复的配置）
export ENFLAME_ENABLE_EFP=true
export ENFLAME_PT_ENABLE_HBM_INPLACE=true
export OMP_NUM_THREADS=2  # 减少线程数
export ECCL_MAX_NCHANNELS=1
export ENFLAME_UMD_FLAGS="mem_alloc_retry_times=1"

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

echo "🎯 内存优化参数："
echo "  - micro_batch_size: 1 → 1 (保持最小)"
echo "  - gradient_accumulation: 64 → 2 (大幅减少)"
echo "  - max_tokens: 2048 → 256 (减少序列长度)"
echo "  - max_steps: ∞ → 3 (快速测试)"
echo "  - fp16: enabled (减少内存使用)"
echo "  - OMP_NUM_THREADS: 5 → 2 (减少线程)"

echo ""
echo "🚀 启动内存优化的单GCU训练"
echo "============================"

# 启动超小内存单卡训练
python3.8 finetune_chatglm3_for_multiturn.py \
    --model_path "/workspace/code/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b" \
    --train_file "/workspace/code/OntoThink_V4/enflame_training/datasets/ontothink_multiturn/train.jsonl" \
    --tp_size 1 \
    --dp_size 1 \
    --pp_size 1 \
    --train_micro_batch_size 1 \
    --gradient_accumulation_steps 2 \
    --max_steps 3 \
    --max_tokens 256 \
    --ladder_shape False \
    --skip_steps 1 \
    --eval_batch_size 1 \
    --eval_per_n_epochs 1 \
    --train_epochs 1 \
    --save_interval 999 \
    --checkpoint_interval 999 2>&1 | tee /tmp/memory_optimized_gcu.log

echo ""
echo "🔍 内存优化结果分析"
echo "===================="

if [ -f /tmp/memory_optimized_gcu.log ]; then
    echo "📋 检查最新的输出:"
    tail -20 /tmp/memory_optimized_gcu.log
    
    echo ""
    echo "📋 检查内存分配："
    if grep -q -i "topsMalloc.*failed\|Check failed.*topsSuccess\|memory.*error" /tmp/memory_optimized_gcu.log; then
        echo "❌ 仍有内存分配问题:"
        grep -i -A2 -B2 "topsMalloc.*failed\|Check failed.*topsSuccess\|memory.*error" /tmp/memory_optimized_gcu.log | tail -5
    else
        echo "✅ 内存分配问题已解决"
    fi
    
    echo ""
    echo "📋 检查优化器初始化："
    if grep -q -i "optimizer.*init\|DeepSpeed.*Basic.*Optimizer\|Creating.*optimizer" /tmp/memory_optimized_gcu.log; then
        echo "✅ 找到优化器初始化:"
        grep -i "optimizer.*init\|DeepSpeed.*Basic.*Optimizer\|Creating.*optimizer" /tmp/memory_optimized_gcu.log | tail -3
    fi
    
    echo ""
    echo "📋 检查训练步骤："
    if grep -q -i "step.*loss\|epoch.*\|training.*step\|global.*step" /tmp/memory_optimized_gcu.log; then
        echo "🎉 找到训练步骤:"
        grep -i "step.*loss\|epoch.*\|training.*step\|global.*step" /tmp/memory_optimized_gcu.log | tail -5
    else
        echo "⚠️  未找到训练步骤"
    fi
    
    echo ""
    echo "📋 检查ECCL状态："
    if grep -q -i "ecclCommInitRank.*success" /tmp/memory_optimized_gcu.log; then
        echo "✅ ECCL正常工作"
    else
        echo "⚠️  ECCL状态未知"
    fi
    
    echo ""
    echo "📋 检查错误信息："
    if grep -q -i "error\|fail\|exception\|abort" /tmp/memory_optimized_gcu.log; then
        echo "❌ 发现错误:"
        grep -i -A1 -B1 "error\|fail\|exception\|abort" /tmp/memory_optimized_gcu.log | tail -6
    else
        echo "✅ 没有发现错误"
    fi
fi

echo ""
echo "💡 内存优化结果总结"
echo "==================="

if [ -f /tmp/memory_optimized_gcu.log ]; then
    # 检查是否成功
    if grep -q -i "step.*loss\|training.*completed\|epoch.*step" /tmp/memory_optimized_gcu.log && ! grep -q -i "topsMalloc.*failed\|Check failed.*topsSuccess" /tmp/memory_optimized_gcu.log; then
        echo "🎉 内存优化成功！"
        echo "✅ GCU内存分配正常"
        echo "✅ 优化器初始化成功"
        echo "✅ 训练步骤正常"
        echo ""
        echo "🚀 下一步：逐步扩展配置"
        echo "1. 增加序列长度: 256 → 512 → 1024"
        echo "2. 增加batch size: 1 → 2 → 4"
        echo "3. 增加并行度: 1卡 → 2卡 → 4卡 → 8卡"
    elif grep -q -i "DeepSpeed.*Optimizer\|Creating.*optimizer" /tmp/memory_optimized_gcu.log && ! grep -q -i "topsMalloc.*failed" /tmp/memory_optimized_gcu.log; then
        echo "🎯 部分成功！"
        echo "✅ 优化器初始化成功"
        echo "⚠️  可能在训练循环中遇到其他问题"
        echo "💡 建议进一步调试训练循环"
    else
        echo "⚠️  仍需要进一步优化"
        echo "📋 完整日志: /tmp/memory_optimized_gcu.log"
        echo ""
        echo "🔧 更激进的内存优化建议："
        echo "1. 使用更小的模型或checkpoint"
        echo "2. 禁用一些DeepSpeed功能"
        echo "3. 减少更多参数"
    fi
fi

echo ""
echo "📋 当前优化配置："
echo "GCU_VISIBLE_DEVICES=$GCU_VISIBLE_DEVICES"
echo "WORLD_SIZE=$WORLD_SIZE"
echo "OMP_NUM_THREADS=$OMP_NUM_THREADS"
echo "max_tokens=256, micro_batch=1, grad_accum=2"
