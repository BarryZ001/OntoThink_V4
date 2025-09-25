#!/bin/bash

# 🔧 修复numpy版本兼容性问题
# 解决 np.object 弃用错误
# ============================

echo "🔧 修复numpy版本兼容性问题"
echo "解决 np.object 弃用错误"
echo "=========================="

echo ""
echo "🎯 问题分析："
echo "- 错误：module 'numpy' has no attribute 'object'"
echo "- 原因：numpy 1.24.4 版本中 np.object 已被弃用"
echo "- 影响：tensorboard和燧原包无法正常工作"

echo ""
echo "📦 1. 降级numpy版本"
echo "==================="

echo "🔧 降级到numpy 1.20.3 (兼容版本)..."
pip3 install numpy==1.20.3 --force-reinstall --no-deps --disable-pip-version-check

echo "🧪 测试numpy版本:"
python3 -c "
import numpy as np
print('✅ numpy 版本:', np.__version__)

# 测试np.object是否可用
try:
    test_obj = np.object
    print('✅ np.object 可用')
except AttributeError:
    print('❌ np.object 不可用')
except Exception as e:
    print('❌ np.object 测试失败:', e)
"

echo ""
echo "📦 2. 重新安装可能受影响的包"
echo "=========================="

echo "🔧 重新安装tensorboard..."
pip3 install tensorboard==2.14.0 --force-reinstall --no-deps --disable-pip-version-check

echo "🔧 重新安装scipy (如果需要)..."
pip3 install scipy==1.10.1 --force-reinstall --no-deps --disable-pip-version-check

echo ""
echo "🧪 3. 测试关键包导入"
echo "===================="

python3 -c "
import sys

# 测试关键包
test_packages = [
    'numpy',
    'torch', 
    'ptex',
    'collie',
    'transformers',
    'accelerate',
    'peft',
    'deepspeed',
    'sentencepiece',
    'tensorboard'
]

success_count = 0
critical_packages = ['numpy', 'torch', 'ptex', 'collie', 'transformers']
critical_success = 0

print('🧪 关键包导入测试:')
for pkg in test_packages:
    try:
        module = __import__(pkg)
        version = getattr(module, '__version__', 'unknown')
        print(f'✅ {pkg}: {version}')
        success_count += 1
        if pkg in critical_packages:
            critical_success += 1
    except Exception as e:
        print(f'❌ {pkg}: {e}')

print(f'')
print(f'📊 总体成功率: {success_count}/{len(test_packages)}')
print(f'📊 关键包成功率: {critical_success}/{len(critical_packages)}')

if critical_success >= 4:
    print('🎉 关键包都可用，训练环境应该正常了!')
else:
    print('❌ 关键包仍有问题')
"

echo ""
echo "🧪 4. 专门测试tensorboard兼容性"
echo "============================="

python3 -c "
try:
    import tensorboard
    print('✅ tensorboard 导入成功')
    
    # 测试可能有问题的模块
    from tensorboard.compat.tensorflow_stub import dtypes
    print('✅ tensorboard.compat.tensorflow_stub.dtypes 导入成功')
    
    from torch.utils.tensorboard import SummaryWriter
    print('✅ torch.utils.tensorboard.SummaryWriter 导入成功')
    
except Exception as e:
    print('❌ tensorboard 相关导入失败:', e)
    import traceback
    traceback.print_exc()
"

echo ""
echo "🚀 5. 建议的下一步"
echo "=================="

echo "💡 修复完成后的测试步骤:"
echo "1. 再次运行训练：bash train_ontothink_enflame_official.sh"
echo "2. 如果仍有numpy问题，可以尝试更低版本：numpy==1.19.5"
echo "3. 或者禁用tensorboard相关功能"

echo ""
echo "🔧 修复完成！"
echo ""
echo "🚀 现在可以尝试："
echo "bash train_ontothink_enflame_official.sh"
