#!/bin/bash

# 🔍 详细检查训练进展
# 分析CPU offload效果和训练状态
# ==============================

echo "🔍 详细检查训练进展"
echo "分析CPU offload效果和训练状态"
echo "============================"

echo ""
echo "📋 检查完整训练日志"
echo "=================="

if [ -f /tmp/cpu_offload_training.log ]; then
    echo "✅ 找到CPU offload训练日志"
    echo ""
    
    echo "📊 日志文件统计:"
    echo "  总行数: $(wc -l < /tmp/cpu_offload_training.log)"
    echo "  文件大小: $(du -h /tmp/cpu_offload_training.log | cut -f1)"
    
    echo ""
    echo "🔍 1. 检查DeepSpeed配置信息"
    echo "============================="
    if grep -q -i "deepspeed\|zero\|stage" /tmp/cpu_offload_training.log; then
        echo "✅ 找到DeepSpeed相关信息:"
        grep -i -n "deepspeed\|zero\|stage" /tmp/cpu_offload_training.log | head -5
    else
        echo "⚠️  未找到DeepSpeed配置信息"
    fi
    
    echo ""
    echo "🔍 2. 检查优化器配置"
    echo "=================="
    if grep -q -i "optimizer\|adam" /tmp/cpu_offload_training.log; then
        echo "✅ 找到优化器配置:"
        grep -i -n "optimizer\|adam" /tmp/cpu_offload_training.log | head -3
    else
        echo "⚠️  未找到优化器配置信息"
    fi
    
    echo ""
    echo "🔍 3. 检查内存使用情况"
    echo "====================/"
    echo "📊 内存分配成功的信息:"
    if grep -q -i "Reserve unified pointer\|memory.*success\|allocated" /tmp/cpu_offload_training.log; then
        grep -i "Reserve unified pointer\|memory.*success\|allocated" /tmp/cpu_offload_training.log | tail -3
    else
        echo "⚠️  未找到内存分配成功信息"
    fi
    
    echo ""
    echo "❌ 内存分配失败的信息:"
    if grep -q -i "topsMalloc.*failed\|Check failed.*topsSuccess\|memory.*error" /tmp/cpu_offload_training.log; then
        echo "发现内存错误:"
        grep -i -n "topsMalloc.*failed\|Check failed.*topsSuccess\|memory.*error" /tmp/cpu_offload_training.log | tail -2
    else
        echo "✅ 没有内存分配失败"
    fi
    
    echo ""
    echo "🔍 4. 检查训练循环状态"
    echo "====================="
    if grep -q -i "step.*loss\|epoch.*\|training.*start\|loss.*:" /tmp/cpu_offload_training.log; then
        echo "🎉 找到训练循环信息:"
        grep -i -n "step.*loss\|epoch.*\|training.*start\|loss.*:" /tmp/cpu_offload_training.log | tail -5
    elif grep -q -i "data.*load\|dataset\|batch" /tmp/cpu_offload_training.log; then
        echo "⚠️  正在数据加载阶段:"
        grep -i -n "data.*load\|dataset\|batch" /tmp/cpu_offload_training.log | tail -3
    else
        echo "⚠️  未找到训练循环信息"
    fi
    
    echo ""
    echo "🔍 5. 检查ECCL通信状态"
    echo "====================="
    ECCL_SUCCESS=$(grep -c "ecclCommInitRank.*success" /tmp/cpu_offload_training.log)
    echo "✅ ECCL成功初始化次数: $ECCL_SUCCESS"
    
    echo ""
    echo "🔍 6. 检查进程状态"
    echo "=================="
    if grep -q -i "abort\|terminate\|exit\|killed" /tmp/cpu_offload_training.log; then
        echo "❌ 进程异常终止:"
        grep -i -n "abort\|terminate\|exit\|killed" /tmp/cpu_offload_training.log | tail -2
    else
        echo "✅ 进程正常运行"
    fi
    
    echo ""
    echo "🔍 7. 检查最新状态 (最后20行)"
    echo "=============================="
    echo "📋 训练日志最新输出:"
    tail -20 /tmp/cpu_offload_training.log
    
else
    echo "❌ 未找到CPU offload训练日志文件"
fi

echo ""
echo "🔍 8. 检查系统资源使用"
echo "====================="
echo "📊 当前系统内存使用:"
free -h 2>/dev/null || echo "⚠️  无法获取内存信息"

echo ""
echo "📊 当前GCU进程:"
ps aux | grep -E "python.*finetune|torch" | grep -v grep || echo "⚠️  未找到训练进程"

echo ""
echo "🔍 9. 检查DeepSpeed配置文件"
echo "=========================="
if [ -f /tmp/deepspeed_cpu_offload.json ]; then
    echo "✅ DeepSpeed配置文件存在"
    echo "📋 配置内容摘要:"
    cat /tmp/deepspeed_cpu_offload.json | jq -r '
        "Zero Stage: " + (.zero_optimization.stage | tostring) + 
        ", Offload: " + (.zero_optimization.offload_optimizer.device // "none") +
        ", FP16: " + (.fp16.enabled | tostring)' 2>/dev/null || echo "无法解析JSON配置"
else
    echo "❌ DeepSpeed配置文件不存在"
fi

echo ""
echo "💡 训练进展总结"
echo "================"

if [ -f /tmp/cpu_offload_training.log ]; then
    # 综合分析训练状态
    HAS_MEMORY_ERROR=$(grep -c "topsMalloc.*failed\|Check failed.*topsSuccess" /tmp/cpu_offload_training.log)
    HAS_TRAINING_LOOP=$(grep -c "step.*loss\|epoch.*\|loss.*:" /tmp/cpu_offload_training.log)
    HAS_DATA_LOADING=$(grep -c "data.*load\|dataset\|batch" /tmp/cpu_offload_training.log)
    HAS_OPTIMIZER=$(grep -c "optimizer.*initialized\|DeepSpeed.*initialized" /tmp/cpu_offload_training.log)
    
    echo "📊 状态统计:"
    echo "  内存错误: $HAS_MEMORY_ERROR 次"
    echo "  训练循环: $HAS_TRAINING_LOOP 次"
    echo "  数据加载: $HAS_DATA_LOADING 次"
    echo "  优化器初始化: $HAS_OPTIMIZER 次"
    
    if [ $HAS_MEMORY_ERROR -eq 0 ] && [ $HAS_TRAINING_LOOP -gt 0 ]; then
        echo ""
        echo "🎉🎉🎉 完全成功！"
        echo "✅ CPU offload解决了内存问题"
        echo "✅ 训练循环正常运行"
        echo "✅ 可以开始扩展训练规模"
    elif [ $HAS_MEMORY_ERROR -eq 0 ] && [ $HAS_OPTIMIZER -gt 0 ]; then
        echo ""
        echo "🎯 部分成功！"
        echo "✅ 内存问题已解决"
        echo "✅ 优化器初始化成功"
        echo "⚠️  可能在数据处理或训练准备阶段"
    elif [ $HAS_MEMORY_ERROR -eq 0 ]; then
        echo ""
        echo "🎯 内存突破成功！"
        echo "✅ CPU offload策略有效"
        echo "✅ 没有内存分配错误"
        echo "⚠️  需要进一步检查训练流程"
    else
        echo ""
        echo "⚠️  仍需优化"
        echo "❌ 内存问题未完全解决"
        echo "💡 可能需要更激进的offload策略"
    fi
fi

echo ""
echo "🚀 建议的下一步:"
if [ -f /tmp/cpu_offload_training.log ] && [ $(grep -c "topsMalloc.*failed" /tmp/cpu_offload_training.log) -eq 0 ]; then
    echo "1. ✅ 内存问题已解决，可以增加训练参数"
    echo "2. 🔧 尝试增加max_tokens: 128 → 256"
    echo "3. 🔧 尝试增加max_steps: 1 → 10"
    echo "4. 🚀 测试多卡并行训练"
else
    echo "1. 🔧 尝试Zero Stage 3 (模型参数也offload)"
    echo "2. 🔧 尝试模型并行 (tp_size > 1)"
    echo "3. 🔧 检查是否需要更小的模型"
fi

echo ""
echo "📋 完整日志文件: /tmp/cpu_offload_training.log"
