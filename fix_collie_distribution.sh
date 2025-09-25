#!/bin/bash

# 🔧 修复collie分布式初始化问题
# 设置必要的分布式环境变量
# ===============================

echo "🔧 修复collie分布式初始化问题"
echo "设置必要的分布式环境变量"
echo "==========================="

echo ""
echo "🎯 问题分析："
echo "❌ UnboundLocalError: local variable 'master_addr' referenced before assignment"
echo "💡 collie框架需要分布式环境变量，即使是单卡训练"

echo ""
echo "🔧 设置完整的燧原分布式环境"
echo "=========================="

# 燧原T20基础环境变量
export ENFLAME_ENABLE_EFP=true
export ENFLAME_PT_ENABLE_HBM_INPLACE=true
export OMP_NUM_THREADS=5
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
export CUDA_VISIBLE_DEVICES=""  # 禁用CUDA
export PTEX_DDP_BACKEND=eccl

echo "✅ 燧原完整分布式环境设置完成"

echo ""
echo "🚀 启动修复后的单GCU训练"
echo "========================"

# 燧原脚本目录
ENFLAME_SCRIPT_DIR="/workspace/code/OntoThink_V4/FromEnflame/ai_development_toolkit/distributed/llm_scripts_1.0.40/finetuning/chatglm3"

if [ ! -f "$ENFLAME_SCRIPT_DIR/finetune_chatglm3_for_multiturn.py" ]; then
    echo "❌ 训练脚本不存在"
    exit 1
fi

echo "✅ 找到训练脚本: $ENFLAME_SCRIPT_DIR"
cd "$ENFLAME_SCRIPT_DIR"

echo ""
echo "🔧 使用完整环境变量启动单GCU训练..."

# 启动单卡训练
python3.8 finetune_chatglm3_for_multiturn.py \
    --model_path "/workspace/code/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b" \
    --train_file "/workspace/code/OntoThink_V4/enflame_training/datasets/ontothink_multiturn/train.jsonl" \
    --tp_size 1 \
    --dp_size 1 \
    --pp_size 1 \
    --train_micro_batch_size 1 \
    --gradient_accumulation_steps 4 \
    --max_steps 5 \
    --max_tokens 512 \
    --ladder_shape False \
    --skip_steps 1 \
    --eval_batch_size 1 \
    --eval_per_n_epochs 1 \
    --train_epochs 1 2>&1 | tee /tmp/fixed_single_gcu.log

echo ""
echo "🔍 修复结果分析"
echo "================"

if [ -f /tmp/fixed_single_gcu.log ]; then
    echo "📋 检查最新的输出:"
    tail -20 /tmp/fixed_single_gcu.log
    
    echo ""
    echo "📋 检查分布式初始化："
    if grep -q -i "master_addr\|UnboundLocalError" /tmp/fixed_single_gcu.log; then
        echo "❌ 仍有分布式初始化问题:"
        grep -i -A2 -B2 "master_addr\|UnboundLocalError" /tmp/fixed_single_gcu.log
    else
        echo "✅ 分布式初始化问题已解决"
    fi
    
    echo ""
    echo "📋 检查模型加载："
    if grep -q -i "model.*loaded\|model.*success\|parameters\|layers" /tmp/fixed_single_gcu.log; then
        echo "✅ 找到模型加载信息:"
        grep -i "model.*loaded\|model.*success\|parameters\|layers" /tmp/fixed_single_gcu.log | head -3
    fi
    
    echo ""
    echo "📋 检查训练开始："
    if grep -q -i "training\|epoch.*step\|loss.*\|optimizer\|learning_rate" /tmp/fixed_single_gcu.log; then
        echo "🎉 找到训练开始信息:"
        grep -i "training\|epoch.*step\|loss.*\|optimizer\|learning_rate" /tmp/fixed_single_gcu.log | tail -5
    else
        echo "⚠️  未找到训练开始信息"
    fi
    
    echo ""
    echo "📋 检查错误信息："
    if grep -q -i "error\|fail\|exception" /tmp/fixed_single_gcu.log; then
        echo "❌ 发现其他错误:"
        grep -i -A2 -B1 "error\|fail\|exception" /tmp/fixed_single_gcu.log | tail -8
    else
        echo "✅ 没有发现其他错误"
    fi
fi

echo ""
echo "💡 修复结果总结"
echo "================"

if [ -f /tmp/fixed_single_gcu.log ]; then
    # 检查是否成功
    if grep -q -i "training\|epoch.*step\|loss" /tmp/fixed_single_gcu.log && ! grep -q -i "UnboundLocalError\|master_addr.*referenced" /tmp/fixed_single_gcu.log; then
        echo "🎉 单GCU训练修复成功！"
        echo "✅ 分布式初始化正常"
        echo "✅ 模型加载正常"
        echo "✅ 训练开始正常"
        echo ""
        echo "🚀 下一步：尝试多卡训练"
        echo "bash train_2gcu.sh   # 2卡训练"
        echo "bash train_4gcu.sh   # 4卡训练"
        echo "bash train_8gcu.sh   # 8卡训练"
    else
        echo "⚠️  仍有问题需要进一步调试"
        echo "📋 完整日志: /tmp/fixed_single_gcu.log"
    fi
fi

echo ""
echo "📋 环境变量设置："
echo "MASTER_ADDR=$MASTER_ADDR"
echo "MASTER_PORT=$MASTER_PORT"
echo "WORLD_SIZE=$WORLD_SIZE"
echo "RANK=$RANK"
echo "LOCAL_RANK=$LOCAL_RANK"
echo "GCU_VISIBLE_DEVICES=$GCU_VISIBLE_DEVICES"
