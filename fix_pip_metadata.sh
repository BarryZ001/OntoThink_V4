#!/bin/bash

# 🔧 修复燧原包pip元数据问题
# 处理版本解析错误和METADATA缺失问题
# ======================================

echo "🔧 修复燧原包pip元数据问题"
echo "处理版本解析错误和METADATA缺失"
echo "================================"

echo ""
echo "🔍 1. 检查当前pip问题"
echo "------------------------"

echo "🚨 当前pip错误:"
echo "- Invalid version: '0.19.1.115.gcu-2.5.136'"
echo "- METADATA文件缺失: ptex, collie-lm"
echo "- Invalid version: '1.10.0-2.5.136' (torch-gcu)"

echo ""
echo "🧹 2. 清理有问题的包"
echo "------------------------"

echo "🗑️  移除有问题的包和元数据..."

# 移除有问题的包的dist-info目录
sudo rm -rf /usr/local/lib/python3.8/dist-packages/ptex-*.dist-info/
sudo rm -rf /usr/local/lib/python3.8/dist-packages/collie_lm-*.dist-info/
sudo rm -rf /usr/local/lib/python3.8/dist-packages/torch_gcu-*.dist-info/
sudo rm -rf /usr/local/lib/python3.8/dist-packages/horovod-*.dist-info/

# 移除实际的包文件
sudo rm -rf /usr/local/lib/python3.8/dist-packages/ptex*
sudo rm -rf /usr/local/lib/python3.8/dist-packages/collie_lm*
sudo rm -rf /usr/local/lib/python3.8/dist-packages/torch_gcu*

echo "✅ 清理完成"

echo ""
echo "🔍 3. 重新安装基础torch"
echo "========================"

# 确保有一个可用的torch
pip3 install torch==1.10.0 --force-reinstall --no-deps --disable-pip-version-check

echo ""
echo "🔧 4. 手动提取和安装燧原包"
echo "============================="

ENFLAME_ROOT="/installer/topsrider_extracted/TopsRider_installer/ai_development_toolkit"

# 创建临时目录
TEMP_DIR="/tmp/enflame_manual_install"
mkdir -p "$TEMP_DIR"

echo "📦 手动提取和安装ptex..."
if [ -f "$ENFLAME_ROOT/distributed/ptex-1.3.20-py3-none-any.whl" ]; then
    cd "$TEMP_DIR"
    # 解压wheel文件
    unzip -q "$ENFLAME_ROOT/distributed/ptex-1.3.20-py3-none-any.whl"
    
    # 手动复制文件到site-packages
    if [ -d "ptex" ]; then
        sudo cp -r ptex /usr/local/lib/python3.8/dist-packages/
        echo "✅ ptex 手动安装完成"
    fi
    
    # 清理
    rm -rf ptex* *.dist-info
fi

echo ""
echo "📦 手动提取和安装collie_lm..."
if [ -f "$ENFLAME_ROOT/distributed/collie_lm-1.0.6.dev0+gcu.38-py3-none-any.whl" ]; then
    cd "$TEMP_DIR"
    # 解压wheel文件
    unzip -q "$ENFLAME_ROOT/distributed/collie_lm-1.0.6.dev0+gcu.38-py3-none-any.whl"
    
    # 手动复制文件到site-packages
    if [ -d "collie" ]; then
        sudo cp -r collie /usr/local/lib/python3.8/dist-packages/
        echo "✅ collie_lm 手动安装完成"
    fi
    
    # 清理
    rm -rf collie* *.dist-info
fi

echo ""
echo "📦 手动提取和安装deepspeed..."
if [ -f "$ENFLAME_ROOT/distributed/deepspeed-0.9.2+gcu.49-py3-none-any.whl" ]; then
    cd "$TEMP_DIR"
    # 解压wheel文件
    unzip -q "$ENFLAME_ROOT/distributed/deepspeed-0.9.2+gcu.49-py3-none-any.whl"
    
    # 手动复制文件到site-packages
    if [ -d "deepspeed" ]; then
        sudo cp -r deepspeed /usr/local/lib/python3.8/dist-packages/
        echo "✅ deepspeed 手动安装完成"
    fi
    
    # 清理
    rm -rf deepspeed* *.dist-info
fi

echo ""
echo "📦 手动提取和安装transformers..."
if [ -f "$ENFLAME_ROOT/huggingface-gcu/transformers-4.32.0+gcu.7-py3-none-any.whl" ]; then
    cd "$TEMP_DIR"
    # 解压wheel文件
    unzip -q "$ENFLAME_ROOT/huggingface-gcu/transformers-4.32.0+gcu.7-py3-none-any.whl"
    
    # 手动复制文件到site-packages
    if [ -d "transformers" ]; then
        sudo cp -r transformers /usr/local/lib/python3.8/dist-packages/
        echo "✅ transformers 手动安装完成"
    fi
    
    # 清理
    rm -rf transformers* *.dist-info
fi

# 清理临时目录
rm -rf "$TEMP_DIR"

echo ""
echo "🔍 5. 安装必要的依赖"
echo "====================="

# 安装必要的依赖包
pip3 install --no-deps --disable-pip-version-check \
    numpy \
    pydantic==1.10.12 \
    sentencepiece==0.1.99 \
    einops==0.6.1 \
    tokenizers \
    huggingface-hub \
    safetensors \
    datasets \
    accelerate \
    peft

echo ""
echo "🧪 6. 测试安装结果"
echo "==================="

python3 -c "
import sys
success_count = 0
total_count = 7

packages = [
    ('torch', 'torch'),
    ('ptex', 'ptex'),
    ('collie_lm', 'collie'),  # collie_lm实际导入名是collie
    ('deepspeed', 'deepspeed'),
    ('transformers', 'transformers'),
    ('sentencepiece', 'sentencepiece'),
    ('einops', 'einops')
]

print('🧪 燧原包测试结果:')
for pkg_name, import_name in packages:
    try:
        module = __import__(import_name)
        version = getattr(module, '__version__', 'unknown')
        print(f'✅ {pkg_name}: {version}')
        success_count += 1
    except Exception as e:
        print(f'❌ {pkg_name}: {e}')

print(f'')
print(f'📊 成功率: {success_count}/{total_count} ({success_count/total_count*100:.1f}%)')

if success_count >= 5:
    print('🎉 燧原环境可用！可以尝试训练!')
    sys.exit(0)
else:
    print('❌ 仍有问题，需要进一步调试')
    sys.exit(1)
"

RESULT=$?

echo ""
if [ $RESULT -eq 0 ]; then
    echo "🎉 燧原包修复完成！"
    echo ""
    echo "🚀 现在可以尝试训练："
    echo "bash train_ontothink_enflame_official.sh"
else
    echo "❌ 修复不完整，需要进一步调试"
fi
