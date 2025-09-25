#!/bin/bash

# 🔍 检查燧原T20安装状态脚本
# ================================

echo "🔍 检查燧原T20环境安装状态"
echo "==============================="

echo ""
echo "📦 检查燧原核心包..."
python3 -c "
try:
    import ptex
    print('✅ ptex: 已安装')
except Exception as e:
    print('❌ ptex:', e)

try:
    import collie_lm
    print('✅ collie_lm: 已安装')
except Exception as e:
    print('❌ collie_lm:', e)

try:
    import deepspeed
    print('✅ deepspeed: 已安装，版本:', deepspeed.__version__)
except Exception as e:
    print('❌ deepspeed:', e)

try:
    import transformers
    print('✅ transformers: 已安装，版本:', transformers.__version__)
except Exception as e:
    print('❌ transformers:', e)

try:
    import accelerate
    print('✅ accelerate: 已安装，版本:', accelerate.__version__)
except Exception as e:
    print('❌ accelerate:', e)

try:
    import peft
    print('✅ peft: 已安装，版本:', peft.__version__)
except Exception as e:
    print('❌ peft:', e)

try:
    import sentencepiece
    print('✅ sentencepiece: 已安装，版本:', sentencepiece.__version__)
except Exception as e:
    print('❌ sentencepiece:', e)

try:
    import torch
    print('✅ torch: 已安装，版本:', torch.__version__)
except Exception as e:
    print('❌ torch:', e)
"

echo ""
echo "🔥 现在可以尝试运行训练了！"
echo "请运行: bash train_ontothink_enflame_official.sh"
