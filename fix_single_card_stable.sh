#!/bin/bash
# 修复SIGILL问题 - 创建最稳定的单卡训练方案
# 基于4卡成功经验，简化为单卡避免分布式复杂性
# 确保在项目根目录运行

echo "🔧 修复SIGILL问题 - 最稳定的单卡训练方案"
echo "基于4卡成功经验，简化避免分布式复杂性"
echo "=============================================="

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

echo "🎯 问题分析："
echo "✅ 4卡训练内存优化完全成功"
echo "✅ 训练循环正常运行2个步骤" 
echo "✅ 模型编译和ECCL初始化完美"
echo "❌ Signal 4 (SIGILL) 终止 - 可能是分布式复杂性或指令集问题"
echo "💡 解决方案: 简化为单卡训练，保持所有成功的内存优化策略"

echo ""
echo "🔧 最稳定单卡策略"
echo "=================="

# 设置分布式环境变量 - 单卡最简配置
export MASTER_ADDR=localhost
export MASTER_PORT=29500
export WORLD_SIZE=1      # 单卡训练
export RANK=0            
export LOCAL_RANK=0      
export GCU_VISIBLE_DEVICES="0" # 只使用第0张GCU卡
export PTEX_DDP_BACKEND=eccl

# 设置其他燧原环境变量 (保持4卡成功的配置)
export ENFLAME_ENABLE_EFP=true
export ENFLAME_PT_ENABLE_HBM_INPLACE=false # 禁用原地操作
export OMP_NUM_THREADS=1 # 最小线程数
export ECCL_MAX_NCHANNELS=1 # 最小通信通道
export ENFLAME_UMD_FLAGS="mem_alloc_retry_times=1"
export ECCL_BUFFSIZE=8388608 # 8MB通信缓冲区

# 设置训练参数 - 继承4卡成功的超级内存优化策略
export PRETRAINED_MODEL_PATH="/workspace/code/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b"
export TRAIN_FILE="/workspace/code/OntoThink_V4/enflame_training/datasets/ontothink_multiturn/train.jsonl"
export MAX_TOKENS="128" # 超级内存优化: 最小序列长度
export TP_SIZE="1" # 单卡: 无模型并行
export DP_SIZE="1" # 单卡: 无数据并行  
export PP_SIZE="1" # 单卡: 无流水线并行
export MICRO_BATCH_SIZE="1" # 超级内存优化: 最小批次
export GARDIENT_ACCUMULATION_STEPS="1" # 超级内存优化: 无梯度累积
export TRAIN_EPOCHS="1"
export MAX_STEPS="10" # 增加到10步验证稳定性

echo "🎯 最稳定单卡配置："
echo "  硬件: 单张GCU (GCU_VISIBLE_DEVICES=0)"
echo "  并行: 无分布式 (TP=1, DP=1, PP=1)"
echo "  内存: 超级优化 (tokens=128, batch=1, accum=1)"
echo "  步骤: MAX_STEPS=10 (验证稳定性)"
echo "  环境: 继承4卡成功的所有环境变量"

echo ""
echo "🚀 启动最稳定单卡训练"
echo "======================"
echo "日志将输出到 /tmp/ontothink_single_card_stable.log"

# 切换到脚本目录并运行
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
        --output_dir "/workspace/code/OntoThink_V4/enflame_training/models/ontothink-chatglm3-6b" \
        &> /tmp/ontothink_single_card_stable.log)

echo ""
echo "🔍 单卡稳定性测试完成。请查看日志文件: /tmp/ontothink_single_card_stable.log"
echo ""

echo "🔍 修复结果分析"
echo "================"
ERROR_LOG=$(grep -E "ERROR|Traceback|Failures|SIGILL|Signal" /tmp/ontothink_single_card_stable.log || true)
if [ -n "$ERROR_LOG" ]; then
    echo "❌ 发现错误或信号:"
    echo "$ERROR_LOG"
else
    echo "✅ 未发现错误或异常信号"
fi

if grep -q "ecclCommInitRank success!" /tmp/ontothink_single_card_stable.log; then
    echo "✅ ECCL初始化成功"
else
    echo "❌ ECCL初始化失败"
fi

TRAINING_STEPS=$(grep -c "step.*loss\|epoch.*step" /tmp/ontothink_single_card_stable.log || echo "0")
echo "📊 完成训练步骤: $TRAINING_STEPS 步"

if [ "$TRAINING_STEPS" -ge 5 ]; then
    echo "🎉 单卡训练完全稳定! (≥5步)"
elif [ "$TRAINING_STEPS" -ge 1 ]; then
    echo "✅ 单卡训练基本稳定 (≥1步)"
else
    echo "❌ 单卡训练未开始"
fi

echo ""
echo "💡 单卡稳定性总结"
echo "================="
echo "🎯 如果单卡成功运行10步："
echo "  - 确认SIGILL问题来自分布式复杂性"
echo "  - 可以基于单卡逐步扩展"
echo "  - 单卡→2卡→4卡渐进式优化"
echo "🎯 如果单卡也出现SIGILL："
echo "  - 可能是GCU驱动或指令集问题"
echo "  - 需要检查燧原环境和模型兼容性"
echo "📋 日志文件: /tmp/ontothink_single_card_stable.log"
echo "🔍 可以查看完整日志获取更多信息"

echo ""
echo "🚀 基于4卡突破的后续计划:"
echo "========================="
echo "1. ✅ 内存优化策略已完全验证 (4卡成功)"
echo "2. 🔧 单卡消除分布式复杂性"
echo "3. 📈 逐步扩展: 1卡→2卡→4卡"
echo "4. 🎯 最终目标: 稳定的多卡OntoThink训练"
echo ""
echo "🎉 4卡内存突破是重大成功! 现在优化稳定性!"
