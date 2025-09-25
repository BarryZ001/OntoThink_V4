#!/bin/bash

# 🔧 修复GCU内存分配问题 (修正版)
# 移除不支持的参数，使用正确的燧原脚本参数
# ============================================

echo "🔧 修复GCU内存分配问题 (修正版)"
echo "移除不支持的参数"
echo "========================="

echo ""
echo "🎯 问题分析："
echo "✅ 分布式初始化成功"
echo "✅ 模型加载成功"
echo "✅ DeepSpeed配置正确"
echo "❌ 脚本参数错误: --save_interval, --checkpoint_interval 不支持"

echo ""
echo "🔧 使用正确的燧原脚本参数"
echo "=========================="

# 燧原脚本目录
ENFLAME_SCRIPT_DIR="/workspace/code/OntoThink_V4/FromEnflame/ai_development_toolkit/distributed/llm_scripts_1.0.40/finetuning/chatglm3"

if [ ! -f "$ENFLAME_SCRIPT_DIR/finetune_chatglm3_for_multiturn.py" ]; then
    echo "❌ 训练脚本不存在"
    exit 1
fi

echo "✅ 找到训练脚本: $ENFLAME_SCRIPT_DIR"
cd "$ENFLAME_SCRIPT_DIR"

# 设置燧原分布式环境变量
export ENFLAME_ENABLE_EFP=true
export ENFLAME_PT_ENABLE_HBM_INPLACE=true
export OMP_NUM_THREADS=2
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
echo "  - micro_batch_size: 1 (最小)"
echo "  - gradient_accumulation: 2 (大幅减少)"
echo "  - max_tokens: 256 (减少序列长度)"
echo "  - max_steps: 3 (快速测试)"
echo "  - train_epochs: 1 (最小轮数)"

echo ""
echo "🚀 启动修正的内存优化单GCU训练"
echo "============================="

# 启动训练，只使用支持的参数
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
    --train_epochs 1 2>&1 | tee /tmp/memory_optimized_corrected.log

echo ""
echo "🔍 修正后的结果分析"
echo "=================="

if [ -f /tmp/memory_optimized_corrected.log ]; then
    echo "📋 检查最新的输出:"
    tail -20 /tmp/memory_optimized_corrected.log
    
    echo ""
    echo "📋 检查参数错误："
    if grep -q -i "unrecognized arguments\|error.*argument" /tmp/memory_optimized_corrected.log; then
        echo "❌ 仍有参数错误:"
        grep -i "unrecognized arguments\|error.*argument" /tmp/memory_optimized_corrected.log
    else
        echo "✅ 参数错误已解决"
    fi
    
    echo ""
    echo "📋 检查ECCL初始化："
    if grep -q -i "ecclCommInitRank.*success" /tmp/memory_optimized_corrected.log; then
        echo "✅ ECCL初始化成功"
    else
        echo "⚠️  等待ECCL初始化"
    fi
    
    echo ""
    echo "📋 检查DeepSpeed："
    if grep -q -i "DeepSpeed.*Optimizer\|Creating.*optimizer\|DeepSpeed.*Basic" /tmp/memory_optimized_corrected.log; then
        echo "✅ DeepSpeed正常工作:"
        grep -i "DeepSpeed.*Optimizer\|Creating.*optimizer\|DeepSpeed.*Basic" /tmp/memory_optimized_corrected.log | tail -2
    fi
    
    echo ""
    echo "📋 检查内存分配："
    if grep -q -i "topsMalloc.*failed\|Check failed.*topsSuccess\|memory.*error" /tmp/memory_optimized_corrected.log; then
        echo "❌ 仍有内存分配问题:"
        grep -i -A2 -B2 "topsMalloc.*failed\|Check failed.*topsSuccess\|memory.*error" /tmp/memory_optimized_corrected.log | tail -5
    else
        echo "✅ 内存分配正常"
    fi
    
    echo ""
    echo "📋 检查训练步骤："
    if grep -q -i "step.*loss\|epoch.*step\|training.*step\|global.*step\|loss.*:" /tmp/memory_optimized_corrected.log; then
        echo "🎉 找到训练步骤:"
        grep -i "step.*loss\|epoch.*step\|training.*step\|global.*step\|loss.*:" /tmp/memory_optimized_corrected.log | tail -3
    else
        echo "⚠️  未找到训练步骤"
    fi
    
    echo ""
    echo "📋 检查错误信息："
    if grep -q -i "error\|fail\|exception\|abort\|traceback" /tmp/memory_optimized_corrected.log; then
        echo "❌ 发现错误:"
        grep -i -A1 -B1 "error\|fail\|exception\|abort\|traceback" /tmp/memory_optimized_corrected.log | tail -6
    else
        echo "✅ 没有发现错误"
    fi
fi

echo ""
echo "💡 修正后的结果总结"
echo "=================="

if [ -f /tmp/memory_optimized_corrected.log ]; then
    # 检查是否成功
    if grep -q -i "step.*loss\|epoch.*step\|loss.*:" /tmp/memory_optimized_corrected.log && ! grep -q -i "unrecognized arguments\|topsMalloc.*failed" /tmp/memory_optimized_corrected.log; then
        echo "🎉 训练成功启动！"
        echo "✅ 参数正确"
        echo "✅ 内存分配正常"
        echo "✅ 训练步骤开始"
        echo ""
        echo "🚀 下一步：扩展训练配置"
        echo "1. 增加序列长度和batch size"
        echo "2. 增加训练步数"
        echo "3. 尝试多卡并行训练"
    elif grep -q -i "DeepSpeed.*Optimizer\|Creating.*optimizer" /tmp/memory_optimized_corrected.log && ! grep -q -i "unrecognized arguments\|topsMalloc.*failed" /tmp/memory_optimized_corrected.log; then
        echo "🎯 优化器成功，检查训练循环"
        echo "✅ 参数正确"
        echo "✅ 优化器初始化成功"
        echo "⚠️  可能在训练数据处理中"
    elif ! grep -q -i "unrecognized arguments" /tmp/memory_optimized_corrected.log; then
        echo "✅ 参数问题已解决"
        echo "🔧 继续调试其他问题"
    else
        echo "⚠️  仍有其他问题需要解决"
    fi
fi

echo ""
echo "📋 完整日志文件: /tmp/memory_optimized_corrected.log"
echo "📋 当前优化配置:"
echo "  GCU_VISIBLE_DEVICES=$GCU_VISIBLE_DEVICES"
echo "  WORLD_SIZE=$WORLD_SIZE"
echo "  max_tokens=256, micro_batch=1, grad_accum=2, max_steps=3"
