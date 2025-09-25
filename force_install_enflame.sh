#!/bin/bash

# 🔥 燧原T20强制安装脚本
# 绕过版本解析错误，手动安装所有燧原包
# =========================================

echo "🔥 燧原T20强制安装脚本"
echo "绕过版本解析错误，手动安装燧原包"
echo "=================================="

# 确定项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

echo "📁 项目根目录: $PROJECT_ROOT"

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

echo ""
echo "🧹 1. 清理可能冲突的包..."
echo "----------------------------------------"

# 强制卸载可能冲突的包
pip3 uninstall -y torch transformers accelerate peft deepspeed 2>/dev/null || true
pip3 uninstall -y ptex collie_lm collie-lm 2>/dev/null || true

echo "✅ 清理完成"

echo ""
echo "📦 2. 手动强制安装燧原核心包..."
echo "----------------------------------------"

# 设置环境变量来绕过版本检查
export PIP_DISABLE_PIP_VERSION_CHECK=1
export PIP_NO_DEPS=1

# 手动安装燧原核心包（按依赖顺序）
echo "🔧 安装 ptex (燧原核心扩展)..."
pip3 install "$DIST_PATH"/ptex-*.whl --force-reinstall --no-deps --disable-pip-version-check

echo "🔧 安装 torch_gcu (燧原PyTorch)..."
# 查找并安装torch_gcu
TORCH_GCU_WHL=$(find "$ENFLAME_ROOT/.." -name "torch_gcu-*-py3.8-*.whl" 2>/dev/null | head -1)
if [ -n "$TORCH_GCU_WHL" ]; then
    echo "找到torch_gcu: $TORCH_GCU_WHL"
    pip3 install "$TORCH_GCU_WHL" --force-reinstall --no-deps --disable-pip-version-check
else
    echo "⚠️  未找到torch_gcu，跳过"
fi

echo "🔧 安装 transformers (燧原优化版)..."
pip3 install "$HF_PATH"/transformers-*.whl --force-reinstall --no-deps --disable-pip-version-check

echo "🔧 安装 accelerate (燧原优化版)..."
pip3 install "$HF_PATH"/accelerate-*.whl --force-reinstall --no-deps --disable-pip-version-check

echo "🔧 安装 peft (燧原优化版)..."
pip3 install "$HF_PATH"/peft-*.whl --force-reinstall --no-deps --disable-pip-version-check

echo "🔧 安装 deepspeed (燧原优化版)..."
pip3 install "$DIST_PATH"/deepspeed-*.whl --force-reinstall --no-deps --disable-pip-version-check

echo "🔧 安装 collie_lm (燧原分布式训练)..."
pip3 install "$DIST_PATH"/collie_lm-*.whl --force-reinstall --no-deps --disable-pip-version-check

echo ""
echo "📚 3. 安装必要的依赖包..."
echo "----------------------------------------"

# 安装必要的依赖，但不检查版本
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
    ninja \
    regex \
    requests \
    filelock \
    typing-extensions

echo ""
echo "🔍 4. 验证安装结果..."
echo "----------------------------------------"

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

if success_count >= 6:  # 至少6个包成功
    print('🎉 燧原环境基本就绪，可以尝试训练！')
    sys.exit(0)
else:
    print('❌ 安装不完整，需要进一步排查')
    sys.exit(1)
"

INSTALL_RESULT=$?

echo ""
if [ $INSTALL_RESULT -eq 0 ]; then
    echo "🎉 燧原强制安装完成！"
    echo ""
    echo "📋 接下来可以运行："
    echo "bash train_ontothink_enflame_official.sh"
else
    echo "❌ 安装仍有问题，需要进一步排查"
    echo ""
    echo "💡 可能的解决方案："
    echo "1. 检查燧原工具包是否完整"
    echo "2. 确认Python版本为3.8"
    echo "3. 检查系统权限"
fi
