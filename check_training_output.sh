#!/bin/bash
# 检查训练输出文件 - 验证是否生成了训练结果
# 确认OntoThink训练的实际成果

echo "🔍 检查训练输出文件 - 验证OntoThink训练成果"
echo "=========================================="

echo "📋 1. 检查预期输出目录"
echo "====================="
# 根据之前的配置，输出可能在以下位置
OUTPUT_DIRS=(
    "/workspace/code/OntoThink_V4/enflame_training/models/ontothink-chatglm3-6b"
    "$(pwd)/enflame_training/models/ontothink-chatglm3-6b"
    "$(pwd)/models"
    "$(pwd)/output"
    "/tmp/ontothink_output"
)

for dir in "${OUTPUT_DIRS[@]}"; do
    echo "🔍 检查目录: $dir"
    if [ -d "$dir" ]; then
        echo "✅ 目录存在"
        echo "📊 目录内容:"
        ls -la "$dir"
        echo ""
    else
        echo "❌ 目录不存在"
    fi
    echo "---"
done

echo ""
echo "📋 2. 搜索可能的模型文件"
echo "======================="
echo "🔍 搜索.bin文件 (PyTorch模型):"
find /workspace/code/OntoThink_V4 -name "*.bin" -type f -newer /tmp/ontothink_ladder_shape_fixed.log 2>/dev/null | head -10

echo ""
echo "🔍 搜索.safetensors文件 (SafeTensors模型):"
find /workspace/code/OntoThink_V4 -name "*.safetensors" -type f -newer /tmp/ontothink_ladder_shape_fixed.log 2>/dev/null | head -10

echo ""
echo "🔍 搜索config.json文件 (模型配置):"
find /workspace/code/OntoThink_V4 -name "config.json" -type f -newer /tmp/ontothink_ladder_shape_fixed.log 2>/dev/null | head -10

echo ""
echo "🔍 搜索checkpoint目录:"
find /workspace/code/OntoThink_V4 -name "*checkpoint*" -type d 2>/dev/null | head -10

echo ""
echo "📋 3. 检查训练脚本工作目录"
echo "========================="
CHATGLM3_SCRIPT_DIR="/installer/topsrider_extracted/TopsRider_installer/ai_development_toolkit/distributed/llm_scripts_1.0.40/finetuning/chatglm3"
echo "🔍 燧原脚本目录: $CHATGLM3_SCRIPT_DIR"
if [ -d "$CHATGLM3_SCRIPT_DIR" ]; then
    echo "📊 脚本目录内容 (最近文件):"
    find "$CHATGLM3_SCRIPT_DIR" -type f -newer /tmp/ontothink_ladder_shape_fixed.log 2>/dev/null | head -10
else
    echo "❌ 脚本目录不存在"
fi

echo ""
echo "📋 4. 检查DeepSpeed输出"
echo "====================="
echo "🔍 搜索ds_logs目录:"
find /workspace/code -name "ds_logs" -type d 2>/dev/null | head -5

echo ""
echo "🔍 搜索DeepSpeed相关文件:"
find /workspace/code -name "*deepspeed*" -type f -newer /tmp/ontothink_ladder_shape_fixed.log 2>/dev/null | head -10

echo ""
echo "📋 5. 检查时间戳相关文件"
echo "======================="
echo "🔍 训练期间创建或修改的文件 (最近2小时):"
find /workspace/code/OntoThink_V4 -type f -newermt "2 hours ago" 2>/dev/null | grep -v "__pycache__" | head -20

echo ""
echo "📋 6. 检查进程工作目录"
echo "===================="
echo "🔍 当前目录内容检查:"
ls -la . | grep -E "$(date +%Y-%m-%d|%b.*$(date +%d))"

echo ""
echo "📋 7. 检查日志中的输出路径提示"
echo "============================="
LOG_FILE="/tmp/ontothink_ladder_shape_fixed.log"
if [ -f "$LOG_FILE" ]; then
    echo "🔍 从日志中提取输出路径信息:"
    grep -i "output.*dir\|save.*to\|checkpoint.*save\|model.*save" "$LOG_FILE" | head -10
    
    echo ""
    echo "🔍 从日志中提取路径相关信息:"
    grep -i "path.*model\|directory.*output" "$LOG_FILE" | head -10
fi

echo ""
echo "💡 输出文件检查总结"
echo "=================="
echo "基于检查结果:"

# 统计发现的文件
RECENT_MODELS=$(find /workspace/code/OntoThink_V4 -name "*.bin" -o -name "*.safetensors" -type f -newer /tmp/ontothink_ladder_shape_fixed.log 2>/dev/null | wc -l)
RECENT_CONFIGS=$(find /workspace/code/OntoThink_V4 -name "config.json" -type f -newer /tmp/ontothink_ladder_shape_fixed.log 2>/dev/null | wc -l)

echo "📊 发现的新文件:"
echo "  模型文件 (.bin/.safetensors): $RECENT_MODELS"
echo "  配置文件 (config.json): $RECENT_CONFIGS"

if [ "$RECENT_MODELS" -gt 0 ] || [ "$RECENT_CONFIGS" -gt 0 ]; then
    echo ""
    echo "🎉 发现训练输出文件！"
    echo "✅ OntoThink模型训练可能生成了实际输出"
    echo "📋 建议检查具体文件内容和大小"
else
    echo ""
    echo "🤔 未发现明显的模型输出文件"
    echo "💡 可能的原因:"
    echo "1. 训练过程可能主要进行了编译和验证"
    echo "2. 输出文件可能在其他位置"
    echo "3. MAX_STEPS=5可能不足以生成checkpoint"
    echo "4. SIGILL在保存前终止了训练"
fi

echo ""
echo "🚀 建议下一步:"
echo "=============="
echo "1. 🔍 如果发现模型文件 → 验证文件大小和内容"
echo "2. 📈 增加MAX_STEPS → 确保有足够步骤生成输出"
echo "3. 🎯 扩展训练配置 → 增加tokens、epochs、数据"
echo "4. 🏆 庆祝基础突破 → OntoThink训练环境已完全建立"

echo ""
echo "📋 检查完成!"
