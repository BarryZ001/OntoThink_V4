#!/bin/bash

# 🔧 手动逐个安装燧原包脚本
# 一步步安装并测试每个包
# ===========================

echo "🔧 手动逐个安装燧原包"
echo "一步步安装并测试"
echo "======================"

ENFLAME_ROOT="/installer/topsrider_extracted/TopsRider_installer/ai_development_toolkit"

# 设置环境变量
export PIP_DISABLE_PIP_VERSION_CHECK=1

echo ""
echo "🔍 第1步: 确保基础torch安装"
echo "============================="

# 先尝试安装基础torch
echo "🔧 安装基础torch..."
pip3 install torch==1.10.0 --no-deps --disable-pip-version-check --force-reinstall

echo "🧪 测试torch导入:"
python3 -c "
try:
    import torch
    print('✅ torch 导入成功, 版本:', torch.__version__)
except Exception as e:
    print('❌ torch 导入失败:', e)
    exit(1)
"

if [ $? -ne 0 ]; then
    echo "❌ torch 安装失败，无法继续"
    exit 1
fi

echo ""
echo "🔍 第2步: 安装 torch_gcu"
echo "========================"

# 查找torch_gcu
TORCH_GCU_WHL=$(find "/installer/topsrider_extracted/TopsRider_installer" -name "torch_gcu-*-py3.8-*.whl" 2>/dev/null | head -1)

if [ -n "$TORCH_GCU_WHL" ]; then
    echo "✅ 找到torch_gcu: $TORCH_GCU_WHL"
    echo "🔧 安装 torch_gcu..."
    pip3 install "$TORCH_GCU_WHL" --force-reinstall --no-deps --disable-pip-version-check
    
    echo "🧪 测试torch_gcu:"
    python3 -c "
try:
    import torch
    print('✅ torch (with GCU) 导入成功, 版本:', torch.__version__)
    print('torch路径:', torch.__file__)
except Exception as e:
    print('❌ torch_gcu 导入失败:', e)
"
else
    echo "⚠️  未找到torch_gcu，继续使用标准torch"
fi

echo ""
echo "🔍 第3步: 安装 ptex"
echo "==================="

PTEX_WHL="$ENFLAME_ROOT/distributed/ptex-1.3.20-py3-none-any.whl"
if [ -f "$PTEX_WHL" ]; then
    echo "✅ 找到ptex: $PTEX_WHL"
    echo "🔧 安装 ptex..."
    pip3 install "$PTEX_WHL" --force-reinstall --no-deps --disable-pip-version-check
    
    echo "🧪 测试ptex导入:"
    python3 -c "
try:
    import ptex
    print('✅ ptex 导入成功')
    print('ptex路径:', ptex.__file__)
except Exception as e:
    print('❌ ptex 导入失败:', e)
    import traceback
    traceback.print_exc()
"
else
    echo "❌ 未找到ptex.whl文件: $PTEX_WHL"
fi

echo ""
echo "🔍 第4步: 安装基础依赖"
echo "====================="

echo "🔧 安装基础Python包..."
pip3 install --no-deps --disable-pip-version-check \
    numpy \
    pydantic==1.10.12 \
    packaging \
    psutil \
    tqdm \
    typing-extensions \
    filelock

echo ""
echo "🔍 第5步: 安装 transformers"
echo "=========================="

TRANSFORMERS_WHL="$ENFLAME_ROOT/huggingface-gcu/transformers-4.32.0+gcu.7-py3-none-any.whl"
if [ -f "$TRANSFORMERS_WHL" ]; then
    echo "✅ 找到transformers: $TRANSFORMERS_WHL"
    
    # 先安装transformers的一些基础依赖
    pip3 install --no-deps --disable-pip-version-check \
        tokenizers \
        huggingface-hub \
        safetensors \
        regex \
        requests
    
    echo "🔧 安装 transformers..."
    pip3 install "$TRANSFORMERS_WHL" --force-reinstall --no-deps --disable-pip-version-check
    
    echo "🧪 测试transformers导入:"
    python3 -c "
try:
    import transformers
    print('✅ transformers 导入成功, 版本:', transformers.__version__)
except Exception as e:
    print('❌ transformers 导入失败:', e)
    import traceback
    traceback.print_exc()
"
else
    echo "❌ 未找到transformers.whl文件: $TRANSFORMERS_WHL"
fi

echo ""
echo "🔍 第6步: 安装 deepspeed"
echo "======================="

DEEPSPEED_WHL="$ENFLAME_ROOT/distributed/deepspeed-0.9.2+gcu.49-py3-none-any.whl"
if [ -f "$DEEPSPEED_WHL" ]; then
    echo "✅ 找到deepspeed: $DEEPSPEED_WHL"
    echo "🔧 安装 deepspeed..."
    pip3 install "$DEEPSPEED_WHL" --force-reinstall --no-deps --disable-pip-version-check
    
    echo "🧪 测试deepspeed导入:"
    python3 -c "
try:
    import deepspeed
    print('✅ deepspeed 导入成功, 版本:', deepspeed.__version__)
except Exception as e:
    print('❌ deepspeed 导入失败:', e)
    import traceback
    traceback.print_exc()
"
else
    echo "❌ 未找到deepspeed.whl文件: $DEEPSPEED_WHL"
fi

echo ""
echo "🔍 第7步: 安装 collie_lm"
echo "======================"

COLLIE_WHL="$ENFLAME_ROOT/distributed/collie_lm-1.0.6.dev0+gcu.38-py3-none-any.whl"
if [ -f "$COLLIE_WHL" ]; then
    echo "✅ 找到collie_lm: $COLLIE_WHL"
    echo "🔧 安装 collie_lm..."
    pip3 install "$COLLIE_WHL" --force-reinstall --no-deps --disable-pip-version-check
    
    echo "🧪 测试collie_lm导入:"
    python3 -c "
try:
    import collie_lm
    print('✅ collie_lm 导入成功')
except Exception as e:
    print('❌ collie_lm 导入失败:', e)
    import traceback
    traceback.print_exc()
"
else
    echo "❌ 未找到collie_lm.whl文件: $COLLIE_WHL"
fi

echo ""
echo "🔍 第8步: 最终验证"
echo "=================="

echo "🧪 最终包导入测试:"
python3 -c "
packages = ['torch', 'ptex', 'transformers', 'deepspeed', 'collie_lm']
success = 0
total = len(packages)

for pkg in packages:
    try:
        module = __import__(pkg)
        version = getattr(module, '__version__', 'unknown')
        print(f'✅ {pkg}: {version}')
        success += 1
    except Exception as e:
        print(f'❌ {pkg}: {e}')

print(f'')
print(f'📊 成功率: {success}/{total} ({success/total*100:.1f}%)')

if success >= 4:  # 至少4个包成功
    print('🎉 燧原环境基本可用！')
    print('🚀 可以尝试运行训练了!')
else:
    print('❌ 仍有问题，需要进一步调试')
"

echo ""
echo "🎉 手动安装完成！"
echo "如果大部分包都能导入，现在可以尝试训练了：bash train_ontothink_enflame_official.sh"
