#!/bin/bash
# 完整的燧原环境配置脚本

echo "🚀 完整燧原环境配置"
echo "========================================"

# 1. 首先尝试运行燧原官方安装脚本
echo "🔧 步骤1: 运行燧原官方依赖安装..."
ENFLAME_INSTALL_SCRIPT="/installer/topsrider_extracted/TopsRider_installer/ai_development_toolkit/distributed/llm_scripts_1.0.40/install_for_llm_scripts.sh"

if [ -f "$ENFLAME_INSTALL_SCRIPT" ]; then
    echo "✅ 找到燧原安装脚本: $ENFLAME_INSTALL_SCRIPT"
    
    # 切换到脚本目录并运行
    cd "$(dirname "$ENFLAME_INSTALL_SCRIPT")"
    echo "📁 当前目录: $(pwd)"
    
    # 设置燧原环境变量
    export ENFLAME_ENABLE_EFP=true
    export ENFLAME_PT_ENABLE_HBM_INPLACE=true
    export OMP_NUM_THREADS=5
    export ECCL_MAX_NCHANNELS=2
    export ENFLAME_UMD_FLAGS="mem_alloc_retry_times=1"
    
    echo "🔧 运行燧原安装脚本..."
    bash install_for_llm_scripts.sh
    
    if [ $? -eq 0 ]; then
        echo "✅ 燧原依赖安装成功"
    else
        echo "⚠️  燧原依赖安装有警告，继续手动安装..."
    fi
else
    echo "❌ 未找到燧原安装脚本，使用手动安装"
fi

# 2. 手动安装必要的Python包
echo ""
echo "🔧 步骤2: 手动安装Python依赖..."

# 返回项目目录
cd /workspace/code/OntoThink_V4

# 使用清华源安装，更稳定
echo "📦 安装transformers..."
pip3 install transformers==4.30.2 -i https://pypi.tuna.tsinghua.edu.cn/simple/ --trusted-host pypi.tuna.tsinghua.edu.cn

echo "📦 安装tokenizers..."
pip3 install tokenizers==0.13.3 -i https://pypi.tuna.tsinghua.edu.cn/simple/ --trusted-host pypi.tuna.tsinghua.edu.cn

echo "📦 安装accelerate..."
pip3 install accelerate==0.21.0 -i https://pypi.tuna.tsinghua.edu.cn/simple/ --trusted-host pypi.tuna.tsinghua.edu.cn

echo "📦 安装datasets..."
pip3 install datasets==2.14.4 -i https://pypi.tuna.tsinghua.edu.cn/simple/ --trusted-host pypi.tuna.tsinghua.edu.cn

echo "📦 安装sentencepiece..."
pip3 install sentencepiece==0.1.99 -i https://pypi.tuna.tsinghua.edu.cn/simple/ --trusted-host pypi.tuna.tsinghua.edu.cn

echo "📦 安装其他依赖..."
pip3 install numpy pandas loguru tqdm -i https://pypi.tuna.tsinghua.edu.cn/simple/ --trusted-host pypi.tuna.tsinghua.edu.cn

# 3. 验证安装
echo ""
echo "🔧 步骤3: 验证环境配置..."

python3 -c "
import sys
print('🐍 Python版本:', sys.version)
print('📁 Python路径:', sys.executable)
print()

# 检查关键包
packages = {
    'transformers': 'transformers',
    'tokenizers': 'tokenizers', 
    'accelerate': 'accelerate',
    'datasets': 'datasets',
    'sentencepiece': 'sentencepiece',
    'numpy': 'numpy',
    'pandas': 'pandas',
    'torch': 'torch',
    'ptex': 'ptex'
}

print('📦 包检查结果:')
for name, module in packages.items():
    try:
        mod = __import__(module)
        if hasattr(mod, '__version__'):
            print(f'  ✅ {name}: {mod.__version__}')
        else:
            print(f'  ✅ {name}: 已安装')
    except ImportError:
        print(f'  ❌ {name}: 未安装')

print()
print('🎉 环境检查完成！')
"

echo ""
echo "✅ 燧原环境配置完成！"
echo ""
echo "🚀 现在可以重新尝试训练："
echo "   python3 enflame_training/scripts/train_ontothink_enflame.py --step full"
echo ""
echo "💡 如果仍有问题，请检查:"
echo "   1. 燧原驱动是否正确安装"
echo "   2. 环境变量是否正确设置"
echo "   3. GPU资源是否可用"
