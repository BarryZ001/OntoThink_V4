#!/bin/bash
# 安装燧原环境缺失的依赖

echo "🔧 安装燧原环境缺失的依赖"
echo "========================================"

# 检查当前Python环境
echo "🐍 当前Python版本:"
python3 --version

echo "📦 检查已安装的包:"
python3 -c "import sys; print('Python路径:', sys.executable)"

# 安装基础依赖
echo "📦 安装transformers和相关依赖..."
pip3 install transformers==4.30.2 -i https://pypi.tuna.tsinghua.edu.cn/simple/

echo "📦 安装其他必要依赖..."
pip3 install tokenizers==0.13.3 -i https://pypi.tuna.tsinghua.edu.cn/simple/
pip3 install accelerate==0.21.0 -i https://pypi.tuna.tsinghua.edu.cn/simple/
pip3 install datasets==2.14.4 -i https://pypi.tuna.tsinghua.edu.cn/simple/
pip3 install sentencepiece==0.1.99 -i https://pypi.tuna.tsinghua.edu.cn/simple/

# 检查安装结果
echo "🔍 验证安装结果:"
python3 -c "
try:
    import transformers
    print('✅ transformers version:', transformers.__version__)
    
    import tokenizers
    print('✅ tokenizers version:', tokenizers.__version__)
    
    import accelerate
    print('✅ accelerate version:', accelerate.__version__)
    
    import datasets
    print('✅ datasets version:', datasets.__version__)
    
    import sentencepiece
    print('✅ sentencepiece version:', sentencepiece.__version__)
    
    # 检查燧原相关包
    try:
        import torch
        print('✅ torch version:', torch.__version__)
    except ImportError:
        print('❌ torch 未安装')
    
    try:
        import ptex
        print('✅ ptex (燧原扩展) 可用')
    except ImportError:
        print('❌ ptex (燧原扩展) 不可用')
        
    print('\\n🎉 依赖安装验证完成！')
    
except ImportError as e:
    print(f'❌ 导入失败: {e}')
"

echo ""
echo "✅ 燧原环境依赖安装完成！"
echo "💡 现在可以重新尝试训练："
echo "   python3 enflame_training/scripts/train_ontothink_enflame.py --step full"
