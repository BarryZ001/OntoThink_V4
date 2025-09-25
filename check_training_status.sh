#!/bin/bash
# 检查训练状态 - 分析是否真的卡住还是在正常处理
# 监控进程、内存、日志增长等

echo "🔍 检查训练状态 - 分析是否卡住"
echo "=============================="

echo "📋 1. 检查训练进程"
echo "=================="
echo "🔍 Python训练进程:"
ps aux | grep "finetune_chatglm3_for_multiturn.py" | grep -v grep
echo ""

echo "🔍 torch.distributed.launch进程:"
ps aux | grep "torch.distributed.launch" | grep -v grep
echo ""

echo "🔍 所有Python进程 (最近5个):"
ps aux | grep python | grep -v grep | head -5
echo ""

echo "📋 2. 检查日志文件状态"
echo "====================="
LOG_FILE="/tmp/ontothink_ladder_shape_fixed.log"
if [ -f "$LOG_FILE" ]; then
    echo "✅ 日志文件存在: $LOG_FILE"
    echo "📊 当前文件大小: $(ls -lh $LOG_FILE | awk '{print $5}')"
    echo "📊 最后修改时间: $(ls -l $LOG_FILE | awk '{print $6 " " $7 " " $8}')"
    echo ""
    
    echo "🔍 日志最后20行:"
    tail -20 "$LOG_FILE"
    echo ""
    
    # 检查日志是否还在增长
    INITIAL_SIZE=$(stat -c%s "$LOG_FILE" 2>/dev/null || stat -f%z "$LOG_FILE" 2>/dev/null)
    echo "⏱️  等待10秒检查日志是否还在增长..."
    sleep 10
    FINAL_SIZE=$(stat -c%s "$LOG_FILE" 2>/dev/null || stat -f%z "$LOG_FILE" 2>/dev/null)
    
    if [ "$FINAL_SIZE" -gt "$INITIAL_SIZE" ]; then
        echo "✅ 日志文件正在增长 (从 $INITIAL_SIZE 到 $FINAL_SIZE 字节)"
        echo "💡 训练可能正在正常进行，只是输出较少"
    else
        echo "⚠️  日志文件没有增长，可能确实卡住了"
    fi
else
    echo "❌ 日志文件不存在: $LOG_FILE"
fi

echo ""
echo "📋 3. 检查GCU使用情况"
echo "===================="
echo "🔍 GCU相关进程:"
ps aux | grep -E "gcu|tpu|enflame" | grep -v grep || echo "未找到GCU相关进程"

echo ""
echo "📋 4. 检查系统资源"
echo "=================="
echo "🔍 内存使用:"
free -h

echo ""
echo "🔍 CPU负载:"
uptime

echo ""
echo "📋 5. 检查网络端口 (分布式通信)"
echo "=============================="
echo "🔍 检查端口29500 (MASTER_PORT):"
netstat -tlnp | grep 29500 || echo "端口29500未监听"

echo ""
echo "📋 6. 检查可能的错误模式"
echo "======================="
if [ -f "$LOG_FILE" ]; then
    echo "🔍 查找常见卡住原因:"
    
    if grep -q "NCCL\|ECCL.*timeout\|communication.*timeout" "$LOG_FILE"; then
        echo "❌ 发现通信超时 - 分布式通信问题"
    elif grep -q "CUDA.*out of memory\|GCU.*out of memory\|topsMalloc.*failed" "$LOG_FILE"; then
        echo "❌ 发现内存不足 - 需要进一步优化"
    elif grep -q "Waiting for.*rank\|rank.*not responding" "$LOG_FILE"; then
        echo "❌ 发现rank同步问题 - 某个进程可能失败"
    elif grep -q "model.*loading\|checkpoint.*loading" "$LOG_FILE"; then
        echo "⏳ 可能在加载模型 - 大模型加载需要时间"
    elif grep -q "compiling\|compilation" "$LOG_FILE"; then
        echo "⏳ 可能在编译模型 - 首次编译需要较长时间"
    elif grep -q "factor.*compile.*begin\|HLIR.*compile" "$LOG_FILE"; then
        echo "⏳ 正在进行HLIR编译 - 这个过程可能需要几分钟"
    else
        echo "🤔 未发现明显的卡住原因"
    fi
fi

echo ""
echo "💡 建议操作"
echo "=========="
echo "基于检查结果："

if [ -f "$LOG_FILE" ] && grep -q "factor.*compile.*begin\|HLIR.*compile" "$LOG_FILE"; then
    echo "✅ 如果在HLIR编译阶段 - 这是正常的，请耐心等待"
    echo "   编译ChatGLM3-6B可能需要5-10分钟"
elif ps aux | grep "finetune_chatglm3_for_multiturn.py" | grep -v grep > /dev/null; then
    echo "✅ 进程仍在运行 - 建议再等待几分钟"
    echo "   首次运行通常需要较长的初始化时间"
else
    echo "❌ 进程可能已终止 - 建议检查完整日志"
    echo "   或者尝试单卡训练方案"
fi

echo ""
echo "🚀 如果确实卡住，可以尝试:"
echo "1. Ctrl+C 终止当前训练"
echo "2. 运行单卡版本: bash fix_single_card_stable.sh"
echo "3. 或者检查完整日志: cat $LOG_FILE"

echo ""
echo "📋 状态检查完成!"
