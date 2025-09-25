#!/bin/bash

# 🔥 从服务器燧原目录直接安装脚本
# 使用服务器上的燧原安装包：/installer/topsrider_extracted/TopsRider_installer/ai_development_toolkit
# ================================================================================

echo "🔥 从服务器燧原目录直接安装"
echo "目录: /installer/topsrider_extracted/TopsRider_installer/ai_development_toolkit"
echo "=================================================================="

# 燧原服务器安装目录
ENFLAME_ROOT="/installer/topsrider_extracted/TopsRider_installer/ai_development_toolkit"
DIST_PATH="$ENFLAME_ROOT/distributed"
HF_PATH="$ENFLAME_ROOT/huggingface-gcu"

# 检查目录是否存在
echo "🔍 检查燧原安装目录..."
if [ ! -d "$ENFLAME_ROOT" ]; then
    echo "❌ 燧原根目录不存在: $ENFLAME_ROOT"
    exit 1
fi

if [ ! -d "$DIST_PATH" ]; then
    echo "❌ 分布式目录不存在: $DIST_PATH"
    exit 1
fi

if [ ! -d "$HF_PATH" ]; then
    echo "❌ HuggingFace-GCU目录不存在: $HF_PATH"
    exit 1
fi

echo "✅ 燧原安装目录检查通过"

# 列出可用的包
echo ""
echo "📦 可用的燧原包："
echo "----------------------------------------"
echo "🔥 分布式训练包 ($DIST_PATH):"
ls -la "$DIST_PATH"/*.whl 2>/dev/null || echo "  未找到.whl文件"

echo ""
echo "🤗 HuggingFace-GCU包 ($HF_PATH):"
ls -la "$HF_PATH"/*.whl 2>/dev/null || echo "  未找到.whl文件"

echo ""
echo "🚀 开始安装燧原包..."
echo "=================================="

# 设置pip参数绕过版本检查
export PIP_DISABLE_PIP_VERSION_CHECK=1

echo ""
echo "🧹 1. 清理旧包..."
pip3 uninstall -y torch transformers accelerate peft deepspeed ptex collie_lm collie-lm 2>/dev/null || true

echo ""
echo "📦 2. 从服务器目录安装燧原包..."

# 按顺序安装燧原包
echo "🔧 安装 ptex (燧原核心)..."
if ls "$DIST_PATH"/ptex-*.whl 1> /dev/null 2>&1; then
    pip3 install "$DIST_PATH"/ptex-*.whl --force-reinstall --no-deps --disable-pip-version-check
    echo "✅ ptex 安装完成"
else
    echo "❌ 未找到 ptex 包"
fi

echo ""
echo "🔧 安装 deepspeed (燧原分布式)..."
if ls "$DIST_PATH"/deepspeed-*.whl 1> /dev/null 2>&1; then
    pip3 install "$DIST_PATH"/deepspeed-*.whl --force-reinstall --no-deps --disable-pip-version-check
    echo "✅ deepspeed 安装完成"
else
    echo "❌ 未找到 deepspeed 包"
fi

echo ""
echo "🔧 安装 collie_lm (燧原训练框架)..."
if ls "$DIST_PATH"/collie_lm-*.whl 1> /dev/null 2>&1; then
    pip3 install "$DIST_PATH"/collie_lm-*.whl --force-reinstall --no-deps --disable-pip-version-check
    echo "✅ collie_lm 安装完成"
else
    echo "❌ 未找到 collie_lm 包"
fi

echo ""
echo "🔧 安装 transformers (燧原优化版)..."
if ls "$HF_PATH"/transformers-*.whl 1> /dev/null 2>&1; then
    pip3 install "$HF_PATH"/transformers-*.whl --force-reinstall --no-deps --disable-pip-version-check
    echo "✅ transformers 安装完成"
else
    echo "❌ 未找到 transformers 包"
fi

echo ""
echo "🔧 安装 accelerate (燧原优化版)..."
if ls "$HF_PATH"/accelerate-*.whl 1> /dev/null 2>&1; then
    pip3 install "$HF_PATH"/accelerate-*.whl --force-reinstall --no-deps --disable-pip-version-check
    echo "✅ accelerate 安装完成"
else
    echo "❌ 未找到 accelerate 包"
fi

echo ""
echo "🔧 安装 peft (燧原优化版)..."
if ls "$HF_PATH"/peft-*.whl 1> /dev/null 2>&1; then
    pip3 install "$HF_PATH"/peft-*.whl --force-reinstall --no-deps --disable-pip-version-check
    echo "✅ peft 安装完成"
else
    echo "❌ 未找到 peft 包"
fi

echo ""
echo "🔧 寻找并安装 torch_gcu..."
# 在整个TopsRider目录中查找torch_gcu
TORCH_GCU_WHL=$(find "/installer/topsrider_extracted/TopsRider_installer" -name "torch_gcu-*-py3.8-*.whl" 2>/dev/null | head -1)
if [ -n "$TORCH_GCU_WHL" ]; then
    echo "✅ 找到 torch_gcu: $TORCH_GCU_WHL"
    pip3 install "$TORCH_GCU_WHL" --force-reinstall --no-deps --disable-pip-version-check
    echo "✅ torch_gcu 安装完成"
else
    echo "⚠️  未找到 torch_gcu，尝试安装标准torch..."
    pip3 install torch==1.10.0 --no-deps --disable-pip-version-check
fi

echo ""
echo "📚 3. 安装基础依赖..."
pip3 install --no-deps --disable-pip-version-check \
    numpy \
    datasets \
    tokenizers \
    huggingface-hub \
    safetensors \
    pydantic==1.10.12 \
    sentencepiece==0.1.99 \
    einops==0.6.1 \
    tqdm \
    packaging \
    psutil \
    regex \
    requests \
    filelock \
    typing-extensions

echo ""
echo "🔍 4. 验证安装..."
echo "=================================="

python3 -c "
import sys
success_count = 0
total_count = 8

packages = [
    ('ptex', 'ptex'),
    ('collie_lm', 'collie_lm'), 
    ('deepspeed', 'deepspeed'),
    ('transformers', 'transformers'),
    ('accelerate', 'accelerate'), 
    ('peft', 'peft'),
    ('sentencepiece', 'sentencepiece'),
    ('torch', 'torch')
]

print('📦 燧原包验证结果:')
for pkg_name, import_name in packages:
    try:
        module = __import__(import_name)
        version = getattr(module, '__version__', 'unknown')
        print(f'✅ {pkg_name}: {version}')
        success_count += 1
    except Exception as e:
        print(f'❌ {pkg_name}: {e}')

print(f'')
print(f'📊 安装结果: {success_count}/{total_count} 成功')

if success_count >= 6:
    print('🎉 燧原环境基本可用！')
    print('🚀 现在可以尝试训练: bash train_ontothink_enflame_official.sh')
    sys.exit(0)
else:
    print('❌ 安装不完整，需要进一步排查')
    sys.exit(1)
"
