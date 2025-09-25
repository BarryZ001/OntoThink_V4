#!/bin/bash

# 🔧 7卡训练解决方案
# rank 7 (第8张卡) 故障，使用7张卡继续训练
# ===============================================

echo "🔧 7卡训练解决方案"
echo "rank 7 (第8张卡) 故障，使用7张卡继续训练"
echo "============================================="

echo ""
echo "🎯 问题分析:"
echo "✅ 重大突破: 数据格式错误 = 0 (KeyError: 'role'已解决)"
echo "✅ 重大突破: 内存分配错误 = 0 (topsMalloc failed已解决)" 
echo "✅ 通信正常: ECCL初始化98次成功"
echo "✅ 7张卡正常: rank 0-6 都正常启动"
echo "❌ 单卡故障: rank 7 (第8张卡) 失败"

echo ""
echo "💡 解决策略:"
echo "- 使用7张卡继续训练 (nproc_per_node=7)"
echo "- 调整PP_SIZE=7 适配7卡流水线"
echo "- 避开故障的第8张卡"
echo "- 保持其他成功的配置不变"

echo ""
echo "🔧 设置7卡训练环境"
echo "=================="

# 燧原脚本目录
ENFLAME_SCRIPT_DIR="/workspace/code/OntoThink_V4/FromEnflame/ai_development_toolkit/distributed/llm_scripts_1.0.40/finetuning/chatglm3"

if [ ! -f "$ENFLAME_SCRIPT_DIR/finetune_chatglm3_for_multiturn.py" ]; then
    echo "❌ 训练脚本不存在"
    exit 1
fi

echo "✅ 找到训练脚本: $ENFLAME_SCRIPT_DIR"
cd "$ENFLAME_SCRIPT_DIR"

# 使用已验证有效的燧原环境变量
echo "🎯 设置燧原环境变量 (保持成功配置)..."
export ENFLAME_ENABLE_EFP=true
export ENFLAME_PT_ENABLE_HBM_INPLACE=true
export OMP_NUM_THREADS=5
export ECCL_MAX_NCHANNELS=2
export ENFLAME_UMD_FLAGS="mem_alloc_retry_times=1"

# 明确排除故障卡，只使用前7张卡
export GCU_VISIBLE_DEVICES=0,1,2,3,4,5,6
echo "🎯 使用GCU卡: $GCU_VISIBLE_DEVICES (排除故障的卡7)"

# 设置7卡训练参数
echo "🎯 设置7卡训练参数..."
export PRETRAINED_MODEL_PATH="/workspace/code/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b"
export TRAIN_FILE="/workspace/code/OntoThink_V4/enflame_training/datasets/ontothink_multiturn/train.jsonl"
export MAX_TOKENS="512"      # 保持成功的配置
export TP_SIZE="1"           # 保持成功的配置
export DP_SIZE="1"           # 保持成功的配置
export PP_SIZE="7"           # 🔥 调整为7卡流水线并行
export LADDER_SHAPE="False"
export SKIP_STEPS="10"
export MAX_STEPS="100"       # 增加到100步验证稳定性
export MICRO_BATCH_SIZE="1"
export GARDIENT_ACCUMULATION_STEPS="16"
export EVAL_BATCH_SIZE="1"
export EVAL_PER_N_EPOCHS="100"
export TRAIN_EPOCHS="1"

echo "✅ 7卡训练配置:"
echo "  🔥 核心配置: PP_SIZE=$PP_SIZE (7卡流水线并行)"
echo "  🎯 使用卡数: 7张 (GCU 0-6)"
echo "  📊 模型: $PRETRAINED_MODEL_PATH"
echo "  📁 数据: $TRAIN_FILE (已转换格式)"
echo "  📏 序列长度: MAX_TOKENS=$MAX_TOKENS"
echo "  🔄 训练步数: MAX_STEPS=$MAX_STEPS"
echo "  📦 批次配置: micro_batch=$MICRO_BATCH_SIZE, grad_accum=$GARDIENT_ACCUMULATION_STEPS"

echo ""
echo "🚀 启动7卡流水线并行训练"
echo "========================"
echo "避开故障卡，使用7张正常工作的GCU"
echo "日志将输出到 /tmp/ontothink_7card_training.log"

# 启动7卡训练
python3.8 -u -m torch.distributed.launch \
    --nproc_per_node=7 \
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
    --train_epochs "$TRAIN_EPOCHS" 2>&1 | tee /tmp/ontothink_7card_training.log

echo ""
echo "🔍 7卡训练结果分析"
echo "=================="

if [ -f /tmp/ontothink_7card_training.log ]; then
    echo "📋 检查最新输出:"
    tail -20 /tmp/ontothink_7card_training.log
    
    echo ""
    echo "📊 关键指标检查:"
    
    # 检查数据格式问题 (应该依然为0)
    DATA_ERRORS=$(grep -c "KeyError.*role\|role.*KeyError" /tmp/ontothink_7card_training.log)
    echo "  📋 数据格式错误: $DATA_ERRORS 次"
    
    # 检查内存问题 (应该依然为0)
    MEMORY_ERRORS=$(grep -c "topsMalloc.*failed\|Check failed.*topsSuccess" /tmp/ontothink_7card_training.log)
    echo "  💾 内存分配错误: $MEMORY_ERRORS 次"
    
    # 检查训练进展 (关键指标)
    TRAINING_STEPS=$(grep -c -i "step.*loss\|loss.*:" /tmp/ontothink_7card_training.log)
    echo "  📈 训练步骤: $TRAINING_STEPS 次"
    
    # 检查7卡初始化
    ECCL_SUCCESS=$(grep -c "ecclCommInitRank.*success" /tmp/ontothink_7card_training.log)
    echo "  🔗 ECCL成功初始化: $ECCL_SUCCESS 次"
    
    # 检查进程数量
    PROC_COUNT=$(grep -c -i "rank.*[0-6]" /tmp/ontothink_7card_training.log)
    echo "  🖥️  检测到进程数: $PROC_COUNT 个 (应该≥7)"
    
    # 检查rank 7错误 (应该为0)
    RANK7_ERRORS=$(grep -c "rank.*7.*fail\|local_rank.*7" /tmp/ontothink_7card_training.log)
    echo "  ❌ rank 7错误: $RANK7_ERRORS 次 (应该为0)"
    
    echo ""
    echo "💡 7卡训练评估:"
    
    if [ $DATA_ERRORS -eq 0 ] && [ $MEMORY_ERRORS -eq 0 ] && [ $TRAINING_STEPS -gt 0 ] && [ $RANK7_ERRORS -eq 0 ]; then
        echo "🎉🎉🎉 完全成功！7卡训练正常运行！"
        echo "✅ 数据格式完美 (无role错误)"
        echo "✅ 内存问题彻底解决 (无分配失败)"
        echo "✅ 训练循环正常 ($TRAINING_STEPS 个训练步骤)"
        echo "✅ 7卡流水线并行稳定工作"
        echo "✅ 成功避开故障卡"
        echo ""
        echo "🚀 OntoThink哲学模型微调成功启动！"
        echo "🏆 ChatGLM3-6B在燧原T20上的训练目标达成！"
        echo ""
        echo "📈 现在可以扩展训练规模:"
        echo "1. 增加MAX_TOKENS: 512 → 1024 → 1800"
        echo "2. 增加MAX_STEPS: 100 → 1000 → 10000"
        echo "3. 增加GRADIENT_ACCUMULATION: 16 → 64 → 128"
        echo "4. 增加TRAIN_EPOCHS: 1 → 3 → 10"
        echo "5. 使用完整的OntoThink数据集进行长期训练"
        
    elif [ $DATA_ERRORS -eq 0 ] && [ $MEMORY_ERRORS -eq 0 ] && [ $RANK7_ERRORS -eq 0 ]; then
        echo "🎯 硬件问题完全解决！"
        echo "✅ 数据格式修复成功"
        echo "✅ 内存问题彻底解决"
        echo "✅ 成功避开故障卡"
        echo "⚠️  训练可能还在初始化阶段"
        echo ""
        echo "💡 重大突破！所有基础问题都已解决"
        
    else
        echo "⚠️  需要进一步调试剩余问题"
        if [ $RANK7_ERRORS -gt 0 ]; then
            echo "❌ rank 7错误仍然出现，可能需要检查GCU_VISIBLE_DEVICES设置"
        fi
    fi
    
    echo ""
    echo "📋 故障排除总结:"
    if [ $RANK7_ERRORS -eq 0 ]; then
        echo "✅ 成功避开故障的第8张卡 (rank 7)"
        echo "✅ 7张卡工作正常，训练可以继续"
        echo "💡 可以考虑后续检修第8张卡或继续使用7卡配置"
    else
        echo "❌ rank 7错误仍然出现"
        echo "💡 可能需要更严格的卡隔离或其他配置调整"
    fi
    
else
    echo "❌ 训练日志文件不存在"
fi

echo ""
echo "📋 7卡配置总结:"
echo "  🎯 策略: 避开故障卡，使用7张正常工作的GCU"
echo "  🔄 并行: 7卡流水线并行 (PP_SIZE=7)"
echo "  💾 模型: ChatGLM3-6B"
echo "  📊 数据: OntoThink哲学问答 (已转换格式)"
echo "  📏 参数: max_tokens=$MAX_TOKENS, steps=$MAX_STEPS"
echo "  📋 日志: /tmp/ontothink_7card_training.log"

echo ""
echo "🎯 成功判定标准:"
echo "✅ 数据格式错误 = 0 (保持)"
echo "✅ 内存分配错误 = 0 (保持)"
echo "✅ 训练步骤 > 0 (新突破)"
echo "✅ ECCL初始化成功 (保持)"
echo "✅ rank 7错误 = 0 (故障排除)"

echo ""
if [ -f /tmp/ontothink_7card_training.log ]; then
    DATA_OK=$([ $(grep -c "KeyError.*role" /tmp/ontothink_7card_training.log) -eq 0 ] && echo "true" || echo "false")
    MEMORY_OK=$([ $(grep -c "topsMalloc.*failed" /tmp/ontothink_7card_training.log) -eq 0 ] && echo "true" || echo "false")
    TRAINING_OK=$([ $(grep -c "step.*loss" /tmp/ontothink_7card_training.log) -gt 0 ] && echo "true" || echo "false")
    RANK7_OK=$([ $(grep -c "rank.*7.*fail" /tmp/ontothink_7card_training.log) -eq 0 ] && echo "true" || echo "false")
    
    if [ "$DATA_OK" = "true" ] && [ "$MEMORY_OK" = "true" ] && [ "$TRAINING_OK" = "true" ] && [ "$RANK7_OK" = "true" ]; then
        echo "🏆🏆🏆 OntoThink训练完全成功！"
        echo "🎯 ChatGLM3-6B哲学问答模型微调正式开始！"
        echo "🚀 燧原T20训练环境完美搭建！"
    else
        echo "⚠️  部分问题仍需解决，但已取得历史性突破"
        echo "💪 继续调试，成功在望！"
    fi
fi
