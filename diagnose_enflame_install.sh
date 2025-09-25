#!/bin/bash

# 🔍 燧原T20安装诊断脚本
# 详细检查燧原包的安装状态和问题
# =====================================

echo "🔍 燧原T20安装详细诊断"
echo "============================="

echo ""
echo "🐍 1. Python环境信息"
echo "------------------------"
echo "Python版本: $(python3 --version)"
echo "Python路径: $(which python3)"
echo "pip版本: $(pip3 --version)"

echo ""
echo "📦 2. 检查已安装的包"
echo "------------------------"
echo "🔍 查看所有已安装的包:"
pip3 list | grep -E "(ptex|collie|deepspeed|transformers|accelerate|peft|torch)"

echo ""
echo "🔍 详细检查每个燧原包的安装状态:"

# 检查ptex
echo ""
echo "📋 ptex 详细检查:"
pip3 show ptex 2>/dev/null && echo "✅ ptex 包信息正常" || echo "❌ ptex 包未正确安装"

# 检查collie_lm
echo ""
echo "📋 collie_lm 详细检查:"
pip3 show collie-lm 2>/dev/null && echo "✅ collie-lm 包信息正常" || echo "❌ collie-lm 包未正确安装"

# 检查deepspeed
echo ""
echo "📋 deepspeed 详细检查:"
pip3 show deepspeed 2>/dev/null && echo "✅ deepspeed 包信息正常" || echo "❌ deepspeed 包未正确安装"

# 检查transformers
echo ""
echo "📋 transformers 详细检查:"
pip3 show transformers 2>/dev/null && echo "✅ transformers 包信息正常" || echo "❌ transformers 包未正确安装"

# 检查torch
echo ""
echo "📋 torch 详细检查:"
pip3 show torch 2>/dev/null && echo "✅ torch 包信息正常" || echo "❌ torch 包未正确安装"

echo ""
echo "🔍 3. 检查Python导入路径"
echo "------------------------"
python3 -c "
import sys
print('Python sys.path:')
for path in sys.path:
    print(f'  {path}')
"

echo ""
echo "🔍 4. 尝试手动导入每个包"
echo "------------------------"

echo "🔧 尝试导入 torch:"
python3 -c "
try:
    import torch
    print('✅ torch 导入成功, 版本:', torch.__version__)
    print('   torch路径:', torch.__file__)
except Exception as e:
    print('❌ torch 导入失败:', e)
    import traceback
    traceback.print_exc()
"

echo ""
echo "🔧 尝试导入 ptex:"
python3 -c "
try:
    import ptex
    print('✅ ptex 导入成功')
    print('   ptex路径:', ptex.__file__)
except Exception as e:
    print('❌ ptex 导入失败:', e)
    import traceback
    traceback.print_exc()
"

echo ""
echo "🔧 尝试导入 collie_lm:"
python3 -c "
try:
    import collie_lm
    print('✅ collie_lm 导入成功')
    print('   collie_lm路径:', collie_lm.__file__)
except Exception as e:
    print('❌ collie_lm 导入失败:', e)
    import traceback
    traceback.print_exc()
"

echo ""
echo "🔍 5. 检查燧原包文件是否存在"
echo "------------------------"
echo "🔍 查找已安装的燧原相关文件:"
find /usr/local/lib/python3.8/dist-packages/ -name "*ptex*" -o -name "*collie*" -o -name "*torch*" | head -20

echo ""
echo "🔍 6. 手动检查.whl安装"
echo "------------------------"
ENFLAME_ROOT="/installer/topsrider_extracted/TopsRider_installer/ai_development_toolkit"

echo "🔍 检查燧原.whl文件是否存在:"
if [ -d "$ENFLAME_ROOT/distributed" ]; then
    echo "📦 distributed 目录中的.whl文件:"
    ls -la "$ENFLAME_ROOT/distributed"/*.whl
else
    echo "❌ distributed 目录不存在"
fi

if [ -d "$ENFLAME_ROOT/huggingface-gcu" ]; then
    echo ""
    echo "📦 huggingface-gcu 目录中的.whl文件:"
    ls -la "$ENFLAME_ROOT/huggingface-gcu"/*.whl
else
    echo "❌ huggingface-gcu 目录不存在"
fi

echo ""
echo "🔍 7. 建议修复方案"
echo "------------------------"
echo "💡 基于诊断结果的建议:"
echo "1. 如果torch未安装，需要先安装torch"
echo "2. 如果ptex导入失败，可能需要先安装torch_gcu"
echo "3. 如果包显示已安装但导入失败，可能是依赖问题"
echo "4. 建议尝试单独安装每个包并测试"

echo ""
echo "🚀 可以尝试的修复命令:"
echo "bash manual_install_each_package.sh"
