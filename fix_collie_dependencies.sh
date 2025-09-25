#!/bin/bash

# 🔧 修复collie_lm依赖问题
# 安装einops和其他collie_lm需要的依赖
# =======================================

echo "🔧 修复collie_lm依赖问题"
echo "安装einops和其他必要依赖"
echo "=========================="

echo ""
echo "🎯 问题分析："
echo "- collie_lm 已安装但导入失败"
echo "- 错误：No module named 'einops'"
echo "- 需要安装einops依赖"

echo ""
echo "📦 1. 安装einops"
echo "=================="

echo "🔧 安装 einops==0.6.1..."
pip3 install einops==0.6.1 --force-reinstall --no-deps --disable-pip-version-check

echo "🧪 测试einops导入:"
python3 -c "
try:
    import einops
    print('✅ einops 导入成功, 版本:', einops.__version__)
except Exception as e:
    print('❌ einops 导入失败:', e)
"

echo ""
echo "📦 2. 安装其他可能的依赖"
echo "========================="

echo "🔧 安装collie_lm可能需要的其他依赖..."

# 从燧原requirements文件看到的依赖
pip3 install --no-deps --disable-pip-version-check \
    tqdm==4.66.1 \
    protobuf==3.20.1 \
    numpy==1.24.4 \
    scipy==1.10.1 \
    rich \
    fire==0.5.0

echo ""
echo "🧪 3. 测试collie_lm导入"
echo "======================="

echo "🔍 尝试导入collie_lm:"
python3 -c "
try:
    import collie_lm
    print('✅ collie_lm 导入成功!')
    if hasattr(collie_lm, '__version__'):
        print('   版本:', collie_lm.__version__)
    if hasattr(collie_lm, '__file__'):
        print('   路径:', collie_lm.__file__)
except ImportError as e:
    print('❌ collie_lm 导入失败 (ImportError):', e)
    print('   尝试导入collie...')
    try:
        import collie
        print('✅ collie 导入成功!')
        if hasattr(collie, '__version__'):
            print('   版本:', collie.__version__)
        if hasattr(collie, '__file__'):
            print('   路径:', collie.__file__)
    except Exception as e2:
        print('❌ collie 也导入失败:', e2)
except Exception as e:
    print('❌ collie_lm 导入失败 (其他错误):', e)
    import traceback
    traceback.print_exc()
"

echo ""
echo "📦 4. 检查collie包的实际安装位置"
echo "==============================="

echo "🔍 查找collie相关文件:"
find /usr/local/lib/python3.8/dist-packages/ -name "*collie*" -type d 2>/dev/null || echo "未找到collie目录"

echo ""
echo "🔍 检查pip安装记录:"
pip3 show collie-lm 2>/dev/null || echo "pip show 失败"

echo ""
echo "🔍 列出site-packages中的相关目录:"
ls -la /usr/local/lib/python3.8/dist-packages/ | grep -i collie || echo "未找到collie相关目录"

echo ""
echo "🧪 5. 最终全面测试"
echo "=================="

python3 -c "
import sys
print('🐍 Python路径:')
for path in sys.path:
    print(f'  {path}')

print('')
print('📦 最终包导入测试:')

packages = [
    ('torch', 'torch'),
    ('ptex', 'ptex'),
    ('einops', 'einops'),
    ('collie_lm', 'collie_lm'),
    ('collie', 'collie'),
    ('deepspeed', 'deepspeed'),
    ('transformers', 'transformers'),
    ('accelerate', 'accelerate'),
    ('peft', 'peft'),
    ('sentencepiece', 'sentencepiece')
]

success_count = 0
critical_packages = ['torch', 'ptex', 'deepspeed', 'transformers', 'sentencepiece']
critical_success = 0
collie_available = False

for pkg_name, import_name in packages:
    try:
        module = __import__(import_name)
        version = getattr(module, '__version__', 'unknown')
        print(f'✅ {pkg_name}: {version}')
        success_count += 1
        if pkg_name in critical_packages:
            critical_success += 1
        if pkg_name in ['collie_lm', 'collie']:
            collie_available = True
    except Exception as e:
        print(f'❌ {pkg_name}: {e}')

print(f'')
print(f'📊 总体成功率: {success_count}/{len(packages)}')
print(f'📊 关键包成功率: {critical_success}/{len(critical_packages)}')
print(f'📊 collie可用: {collie_available}')

if critical_success >= 4:  # 至少4个关键包
    print(f'')
    print('🎉 燧原环境基本可用!')
    if collie_available:
        print('✅ collie也可用，环境完整!')
    else:
        print('⚠️  collie暂不可用，但可以尝试训练')
    print('🚀 可以运行: bash train_ontothink_enflame_official.sh')
else:
    print(f'')
    print('❌ 关键包不足，需要进一步调试')
"

echo ""
echo "🔧 修复完成！"
echo ""
echo "💡 如果collie_lm仍然不可用，可能的解决方案："
echo "1. 手动解压collie_lm.whl并检查内容"
echo "2. 检查是否有其他隐藏的依赖"
echo "3. 即使collie_lm不可用，其他包足够进行基本训练"
echo ""
echo "🚀 建议现在尝试训练："
echo "bash train_ontothink_enflame_official.sh"
