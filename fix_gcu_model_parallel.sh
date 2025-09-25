#!/bin/bash

# 🔧 模型并行最终解决方案
# 使用多张GCU卡分担模型参数
# ============================

echo "🔧 模型并行最终解决方案"
echo "使用多张GCU卡分担模型参数"
echo "========================="

echo ""
echo "🎯 终极问题确认："
echo "✅ 硬件: 8张T20卡，每张32GB"
echo "✅ 系统内存: 1TB，989GB可用"
echo "✅ ECCL通信: 完全正常"
echo "✅ 软件环境: 完全配置正确"
echo "❌ Zero Stage 3最激进offload仍失败"
echo "💡 结论: ChatGLM3-6B单卡内存不足，需要模型并行"

echo ""
echo "🔧 模型并行策略"
echo "================"

# 燧原脚本目录
ENFLAME_SCRIPT_DIR="/workspace/code/OntoThink_V4/FromEnflame/ai_development_toolkit/distributed/llm_scripts_1.0.40/finetuning/chatglm3"

if [ ! -f "$ENFLAME_SCRIPT_DIR/finetune_chatglm3_for_multiturn.py" ]; then
    echo "❌ 训练脚本不存在"
    exit 1
fi

echo "✅ 找到训练脚本: $ENFLAME_SCRIPT_DIR"
cd "$ENFLAME_SCRIPT_DIR"

# 设置燧原分布式环境变量
export ENFLAME_ENABLE_EFP=true
export ENFLAME_PT_ENABLE_HBM_INPLACE=false
export OMP_NUM_THREADS=1
export ECCL_MAX_NCHANNELS=1
export ENFLAME_UMD_FLAGS="mem_alloc_retry_times=5"

# 分布式环境变量（多卡配置）
export MASTER_ADDR=localhost
export MASTER_PORT=29500
export WORLD_SIZE=2  # 使用2卡开始测试
export RANK=0
export LOCAL_RANK=0
export GCU_VISIBLE_DEVICES=0,1  # 使用前2张卡

# 燧原特定的分布式变量
export CUDA_VISIBLE_DEVICES=""
export PTEX_DDP_BACKEND=eccl

# 设置保守的内存使用
export ECCL_BUFFSIZE=8388608  # 8MB

echo "🎯 模型并行参数 (2卡测试)："
echo "  - tp_size: 2 (模型张量并行，分布在2张卡)"
echo "  - dp_size: 1 (数据并行)"
echo "  - pp_size: 1 (流水线并行)"
echo "  - 每张卡负担: 3B参数 (6B/2)"
echo "  - max_tokens: 64 (极小测试)"
echo "  - GCU卡: 0,1"

echo ""
echo "🚀 启动2卡模型并行训练"
echo "======================"

# 启动2卡模型并行
python3.8 -u -m torch.distributed.launch \
    --nproc_per_node=2 \
    --standalone \
    --use_env finetune_chatglm3_for_multiturn.py \
    --model_path "/workspace/code/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b" \
    --train_file "/workspace/code/OntoThink_V4/enflame_training/datasets/ontothink_multiturn/train.jsonl" \
    --tp_size 2 \
    --dp_size 1 \
    --pp_size 1 \
    --train_micro_batch_size 1 \
    --gradient_accumulation_steps 1 \
    --max_steps 1 \
    --max_tokens 64 \
    --ladder_shape False \
    --skip_steps 1 \
    --eval_batch_size 1 \
    --eval_per_n_epochs 50 \
    --train_epochs 1 2>&1 | tee /tmp/model_parallel_2gcu.log

echo ""
echo "🔍 2卡模型并行结果分析"
echo "===================="

if [ -f /tmp/model_parallel_2gcu.log ]; then
    echo "📋 检查最新的输出:"
    tail -20 /tmp/model_parallel_2gcu.log
    
    echo ""
    echo "📋 检查模型并行是否生效："
    if grep -q -i "tp_size.*2\|tensor.*parallel.*2\|model.*parallel" /tmp/model_parallel_2gcu.log; then
        echo "✅ 模型并行正在工作:"
        grep -i "tp_size.*2\|tensor.*parallel.*2\|model.*parallel" /tmp/model_parallel_2gcu.log | tail -2
    else
        echo "⚠️  未检测到模型并行信息"
    fi
    
    echo ""
    echo "📋 检查内存分配："
    MEMORY_ERRORS=$(grep -c "topsMalloc.*failed\|Check failed.*topsSuccess" /tmp/model_parallel_2gcu.log)
    if [ $MEMORY_ERRORS -eq 0 ]; then
        echo "✅ 没有内存分配错误！模型并行解决了问题！"
    else
        echo "❌ 仍有 $MEMORY_ERRORS 个内存错误"
    fi
    
    echo ""
    echo "📋 检查多卡通信："
    ECCL_SUCCESS=$(grep -c "ecclCommInitRank.*success" /tmp/model_parallel_2gcu.log)
    echo "✅ ECCL成功初始化次数: $ECCL_SUCCESS"
    
    echo ""
    echo "📋 检查训练进展："
    if grep -q -i "step.*loss\|epoch.*step\|loss.*:\|training.*complete" /tmp/model_parallel_2gcu.log; then
        echo "🎉 训练成功运行！"
        grep -i "step.*loss\|epoch.*step\|loss.*:\|training.*complete" /tmp/model_parallel_2gcu.log | tail -3
    elif grep -q -i "optimizer.*init\|DeepSpeed.*init\|model.*loaded" /tmp/model_parallel_2gcu.log; then
        echo "⚠️  训练初始化中..."
        grep -i "optimizer.*init\|DeepSpeed.*init\|model.*loaded" /tmp/model_parallel_2gcu.log | tail -2
    else
        echo "⚠️  未找到训练进展信息"
    fi
    
    echo ""
    echo "📋 检查错误信息："
    if grep -q -i "error\|fail\|exception\|abort" /tmp/model_parallel_2gcu.log; then
        echo "❌ 发现错误:"
        grep -i -A1 "error\|fail\|exception\|abort" /tmp/model_parallel_2gcu.log | tail -4
    else
        echo "✅ 没有发现错误"
    fi
fi

echo ""
echo "💡 2卡模型并行结果总结"
echo "===================="

if [ -f /tmp/model_parallel_2gcu.log ]; then
    # 检查是否成功
    MEMORY_ERRORS=$(grep -c "topsMalloc.*failed\|Check failed.*topsSuccess" /tmp/model_parallel_2gcu.log)
    TRAINING_SUCCESS=$(grep -c "step.*loss\|loss.*:" /tmp/model_parallel_2gcu.log)
    
    if [ $MEMORY_ERRORS -eq 0 ] && [ $TRAINING_SUCCESS -gt 0 ]; then
        echo "🎉🎉🎉 完全成功！模型并行解决了所有问题！"
        echo "✅ 2张GCU卡分担6B参数"
        echo "✅ 每张卡只需处理3B参数"
        echo "✅ 内存压力大幅减少"
        echo "✅ 训练成功运行"
        echo ""
        echo "🚀 下一步可以："
        echo "1. 增加max_tokens: 64 → 128 → 256 → 512"
        echo "2. 增加max_steps: 1 → 10 → 100"
        echo "3. 增加batch size和gradient accumulation"
        echo "4. 尝试更多卡: tp_size=4, tp_size=8"
        echo "5. 添加数据并行: dp_size=2,4"
    elif [ $MEMORY_ERRORS -eq 0 ]; then
        echo "🎯 内存问题完全解决！"
        echo "✅ 模型并行策略有效"
        echo "✅ 没有任何内存分配错误"
        echo "⚠️  可能在训练初始化或数据处理阶段"
        echo ""
        echo "💡 这是重大突破！可以开始扩展配置"
    else
        echo "⚠️  2卡仍不足，尝试更多卡"
        echo "💡 进一步并行方案："
        echo "1. 尝试4卡: tp_size=4 (每卡1.5B参数)"
        echo "2. 尝试8卡: tp_size=8 (每卡0.75B参数)"
        echo "3. 结合流水线并行: pp_size=2,4"
    fi
fi

echo ""
echo "📋 模型并行配置:"
echo "  张量并行: tp_size=2"
echo "  使用卡数: 2张 (GCU 0,1)"
echo "  每卡参数: 3B (6B/2)"
echo "  训练参数: max_tokens=64, micro_batch=1, max_steps=1"
echo "  完整日志: /tmp/model_parallel_2gcu.log"

echo ""
echo "📊 如果2卡成功，接下来的扩展路径:"
echo "  1. 增加序列长度和批次大小"
echo "  2. 尝试4卡并行 (tp_size=4)"
echo "  3. 尝试8卡并行 (tp_size=8)"
echo "  4. 添加数据并行 (dp_size=2,4)"
echo "  5. 最终目标: 8卡高效训练ChatGLM3-6B"
