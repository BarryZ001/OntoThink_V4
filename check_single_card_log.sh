#!/bin/bash
# 检查单卡训练详细日志
# 分析启动失败的具体原因

echo "🔍 检查单卡训练详细日志"
echo "========================="

LOG_FILE="/tmp/ontothink_single_card_stable.log"

if [ ! -f "$LOG_FILE" ]; then
    echo "❌ 错误: 日志文件不存在: $LOG_FILE"
    exit 1
fi

echo "📋 日志文件: $LOG_FILE"
echo "📊 文件大小: $(ls -lh $LOG_FILE | awk '{print $5}')"
echo ""

echo "🔍 1. 检查启动错误"
echo "=================="
grep -A 10 -B 5 "ERROR\|Traceback\|failed" "$LOG_FILE" | head -20

echo ""
echo "🔍 2. 检查torch.distributed启动"
echo "============================"
grep -A 5 -B 5 "torch.distributed" "$LOG_FILE" | head -15

echo ""
echo "🔍 3. 检查环境变量设置"
echo "===================="
grep -A 3 -B 3 "MASTER_ADDR\|WORLD_SIZE\|GCU_VISIBLE" "$LOG_FILE" | head -10

echo ""
echo "🔍 4. 检查模型加载"
echo "================"
grep -A 3 -B 3 "model_path\|ChatGLM\|from_pretrained" "$LOG_FILE" | head -10

echo ""
echo "🔍 5. 检查ECCL相关"
echo "================"
grep -A 2 -B 2 "ECCL\|eccl" "$LOG_FILE" | head -10

echo ""
echo "🔍 6. 检查Python导入错误"
echo "====================="
grep -A 3 -B 3 "ImportError\|ModuleNotFoundError" "$LOG_FILE" | head -10

echo ""
echo "🔍 7. 最后50行日志"
echo "================="
echo "--- 最后50行 ---"
tail -50 "$LOG_FILE"

echo ""
echo "💡 分析建议"
echo "=========="
echo "基于上述日志信息，单卡失败可能原因："
echo "1. torch.distributed.launch参数不适用于单卡"
echo "2. 环境变量设置冲突"
echo "3. ECCL在单卡模式下的配置问题"
echo "4. 模型路径或数据路径问题"
echo ""
echo "🚀 建议解决方案："
echo "1. 创建直接Python训练脚本（绕过torch.distributed.launch）"
echo "2. 使用最简单的单进程训练模式"
echo "3. 验证模型和数据文件路径"
echo ""
echo "📋 完整日志位置: $LOG_FILE"
