#!/bin/bash

# 🔧 简单的单GCU训练测试
# 绕过分布式复杂性，测试基本功能
# ===============================

echo "🔧 简单的单GCU训练测试"
echo "绕过分布式复杂性，测试基本功能"
echo "=============================="

echo ""
echo "🎯 目标："
echo "- 测试单个GCU是否能正常训练"
echo "- 绕过8卡分布式的复杂性"
echo "- 确认模型加载和基本训练流程"

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
echo "🔍 检查环境"
echo "============"

echo "🔥 可用的GCU设备:"
ls -la /dev/gcu0 2>/dev/null && echo "✅ GCU0 可用" || echo "❌ GCU0 不可用"

echo ""
echo "📦 关键包检查:"
python3 -c "
packages = ['torch', 'ptex', 'transformers', 'sentencepiece']
for pkg in packages:
    try:
        __import__(pkg)
        print(f'✅ {pkg}: 可用')
    except:
        print(f'❌ {pkg}: 不可用')
"

echo ""
echo "🚀 启动单GCU训练测试"
echo "===================="

# 燧原脚本目录
ENFLAME_SCRIPT_DIR="/workspace/code/OntoThink_V4/FromEnflame/ai_development_toolkit/distributed/llm_scripts_1.0.40/finetuning/chatglm3"

if [ ! -f "$ENFLAME_SCRIPT_DIR/finetune_chatglm3_for_multiturn.py" ]; then
    echo "❌ 训练脚本不存在"
    exit 1
fi

echo "✅ 找到训练脚本: $ENFLAME_SCRIPT_DIR"
cd "$ENFLAME_SCRIPT_DIR"

echo ""
echo "🔧 启动单进程训练 (不使用分布式)..."

# 使用单进程，非分布式启动
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
    --train_epochs 1 \
    --local_rank 0 \
    --world_size 1 \
    --rank 0 2>&1 | tee /tmp/single_gcu_test.log

echo ""
echo "🔍 测试结果分析"
echo "================"

if [ -f /tmp/single_gcu_test.log ]; then
    echo "📋 检查是否有错误:"
    if grep -q -i "error\|fail\|exception" /tmp/single_gcu_test.log; then
        echo "❌ 发现错误:"
        grep -i -A3 -B1 "error\|fail\|exception" /tmp/single_gcu_test.log | tail -10
    else
        echo "✅ 没有发现明显错误"
    fi
    
    echo ""
    echo "📋 检查是否成功开始训练:"
    if grep -q -i "training\|epoch\|step\|loss" /tmp/single_gcu_test.log; then
        echo "✅ 成功开始训练!"
        grep -i "training\|epoch\|step\|loss" /tmp/single_gcu_test.log | tail -5
    else
        echo "❌ 未能开始训练"
    fi
    
    echo ""
    echo "📋 检查模型加载:"
    if grep -q -i "loading\|model\|tokenizer" /tmp/single_gcu_test.log; then
        echo "📦 模型加载相关信息:"
        grep -i "loading\|model\|tokenizer" /tmp/single_gcu_test.log | head -5
    fi
fi

echo ""
echo "💡 单GCU测试总结"
echo "================="

echo "🎯 如果单GCU测试成功："
echo "  - 说明基本环境正常"
echo "  - 问题在于8卡分布式配置"
echo "  - 可以尝试减少并行度 (如4卡或2卡)"

echo ""
echo "🎯 如果单GCU测试失败："
echo "  - 说明基础环境有问题"
echo "  - 需要进一步调试模型加载或其他基础问题"

echo ""
echo "📋 日志文件: /tmp/single_gcu_test.log"
echo "🔍 可以查看完整日志获取更多信息"
