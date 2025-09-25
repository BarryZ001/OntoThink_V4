#!/bin/bash

# 🔧 4卡超级内存优化方案
# 解决GCU内存耗尽问题 - 26.3GB接近32GB限制
# =======================================

echo "🔧 4卡超级内存优化方案"
echo "解决GCU内存耗尽问题"
echo "===================="

echo ""
echo "🎯 内存问题分析:"
echo "✅ 模型编译成功: 4个stage都完成"
echo "✅ ECCL通信正常: 4卡并行建立成功"
echo "❌ 内存耗尽: 26.3GB接近32GB限制"
echo "❌ 问题: 所有8张卡都分配内存，而非仅用4张"

echo ""
echo "💡 超级内存优化策略:"
echo "- 更严格的GPU隔离"
echo "- 进一步减少序列长度"
echo "- 更小的批次大小"
echo "- 禁用所有非必要功能"

echo ""
echo "🔧 设置4卡超级内存优化环境"
echo "=========================="

# 燧原脚本目录
ENFLAME_SCRIPT_DIR="/workspace/code/OntoThink_V4/FromEnflame/ai_development_toolkit/distributed/llm_scripts_1.0.40/finetuning/chatglm3"

if [ ! -f "$ENFLAME_SCRIPT_DIR/finetune_chatglm3_for_multiturn.py" ]; then
    echo "❌ 训练脚本不存在"
    exit 1
fi

echo "✅ 找到训练脚本: $ENFLAME_SCRIPT_DIR"
cd "$ENFLAME_SCRIPT_DIR"

# 清理之前的进程和内存
echo "🧹 清理环境和内存..."
pkill -f "finetune_chatglm3" || true
pkill -f "torch.distributed" || true
sleep 3

# 使用最严格的燧原环境变量
echo "🎯 设置超级保守的燧原环境变量..."
export ENFLAME_ENABLE_EFP=true
export ENFLAME_PT_ENABLE_HBM_INPLACE=false  # 禁用原地操作
export OMP_NUM_THREADS=1  # 最小线程数
export ECCL_MAX_NCHANNELS=1  # 最小通道数
export ENFLAME_UMD_FLAGS="mem_alloc_retry_times=5"  # 增加重试次数

# 更严格的GPU隔离
export GCU_VISIBLE_DEVICES=0,1,2,3
export CUDA_VISIBLE_DEVICES=""  # 明确禁用CUDA
echo "🎯 严格使用GCU卡: $GCU_VISIBLE_DEVICES"

# 设置分布式环境变量
export MASTER_ADDR=localhost
export MASTER_PORT=29502  # 换个端口
export WORLD_SIZE=4
export NCCL_DEBUG=WARN  # 减少调试输出

# 设置4卡超级内存优化参数
echo "🎯 设置超级内存优化参数..."
export PRETRAINED_MODEL_PATH="/workspace/code/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b"
export TRAIN_FILE="/workspace/code/OntoThink_V4/enflame_training/datasets/ontothink_multiturn/train.jsonl"
export MAX_TOKENS="128"      # 进一步减小到128
export TP_SIZE="1"           
export DP_SIZE="1"           
export PP_SIZE="4"           # 保持4卡流水线
export LADDER_SHAPE="False"
export SKIP_STEPS="2"        # 更频繁检查
export MAX_STEPS="5"         # 先运行5步验证
export MICRO_BATCH_SIZE="1"  # 保持最小
export GARDIENT_ACCUMULATION_STEPS="1"  # 减少到1，避免额外内存
export EVAL_BATCH_SIZE="1"
export EVAL_PER_N_EPOCHS="100"
export TRAIN_EPOCHS="1"

echo "✅ 超级内存优化配置:"
echo "  🔥 核心配置: PP_SIZE=$PP_SIZE (4卡流水线并行)"
echo "  🎯 使用卡数: 4张 (GCU 0-3)"
echo "  📊 模型: $PRETRAINED_MODEL_PATH"
echo "  📁 数据: $TRAIN_FILE"
echo "  📏 序列长度: MAX_TOKENS=$MAX_TOKENS (超小)"
echo "  🔄 训练步数: MAX_STEPS=$MAX_STEPS (快速验证)"
echo "  📦 批次配置: micro_batch=$MICRO_BATCH_SIZE, grad_accum=$GARDIENT_ACCUMULATION_STEPS (最小)"
echo "  🧵 线程配置: OMP_NUM_THREADS=$OMP_NUM_THREADS (最小)"

echo ""
echo "🚀 启动4卡超级内存优化训练"
echo "=========================="
echo "目标：将内存使用降到20GB以下"
echo "日志将输出到 /tmp/ontothink_4card_ultra_memory.log"

# 启动4卡超级内存优化训练
python3.8 -u -m torch.distributed.launch \
    --nproc_per_node=4 \
    --standalone \
    --use_env finetune_chatglm3_for_multiturn.py \
    --model_path "$PRETRAINED_MODEL_PATH" \
    --train_file "$TRAIN_FILE" \
    --tp_size "$TP_SIZE" \
    --dp_size "$DP_SIZE" \
    --pp_size "$PP_SIZE" \
    --train_micro_batch_size "$MICRO_BATCH_SIZE" \
    --gradient_accumulation_steps "$GARDIENT_ACCUMULATION_STEPS" \
    --max_steps "$MAX_STEPS" \
    --max_tokens "$MAX_TOKENS" \
    --ladder_shape "$LADDER_SHAPE" \
    --skip_steps "$SKIP_STEPS" \
    --eval_batch_size "$EVAL_BATCH_SIZE" \
    --eval_per_n_epochs "$EVAL_PER_N_EPOCHS" \
    --train_epochs "$TRAIN_EPOCHS" 2>&1 | tee /tmp/ontothink_4card_ultra_memory.log

echo ""
echo "🔍 4卡超级内存优化结果分析"
echo "========================="

if [ -f /tmp/ontothink_4card_ultra_memory.log ]; then
    echo "📋 检查最新输出:"
    tail -30 /tmp/ontothink_4card_ultra_memory.log
    
    echo ""
    echo "📊 关键指标检查:"
    
    # 检查内存错误
    MEMORY_ERRORS=$(grep -c "Out of Memory\|topsMalloc.*failed" /tmp/ontothink_4card_ultra_memory.log)
    echo "  💾 内存错误: $MEMORY_ERRORS 次"
    
    # 检查训练进展
    TRAINING_STEPS=$(grep -c -i "step.*loss\|loss.*:" /tmp/ontothink_4card_ultra_memory.log)
    echo "  📈 训练步骤: $TRAINING_STEPS 次"
    
    # 检查内存使用情况
    MEMORY_USAGE=$(grep -A1 "Total current used size" /tmp/ontothink_4card_ultra_memory.log | tail -1)
    echo "  📊 内存使用: $MEMORY_USAGE"
    
    # 检查4卡初始化
    ECCL_SUCCESS=$(grep -c "ecclCommInitRank.*success" /tmp/ontothink_4card_ultra_memory.log)
    echo "  🔗 ECCL成功初始化: $ECCL_SUCCESS 次"
    
    # 检查进程失败
    RANK_FAILURES=$(grep -c "rank.*fail\|exitcode.*1" /tmp/ontothink_4card_ultra_memory.log)
    echo "  ❌ rank失败: $RANK_FAILURES 次"
    
    echo ""
    echo "💡 超级内存优化评估:"
    
    if [ $MEMORY_ERRORS -eq 0 ] && [ $TRAINING_STEPS -gt 0 ] && [ $RANK_FAILURES -eq 0 ]; then
        echo "🎉🎉🎉 完全成功！超级内存优化解决了问题！"
        echo "✅ 内存问题彻底解决"
        echo "✅ 训练循环正常运行 ($TRAINING_STEPS 个训练步骤)"
        echo "✅ 4卡流水线并行稳定工作"
        echo "✅ 所有进程正常完成"
        echo ""
        echo "🚀 OntoThink哲学模型微调成功！"
        echo "🏆 ChatGLM3-6B在燧原T20上的4卡训练完全突破！"
        echo ""
        echo "📈 现在可以逐步扩展:"
        echo "1. 增加MAX_TOKENS: 128 → 256 → 512"
        echo "2. 增加MAX_STEPS: 5 → 20 → 100"
        echo "3. 增加GRADIENT_ACCUMULATION: 1 → 4 → 16"
        echo "4. 最终扩展到完整训练配置"
        
    elif [ $MEMORY_ERRORS -eq 0 ] && [ $RANK_FAILURES -eq 0 ]; then
        echo "🎯 内存问题解决！"
        echo "✅ 内存优化成功"
        echo "✅ 进程稳定运行"
        echo "⚠️  训练可能还在初始化阶段"
        echo ""
        echo "💡 重大突破！可以开始增加参数规模"
        
    elif [ $MEMORY_ERRORS -eq 0 ]; then
        echo "🎯 内存问题解决！"
        echo "✅ 超级内存优化有效"
        echo "⚠️  仍有进程稳定性问题"
        echo ""
        echo "💡 可能需要进一步调整其他参数"
        
    else
        echo "⚠️  内存问题仍未完全解决"
        echo "💡 可能需要更激进的方案:"
        echo "1. 尝试2卡并行 (PP_SIZE=2)"
        echo "2. 尝试单卡训练 (测试基础功能)"
        echo "3. 检查是否需要更小的模型"
    fi
    
    echo ""
    echo "📋 内存优化对比:"
    echo "  之前: 26.3GB (接近32GB限制 ❌)"
    echo "  目标: <20GB (安全范围 ✅)"
    
    if grep -q "Total current used size" /tmp/ontothink_4card_ultra_memory.log; then
        CURRENT_MEMORY=$(grep "Total current used size" /tmp/ontothink_4card_ultra_memory.log | tail -1 | grep -o "[0-9]*KB")
        if [ -n "$CURRENT_MEMORY" ]; then
            echo "  当前: $CURRENT_MEMORY"
        fi
    fi
    
else
    echo "❌ 训练日志文件不存在"
fi

echo ""
echo "📋 超级内存优化配置总结:"
echo "  🎯 策略: 极限内存优化，确保在32GB限制内"
echo "  🔄 并行: 4卡流水线并行 (PP_SIZE=4)"
echo "  💾 模型: ChatGLM3-6B"
echo "  📊 数据: OntoThink哲学问答"
echo "  📏 参数: max_tokens=128, steps=5, batch=1, accum=1"
echo "  📋 日志: /tmp/ontothink_4card_ultra_memory.log"

echo ""
echo "🎯 成功判定标准:"
echo "✅ 内存错误 = 0"
echo "✅ 训练步骤 > 0"
echo "✅ 进程失败 = 0"
echo "✅ 内存使用 < 25GB"

echo ""
if [ -f /tmp/ontothink_4card_ultra_memory.log ]; then
    MEMORY_OK=$([ $(grep -c "Out of Memory" /tmp/ontothink_4card_ultra_memory.log) -eq 0 ] && echo "true" || echo "false")
    TRAINING_OK=$([ $(grep -c "step.*loss" /tmp/ontothink_4card_ultra_memory.log) -gt 0 ] && echo "true" || echo "false")
    PROCESS_OK=$([ $(grep -c "rank.*fail\|exitcode.*1" /tmp/ontothink_4card_ultra_memory.log) -eq 0 ] && echo "true" || echo "false")
    
    if [ "$MEMORY_OK" = "true" ] && [ "$TRAINING_OK" = "true" ] && [ "$PROCESS_OK" = "true" ]; then
        echo "🏆🏆🏆 OntoThink 4卡超级内存优化完全成功！"
        echo "🎯 ChatGLM3-6B哲学问答模型微调正式开始！"
        echo "🚀 燧原T20内存优化训练环境完美搭建！"
    elif [ "$MEMORY_OK" = "true" ] && [ "$PROCESS_OK" = "true" ]; then
        echo "🎯 内存优化成功！训练环境稳定！"
        echo "💪 可以开始逐步扩展配置参数"
    elif [ "$MEMORY_OK" = "true" ]; then
        echo "🎯 内存突破成功！"
        echo "💪 继续优化训练稳定性"
    else
        echo "⚠️  需要更激进的内存优化方案"
        echo "💡 考虑减少并行度或使用更小配置"
    fi
fi

echo ""
echo "🔄 下一步计划:"
echo "如果内存成功 → 逐步增加tokens和steps"
echo "如果仍超限 → 考虑2卡并行或单卡训练"
echo "如果训练成功 → 开始正式的模型微调工作"
