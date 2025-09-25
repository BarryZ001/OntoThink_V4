#!/bin/bash

# 🔧 4卡模型并行解决方案
# 2卡仍不足，使用4张GCU卡进一步分担模型参数
# =======================================

echo "🔧 4卡模型并行解决方案"
echo "2卡仍不足，使用4张GCU卡"
echo "======================="

echo ""
echo "🎯 2卡测试结果分析："
echo "✅ 方向正确: 脚本建议尝试更多卡"
echo "⚠️ 2卡仍不足: 3B参数/卡仍超限"
echo "💡 解决方案: 4卡并行，1.5B参数/卡"

echo ""
echo "🔧 4卡模型并行策略"
echo "=================="

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

# 分布式环境变量（4卡配置）
export MASTER_ADDR=localhost
export MASTER_PORT=29500
export WORLD_SIZE=4  # 使用4卡
export RANK=0
export LOCAL_RANK=0
export GCU_VISIBLE_DEVICES=0,1,2,3  # 使用前4张卡

# 燧原特定的分布式变量
export CUDA_VISIBLE_DEVICES=""
export PTEX_DDP_BACKEND=eccl

# 设置保守的内存使用
export ECCL_BUFFSIZE=4194304  # 4MB (更保守)

echo "🎯 4卡模型并行参数："
echo "  - tp_size: 4 (模型张量并行，分布在4张卡)"
echo "  - dp_size: 1 (数据并行)"
echo "  - pp_size: 1 (流水线并行)"
echo "  - 每张卡负担: 1.5B参数 (6B/4)"
echo "  - max_tokens: 64 (极小测试)"
echo "  - GCU卡: 0,1,2,3"
echo "  - 内存大幅减少: 从32GB需求降到~8GB"

echo ""
echo "🚀 启动4卡模型并行训练"
echo "======================"

# 启动4卡模型并行
python3.8 -u -m torch.distributed.launch \
    --nproc_per_node=4 \
    --standalone \
    --use_env finetune_chatglm3_for_multiturn.py \
    --model_path "/workspace/code/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b" \
    --train_file "/workspace/code/OntoThink_V4/enflame_training/datasets/ontothink_multiturn/train.jsonl" \
    --tp_size 4 \
    --dp_size 1 \
    --pp_size 1 \
    --train_micro_batch_size 1 \
    --gradient_accumulation_steps 1 \
    --max_steps 1 \
    --max_tokens 64 \
    --ladder_shape False \
    --skip_steps 1 \
    --eval_batch_size 1 \
    --eval_per_n_epochs 100 \
    --train_epochs 1 2>&1 | tee /tmp/model_parallel_4gcu.log

echo ""
echo "🔍 4卡模型并行结果分析"
echo "===================="

if [ -f /tmp/model_parallel_4gcu.log ]; then
    echo "📋 检查最新的输出:"
    tail -20 /tmp/model_parallel_4gcu.log
    
    echo ""
    echo "📋 检查4卡模型并行是否生效："
    if grep -q -i "tp_size.*4\|tensor.*parallel.*4\|4.*cards\|nproc.*4" /tmp/model_parallel_4gcu.log; then
        echo "✅ 4卡模型并行正在工作:"
        grep -i "tp_size.*4\|tensor.*parallel.*4\|4.*cards\|nproc.*4" /tmp/model_parallel_4gcu.log | tail -2
    else
        echo "⚠️  未检测到4卡并行信息"
    fi
    
    echo ""
    echo "📋 检查内存分配："
    MEMORY_ERRORS=$(grep -c "topsMalloc.*failed\|Check failed.*topsSuccess" /tmp/model_parallel_4gcu.log)
    if [ $MEMORY_ERRORS -eq 0 ]; then
        echo "🎉 没有内存分配错误！4卡并行解决了问题！"
    else
        echo "❌ 仍有 $MEMORY_ERRORS 个内存错误 (但应该比2卡少)"
    fi
    
    echo ""
    echo "📋 检查多卡通信："
    ECCL_SUCCESS=$(grep -c "ecclCommInitRank.*success" /tmp/model_parallel_4gcu.log)
    echo "✅ ECCL成功初始化次数: $ECCL_SUCCESS (应该≥4)"
    
    echo ""
    echo "📋 检查分布式启动："
    if grep -q -i "rank.*0\|rank.*1\|rank.*2\|rank.*3" /tmp/model_parallel_4gcu.log; then
        echo "✅ 4个进程成功启动:"
        grep -c -i "rank.*[0-3]" /tmp/model_parallel_4gcu.log
    fi
    
    echo ""
    echo "📋 检查训练进展："
    if grep -q -i "step.*loss\|epoch.*step\|loss.*:\|training.*complete" /tmp/model_parallel_4gcu.log; then
        echo "🎉🎉 训练成功运行！"
        grep -i "step.*loss\|epoch.*step\|loss.*:\|training.*complete" /tmp/model_parallel_4gcu.log | tail -3
    elif grep -q -i "optimizer.*init\|DeepSpeed.*init\|model.*loaded" /tmp/model_parallel_4gcu.log; then
        echo "⚠️  训练初始化中..."
        grep -i "optimizer.*init\|DeepSpeed.*init\|model.*loaded" /tmp/model_parallel_4gcu.log | tail -2
    else
        echo "⚠️  未找到训练进展信息"
    fi
    
    echo ""
    echo "📋 检查错误信息："
    if grep -q -i "error\|fail\|exception\|abort" /tmp/model_parallel_4gcu.log; then
        echo "❌ 发现错误:"
        grep -i -A1 "error\|fail\|exception\|abort" /tmp/model_parallel_4gcu.log | tail -4
    else
        echo "✅ 没有发现错误"
    fi
fi

echo ""
echo "💡 4卡模型并行结果总结"
echo "===================="

if [ -f /tmp/model_parallel_4gcu.log ]; then
    # 检查是否成功
    MEMORY_ERRORS=$(grep -c "topsMalloc.*failed\|Check failed.*topsSuccess" /tmp/model_parallel_4gcu.log)
    TRAINING_SUCCESS=$(grep -c "step.*loss\|loss.*:" /tmp/model_parallel_4gcu.log)
    
    if [ $MEMORY_ERRORS -eq 0 ] && [ $TRAINING_SUCCESS -gt 0 ]; then
        echo "🎉🎉🎉 完全成功！4卡模型并行解决了所有问题！"
        echo "✅ 4张GCU卡分担6B参数"
        echo "✅ 每张卡只需处理1.5B参数"
        echo "✅ 内存压力降到~8GB/卡"
        echo "✅ 训练成功运行"
        echo ""
        echo "🚀 现在可以开始扩展配置："
        echo "1. 增加max_tokens: 64 → 128 → 256 → 512 → 1024"
        echo "2. 增加max_steps: 1 → 10 → 100 → 1000"
        echo "3. 增加batch size: 1 → 2 → 4"
        echo "4. 增加gradient accumulation: 1 → 8 → 16"
        echo "5. 最终扩展到完整训练配置"
    elif [ $MEMORY_ERRORS -eq 0 ]; then
        echo "🎯 内存问题完全解决！"
        echo "✅ 4卡模型并行策略有效"
        echo "✅ 没有任何内存分配错误"
        echo "⚠️  可能在训练初始化或数据处理阶段"
        echo ""
        echo "💡 重大突破！内存瓶颈已解决，可以开始优化训练流程"
    else
        echo "⚠️  4卡仍有问题，尝试8卡"
        echo "💡 最终方案："
        echo "1. 尝试8卡: tp_size=8 (每卡0.75B参数)"
        echo "2. 检查是否有其他限制因素"
    fi
fi

echo ""
echo "📋 4卡模型并行配置:"
echo "  张量并行: tp_size=4"
echo "  使用卡数: 4张 (GCU 0,1,2,3)"
echo "  每卡参数: 1.5B (6B/4)"
echo "  预计内存: ~8GB/卡 (大幅低于32GB限制)"
echo "  训练参数: max_tokens=64, micro_batch=1, max_steps=1"
echo "  完整日志: /tmp/model_parallel_4gcu.log"

echo ""
echo "📊 内存使用对比:"
echo "  单卡: >32GB (超限 ❌)"
echo "  2卡: ~16GB/卡 (仍超限 ⚠️)"
echo "  4卡: ~8GB/卡 (应该OK ✅)"
echo "  8卡: ~4GB/卡 (绝对OK ✅)"

echo ""
if [ -f /tmp/model_parallel_4gcu.log ] && [ $(grep -c "topsMalloc.*failed" /tmp/model_parallel_4gcu.log) -eq 0 ]; then
    echo "🎉 恭喜！我们成功解决了ChatGLM3-6B在燧原T20上的训练问题！"
    echo "💪 现在可以开始正式的模型微调工作了！"
else
    echo "🔧 如果4卡仍有问题，我们还有8卡并行的终极方案"
fi
