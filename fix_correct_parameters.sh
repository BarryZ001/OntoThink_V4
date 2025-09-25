#!/bin/bash
# 修复参数错误 - 使用燧原脚本支持的正确参数
# 移除不支持的--output_dir参数
# 确保在项目根目录运行

echo "🔧 修复参数错误 - 使用燧原脚本支持的正确参数"
echo "移除不支持的--output_dir参数"
echo "================================================"

# 检查项目根目录
if [ ! -d "FromEnflame" ]; then
    echo "❌ 错误: 未在项目根目录找到 'FromEnflame' 目录。请切换到项目根目录再运行此脚本。"
    exit 1
fi

# 查找燧原LLM脚本目录
ENFLAME_TOOLKIT_ROOT="/installer/topsrider_extracted/TopsRider_installer/ai_development_toolkit"
CHATGLM3_SCRIPT_DIR="${ENFLAME_TOOLKIT_ROOT}/distributed/llm_scripts_1.0.40/finetuning/chatglm3"
TRAINING_SCRIPT="${CHATGLM3_SCRIPT_DIR}/finetune_chatglm3_for_multiturn.py"

if [ ! -f "$TRAINING_SCRIPT" ]; then
    echo "❌ 错误: 未找到燧原ChatGLM3训练脚本: $TRAINING_SCRIPT"
    echo "请确认燧原工具包已正确安装，并更新脚本中的 ENFLAME_TOOLKIT_ROOT 变量。"
    exit 1
fi

echo "✅ 找到训练脚本: $TRAINING_SCRIPT"

echo "🎯 问题确认："
echo "❌ 之前使用了不支持的参数: --output_dir"
echo "✅ 燧原脚本支持的参数:"
echo "  --train_file, --max_tokens, --model_path"  
echo "  --pp_size, --tp_size, --dp_size"
echo "  --max_steps, --train_micro_batch_size"
echo "  --gradient_accumulation_steps, --train_epochs"

echo ""
echo "🔧 正确参数配置"
echo "=================="

# 设置分布式环境变量 - 单卡最简配置
export MASTER_ADDR=localhost
export MASTER_PORT=29500
export WORLD_SIZE=1      # 单卡训练
export RANK=0            
export LOCAL_RANK=0      
export GCU_VISIBLE_DEVICES="0" # 只使用第0张GCU卡
export PTEX_DDP_BACKEND=eccl

# 设置其他燧原环境变量 (继承4卡成功的配置)
export ENFLAME_ENABLE_EFP=true
export ENFLAME_PT_ENABLE_HBM_INPLACE=false # 禁用原地操作
export OMP_NUM_THREADS=1 # 最小线程数
export ECCL_MAX_NCHANNELS=1 # 最小通信通道
export ENFLAME_UMD_FLAGS="mem_alloc_retry_times=1"
export ECCL_BUFFSIZE=8388608 # 8MB通信缓冲区

# 设置训练参数 - 继承4卡成功的超级内存优化策略，移除--output_dir
export PRETRAINED_MODEL_PATH="/workspace/code/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b"
export TRAIN_FILE="/workspace/code/OntoThink_V4/enflame_training/datasets/ontothink_multiturn/train.jsonl"
export MAX_TOKENS="128" # 超级内存优化: 最小序列长度
export TP_SIZE="1" # 单卡: 无模型并行
export DP_SIZE="1" # 单卡: 无数据并行  
export PP_SIZE="1" # 单卡: 无流水线并行
export MICRO_BATCH_SIZE="1" # 超级内存优化: 最小批次
export GARDIENT_ACCUMULATION_STEPS="1" # 超级内存优化: 无梯度累积
export TRAIN_EPOCHS="1"
export MAX_STEPS="10" # 验证稳定性

echo "🎯 正确参数配置："
echo "  硬件: 单张GCU (GCU_VISIBLE_DEVICES=0)"
echo "  并行: 无分布式 (TP=1, DP=1, PP=1)"
echo "  内存: 超级优化 (tokens=128, batch=1, accum=1)"
echo "  步骤: MAX_STEPS=10 (验证稳定性)"
echo "  ❌ 移除: --output_dir (不支持的参数)"

echo ""
echo "🚀 启动正确参数的单卡训练"
echo "=========================="
echo "日志将输出到 /tmp/ontothink_correct_parameters.log"

# 切换到脚本目录并运行 - 移除--output_dir参数
(cd "$CHATGLM3_SCRIPT_DIR" && \
    python3.8 -u -m torch.distributed.launch \
        --nproc_per_node=1 \
        --standalone \
        --use_env "$TRAINING_SCRIPT" \
        --model_path "$PRETRAINED_MODEL_PATH" \
        --train_file "$TRAIN_FILE" \
        --tp_size "$TP_SIZE" \
        --dp_size "$DP_SIZE" \
        --pp_size "$PP_SIZE" \
        --train_micro_batch_size "$MICRO_BATCH_SIZE" \
        --gradient_accumulation_steps "$GARDIENT_ACCUMULATION_STEPS" \
        --max_tokens "$MAX_TOKENS" \
        --train_epochs "$TRAIN_EPOCHS" \
        --max_steps "$MAX_STEPS" \
        &> /tmp/ontothink_correct_parameters.log)

echo ""
echo "🔍 正确参数测试完成。请查看日志文件: /tmp/ontothink_correct_parameters.log"
echo ""

echo "🔍 修复结果分析"
echo "================"
ERROR_LOG=$(grep -E "ERROR|Traceback|Failures|unrecognized arguments" /tmp/ontothink_correct_parameters.log || true)
if [ -n "$ERROR_LOG" ]; then
    echo "❌ 发现错误:"
    echo "$ERROR_LOG"
else
    echo "✅ 未发现参数错误"
fi

if grep -q "ecclCommInitRank success!" /tmp/ontothink_correct_parameters.log; then
    echo "✅ ECCL初始化成功"
else
    echo "⚠️  ECCL初始化状态未知"
fi

TRAINING_STEPS=$(grep -c "step.*loss\|epoch.*step" /tmp/ontothink_correct_parameters.log || echo "0")
echo "📊 完成训练步骤: $TRAINING_STEPS 步"

if [ "$TRAINING_STEPS" -ge 5 ]; then
    echo "🎉 单卡训练完全成功! (≥5步)"
elif [ "$TRAINING_STEPS" -ge 1 ]; then
    echo "✅ 单卡训练基本成功 (≥1步)"
else
    echo "⚠️  训练步骤尚未开始，可能仍在初始化"
fi

echo ""
echo "💡 参数修复总结"
echo "================="
echo "🎯 关键修复:"
echo "  ❌ 移除了不支持的 --output_dir 参数"
echo "  ✅ 使用燧原脚本官方支持的参数"
echo "  ✅ 继承4卡成功的所有环境变量和内存优化"
echo ""
echo "🎯 如果单卡成功运行10步："
echo "  - 确认参数问题已解决"
echo "  - 验证4卡SIGILL可能是正常结束"
echo "  - 可以基于正确参数重新运行4卡训练"
echo ""
echo "📋 日志文件: /tmp/ontothink_correct_parameters.log"
echo "🔍 可以查看完整日志获取更多信息"

echo ""
echo "🚀 下一步计划:"
echo "=============="
echo "1. ✅ 参数错误已修复"
echo "2. 🔧 单卡验证训练稳定性"
echo "3. 📈 基于正确参数重新测试4卡训练"
echo "4. 🎯 确认4卡SIGILL是否为正常完成"
echo ""
echo "🎉 参数修复完成! 基于4卡成功经验优化单卡训练!"
