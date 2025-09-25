#!/bin/bash

# 🔍 调试训练失败详细信息
# 获取具体的错误原因
# ========================

echo "🔍 调试训练失败详细信息"
echo "获取rank 7进程失败的具体原因"
echo "=========================="

echo ""
echo "🎉 首先确认已取得的成功："
echo "✅ ECCL通信初始化成功"
echo "✅ 8个GCU进程全部启动"
echo "✅ 燧原分布式框架正常"
echo "✅ 进入了实际训练阶段"

echo ""
echo "🔍 1. 检查系统资源状态"
echo "========================"

echo "💾 内存使用情况："
free -h

echo ""
echo "🔥 GCU设备状态："
ls -la /dev/gcu* 2>/dev/null || echo "GCU设备检查失败"

echo ""
echo "📊 进程状态检查："
ps aux | grep python | head -10

echo ""
echo "🔍 2. 启用详细错误追踪的训练"
echo "=========================="

# 设置环境变量获取更详细的错误信息
export TORCH_DISTRIBUTED_DEBUG=DETAIL
export TORCH_SHOW_CPP_STACKTRACES=1
export NCCL_DEBUG=INFO  # 虽然用的是ECCL，但可能有帮助

echo "🚀 启动带详细错误信息的训练..."

# 创建一个简化的训练配置来测试
cat > /tmp/debug_training.sh << 'EOF'
#!/bin/bash

# 燧原T20环境变量
export ENFLAME_ENABLE_EFP=true
export ENFLAME_PT_ENABLE_HBM_INPLACE=true
export OMP_NUM_THREADS=5
export ECCL_MAX_NCHANNELS=2
export ENFLAME_UMD_FLAGS="mem_alloc_retry_times=1"
export GCU_VISIBLE_DEVICES=0,1,2,3,4,5,6,7

# 详细错误信息
export TORCH_DISTRIBUTED_DEBUG=DETAIL
export TORCH_SHOW_CPP_STACKTRACES=1

# 项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# 燧原脚本目录
ENFLAME_SCRIPT_DIR="/workspace/code/OntoThink_V4/FromEnflame/ai_development_toolkit/distributed/llm_scripts_1.0.40/finetuning/chatglm3"

# 检查脚本是否存在
if [ ! -f "$ENFLAME_SCRIPT_DIR/finetune_chatglm3_for_multiturn.py" ]; then
    echo "❌ 训练脚本不存在: $ENFLAME_SCRIPT_DIR/finetune_chatglm3_for_multiturn.py"
    exit 1
fi

echo "🚀 启动调试训练..."
cd "$ENFLAME_SCRIPT_DIR"

# 使用更小的批次大小来减少内存压力
python3.8 -u -m torch.distributed.launch \
    --nproc_per_node=8 \
    --standalone \
    --use_env finetune_chatglm3_for_multiturn.py \
    --model_path "/workspace/code/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b" \
    --train_file "/workspace/code/OntoThink_V4/enflame_training/datasets/ontothink_multiturn/train.jsonl" \
    --tp_size 1 \
    --dp_size 1 \
    --pp_size 8 \
    --train_micro_batch_size 1 \
    --gradient_accumulation_steps 32 \
    --max_steps 10 \
    --max_tokens 1024 \
    --ladder_shape False \
    --skip_steps 1 \
    --eval_batch_size 1 \
    --eval_per_n_epochs 1 \
    --train_epochs 1 2>&1 | tee /tmp/debug_training.log

echo "训练日志保存到: /tmp/debug_training.log"
EOF

chmod +x /tmp/debug_training.sh
bash /tmp/debug_training.sh

echo ""
echo "🔍 3. 分析错误日志"
echo "=================="

echo "📋 查找关键错误信息..."
if [ -f /tmp/debug_training.log ]; then
    echo "🔍 搜索具体错误原因:"
    grep -i -A5 -B5 "error\|fail\|exception\|traceback" /tmp/debug_training.log | tail -20
    
    echo ""
    echo "🔍 搜索内存相关问题:"
    grep -i -A3 -B3 "memory\|oom\|allocation" /tmp/debug_training.log | tail -10
    
    echo ""
    echo "🔍 搜索GCU相关问题:"
    grep -i -A3 -B3 "gcu\|device\|cuda" /tmp/debug_training.log | tail -10
else
    echo "❌ 训练日志文件不存在"
fi

echo ""
echo "🔍 4. 建议的解决方案"
echo "==================="

echo "💡 基于问题可能的原因："
echo "1. 📦 内存不足解决方案："
echo "   - 减少批次大小 (micro_batch_size=1)"
echo "   - 减少序列长度 (max_tokens=1024)"
echo "   - 减少梯度累积步数"
echo ""
echo "2. 🔧 通信问题解决方案："
echo "   - 调整ECCL参数"
echo "   - 减少并行度"
echo "   - 检查网络配置"
echo ""
echo "3. 🚀 模型加载问题解决方案："
echo "   - 检查模型文件完整性"
echo "   - 验证模型路径"
echo "   - 测试单进程加载"

echo ""
echo "🎯 下一步建议："
echo "1. 查看上面的详细错误信息"
echo "2. 尝试减少资源使用的配置"
echo "3. 或者尝试单GCU训练测试"
