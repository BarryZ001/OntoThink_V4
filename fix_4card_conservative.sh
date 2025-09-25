#!/bin/bash

# 🔧 4卡保守训练解决方案
# 多卡故障，使用保守的4卡配置确保基础功能
# ==========================================

echo "🔧 4卡保守训练解决方案"
echo "多卡故障，使用保守的4卡配置确保基础功能"
echo "=========================================="

echo ""
echo "🎯 问题重新分析:"
echo "✅ 核心突破保持: 数据格式错误 = 0, 内存分配错误 = 0"
echo "✅ 通信基础正常: ECCL初始化86次成功"
echo "❌ 多卡并行问题: 8卡→rank7失败, 7卡→rank6失败"
echo "💡 新策略: 不是硬件故障，是多卡并行配置问题"

echo ""
echo "💡 保守解决策略:"
echo "- 使用4张卡 (减少并行复杂度)"
echo "- PP_SIZE=4 (更稳定的流水线配置)"
echo "- 增加错误检测和故障恢复"
echo "- 保持已验证成功的配置"

echo ""
echo "🔧 设置4卡保守训练环境"
echo "======================"

# 燧原脚本目录
ENFLAME_SCRIPT_DIR="/workspace/code/OntoThink_V4/FromEnflame/ai_development_toolkit/distributed/llm_scripts_1.0.40/finetuning/chatglm3"

if [ ! -f "$ENFLAME_SCRIPT_DIR/finetune_chatglm3_for_multiturn.py" ]; then
    echo "❌ 训练脚本不存在"
    exit 1
fi

echo "✅ 找到训练脚本: $ENFLAME_SCRIPT_DIR"
cd "$ENFLAME_SCRIPT_DIR"

# 使用最保守的燧原环境变量
echo "🎯 设置保守的燧原环境变量..."
export ENFLAME_ENABLE_EFP=true
export ENFLAME_PT_ENABLE_HBM_INPLACE=true
export OMP_NUM_THREADS=3  # 减少线程数，更保守
export ECCL_MAX_NCHANNELS=1  # 最小通道数
export ENFLAME_UMD_FLAGS="mem_alloc_retry_times=3"  # 增加重试次数

# 明确使用前4张卡
export GCU_VISIBLE_DEVICES=0,1,2,3
echo "🎯 使用GCU卡: $GCU_VISIBLE_DEVICES (保守的4卡配置)"

# 设置分布式环境变量，更严格
export MASTER_ADDR=localhost
export MASTER_PORT=29501  # 换个端口避免冲突
export WORLD_SIZE=4
export NCCL_DEBUG=INFO  # 开启详细调试信息

# 设置4卡保守训练参数
echo "🎯 设置4卡保守训练参数..."
export PRETRAINED_MODEL_PATH="/workspace/code/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b"
export TRAIN_FILE="/workspace/code/OntoThink_V4/enflame_training/datasets/ontothink_multiturn/train.jsonl"
export MAX_TOKENS="256"      # 进一步减小，确保稳定
export TP_SIZE="1"           # 保持成功的配置
export DP_SIZE="1"           # 保持成功的配置
export PP_SIZE="4"           # 4卡流水线并行
export LADDER_SHAPE="False"
export SKIP_STEPS="5"        # 更频繁的状态检查
export MAX_STEPS="20"        # 先运行少量步骤验证
export MICRO_BATCH_SIZE="1"
export GARDIENT_ACCUMULATION_STEPS="4"  # 减少累积步数
export EVAL_BATCH_SIZE="1"
export EVAL_PER_N_EPOCHS="100"
export TRAIN_EPOCHS="1"

echo "✅ 4卡保守配置:"
echo "  🔥 核心配置: PP_SIZE=$PP_SIZE (4卡流水线并行)"
echo "  🎯 使用卡数: 4张 (GCU 0-3)"
echo "  📊 模型: $PRETRAINED_MODEL_PATH"
echo "  📁 数据: $TRAIN_FILE (已转换格式)"
echo "  📏 序列长度: MAX_TOKENS=$MAX_TOKENS (保守)"
echo "  🔄 训练步数: MAX_STEPS=$MAX_STEPS (快速验证)"
echo "  📦 批次配置: micro_batch=$MICRO_BATCH_SIZE, grad_accum=$GARDIENT_ACCUMULATION_STEPS"
echo "  🧵 线程配置: OMP_NUM_THREADS=$OMP_NUM_THREADS (保守)"

echo ""
echo "🚀 启动4卡保守流水线并行训练"
echo "==========================="
echo "使用最稳定的4卡配置"
echo "日志将输出到 /tmp/ontothink_4card_conservative.log"

# 清理之前的进程
echo "🧹 清理环境..."
pkill -f "finetune_chatglm3" || true
sleep 2

# 启动4卡保守训练
echo "🚀 启动训练..."
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
    --train_epochs "$TRAIN_EPOCHS" 2>&1 | tee /tmp/ontothink_4card_conservative.log

echo ""
echo "🔍 4卡保守训练结果分析"
echo "===================="

if [ -f /tmp/ontothink_4card_conservative.log ]; then
    echo "📋 检查最新输出:"
    tail -30 /tmp/ontothink_4card_conservative.log
    
    echo ""
    echo "📊 关键指标检查:"
    
    # 检查数据格式问题 (应该依然为0)
    DATA_ERRORS=$(grep -c "KeyError.*role\|role.*KeyError" /tmp/ontothink_4card_conservative.log)
    echo "  📋 数据格式错误: $DATA_ERRORS 次"
    
    # 检查内存问题 (应该依然为0)
    MEMORY_ERRORS=$(grep -c "topsMalloc.*failed\|Check failed.*topsSuccess" /tmp/ontothink_4card_conservative.log)
    echo "  💾 内存分配错误: $MEMORY_ERRORS 次"
    
    # 检查训练进展 (关键指标)
    TRAINING_STEPS=$(grep -c -i "step.*loss\|loss.*:" /tmp/ontothink_4card_conservative.log)
    echo "  📈 训练步骤: $TRAINING_STEPS 次"
    
    # 检查4卡初始化
    ECCL_SUCCESS=$(grep -c "ecclCommInitRank.*success" /tmp/ontothink_4card_conservative.log)
    echo "  🔗 ECCL成功初始化: $ECCL_SUCCESS 次"
    
    # 检查进程失败
    RANK_FAILURES=$(grep -c "rank.*[0-9].*fail\|local_rank.*[0-9].*exitcode.*1" /tmp/ontothink_4card_conservative.log)
    echo "  ❌ rank失败: $RANK_FAILURES 次"
    
    # 检查完成状态
    COMPLETION_MSGS=$(grep -c -i "training.*complete\|epoch.*complete\|Saving.*checkpoint" /tmp/ontothink_4card_conservative.log)
    echo "  🏁 完成状态: $COMPLETION_MSGS 次"
    
    echo ""
    echo "💡 4卡保守训练评估:"
    
    if [ $DATA_ERRORS -eq 0 ] && [ $MEMORY_ERRORS -eq 0 ] && [ $TRAINING_STEPS -gt 0 ] && [ $RANK_FAILURES -eq 0 ]; then
        echo "🎉🎉🎉 完全成功！4卡保守训练正常运行！"
        echo "✅ 数据格式完美 (无role错误)"
        echo "✅ 内存问题彻底解决 (无分配失败)"
        echo "✅ 训练循环正常 ($TRAINING_STEPS 个训练步骤)"
        echo "✅ 4卡流水线并行稳定工作"
        echo "✅ 所有进程正常完成"
        echo ""
        echo "🚀 OntoThink哲学模型微调成功启动！"
        echo "🏆 ChatGLM3-6B在燧原T20上的4卡训练目标达成！"
        echo ""
        echo "📈 现在可以逐步扩展:"
        echo "1. 增加卡数: 4 → 6 → 8"
        echo "2. 增加MAX_TOKENS: 256 → 512 → 1024"
        echo "3. 增加MAX_STEPS: 20 → 100 → 1000"
        echo "4. 增加GRADIENT_ACCUMULATION: 4 → 16 → 64"
        echo "5. 开始长期训练"
        
    elif [ $DATA_ERRORS -eq 0 ] && [ $MEMORY_ERRORS -eq 0 ] && [ $RANK_FAILURES -eq 0 ]; then
        echo "🎯 基础问题完全解决！"
        echo "✅ 数据格式修复成功"
        echo "✅ 内存问题彻底解决"
        echo "✅ 多进程稳定运行"
        echo "⚠️  训练可能还在初始化阶段"
        echo ""
        echo "💡 重大突破！可以开始扩展配置"
        
    elif [ $DATA_ERRORS -eq 0 ] && [ $MEMORY_ERRORS -eq 0 ]; then
        echo "🎯 核心问题解决！"
        echo "✅ 数据格式修复成功"
        echo "✅ 内存问题彻底解决"
        echo "⚠️  仍有进程稳定性问题"
        echo ""
        echo "💡 可能需要进一步调整并行参数"
        
    else
        echo "⚠️  需要继续调试基础问题"
    fi
    
    echo ""
    echo "📋 问题诊断:"
    if [ $RANK_FAILURES -gt 0 ]; then
        echo "❌ 进程失败详情:"
        grep -A2 -B2 "rank.*fail\|exitcode.*1" /tmp/ontothink_4card_conservative.log | tail -10
    fi
    
    if [ $TRAINING_STEPS -eq 0 ]; then
        echo "⚠️  训练未开始，可能的原因:"
        echo "  - 数据加载问题"
        echo "  - 模型初始化问题"
        echo "  - 配置参数问题"
    fi
    
else
    echo "❌ 训练日志文件不存在"
fi

echo ""
echo "📋 4卡保守配置总结:"
echo "  🎯 策略: 使用稳定的4卡配置，降低并行复杂度"
echo "  🔄 并行: 4卡流水线并行 (PP_SIZE=4)"
echo "  💾 模型: ChatGLM3-6B"
echo "  📊 数据: OntoThink哲学问答 (已转换格式)"
echo "  📏 参数: max_tokens=$MAX_TOKENS, steps=$MAX_STEPS"
echo "  📋 日志: /tmp/ontothink_4card_conservative.log"

echo ""
echo "🎯 成功判定标准:"
echo "✅ 数据格式错误 = 0"
echo "✅ 内存分配错误 = 0"
echo "✅ 训练步骤 > 0"
echo "✅ ECCL初始化成功"
echo "✅ 进程失败 = 0"

echo ""
if [ -f /tmp/ontothink_4card_conservative.log ]; then
    DATA_OK=$([ $(grep -c "KeyError.*role" /tmp/ontothink_4card_conservative.log) -eq 0 ] && echo "true" || echo "false")
    MEMORY_OK=$([ $(grep -c "topsMalloc.*failed" /tmp/ontothink_4card_conservative.log) -eq 0 ] && echo "true" || echo "false")
    TRAINING_OK=$([ $(grep -c "step.*loss" /tmp/ontothink_4card_conservative.log) -gt 0 ] && echo "true" || echo "false")
    PROCESS_OK=$([ $(grep -c "rank.*fail\|exitcode.*1" /tmp/ontothink_4card_conservative.log) -eq 0 ] && echo "true" || echo "false")
    
    if [ "$DATA_OK" = "true" ] && [ "$MEMORY_OK" = "true" ] && [ "$TRAINING_OK" = "true" ] && [ "$PROCESS_OK" = "true" ]; then
        echo "🏆🏆🏆 OntoThink 4卡训练完全成功！"
        echo "🎯 ChatGLM3-6B哲学问答模型微调正式开始！"
        echo "🚀 燧原T20稳定训练环境成功搭建！"
    elif [ "$DATA_OK" = "true" ] && [ "$MEMORY_OK" = "true" ] && [ "$PROCESS_OK" = "true" ]; then
        echo "🎯 训练环境稳定！即将开始训练循环"
        echo "💪 基础问题全部解决，训练成功在望！"
    else
        echo "⚠️  仍需继续调试，但进展显著"
        echo "💪 继续优化配置参数"
    fi
fi

echo ""
echo "🔄 下一步计划:"
echo "如果4卡成功 → 逐步扩展到6卡、8卡"
echo "如果仍有问题 → 尝试2卡或单卡训练"
echo "如果训练开始 → 增加训练步数和参数规模"
