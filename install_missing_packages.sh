#!/bin/bash

# 🔧 安装缺失的燧原包
# 安装collie_lm和sentencepiece
# ===========================

echo "🔧 安装缺失的燧原包"
echo "collie_lm 和 sentencepiece"
echo "=========================="

echo ""
echo "🎯 从服务器安装缺失的包"
echo "========================"

# 服务器上的燧原目录
SERVER_ENFLAME_ROOT="/installer/topsrider_extracted/TopsRider_installer/ai_development_toolkit"

echo ""
echo "📦 1. 安装 collie_lm"
echo "====================="

COLLIE_WHL="$SERVER_ENFLAME_ROOT/distributed/collie_lm-1.0.6.dev0+gcu.38-py3-none-any.whl"

if [ -f "$COLLIE_WHL" ]; then
    echo "✅ 找到collie_lm: $COLLIE_WHL"
    echo "🔧 安装 collie_lm..."
    
    pip3 install "$COLLIE_WHL" --force-reinstall --no-deps --disable-pip-version-check
    
    echo "🧪 测试collie_lm导入:"
    python3 -c "
try:
    import collie_lm
    print('✅ collie_lm 导入成功')
    print('collie_lm路径:', collie_lm.__file__)
except ImportError as e:
    print('❌ collie_lm 导入失败 (ImportError):', e)
    # 尝试导入collie (有时包名和导入名不同)
    try:
        import collie
        print('✅ collie 导入成功 (可能导入名是collie)')
        print('collie路径:', collie.__file__)
    except ImportError as e2:
        print('❌ collie 也导入失败:', e2)
except Exception as e:
    print('❌ collie_lm 导入失败 (其他错误):', e)
    import traceback
    traceback.print_exc()
"
else
    echo "❌ 未找到collie_lm.whl文件: $COLLIE_WHL"
    echo "📍 尝试查找文件..."
    find /installer/topsrider_extracted/ -name "*collie*" -type f 2>/dev/null | head -5
fi

echo ""
echo "📦 2. 安装 sentencepiece"
echo "========================"

echo "🔧 安装标准版本的sentencepiece..."
# sentencepiece不在燧原包中，使用标准版本
pip3 install sentencepiece==0.1.99 --force-reinstall --no-deps --disable-pip-version-check

echo "🧪 测试sentencepiece导入:"
python3 -c "
try:
    import sentencepiece
    print('✅ sentencepiece 导入成功, 版本:', sentencepiece.__version__)
except Exception as e:
    print('❌ sentencepiece 导入失败:', e)
    import traceback
    traceback.print_exc()
"

echo ""
echo "🔍 3. 最终验证"
echo "=============="

echo "🧪 验证所有核心包:"
python3 -c "
packages = [
    ('torch', 'torch'),
    ('ptex', 'ptex'),
    ('collie_lm', 'collie_lm'),
    ('collie', 'collie'),  # 备选导入名
    ('deepspeed', 'deepspeed'),
    ('transformers', 'transformers'),
    ('accelerate', 'accelerate'),
    ('peft', 'peft'),
    ('sentencepiece', 'sentencepiece')
]

success_count = 0
important_packages = ['torch', 'ptex', 'deepspeed', 'transformers', 'sentencepiece']
important_success = 0

print('📦 包导入测试结果:')
for pkg_name, import_name in packages:
    try:
        module = __import__(import_name)
        version = getattr(module, '__version__', 'unknown')
        print(f'✅ {pkg_name}: {version}')
        success_count += 1
        if pkg_name in important_packages:
            important_success += 1
    except Exception as e:
        print(f'❌ {pkg_name}: {e}')

print(f'')
print(f'📊 总体成功率: {success_count}/{len(packages)}')
print(f'📊 核心包成功率: {important_success}/{len(important_packages)}')

# 特别检查collie相关包
print(f'')
print('🔍 collie包详细检查:')
for name in ['collie_lm', 'collie']:
    try:
        module = __import__(name)
        print(f'✅ {name} 可导入')
        if hasattr(module, '__file__'):
            print(f'   路径: {module.__file__}')
        if hasattr(module, '__version__'):
            print(f'   版本: {module.__version__}')
        break
    except:
        print(f'❌ {name} 无法导入')

if important_success >= 4:  # 至少4个核心包成功
    print(f'')
    print('🎉 燧原环境基本可用!')
    print('🚀 可以尝试训练: bash train_ontothink_enflame_official.sh')
else:
    print(f'')
    print('❌ 仍有核心包缺失，需要进一步排查')
"

echo ""
echo "🎉 缺失包安装完成！"
echo ""
echo "📋 如果核心包都可用，现在可以运行："
echo "bash check_enflame_status.sh  # 再次检查状态"
echo "bash train_ontothink_enflame_official.sh  # 开始训练"
