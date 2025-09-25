#!/bin/bash

# 🔥 燧原T20官方依赖安装脚本
# 基于燧原官方install_for_llm_scripts.sh
# ========================================

echo "🔥 燧原T20官方依赖安装"
echo "基于燧原官方install_for_llm_scripts.sh"
echo "=================================="

# 确定项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# 查找燧原工具包
ENFLAME_ROOT=""
for potential_root in \
    "$PROJECT_ROOT/FromEnflame/ai_development_toolkit" \
    "/installer/topsrider_extracted/TopsRider_installer/ai_development_toolkit" \
    "/usr/local/topsrider/ai_development_toolkit"; do
    if [ -d "$potential_root/distributed" ] && [ -d "$potential_root/huggingface-gcu" ]; then
        ENFLAME_ROOT="$potential_root"
        break
    fi
done

if [ -z "$ENFLAME_ROOT" ]; then
    echo "❌ 未找到燧原工具包"
    exit 1
fi

echo "✅ 燧原工具包: $ENFLAME_ROOT"

DIST_PATH="$ENFLAME_ROOT/distributed"
HF_PATH="$ENFLAME_ROOT/huggingface-gcu"
LLM_SCRIPTS_PATH="$DIST_PATH/llm_scripts_1.0.40"

# 检查燧原install脚本
if [ ! -f "$LLM_SCRIPTS_PATH/install_for_llm_scripts.sh" ]; then
    echo "❌ 未找到燧原官方安装脚本"
    exit 1
fi

echo "🚀 运行燧原官方依赖安装..."

# 切换到燧原脚本目录并运行官方安装
cd "$LLM_SCRIPTS_PATH"
bash install_for_llm_scripts.sh

echo "✅ 燧原官方依赖安装完成"

# 额外安装一些可能需要的包
echo "📦 安装额外依赖..."
pip3 install sentencepiece==0.1.99 --no-deps
pip3 install einops==0.6.1 --no-deps
pip3 install rich --no-deps

echo "🎉 所有依赖安装完成！"
