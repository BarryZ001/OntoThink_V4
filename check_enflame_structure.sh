#!/bin/bash
# 检查燧原工具包目录结构

echo "🔍 检查燧原工具包目录结构"
echo "========================================"

# 检查FromEnflame链接
if [ -L "FromEnflame" ]; then
    echo "✅ FromEnflame 符号链接存在"
    echo "📁 链接目标: $(readlink FromEnflame)"
else
    echo "❌ FromEnflame 符号链接不存在"
    exit 1
fi

# 检查主要目录
echo ""
echo "📂 FromEnflame 目录内容:"
ls -la FromEnflame/ | head -10

echo ""
echo "📂 ai_development_toolkit 内容:"
if [ -d "FromEnflame/ai_development_toolkit" ]; then
    ls -la FromEnflame/ai_development_toolkit/
else
    echo "❌ ai_development_toolkit 目录不存在"
fi

echo ""
echo "📂 distributed 内容:"
if [ -d "FromEnflame/ai_development_toolkit/distributed" ]; then
    ls -la FromEnflame/ai_development_toolkit/distributed/ | head -10
else
    echo "❌ distributed 目录不存在"
fi

echo ""
echo "🔍 查找 ChatGLM3 相关文件:"
find FromEnflame/ -name "*chatglm*" -type f 2>/dev/null | head -10

echo ""
echo "🔍 查找 llm_scripts 目录:"
find FromEnflame/ -name "*llm_scripts*" -type d 2>/dev/null

echo ""
echo "🔍 查找 finetuning 目录:"
find FromEnflame/ -name "*finetuning*" -type d 2>/dev/null

echo ""
echo "🔍 查找 .py 训练脚本:"
find FromEnflame/ -name "*.py" -type f | grep -i "chatglm\|finetune" | head -10
