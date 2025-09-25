#!/bin/bash
# 检查修正参数后的新错误日志
# 分析exitcode: 1的具体原因

echo "🔍 检查修正参数后的新错误日志"
echo "============================="

LOG_FILE="/tmp/ontothink_correct_parameters.log"

if [ ! -f "$LOG_FILE" ]; then
    echo "❌ 错误: 日志文件不存在: $LOG_FILE"
    exit 1
fi

echo "📋 日志文件: $LOG_FILE"
echo "📊 文件大小: $(ls -lh $LOG_FILE | awk '{print $5}')"
echo ""

echo "🔍 1. 检查参数解析"
echo "=================="
echo "验证--output_dir参数是否已解决："
if grep -q "unrecognized arguments.*--output_dir" "$LOG_FILE"; then
    echo "❌ --output_dir参数错误仍存在"
else
    echo "✅ --output_dir参数错误已解决"
fi

echo ""
echo "🔍 2. 检查新的错误信息"
echo "===================="
grep -A 10 -B 5 "ERROR\|Traceback\|failed.*exitcode.*1" "$LOG_FILE" | head -25

echo ""
echo "🔍 3. 检查模型文件路径"
echo "===================="
grep -A 3 -B 3 "model_path\|No such file\|FileNotFoundError" "$LOG_FILE" | head -10

echo ""
echo "🔍 4. 检查数据文件路径"
echo "===================="
grep -A 3 -B 3 "train_file\|No such file\|FileNotFoundError" "$LOG_FILE" | head -10

echo ""
echo "🔍 5. 检查Python导入错误"
echo "====================="
grep -A 5 -B 3 "ImportError\|ModuleNotFoundError\|No module named" "$LOG_FILE" | head -15

echo ""
echo "🔍 6. 检查内存或硬件错误"
echo "====================="
grep -A 3 -B 3 "CUDA\|GCU\|memory\|topsMalloc" "$LOG_FILE" | head -10

echo ""
echo "🔍 7. 完整日志 (最后100行)"
echo "========================"
echo "--- 完整日志尾部 ---"
tail -100 "$LOG_FILE"

echo ""
echo "💡 错误分析建议"
echo "==============="
echo "基于上述日志信息："
echo "1. 检查模型文件路径是否正确"
echo "2. 检查数据文件是否存在"
echo "3. 验证Python环境和模块导入"
echo "4. 确认GCU硬件访问权限"
echo ""
echo "🎯 重要对比："
echo "- 4卡训练几乎完全成功 (只是最后SIGILL)"
echo "- 单卡应该更简单，如果基础环境正确"
echo "- 问题可能在于路径或权限设置"
echo ""
echo "📋 完整日志位置: $LOG_FILE"
