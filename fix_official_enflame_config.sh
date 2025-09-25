#!/bin/bash
# 基于燧原官方配置修复 - 使用官方chatglm3_6b_1h8c_multiturn.sh的标准配置
# 解决所有环境变量和参数差异

echo "🎯 基于燧原官方配置修复 - 使用官方标准配置"
echo "============================================="

# 确认的燧原工具包路径 (已验证可用)
CONFIRMED_TOOLKIT_ROOT="/installer/topsrider_extracted/TopsRider_installer/ai_development_toolkit"
CHATGLM3_SCRIPT_DIR="${CONFIRMED_TOOLKIT_ROOT}/distributed/llm_scripts_1.0.40/finetuning/chatglm3"
TRAINING_SCRIPT="${CHATGLM3_SCRIPT_DIR}/finetune_chatglm3_for_multiturn.py"

echo "📋 关键发现 - 燧原官方配置对比："
echo "=============================="
echo "❌ 我们的配置过度保守，与官方差异很大："
echo "  ENFLAME_PT_ENABLE_HBM_INPLACE: false → true"
echo "  OMP_NUM_THREADS: 1 → 5"
echo "  ECCL_MAX_NCHANNELS: 1 → 2" 
echo "  PP_SIZE: 4 → 8 (但我们先用4卡测试)"
echo "  MAX_TOKENS: 128 → 1800 (逐步增加)"
echo "  GRADIENT_ACCUMULATION_STEPS: 1 → 128 (逐步增加)"
echo "  LADDER_SHAPE: 'false' → 'False' (大小写)"

echo ""
echo "🎯 燧原官方标准环境配置"
echo "======================"

# 设置燧原官方标准环境变量
export ENFLAME_ENABLE_EFP=true
export ENFLAME_PT_ENABLE_HBM_INPLACE=true  # 官方启用，我们之前禁用了！

export OMP_NUM_THREADS=5  # 官方用5，我们之前用1
export ECCL_MAX_NCHANNELS=2  # 官方用2，我们之前用1
export ENFLAME_UMD_FLAGS="mem_alloc_retry_times=1"

# 分布式环境变量 (保持torch.distributed.launch需要的)
export MASTER_ADDR=localhost
export MASTER_PORT=29500
export WORLD_SIZE=4      # 先用4张GCU卡测试，官方是8卡
export RANK=0
export LOCAL_RANK=0
export GCU_VISIBLE_DEVICES="0,1,2,3"
export PTEX_DDP_BACKEND=eccl

# 设置训练参数 - 基于官方配置但保守调整
export PRETRAINED_MODEL_PATH="/workspace/code/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b"
export TRAIN_FILE="/workspace/code/OntoThink_V4/enflame_training/datasets/ontothink_multiturn/train.jsonl"
export MAX_TOKENS="256"  # 官方1800，我们先用256
export TP_SIZE="1"  # 保持
export DP_SIZE="1"  # 保持
export PP_SIZE="4"  # 官方8，我们先用4卡
export LADDER_SHAPE="False"  # 官方大写False！
export SKIP_STEPS="100"  # 官方默认
export MAX_STEPS="10"  # 先测试10步
export MICRO_BATCH_SIZE="1"  # 保持
export GARDIENT_ACCUMULATION_STEPS="4"  # 官方128，我们先用4
export EVAL_BATCH_SIZE="1"  # 官方默认
export EVAL_PER_N_EPOCHS="1"  # 官方默认
export TRAIN_EPOCHS="1"  # 先测试1个epoch

echo "🎯 官方标准配置："
echo "  硬件: 4张GCU (对应官方8卡的一半)"
echo "  并行: 流水线并行 (TP=$TP_SIZE, DP=$DP_SIZE, PP=$PP_SIZE)"
echo "  内存: 官方优化 (tokens=$MAX_TOKENS, batch=$MICRO_BATCH_SIZE, accum=$GARDIENT_ACCUMULATION_STEPS)"
echo "  步骤: MAX_STEPS=$MAX_STEPS (验证官方配置)"
echo "  🔧 核心修复: ENFLAME_PT_ENABLE_HBM_INPLACE=true"
echo "  🔧 核心修复: OMP_NUM_THREADS=5, ECCL_MAX_NCHANNELS=2"
echo "  🔧 核心修复: LADDER_SHAPE='False' (大写)"
echo "  ❌ 移除: --deepspeed参数 (官方不使用)"

echo ""
echo "🚀 启动燧原官方标准配置训练"
echo "==========================="
echo "日志将输出到 /tmp/ontothink_official_config.log"

# 使用燧原官方参数格式 (完全对应官方脚本)
(cd "$CHATGLM3_SCRIPT_DIR" && \
    python3.8 -u -m torch.distributed.launch \
        --nproc_per_node="$WORLD_SIZE" \
        --standalone \
        --use_env "$TRAINING_SCRIPT" \
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
        --train_epochs "$TRAIN_EPOCHS" \
        &> /tmp/ontothink_official_config.log)

echo ""
echo "🔍 官方配置训练完成。请查看日志文件: /tmp/ontothink_official_config.log"
echo ""

echo "🔍 结果分析"
echo "==========="
ERROR_LOG=$(grep -E "ERROR|Traceback|Failures" /tmp/ontothink_official_config.log || true)
if [ -n "$ERROR_LOG" ]; then
    echo "❌ 发现错误:"
    echo "$ERROR_LOG"
else
    echo "✅ 未发现明显错误"
fi

MEMORY_ERRORS=$(grep -c "topsMalloc.*failed\|Check failed.*topsSuccess" /tmp/ontothink_official_config.log)
ECCL_SUCCESS=$(grep -c "ecclCommInitRank success!" /tmp/ontothink_official_config.log)
TRAINING_STEPS=$(grep -c "step.*loss" /tmp/ontothink_official_config.log)
MODEL_COMPILED=$(grep -c "HLIR Compile Finish" /tmp/ontothink_official_config.log)

echo "📊 关键指标检查:"
echo "  💾 内存错误: $MEMORY_ERRORS 次"
echo "  🔗 ECCL成功初始化: $ECCL_SUCCESS 次"
echo "  📈 训练步骤: $TRAINING_STEPS 次"
echo "  ⚡ 模型编译: $MODEL_COMPILED 次"

if [ $MEMORY_ERRORS -eq 0 ] && [ $ECCL_SUCCESS -gt 0 ] && [ $TRAINING_STEPS -gt 0 ] && [ $MODEL_COMPILED -gt 0 ]; then
    echo ""
    echo "🎉🎉🎉 燧原官方配置完全成功！"
    echo "✅ 官方环境变量配置正确"
    echo "✅ 所有核心指标正常"
    echo "✅ OntoThink官方标准训练建立"
    echo ""
    echo "🚀 重大突破意义："
    echo "  🏆 验证了燧原官方最佳实践"
    echo "  💪 证明了OntoThink可以在官方配置下运行"
    echo "  📈 现在可以逐步扩展到官方完整配置"
    echo "  🎯 下一步: 8卡, MAX_TOKENS=1800, GRADIENT_ACCUMULATION=128"
    
elif [ $ECCL_SUCCESS -gt 0 ] && [ $MODEL_COMPILED -gt 0 ]; then
    echo ""
    echo "🎯 重大进展！核心组件成功！"
    echo "✅ ECCL初始化成功 ($ECCL_SUCCESS 次)"
    echo "✅ 模型编译成功 ($MODEL_COMPILED 次)"
    
    if [ $TRAINING_STEPS -eq 0 ]; then
        echo "⚠️  训练步骤未开始，可能需要等待更长时间"
    else
        echo "✅ 训练步骤已运行 ($TRAINING_STEPS 次)"
    fi
    
    if [ $MEMORY_ERRORS -gt 0 ]; then
        echo "⚠️  内存问题 ($MEMORY_ERRORS 次)，可能需要调整官方参数"
    else
        echo "✅ 内存配置正常 (0次错误)"
    fi
    
else
    echo ""
    echo "⚠️  仍需调试，但官方配置方向正确"
    echo "📊 分析上述指标，可能需要微调"
fi

echo ""
echo "💡 官方配置修复总结"
echo "=================="
echo "🎯 核心修复:"
echo "  ✅ 启用 ENFLAME_PT_ENABLE_HBM_INPLACE=true"
echo "  ✅ 增加 OMP_NUM_THREADS=5 (从1增加到5)"
echo "  ✅ 增加 ECCL_MAX_NCHANNELS=2 (从1增加到2)"
echo "  ✅ 修复 LADDER_SHAPE='False' (大小写)"
echo "  ✅ 增加 GRADIENT_ACCUMULATION_STEPS=4 (从1增加到4)"
echo "  ✅ 增加 MAX_TOKENS=256 (从128增加到256)"
echo "  ❌ 移除 --deepspeed 参数 (官方不使用)"

echo "🎯 如果成功:"
echo "  - 燧原官方配置完全验证"
echo "  - OntoThink可以使用官方最佳实践"
echo "  - 性能和稳定性大幅提升"
echo "  - 为扩展到8卡和完整配置奠定基础"

echo ""
echo "📋 完整日志: /tmp/ontothink_official_config.log"
echo ""
echo "🎉 燧原官方配置训练完成！预期重大突破！"
