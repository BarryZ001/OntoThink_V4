#!/bin/bash
# 燧原T20 GCU环境专用调试脚本
# 针对燧原硬件和软件栈的特殊检查

set -e

echo "🔥 燧原T20 GCU环境调试工具"
echo "专门针对燧原硬件和软件栈"
echo "========================================"

# 自动检测项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ONTOTHINK_ROOT="$SCRIPT_DIR"

echo "📁 项目根目录: $ONTOTHINK_ROOT"

echo ""
echo "🔍 1. 燧原T20硬件检查"
echo "----------------------------------------"

# 检查GCU设备
echo "🔥 GCU设备检查:"
if command -v nvidia-smi >/dev/null 2>&1; then
    echo "⚠️  检测到nvidia-smi (这是NVIDIA工具，应该使用燧原工具)"
fi

# 检查燧原设备信息
if [ -d "/dev" ]; then
    echo "📋 设备文件检查:"
    ls -la /dev/dtu* 2>/dev/null || echo "   未找到DTU设备文件"
    ls -la /dev/gcu* 2>/dev/null || echo "   未找到GCU设备文件"
fi

# 检查燧原驱动
echo ""
echo "🔥 燧原驱动检查:"
if [ -f "/usr/local/corex/bin/dtu-smi" ]; then
    echo "✅ 找到燧原DTU工具"
    /usr/local/corex/bin/dtu-smi 2>/dev/null || echo "   DTU工具运行失败"
elif [ -f "/usr/bin/dtu-smi" ]; then
    echo "✅ 找到燧原DTU工具"
    dtu-smi 2>/dev/null || echo "   DTU工具运行失败"
else
    echo "❌ 未找到燧原DTU工具"
fi

echo ""
echo "🔍 2. 燧原Python环境检查"
echo "----------------------------------------"

echo "🐍 燧原相关Python包检查:"
python3 -c "
import sys
import os

# 燧原特定包检查
enflame_packages = {
    'ptex': '燧原PyTorch扩展',
    'collie_lm': '燧原分布式训练框架', 
    'torch_gcu': '燧原PyTorch GCU版本',
    'deepspeed': '燧原优化版DeepSpeed'
}

print('📦 燧原软件栈检查:')
for pkg, desc in enflame_packages.items():
    try:
        module = __import__(pkg)
        version = getattr(module, '__version__', 'unknown')
        print(f'✅ {pkg}: {version} ({desc})')
    except ImportError:
        print(f'❌ {pkg}: 未安装 ({desc})')
    except Exception as e:
        print(f'⚠️  {pkg}: 导入异常 - {e}')

print()
print('📦 标准包检查:')
standard_packages = ['torch', 'transformers', 'accelerate', 'peft', 'sentencepiece']
for pkg in standard_packages:
    try:
        module = __import__(pkg)
        version = getattr(module, '__version__', 'unknown')
        print(f'✅ {pkg}: {version}')
    except ImportError:
        print(f'❌ {pkg}: 未安装')
    except Exception as e:
        print(f'⚠️  {pkg}: 导入异常 - {e}')
"

echo ""
echo "🔍 3. 燧原环境变量检查"
echo "----------------------------------------"

echo "🔥 燧原相关环境变量:"
env_vars=(
    "COREX_VISIBLE_DEVICES"
    "DTU_VISIBLE_DEVICES" 
    "GCU_VISIBLE_DEVICES"
    "ENFLAME_DEVICE_MODE"
    "PYTHONPATH"
    "LD_LIBRARY_PATH"
    "CUDA_VISIBLE_DEVICES"
)

for var in "${env_vars[@]}"; do
    value=$(printenv "$var" 2>/dev/null || echo "未设置")
    echo "   $var: $value"
done

echo ""
echo "🔍 4. 燧原PyTorch GCU功能测试"
echo "----------------------------------------"

echo "🧪 测试燧原PyTorch GCU功能:"
python3 -c "
import sys

try:
    import torch
    print(f'✅ PyTorch版本: {torch.__version__}')
    
    # 检查是否为燧原版本
    if hasattr(torch, 'gcu'):
        print('✅ 检测到燧原GCU支持')
        
        # 检查GCU可用性
        try:
            if torch.gcu.is_available():
                device_count = torch.gcu.device_count()
                print(f'✅ GCU可用，设备数量: {device_count}')
                
                # 获取设备信息
                for i in range(device_count):
                    try:
                        device_name = torch.gcu.get_device_name(i)
                        print(f'   GCU {i}: {device_name}')
                    except:
                        print(f'   GCU {i}: 信息获取失败')
                
                # 测试基本张量操作
                try:
                    x = torch.tensor([1, 2, 3]).to('gcu:0')
                    y = x + 1
                    print(f'✅ GCU张量操作测试成功: {y.cpu().tolist()}')
                except Exception as e:
                    print(f'❌ GCU张量操作失败: {e}')
                    
            else:
                print('❌ GCU不可用')
        except Exception as e:
            print(f'❌ GCU检查失败: {e}')
    else:
        print('❌ 未检测到燧原GCU支持，可能是标准PyTorch版本')
        
        # 检查CUDA作为对比
        if torch.cuda.is_available():
            print(f'⚠️  检测到CUDA支持 (这不是燧原GCU)')
        else:
            print('❌ 也没有CUDA支持')
            
except ImportError:
    print('❌ PyTorch未安装')
except Exception as e:
    print(f'❌ PyTorch检查失败: {e}')
"

echo ""
echo "🔍 5. 燧原分布式通信检查"
echo "----------------------------------------"

echo "🧪 测试燧原分布式功能:"
python3 -c "
try:
    import torch
    import torch.distributed as dist
    
    print('📡 分布式通信检查:')
    
    # 检查燧原特定的后端
    available_backends = []
    
    # 标准后端
    if dist.is_available():
        print('✅ torch.distributed 可用')
        
        backends = ['nccl', 'gloo', 'mpi']
        for backend in backends:
            if dist.is_backend_available(backend):
                available_backends.append(backend)
                print(f'✅ 后端可用: {backend}')
            else:
                print(f'❌ 后端不可用: {backend}')
    
    # 检查燧原特定通信库
    try:
        import eccl  # 燧原集合通信库
        print('✅ ECCL (燧原集合通信库) 可用')
    except ImportError:
        print('❌ ECCL 不可用')
    
    if not available_backends:
        print('❌ 没有可用的分布式后端')
    else:
        print(f'📊 可用后端: {available_backends}')
        
except Exception as e:
    print(f'❌ 分布式检查失败: {e}')
"

echo ""
echo "🔍 6. 燧原训练脚本兼容性检查"
echo "----------------------------------------"

# 查找燧原ChatGLM3脚本
CHATGLM3_SCRIPT_DIRS=(
    "${ONTOTHINK_ROOT}/FromEnflame/ai_development_toolkit/distributed/llm_scripts_1.0.40/finetuning/chatglm3"
    "/installer/topsrider_extracted/TopsRider_installer/ai_development_toolkit/distributed/llm_scripts_1.0.40/finetuning/chatglm3"
    "${ONTOTHINK_ROOT}/FromEnflame/distributed/llm_scripts_1.0.40/finetuning/chatglm3"
)

CHATGLM3_SCRIPT_DIR=""
for dir in "${CHATGLM3_SCRIPT_DIRS[@]}"; do
    if [ -d "$dir" ] && [ -f "$dir/finetune_chatglm3_for_multiturn.py" ]; then
        CHATGLM3_SCRIPT_DIR="$dir"
        echo "✅ 找到燧原ChatGLM3脚本: $dir"
        break
    fi
done

if [ -n "$CHATGLM3_SCRIPT_DIR" ]; then
    echo "🔍 分析燧原训练脚本..."
    
    # 检查脚本中的燧原特定导入
    echo "📦 脚本导入检查:"
    cd "$CHATGLM3_SCRIPT_DIR"
    
    grep -n "import.*ptex" finetune_chatglm3_for_multiturn.py 2>/dev/null || echo "   未找到ptex导入"
    grep -n "import.*collie" finetune_chatglm3_for_multiturn.py 2>/dev/null || echo "   未找到collie导入"
    grep -n "gcu" finetune_chatglm3_for_multiturn.py 2>/dev/null || echo "   未找到GCU相关代码"
    
    # 检查启动方式
    echo ""
    echo "🚀 训练启动方式检查:"
    if grep -q "torch.distributed.launch" finetune_chatglm3_for_multiturn.py 2>/dev/null; then
        echo "   使用标准torch.distributed.launch"
    fi
    
    if grep -q "torchrun" finetune_chatglm3_for_multiturn.py 2>/dev/null; then
        echo "   使用torchrun"
    fi
    
else
    echo "❌ 未找到燧原ChatGLM3训练脚本"
fi

echo ""
echo "🔍 7. 燧原模型兼容性测试"
echo "----------------------------------------"

MODEL_PATH="${ONTOTHINK_ROOT}/enflame_training/models/THUDM/chatglm3-6b"

if [ -d "$MODEL_PATH" ]; then
    echo "🧪 测试燧原环境下的模型加载..."
    
    cd "$MODEL_PATH"
    python3 -c "
import sys
import os

try:
    print('📥 在燧原环境测试模型加载...')
    
    # 先测试基础导入
    from transformers import AutoTokenizer, AutoConfig
    print('✅ transformers 导入成功')
    
    # 加载tokenizer
    tokenizer = AutoTokenizer.from_pretrained('.', trust_remote_code=True)
    print('✅ tokenizer 加载成功')
    
    # 加载配置
    config = AutoConfig.from_pretrained('.', trust_remote_code=True)
    print('✅ 模型配置加载成功')
    
    # 测试在GCU设备上的兼容性
    try:
        import torch
        if hasattr(torch, 'gcu') and torch.gcu.is_available():
            print('🔥 测试GCU设备兼容性...')
            
            # 创建一个简单的张量测试
            device = 'gcu:0'
            test_tensor = torch.randn(2, 3).to(device)
            print(f'✅ GCU张量创建成功: {test_tensor.shape}')
            
        else:
            print('⚠️  GCU不可用，使用CPU测试')
            
    except Exception as e:
        print(f'❌ GCU测试失败: {e}')
    
    print('✅ 基础模型兼容性测试通过')
    
except Exception as e:
    print(f'❌ 模型兼容性测试失败: {e}')
    import traceback
    traceback.print_exc()
"
else
    echo "❌ 模型目录不存在: $MODEL_PATH"
fi

echo ""
echo "========================================"
echo "🔧 燧原T20 GCU调试总结"
echo ""
echo "💡 常见燧原T20问题和解决方案:"
echo ""
echo "1. 🔥 GCU驱动问题:"
echo "   - 检查DTU/GCU驱动是否正确安装"
echo "   - 确认设备文件(/dev/dtu*或/dev/gcu*)存在"
echo "   - 重启燧原驱动服务"
echo ""
echo "2. 🐍 Python环境问题:"
echo "   - 确保使用燧原优化版本的PyTorch (torch_gcu)"
echo "   - 安装燧原特定包: ptex, collie_lm"
echo "   - 检查pydantic版本兼容性"
echo ""
echo "3. 🚀 分布式训练问题:"
echo "   - 使用燧原特定的分布式启动方式"
echo "   - 检查ECCL通信库"
echo "   - 设置正确的环境变量"
echo ""
echo "4. 🔧 建议的修复步骤:"
echo "   - bash $ONTOTHINK_ROOT/setup_enflame_complete.sh"
echo "   - bash $ONTOTHINK_ROOT/test_single_gcu_training.sh"
echo "   - 检查燧原官方文档和示例"
echo ""
echo "📋 如需进一步帮助，请分享此脚本的完整输出"
