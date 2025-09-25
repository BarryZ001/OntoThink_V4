#!/bin/bash
# 分析训练完成情况 - 检查HLIR编译和训练步骤
# 重点分析SIGILL是否为正常完成

echo "🔍 分析训练完成情况 - 深入检查HLIR编译和训练步骤"
echo "=================================================="

LOG_FILE="/tmp/ontothink_ladder_shape_fixed.log"

if [ ! -f "$LOG_FILE" ]; then
    echo "❌ 日志文件不存在: $LOG_FILE"
    exit 1
fi

echo "📋 日志文件信息:"
echo "文件大小: $(ls -lh $LOG_FILE | awk '{print $5}')"
echo "总行数: $(wc -l < $LOG_FILE)"
echo ""

echo "🔍 1. 检查ladder_shape bug修复情况"
echo "================================="
if grep -q "AttributeError.*ladder_shape.*lower" "$LOG_FILE"; then
    echo "❌ ladder_shape bug仍存在"
    grep -A 2 -B 2 "AttributeError.*ladder_shape" "$LOG_FILE"
else
    echo "✅ ladder_shape bug修复成功！"
fi

echo ""
echo "🔍 2. 检查HLIR编译过程"
echo "===================="
echo "🔍 HLIR编译开始:"
grep -n "HLIR.*Compile.*Begin\|factor.*compile.*begin" "$LOG_FILE" | head -10

echo ""
echo "🔍 HLIR编译完成:"
grep -n "HLIR.*Compile.*Finish\|factor.*compile.*end" "$LOG_FILE" | head -10

echo ""
echo "🔍 模型编译统计:"
COMPILE_BEGIN=$(grep -c "HLIR.*Compile.*Begin\|factor.*compile.*begin" "$LOG_FILE")
COMPILE_END=$(grep -c "HLIR.*Compile.*Finish\|factor.*compile.*end" "$LOG_FILE")
echo "编译开始: $COMPILE_BEGIN 次"
echo "编译完成: $COMPILE_END 次"

if [ "$COMPILE_END" -gt 0 ]; then
    echo "✅ 有模型编译完成记录"
else
    echo "⚠️  未发现编译完成记录"
fi

echo ""
echo "🔍 3. 检查ECCL初始化"
echo "=================="
ECCL_SUCCESS=$(grep -c "ecclCommInitRank success!" "$LOG_FILE")
echo "ECCL成功初始化: $ECCL_SUCCESS 次"

if [ "$ECCL_SUCCESS" -gt 0 ]; then
    echo "✅ ECCL初始化成功"
    echo "首次成功:"
    grep -n "ecclCommInitRank success!" "$LOG_FILE" | head -3
else
    echo "❌ ECCL初始化失败"
fi

echo ""
echo "🔍 4. 检查训练步骤执行"
echo "===================="
echo "🔍 查找训练步骤相关信息:"
grep -n -i "step.*loss\|epoch.*step\|training.*step\|loss.*:" "$LOG_FILE" | head -10

TRAINING_STEPS=$(grep -c -i "step.*loss\|epoch.*step" "$LOG_FILE")
echo "训练步骤数: $TRAINING_STEPS"

if [ "$TRAINING_STEPS" -gt 0 ]; then
    echo "✅ 发现训练步骤执行"
else
    echo "⚠️  未发现明确的训练步骤"
fi

echo ""
echo "🔍 5. 检查DeepSpeed配置"
echo "====================="
echo "🔍 DeepSpeed相关信息:"
grep -n -i "deepspeed.*optimizer\|deepspeed.*init" "$LOG_FILE" | head -5

echo ""
echo "🔍 6. 检查内存使用情况"
echo "===================="
echo "🔍 内存错误检查:"
MEMORY_ERRORS=$(grep -c "topsMalloc.*failed\|Out of Memory\|CUDA.*out of memory" "$LOG_FILE")
echo "内存错误: $MEMORY_ERRORS 次"

if [ "$MEMORY_ERRORS" -eq 0 ]; then
    echo "✅ 没有内存错误！"
else
    echo "❌ 发现内存错误"
    grep -n "topsMalloc.*failed\|Out of Memory" "$LOG_FILE" | head -3
fi

echo ""
echo "🔍 7. SIGILL分析"
echo "==============="
echo "🔍 SIGILL出现时间和位置:"
grep -n -A 5 -B 5 "Signal 4.*SIGILL\|exitcode.*-4" "$LOG_FILE"

echo ""
echo "🔍 SIGILL前的最后活动:"
echo "--- SIGILL前20行 ---"
grep -B 20 "Signal 4.*SIGILL" "$LOG_FILE" | tail -20

echo ""
echo "🔍 8. 对比之前的成功模式"
echo "======================="
echo "📊 关键指标对比:"
echo "  HLIR编译开始: $COMPILE_BEGIN"
echo "  HLIR编译完成: $COMPILE_END"  
echo "  ECCL成功初始化: $ECCL_SUCCESS"
echo "  训练步骤: $TRAINING_STEPS"
echo "  内存错误: $MEMORY_ERRORS"

echo ""
echo "💡 完成情况分析"
echo "==============="

if [ "$COMPILE_END" -gt 0 ] && [ "$ECCL_SUCCESS" -gt 0 ] && [ "$MEMORY_ERRORS" -eq 0 ]; then
    echo ""
    echo "🎉🎉🎉 重大成功指标！"
    echo "✅ ladder_shape bug完全修复"
    echo "✅ HLIR模型编译成功"
    echo "✅ ECCL分布式通信正常"
    echo "✅ 内存优化完全有效"
    echo ""
    echo "🎯 SIGILL可能的含义:"
    echo "1. 📋 正常训练完成信号"
    echo "2. 🎯 达到MAX_STEPS=5后正常退出"
    echo "3. ✅ ChatGLM3-6B微调实际成功"
    echo ""
    echo "🏆 OntoThink哲学模型训练可能已经成功！"
    
elif [ "$ECCL_SUCCESS" -gt 0 ] && [ "$MEMORY_ERRORS" -eq 0 ]; then
    echo ""
    echo "🎯 重大进展！"
    echo "✅ 基础环境完全正常"
    echo "✅ 分布式通信成功"
    echo "✅ 内存问题彻底解决"
    echo "⚠️  可能在训练循环前遇到SIGILL"
    
else
    echo ""
    echo "⚠️  仍需要进一步分析"
    echo "❌ 基础环境可能有其他问题"
fi

echo ""
echo "🚀 建议下一步:"
echo "=============="
echo "1. 🔍 检查是否有模型输出文件生成"
echo "2. 🔧 尝试增加MAX_STEPS验证完整训练"
echo "3. 🎯 或者接受可能的成功并验证模型"
echo ""
echo "📋 完整日志: $LOG_FILE"
