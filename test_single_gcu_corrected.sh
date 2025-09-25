#!/bin/bash

# 🔧 修正的单GCU训练测试
# 使用燧原脚本的正确参数格式
# ==============================

echo "🔧 修正的单GCU训练测试"
echo "使用燧原脚本的正确参数格式"
echo "==========================="

echo ""
echo "🔥 硬件环境确认："
echo "✅ 8张燧原T20卡全部正常"
echo "✅ 每张32GB内存"
echo "✅ 温度和功耗正常"

echo ""
echo "🔧 设置燧原T20单GCU环境"
echo "========================"

# 燧原T20环境变量（单GCU）
export ENFLAME_ENABLE_EFP=true
export ENFLAME_PT_ENABLE_HBM_INPLACE=true
export OMP_NUM_THREADS=5
export ECCL_MAX_NCHANNELS=1
export ENFLAME_UMD_FLAGS="mem_alloc_retry_times=1"
export GCU_VISIBLE_DEVICES=0  # 只使用第一个GCU

echo "✅ 燧原单GCU环境设置完成"

echo ""
echo "🚀 启动修正的单GCU训练测试"
echo "============================"

# 燧原脚本目录
ENFLAME_SCRIPT_DIR="/workspace/code/OntoThink_V4/FromEnflame/ai_development_toolkit/distributed/llm_scripts_1.0.40/finetuning/chatglm3"

if [ ! -f "$ENFLAME_SCRIPT_DIR/finetune_chatglm3_for_multiturn.py" ]; then
    echo "❌ 训练脚本不存在"
    exit 1
fi

echo "✅ 找到训练脚本: $ENFLAME_SCRIPT_DIR"
cd "$ENFLAME_SCRIPT_DIR"

echo ""
echo "🔧 使用燧原支持的参数启动单GCU训练..."

# 使用燧原脚本支持的参数，单卡配置
python3.8 finetune_chatglm3_for_multiturn.py \
    --model_path "/workspace/code/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b" \
    --train_file "/workspace/code/OntoThink_V4/enflame_training/datasets/ontothink_multiturn/train.jsonl" \
    --tp_size 1 \
    --dp_size 1 \
    --pp_size 1 \
    --train_micro_batch_size 1 \
    --gradient_accumulation_steps 8 \
    --max_steps 3 \
    --max_tokens 512 \
    --ladder_shape False \
    --skip_steps 1 \
    --eval_batch_size 1 \
    --eval_per_n_epochs 1 \
    --train_epochs 1 2>&1 | tee /tmp/single_gcu_corrected.log

echo ""
echo "🔍 测试结果分析"
echo "================"

if [ -f /tmp/single_gcu_corrected.log ]; then
    echo "📋 检查最新的输出:"
    tail -20 /tmp/single_gcu_corrected.log
    
    echo ""
    echo "📋 检查是否有错误:"
    if grep -q -i "error\|fail\|exception\|traceback" /tmp/single_gcu_corrected.log; then
        echo "❌ 发现错误:"
        grep -i -A3 -B1 "error\|fail\|exception\|traceback" /tmp/single_gcu_corrected.log | tail -10
    else
        echo "✅ 没有发现明显错误"
    fi
    
    echo ""
    echo "📋 检查是否成功初始化："
    if grep -q -i "collie\|config\|model\|tokenizer" /tmp/single_gcu_corrected.log; then
        echo "✅ 找到初始化信息:"
        grep -i "collie\|config\|model\|tokenizer" /tmp/single_gcu_corrected.log | head -5
    fi
    
    echo ""
    echo "📋 检查是否开始训练："
    if grep -q -i "training\|epoch\|step\|loss\|optimizer" /tmp/single_gcu_corrected.log; then
        echo "✅ 找到训练信息:"
        grep -i "training\|epoch\|step\|loss\|optimizer" /tmp/single_gcu_corrected.log | tail -5
    else
        echo "⚠️  未找到训练相关信息"
    fi
    
    echo ""
    echo "📋 检查燧原特定信息："
    if grep -q -i "ptex\|collie\|gcu\|eccl" /tmp/single_gcu_corrected.log; then
        echo "🔥 找到燧原相关信息:"
        grep -i "ptex\|collie\|gcu\|eccl" /tmp/single_gcu_corrected.log | head -3
    fi
fi

echo ""
echo "💡 单GCU修正测试总结"
echo "===================="

echo "🎯 如果这次测试成功："
echo "  ✅ 单卡训练环境完全正常"
echo "  ✅ 问题确实在8卡分布式配置"
echo "  🔧 建议：逐步增加卡数 (1→2→4→8)"

echo ""
echo "🎯 如果仍然失败："
echo "  🔍 检查模型文件路径和完整性"
echo "  🔍 检查数据文件格式"
echo "  🔍 检查燧原环境配置"

echo ""
echo "📋 日志文件: /tmp/single_gcu_corrected.log"

echo ""
echo "🚀 下一步建议："
echo "1. 如果单GCU成功，尝试 2卡训练 (pp_size=2)"
echo "2. 如果单GCU成功，尝试 4卡训练 (pp_size=4)"  
echo "3. 最后尝试 8卡训练 (pp_size=8)"
