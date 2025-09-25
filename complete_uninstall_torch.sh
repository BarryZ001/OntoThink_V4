#!/bin/bash

# 🗑️ 完全卸载torch相关包脚本
# 为手动安装燧原官方定制包做准备
# =====================================

echo "🗑️ 完全卸载torch相关包"
echo "为手动安装燧原官方定制包做准备"
echo "=================================="

echo ""
echo "🔍 1. 检查当前安装的torch相关包"
echo "======================================"

echo "📦 当前安装的torch相关包:"
pip3 list | grep -i -E "(torch|pytorch|tensor|cuda|gpu|gcu|ptex|collie|deepspeed|transformers|accelerate|peft|horovod)"

echo ""
echo "🗑️ 2. 卸载所有torch相关包"
echo "=========================="

echo "🧹 卸载torch系列包..."
pip3 uninstall -y torch torchvision torchaudio torch-audio torch-vision 2>/dev/null || true

echo "🧹 卸载燧原相关包..."
pip3 uninstall -y torch-gcu ptex collie-lm collie_lm deepspeed 2>/dev/null || true

echo "🧹 卸载transformers系列包..."
pip3 uninstall -y transformers accelerate peft 2>/dev/null || true

echo "🧹 卸载其他深度学习框架..."
pip3 uninstall -y tensorflow tensorflow-gpu horovod 2>/dev/null || true

echo ""
echo "🗂️ 3. 清理残留文件和目录"
echo "========================="

echo "🧹 清理Python site-packages中的残留文件..."

# 清理torch相关目录
sudo rm -rf /usr/local/lib/python3.8/dist-packages/torch*
sudo rm -rf /usr/local/lib/python3.8/dist-packages/pytorch*

# 清理燧原相关目录
sudo rm -rf /usr/local/lib/python3.8/dist-packages/ptex*
sudo rm -rf /usr/local/lib/python3.8/dist-packages/collie*
sudo rm -rf /usr/local/lib/python3.8/dist-packages/deepspeed*

# 清理transformers相关目录
sudo rm -rf /usr/local/lib/python3.8/dist-packages/transformers*
sudo rm -rf /usr/local/lib/python3.8/dist-packages/accelerate*
sudo rm -rf /usr/local/lib/python3.8/dist-packages/peft*

# 清理horovod
sudo rm -rf /usr/local/lib/python3.8/dist-packages/horovod*

# 清理所有相关的.dist-info目录
sudo rm -rf /usr/local/lib/python3.8/dist-packages/torch*.dist-info/
sudo rm -rf /usr/local/lib/python3.8/dist-packages/ptex*.dist-info/
sudo rm -rf /usr/local/lib/python3.8/dist-packages/collie*.dist-info/
sudo rm -rf /usr/local/lib/python3.8/dist-packages/deepspeed*.dist-info/
sudo rm -rf /usr/local/lib/python3.8/dist-packages/transformers*.dist-info/
sudo rm -rf /usr/local/lib/python3.8/dist-packages/accelerate*.dist-info/
sudo rm -rf /usr/local/lib/python3.8/dist-packages/peft*.dist-info/
sudo rm -rf /usr/local/lib/python3.8/dist-packages/horovod*.dist-info/

echo "✅ 残留文件清理完成"

echo ""
echo "🧹 4. 清理pip缓存"
echo "=================="

echo "🗑️ 清理pip缓存..."
pip3 cache purge

echo "✅ pip缓存清理完成"

echo ""
echo "🔍 5. 验证卸载结果"
echo "=================="

echo "📦 检查是否还有torch相关包:"
REMAINING_PACKAGES=$(pip3 list | grep -i -E "(torch|pytorch|tensor|cuda|gpu|gcu|ptex|collie|deepspeed|transformers|accelerate|peft|horovod)" || true)

if [ -z "$REMAINING_PACKAGES" ]; then
    echo "✅ 所有torch相关包已完全卸载"
else
    echo "⚠️ 还有以下包未完全卸载:"
    echo "$REMAINING_PACKAGES"
fi

echo ""
echo "🧪 测试导入结果:"
python3 -c "
packages_to_test = ['torch', 'ptex', 'collie_lm', 'deepspeed', 'transformers', 'accelerate', 'peft']
all_clean = True

for pkg in packages_to_test:
    try:
        __import__(pkg)
        print(f'⚠️  {pkg} 仍然可以导入')
        all_clean = False
    except ImportError:
        print(f'✅ {pkg} 已完全移除')
    except Exception as e:
        print(f'✅ {pkg} 导入失败 (正常): {e}')

if all_clean:
    print('')
    print('🎉 环境完全清理干净！')
else:
    print('')
    print('⚠️  环境未完全清理，可能需要手动处理')
"

echo ""
echo "📋 6. 燧原官方包安装指南"
echo "========================="

echo "🎯 现在您可以手动安装燧原官方定制包了！"
echo ""
echo "📍 燧原包位置:"
echo "   /installer/topsrider_extracted/TopsRider_installer/ai_development_toolkit/"
echo ""
echo "🔧 建议的安装顺序:"
echo "1. 基础框架:"
echo "   cd /installer/topsrider_extracted/TopsRider_installer/framework/"
echo "   pip3 install torch_gcu-*-py3.8-*.whl --force-reinstall --no-deps"
echo ""
echo "2. 燧原核心扩展:"
echo "   cd /installer/topsrider_extracted/TopsRider_installer/ai_development_toolkit/distributed/"
echo "   pip3 install ptex-*.whl --force-reinstall --no-deps"
echo ""
echo "3. 分布式训练:"
echo "   pip3 install deepspeed-*.whl --force-reinstall --no-deps"
echo "   pip3 install collie_lm-*.whl --force-reinstall --no-deps"
echo ""
echo "4. HuggingFace适配:"
echo "   cd /installer/topsrider_extracted/TopsRider_installer/ai_development_toolkit/huggingface-gcu/"
echo "   pip3 install transformers-*.whl --force-reinstall --no-deps"
echo "   pip3 install accelerate-*.whl --force-reinstall --no-deps"
echo "   pip3 install peft-*.whl --force-reinstall --no-deps"
echo ""
echo "💡 安装参数说明:"
echo "   --force-reinstall: 强制重新安装"
echo "   --no-deps: 不检查依赖，避免版本冲突"
echo ""
echo "🚀 安装完成后可以运行："
echo "   bash check_enflame_status.sh  # 检查安装状态"
echo "   bash train_ontothink_enflame_official.sh  # 开始训练"

echo ""
echo "🎉 环境清理完成！请按照上述指南手动安装燧原包。"
