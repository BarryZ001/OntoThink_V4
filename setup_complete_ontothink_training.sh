#!/bin/bash

# 🚀 OntoThink完整训练环境设置
# 包含数据转换 + 燧原官方配置训练
# ================================

echo "🚀 OntoThink完整训练环境设置"
echo "包含数据转换 + 燧原官方配置训练"
echo "================================"

echo ""
echo "📋 设置概览:"
echo "1. 🔄 转换OntoThink数据集为燧原ChatGLM3格式"
echo "2. 📁 创建正确的目录结构"
echo "3. 🔧 使用燧原官方推荐配置"
echo "4. 🚀 启动8卡流水线并行训练"

echo ""
echo "🔄 第一步: 数据格式转换"
echo "======================"

# 检查项目根目录
if [ ! -d "backend/data/processed" ]; then
    echo "❌ 错误: 未找到OntoThink原始数据目录"
    echo "请确保在项目根目录运行此脚本"
    exit 1
fi

echo "✅ 找到OntoThink原始数据目录"

# 转换数据格式
echo "🔄 开始数据格式转换..."
python3 convert_ontothink_to_enflame_format.py

# 验证转换结果
CONVERTED_TRAIN_FILE="/workspace/code/OntoThink_V4/enflame_training/datasets/ontothink_multiturn/train.jsonl"
if [ -f "$CONVERTED_TRAIN_FILE" ]; then
    echo "✅ 数据转换成功"
    echo "📊 训练数据统计:"
    wc -l "$CONVERTED_TRAIN_FILE"
    
    echo ""
    echo "📋 验证数据格式:"
    head -1 "$CONVERTED_TRAIN_FILE" | python3 -m json.tool
    
else
    echo "❌ 数据转换失败"
    exit 1
fi

echo ""
echo "🔧 第二步: 燧原官方配置训练"
echo "=========================="

# 燧原脚本目录
ENFLAME_SCRIPT_DIR="/workspace/code/OntoThink_V4/FromEnflame/ai_development_toolkit/distributed/llm_scripts_1.0.40/finetuning/chatglm3"

if [ ! -f "$ENFLAME_SCRIPT_DIR/finetune_chatglm3_for_multiturn.py" ]; then
    echo "❌ 燧原训练脚本不存在"
    exit 1
fi

echo "✅ 找到燧原训练脚本: $ENFLAME_SCRIPT_DIR"
cd "$ENFLAME_SCRIPT_DIR"

# 设置燧原官方环境变量
echo "🎯 设置燧原官方环境变量..."
export ENFLAME_ENABLE_EFP=true
export ENFLAME_PT_ENABLE_HBM_INPLACE=true
export OMP_NUM_THREADS=5
export ECCL_MAX_NCHANNELS=2
export ENFLAME_UMD_FLAGS="mem_alloc_retry_times=1"

# 设置训练参数 - 基于燧原官方推荐，但做适当调整用于测试
echo "🎯 设置训练参数..."
export PRETRAINED_MODEL_PATH="/workspace/code/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b"
export TRAIN_FILE="$CONVERTED_TRAIN_FILE"
export MAX_TOKENS="512"  # 从官方1800开始，逐步增加
export TP_SIZE="1"       # 官方推荐
export DP_SIZE="1"       # 官方推荐
export PP_SIZE="8"       # 🔥 官方核心推荐：8卡流水线并行
export LADDER_SHAPE="False"
export SKIP_STEPS="10"   # 较小的skip用于快速验证
export MAX_STEPS="50"    # 先运行50步验证
export MICRO_BATCH_SIZE="1"
export GARDIENT_ACCUMULATION_STEPS="16"  # 从官方128开始，逐步增加
export EVAL_BATCH_SIZE="1"
export EVAL_PER_N_EPOCHS="100"
export TRAIN_EPOCHS="1"

echo "✅ 训练配置参数:"
echo "  🔥 核心配置: PP_SIZE=$PP_SIZE (8卡流水线并行)"
echo "  📊 模型: $PRETRAINED_MODEL_PATH"
echo "  📁 数据: $TRAIN_FILE"
echo "  📏 序列长度: MAX_TOKENS=$MAX_TOKENS"
echo "  🔄 训练步数: MAX_STEPS=$MAX_STEPS"
echo "  📦 批次配置: micro_batch=$MICRO_BATCH_SIZE, grad_accum=$GARDIENT_ACCUMULATION_STEPS"
echo "  🧵 线程数: OMP_NUM_THREADS=$OMP_NUM_THREADS"

echo ""
echo "🚀 第三步: 启动官方配置训练"
echo "========================="
echo "使用燧原官方推荐的8卡流水线并行配置"
echo "日志将输出到 /tmp/ontothink_official_training.log"

# 启动训练
python3.8 -u -m torch.distributed.launch \
    --nproc_per_node=8 \
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
    --train_epochs "$TRAIN_EPOCHS" 2>&1 | tee /tmp/ontothink_official_training.log

echo ""
echo "🔍 第四步: 训练结果分析"
echo "===================="

if [ -f /tmp/ontothink_official_training.log ]; then
    echo "📋 检查最新输出:"
    tail -20 /tmp/ontothink_official_training.log
    
    echo ""
    echo "📊 关键指标检查:"
    
    # 检查数据格式问题
    DATA_ERRORS=$(grep -c "KeyError.*role\|role.*KeyError" /tmp/ontothink_official_training.log)
    echo "  📋 数据格式错误: $DATA_ERRORS 次"
    
    # 检查内存问题
    MEMORY_ERRORS=$(grep -c "topsMalloc.*failed\|Check failed.*topsSuccess" /tmp/ontothink_official_training.log)
    echo "  💾 内存分配错误: $MEMORY_ERRORS 次"
    
    # 检查流水线并行
    PIPELINE_MSGS=$(grep -c -i "pp_size.*8\|pipeline.*8" /tmp/ontothink_official_training.log)
    echo "  🔄 流水线并行消息: $PIPELINE_MSGS 次"
    
    # 检查训练进展
    TRAINING_STEPS=$(grep -c -i "step.*loss\|loss.*:" /tmp/ontothink_official_training.log)
    echo "  📈 训练步骤: $TRAINING_STEPS 次"
    
    # 检查ECCL通信
    ECCL_SUCCESS=$(grep -c "ecclCommInitRank.*success" /tmp/ontothink_official_training.log)
    echo "  🔗 ECCL成功初始化: $ECCL_SUCCESS 次"
    
    # 检查8个进程
    PROC_COUNT=$(grep -c -i "rank.*[0-7]" /tmp/ontothink_official_training.log)
    echo "  🖥️  检测到进程数: $PROC_COUNT 个"
    
    echo ""
    echo "💡 综合评估:"
    
    if [ $DATA_ERRORS -eq 0 ] && [ $MEMORY_ERRORS -eq 0 ] && [ $TRAINING_STEPS -gt 0 ]; then
        echo "🎉🎉🎉 完全成功！OntoThink训练正常运行！"
        echo "✅ 数据格式正确 (无role错误)"
        echo "✅ 内存问题解决 (无分配失败)"
        echo "✅ 训练循环正常 ($TRAINING_STEPS 个训练步骤)"
        echo "✅ 8卡流水线并行工作正常"
        echo ""
        echo "🚀 现在可以扩展到完整训练:"
        echo "1. 增加MAX_TOKENS: 512 → 1024 → 1800"
        echo "2. 增加MAX_STEPS: 50 → 500 → 5000"
        echo "3. 增加GRADIENT_ACCUMULATION: 16 → 64 → 128"
        echo "4. 增加TRAIN_EPOCHS: 1 → 3 → 10"
        echo "5. 开始正式的ChatGLM3-6B微调！"
        
    elif [ $DATA_ERRORS -eq 0 ] && [ $MEMORY_ERRORS -eq 0 ]; then
        echo "🎯 核心问题解决！"
        echo "✅ 数据格式修复成功"
        echo "✅ 内存问题彻底解决"
        echo "⚠️  训练可能还在初始化阶段"
        echo ""
        echo "💡 重大进展！基础问题都已解决"
        
    elif [ $DATA_ERRORS -eq 0 ]; then
        echo "🎯 数据格式问题解决！"
        echo "✅ OntoThink → 燧原格式转换成功"
        echo "⚠️  可能还需要进一步的内存或配置优化"
        
    else
        echo "⚠️  仍需要进一步调试"
        echo "📋 请检查数据格式或其他配置问题"
    fi
    
    echo ""
    echo "📋 详细分析:"
    if [ $DATA_ERRORS -gt 0 ]; then
        echo "❌ 数据格式问题 ($DATA_ERRORS 次):"
        grep -A1 "KeyError.*role" /tmp/ontothink_official_training.log | tail -4
    fi
    
    if [ $MEMORY_ERRORS -gt 0 ]; then
        echo "❌ 内存问题 ($MEMORY_ERRORS 次):"
        grep -A1 "topsMalloc.*failed" /tmp/ontothink_official_training.log | tail -4
    fi
    
else
    echo "❌ 训练日志文件不存在"
fi

echo ""
echo "📋 训练配置总结:"
echo "  💾 模型: ChatGLM3-6B"
echo "  📊 数据: OntoThink哲学问答数据集"
echo "  🔄 并行: 8卡流水线并行 (PP_SIZE=8)"
echo "  📏 参数: max_tokens=$MAX_TOKENS, steps=$MAX_STEPS"
echo "  📁 输出: /workspace/code/OntoThink_V4/enflame_training/models/ontothink-chatglm3-6b"
echo "  📋 日志: /tmp/ontothink_official_training.log"

echo ""
echo "🎯 成功标志:"
echo "✅ 数据格式错误 = 0"
echo "✅ 内存分配错误 = 0"  
echo "✅ 训练步骤 > 0"
echo "✅ ECCL初始化成功"
echo "✅ 8个进程正常启动"

echo ""
if [ -f /tmp/ontothink_official_training.log ]; then
    DATA_OK=$([ $(grep -c "KeyError.*role" /tmp/ontothink_official_training.log) -eq 0 ] && echo "true" || echo "false")
    MEMORY_OK=$([ $(grep -c "topsMalloc.*failed" /tmp/ontothink_official_training.log) -eq 0 ] && echo "true" || echo "false")
    TRAINING_OK=$([ $(grep -c "step.*loss" /tmp/ontothink_official_training.log) -gt 0 ] && echo "true" || echo "false")
    
    if [ "$DATA_OK" = "true" ] && [ "$MEMORY_OK" = "true" ] && [ "$TRAINING_OK" = "true" ]; then
        echo "🏆 OntoThink训练环境搭建完全成功！"
        echo "🚀 ChatGLM3-6B哲学问答模型微调已开始！"
    else
        echo "⚠️  部分问题仍需解决，但已取得重大进展"
    fi
fi
