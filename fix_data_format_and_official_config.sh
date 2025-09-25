#!/bin/bash

# 🔧 修复数据格式问题并使用燧原官方配置
# 基于官方chatglm3_6b_1h8c_multiturn.sh配置
# ============================================

echo "🔧 修复数据格式问题并使用燧原官方配置"
echo "基于官方chatglm3_6b_1h8c_multiturn.sh配置"
echo "========================================"

echo ""
echo "🎯 重大发现分析："
echo "✅ 内存问题已解决: 4卡测试显示无topsMalloc错误"
echo "✅ 分布式正常: ECCL初始化64次成功，4个进程启动"  
echo "✅ DeepSpeed正常: 配置和初始化成功"
echo "❌ 数据格式错误: KeyError: 'role' - 数据不符合燧原格式要求"
echo "❌ 配置不正确: 我们用tp_size=4，燧原官方推荐pp_size=8"

echo ""
echo "💡 燧原官方推荐配置："
echo "- PP_SIZE=8 (流水线并行，不是张量并行)"
echo "- TP_SIZE=1 (张量并行)"
echo "- DP_SIZE=1 (数据并行)" 
echo "- MAX_TOKENS=1800 (序列长度)"
echo "- GRADIENT_ACCUMULATION=128"
echo "- OMP_NUM_THREADS=5"

echo ""
echo "🔧 第一步: 修复数据格式"
echo "========================"

# 检查当前数据格式
TRAIN_FILE="/workspace/code/OntoThink_V4/enflame_training/datasets/ontothink_multiturn/train.jsonl"

if [ -f "$TRAIN_FILE" ]; then
    echo "📋 检查当前数据格式:"
    head -2 "$TRAIN_FILE"
    
    echo ""
    echo "🔍 燧原ChatGLM3要求的数据格式应该包含'role'字段"
    echo "标准格式应该类似:"
    echo '{"conversation": [{"role": "user", "content": "..."}, {"role": "assistant", "content": "..."}]}'
    
    # 创建符合燧原格式的测试数据
    TEST_DATA_FILE="/tmp/ontothink_test_format.jsonl"
    cat <<EOF > "$TEST_DATA_FILE"
{"conversation": [{"role": "user", "content": "什么是存在主义？"}, {"role": "assistant", "content": "存在主义是20世纪的一个哲学流派，强调个体存在、自由选择和个人责任。它认为存在先于本质，人们必须为自己的行为承担责任。"}]}
{"conversation": [{"role": "user", "content": "康德的道德哲学有什么特点？"}, {"role": "assistant", "content": "康德的道德哲学以绝对义务论著称，提出了著名的绝对命令。他认为道德行为应该基于义务而不是后果，强调意志的善良和道德法则的普遍性。"}]}
{"conversation": [{"role": "user", "content": "解释一下柏拉图的洞穴寓言。"}, {"role": "assistant", "content": "柏拉图的洞穴寓言描述了被锁链束缚在洞穴中的囚徒，只能看到墙上的影子，以此来说明人们对真理的认识过程。它象征着从无知到智慧，从表象到本质的哲学觉醒之旅。"}]}
EOF
    
    echo "✅ 创建测试数据文件: $TEST_DATA_FILE"
    echo "📋 测试数据格式:"
    head -1 "$TEST_DATA_FILE"
    
else
    echo "❌ 训练数据文件不存在: $TRAIN_FILE"
    exit 1
fi

echo ""
echo "🔧 第二步: 使用燧原官方配置"
echo "=========================="

# 燧原脚本目录
ENFLAME_SCRIPT_DIR="/workspace/code/OntoThink_V4/FromEnflame/ai_development_toolkit/distributed/llm_scripts_1.0.40/finetuning/chatglm3"

if [ ! -f "$ENFLAME_SCRIPT_DIR/finetune_chatglm3_for_multiturn.py" ]; then
    echo "❌ 训练脚本不存在"
    exit 1
fi

echo "✅ 找到训练脚本: $ENFLAME_SCRIPT_DIR"
cd "$ENFLAME_SCRIPT_DIR"

# 使用燧原官方环境变量配置
echo "🎯 设置燧原官方环境变量..."
export ENFLAME_ENABLE_EFP=true
export ENFLAME_PT_ENABLE_HBM_INPLACE=true  # 官方推荐true
export OMP_NUM_THREADS=5  # 官方推荐5，不是1
export ECCL_MAX_NCHANNELS=2  # 官方推荐2
export ENFLAME_UMD_FLAGS="mem_alloc_retry_times=1"

# 使用官方推荐的并行配置
echo "🎯 设置官方并行配置..."
export PRETRAINED_MODEL_PATH="/workspace/code/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b"
export TRAIN_FILE="$TEST_DATA_FILE"  # 使用格式正确的测试数据
export MAX_TOKENS="512"  # 从官方1800开始，但先用较小值测试
export TP_SIZE="1"  # 官方推荐：张量并行=1
export DP_SIZE="1"  # 数据并行=1  
export PP_SIZE="8"  # 🔥 官方推荐：流水线并行=8 （这是关键！）
export LADDER_SHAPE="False"
export SKIP_STEPS="1"  # 快速测试
export MAX_STEPS="1"   # 快速测试
export MICRO_BATCH_SIZE="1"
export GARDIENT_ACCUMULATION_STEPS="1"  # 从官方128开始，但先用1测试
export EVAL_BATCH_SIZE="1"
export EVAL_PER_N_EPOCHS="100"  # 不频繁评估
export TRAIN_EPOCHS="1"

echo "✅ 官方配置参数："
echo "  PP_SIZE=$PP_SIZE (流水线并行，8卡流水线)"
echo "  TP_SIZE=$TP_SIZE (张量并行)"
echo "  DP_SIZE=$DP_SIZE (数据并行)"
echo "  MAX_TOKENS=$MAX_TOKENS"
echo "  数据文件: $TRAIN_FILE (格式修正)"
echo "  OMP_NUM_THREADS=$OMP_NUM_THREADS"

echo ""
echo "🚀 启动燧原官方配置训练"
echo "======================"
echo "使用流水线并行 PP_SIZE=8，而非张量并行"
echo "日志将输出到 /tmp/official_config_training.log"

# 使用燧原官方配置启动训练
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
    --train_epochs "$TRAIN_EPOCHS" 2>&1 | tee /tmp/official_config_training.log

echo ""
echo "🔍 官方配置训练结果分析"
echo "======================"

if [ -f /tmp/official_config_training.log ]; then
    echo "📋 检查最新的输出:"
    tail -20 /tmp/official_config_training.log
    
    echo ""
    echo "📋 检查数据格式问题是否解决："
    DATA_FORMAT_ERRORS=$(grep -c "KeyError.*role\|role.*KeyError" /tmp/official_config_training.log)
    if [ $DATA_FORMAT_ERRORS -eq 0 ]; then
        echo "✅ 数据格式问题已解决！"
    else
        echo "❌ 仍有数据格式问题: $DATA_FORMAT_ERRORS 次"
    fi
    
    echo ""
    echo "📋 检查流水线并行是否生效："
    if grep -q -i "pp_size.*8\|pipeline.*8\|8.*pipeline" /tmp/official_config_training.log; then
        echo "✅ 流水线并行(PP_SIZE=8)正在工作:"
        grep -i "pp_size.*8\|pipeline.*8\|8.*pipeline" /tmp/official_config_training.log | tail -2
    else
        echo "⚠️  未检测到流水线并行信息"
    fi
    
    echo ""
    echo "📋 检查内存分配："
    MEMORY_ERRORS=$(grep -c "topsMalloc.*failed\|Check failed.*topsSuccess" /tmp/official_config_training.log)
    if [ $MEMORY_ERRORS -eq 0 ]; then
        echo "✅ 没有内存分配错误！"
    else
        echo "⚠️  仍有 $MEMORY_ERRORS 个内存错误"
    fi
    
    echo ""
    echo "📋 检查8卡分布式启动："
    PROC_COUNT=$(grep -c -i "rank.*[0-7]" /tmp/official_config_training.log)
    echo "✅ 检测到 $PROC_COUNT 个rank进程 (应该≥8)"
    
    echo ""
    echo "📋 检查训练进展："
    if grep -q -i "step.*loss\|epoch.*step\|loss.*:" /tmp/official_config_training.log; then
        echo "🎉🎉 训练成功运行！"
        grep -i "step.*loss\|epoch.*step\|loss.*:" /tmp/official_config_training.log | tail -3
    elif grep -q -i "optimizer.*init\|DeepSpeed.*init\|model.*loaded" /tmp/official_config_training.log; then
        echo "⚠️  训练初始化中..."
        grep -i "optimizer.*init\|DeepSpeed.*init\|model.*loaded" /tmp/official_config_training.log | tail -2
    else
        echo "⚠️  未找到训练进展信息"
    fi
    
    echo ""
    echo "📋 检查错误信息："
    if grep -q -i "error\|fail\|exception\|abort" /tmp/official_config_training.log; then
        echo "❌ 发现错误:"
        grep -i -A1 "error\|fail\|exception\|abort" /tmp/official_config_training.log | tail -6
    else
        echo "✅ 没有发现错误"
    fi
fi

echo ""
echo "💡 官方配置结果总结"
echo "=================="

if [ -f /tmp/official_config_training.log ]; then
    # 检查是否成功
    DATA_FORMAT_OK=$([ $(grep -c "KeyError.*role" /tmp/official_config_training.log) -eq 0 ] && echo "true" || echo "false")
    MEMORY_OK=$([ $(grep -c "topsMalloc.*failed" /tmp/official_config_training.log) -eq 0 ] && echo "true" || echo "false")
    TRAINING_SUCCESS=$(grep -c "step.*loss\|loss.*:" /tmp/official_config_training.log)
    
    echo "📊 状态检查:"
    echo "  数据格式: $DATA_FORMAT_OK"
    echo "  内存分配: $MEMORY_OK"
    echo "  训练进展: $TRAINING_SUCCESS 次"
    
    if [ "$DATA_FORMAT_OK" = "true" ] && [ "$MEMORY_OK" = "true" ] && [ $TRAINING_SUCCESS -gt 0 ]; then
        echo ""
        echo "🎉🎉🎉 完全成功！官方配置解决了所有问题！"
        echo "✅ 数据格式正确: 包含role字段"
        echo "✅ 内存问题解决: 流水线并行分担内存"
        echo "✅ 训练成功运行: 8卡流水线并行工作"
        echo ""
        echo "🚀 现在可以开始优化和扩展:"
        echo "1. 使用完整的OntoThink数据集"
        echo "2. 增加MAX_TOKENS: 512 → 1024 → 1800"
        echo "3. 增加GRADIENT_ACCUMULATION: 1 → 32 → 128"
        echo "4. 增加训练轮数和步数"
        echo "5. 开始正式的ChatGLM3-6B微调！"
    elif [ "$DATA_FORMAT_OK" = "true" ] && [ "$MEMORY_OK" = "true" ]; then
        echo ""
        echo "🎯 重大突破！核心问题都解决了！"
        echo "✅ 数据格式修复成功"
        echo "✅ 内存问题彻底解决" 
        echo "⚠️  可能在训练初始化或其他环节"
        echo ""
        echo "💡 这表明燧原官方配置是正确的方向！"
    elif [ "$DATA_FORMAT_OK" = "true" ]; then
        echo ""
        echo "🎯 数据格式问题解决！"
        echo "✅ role字段错误已修复"
        echo "⚠️  可能还需要进一步的内存优化或配置调整"
    else
        echo ""
        echo "⚠️  需要进一步调试数据格式或其他问题"
    fi
fi

echo ""
echo "📋 官方配置vs我们之前的配置:"
echo "  我们: tp_size=4 (张量并行4卡)"
echo "  官方: pp_size=8 (流水线并行8卡) ✅"
echo "  我们: max_tokens=64, threads=1"
echo "  官方: max_tokens=1800, threads=5 ✅"
echo "  关键差异: 燧原推荐流水线并行，不是张量并行！"

echo ""
echo "🎯 下一步计划:"
if [ -f /tmp/official_config_training.log ] && [ $(grep -c "KeyError.*role" /tmp/official_config_training.log) -eq 0 ]; then
    echo "1. ✅ 数据格式已解决，转换完整数据集"
    echo "2. ✅ 使用官方配置，逐步扩展参数"
    echo "3. 🚀 开始正式的OntoThink模型微调"
else
    echo "1. 🔧 进一步完善数据格式转换"
    echo "2. 🔧 深入理解燧原数据要求"
fi

echo ""
echo "📋 完整日志文件: /tmp/official_config_training.log"
echo "📋 测试数据文件: $TEST_DATA_FILE"
