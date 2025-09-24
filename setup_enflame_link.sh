#!/bin/bash

echo "🔗 设置燧原工具包符号链接"
echo "=========================================="

# 燧原工具包在服务器上的实际位置
ENFLAME_SOURCE="/installer/topsrider_extracted/TopsRider_installer"
ENFLAME_TARGET="/workspace/code/OntoThink_V4/FromEnflame"

# 检查源目录是否存在
if [ ! -d "$ENFLAME_SOURCE" ]; then
    echo "❌ 燧原工具包源目录不存在: $ENFLAME_SOURCE"
    exit 1
fi

echo "📁 源目录: $ENFLAME_SOURCE"
echo "🎯 目标链接: $ENFLAME_TARGET"

# 如果目标已存在，先删除
if [ -L "$ENFLAME_TARGET" ]; then
    echo "🗑️  删除现有符号链接..."
    rm "$ENFLAME_TARGET"
elif [ -d "$ENFLAME_TARGET" ]; then
    echo "🗑️  删除现有目录..."
    rm -rf "$ENFLAME_TARGET"
fi

# 创建符号链接
echo "🔗 创建符号链接..."
ln -s "$ENFLAME_SOURCE" "$ENFLAME_TARGET"

if [ $? -eq 0 ]; then
    echo "✅ 燧原工具包链接创建成功！"
    
    # 验证链接
    echo "🔍 验证链接..."
    if [ -d "$ENFLAME_TARGET/ai_development_toolkit" ]; then
        echo "✅ ai_development_toolkit 目录可访问"
    else
        echo "❌ ai_development_toolkit 目录不可访问"
    fi
    
    if [ -d "$ENFLAME_TARGET/distributed" ]; then
        echo "✅ distributed 目录可访问"
    else
        echo "❌ distributed 目录不可访问"
    fi
    
    # 检查LLM脚本
    LLM_SCRIPTS_PATH="$ENFLAME_TARGET/ai_development_toolkit/distributed"
    if [ -d "$LLM_SCRIPTS_PATH" ]; then
        echo "✅ LLM脚本目录找到: $LLM_SCRIPTS_PATH"
        ls -la "$LLM_SCRIPTS_PATH" | head -5
    else
        echo "❌ LLM脚本目录未找到"
    fi
    
else
    echo "❌ 符号链接创建失败！"
    exit 1
fi

echo ""
echo "🎉 燧原工具包设置完成！"
echo "💡 现在可以运行训练脚本了："
echo "   python3 enflame_training/scripts/train_ontothink_enflame.py --step full"
