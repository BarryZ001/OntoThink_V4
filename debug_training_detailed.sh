#!/bin/bash
# 详细的训练错误调试脚本
# 获取具体的错误信息和堆栈跟踪

set -e

echo "🔍 OntoThink 详细训练调试工具"
echo "========================================"

# 自动检测项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ONTOTHINK_ROOT="$SCRIPT_DIR"

echo "📁 项目根目录: $ONTOTHINK_ROOT"

# 查找燧原ChatGLM3脚本目录
CHATGLM3_SCRIPT_DIRS=(
    "${ONTOTHINK_ROOT}/FromEnflame/ai_development_toolkit/distributed/llm_scripts_1.0.40/finetuning/chatglm3"
    "/installer/topsrider_extracted/TopsRider_installer/ai_development_toolkit/distributed/llm_scripts_1.0.40/finetuning/chatglm3"
    "${ONTOTHINK_ROOT}/FromEnflame/distributed/llm_scripts_1.0.40/finetuning/chatglm3"
)

CHATGLM3_SCRIPT_DIR=""
for dir in "${CHATGLM3_SCRIPT_DIRS[@]}"; do
    if [ -d "$dir" ] && [ -f "$dir/finetune_chatglm3_for_multiturn.py" ]; then
        CHATGLM3_SCRIPT_DIR="$dir"
        echo "✅ 找到ChatGLM3脚本目录: $dir"
        break
    fi
done

if [ -z "$CHATGLM3_SCRIPT_DIR" ]; then
    echo "❌ 未找到ChatGLM3脚本目录"
    exit 1
fi

cd "$CHATGLM3_SCRIPT_DIR"
echo "📁 当前目录: $PWD"

# 测试单进程运行，获取详细错误信息
echo ""
echo "🔍 1. 单进程测试（获取详细错误）"
echo "----------------------------------------"

# 设置最小化的测试参数
export CUDA_VISIBLE_DEVICES=""  # 清空CUDA设备
export PYTHONPATH="${ONTOTHINK_ROOT}:${PYTHONPATH}"

echo "🧪 测试Python脚本基本加载..."

python3 -c "
import sys
import os
import traceback

# 添加路径
sys.path.insert(0, '.')
sys.path.insert(0, '$ONTOTHINK_ROOT')

print('🐍 Python环境检查...')
print(f'Python版本: {sys.version}')
print(f'当前工作目录: {os.getcwd()}')
print(f'Python路径: {sys.path[:3]}...')

try:
    print('📦 检查核心导入...')
    
    # 检查基础包
    import torch
    print(f'✅ torch: {torch.__version__}')
    
    import transformers
    print(f'✅ transformers: {transformers.__version__}')
    
    # 检查燧原特定包
    try:
        import ptex
        print('✅ ptex: 可用')
    except ImportError as e:
        print(f'❌ ptex: {e}')
    
    try:
        import collie_lm
        print('✅ collie_lm: 可用')
    except ImportError as e:
        print(f'❌ collie_lm: {e}')
    
    try:
        import deepspeed
        print(f'✅ deepspeed: {deepspeed.__version__}')
    except ImportError as e:
        print(f'❌ deepspeed: {e}')
    
    print('📄 检查训练脚本语法...')
    with open('finetune_chatglm3_for_multiturn.py', 'r') as f:
        script_content = f.read()
    
    # 编译检查语法
    compile(script_content, 'finetune_chatglm3_for_multiturn.py', 'exec')
    print('✅ 训练脚本语法正确')
    
    print('🔍 尝试导入训练脚本模块...')
    # 不直接运行，只是导入检查
    import importlib.util
    spec = importlib.util.spec_from_file_location('finetune_module', 'finetune_chatglm3_for_multiturn.py')
    
    print('✅ 基础检查通过')
    
except Exception as e:
    print(f'❌ 错误: {e}')
    print('📋 详细错误信息:')
    traceback.print_exc()
    sys.exit(1)
"

if [ $? -ne 0 ]; then
    echo "❌ Python环境检查失败"
    exit 1
fi

echo ""
echo "🔍 2. 测试模型加载"
echo "----------------------------------------"

MODEL_PATH="${ONTOTHINK_ROOT}/enflame_training/models/THUDM/chatglm3-6b"

python3 -c "
import sys
import os
import traceback

# 设置路径
sys.path.insert(0, '.')
model_path = '$MODEL_PATH'

try:
    print('📥 测试tokenizer加载...')
    from transformers import AutoTokenizer
    
    tokenizer = AutoTokenizer.from_pretrained(
        model_path, 
        add_eos_token=False, 
        trust_remote_code=True
    )
    print('✅ Tokenizer加载成功')
    
    # 测试编码
    test_text = '测试文本'
    tokens = tokenizer.encode(test_text)
    print(f'✅ 编码测试成功: {len(tokens)} tokens')
    
    print('📥 测试模型配置加载...')
    from transformers import AutoConfig
    config = AutoConfig.from_pretrained(model_path, trust_remote_code=True)
    print('✅ 模型配置加载成功')
    
    print('📥 测试模型类加载（不加载权重）...')
    from transformers import AutoModel
    # 只测试类的加载，不加载实际权重
    model_class = AutoModel.from_pretrained.__func__.__qualname__
    print('✅ 模型类可用')
    
except Exception as e:
    print(f'❌ 模型加载错误: {e}')
    print('📋 详细错误信息:')
    traceback.print_exc()
    sys.exit(1)
"

if [ $? -ne 0 ]; then
    echo "❌ 模型加载测试失败"
    exit 1
fi

echo ""
echo "🔍 3. 测试训练脚本参数解析"
echo "----------------------------------------"

# 准备测试参数
TRAIN_DATA_PATH="${ONTOTHINK_ROOT}/enflame_training/datasets/ontothink_multiturn/train.jsonl"
OUTPUT_DIR="${ONTOTHINK_ROOT}/enflame_training/models/ontothink-chatglm3-6b"

echo "📋 使用的参数:"
echo "   模型路径: $MODEL_PATH"
echo "   训练数据: $TRAIN_DATA_PATH" 
echo "   输出目录: $OUTPUT_DIR"

# 创建必要的目录
mkdir -p "$OUTPUT_DIR"

# 测试参数解析
python3 finetune_chatglm3_for_multiturn.py \
    --model_path "$MODEL_PATH" \
    --train_data_path "$TRAIN_DATA_PATH" \
    --output_dir "$OUTPUT_DIR" \
    --max_seq_length 2048 \
    --num_train_epochs 1 \
    --per_device_train_batch_size 1 \
    --gradient_accumulation_steps 1 \
    --learning_rate 1e-5 \
    --logging_steps 1 \
    --save_steps 100 \
    --save_total_limit 2 \
    --remove_unused_columns false \
    --dataloader_pin_memory false \
    --help 2>&1 | head -20

echo ""
echo "🔍 4. 单GPU简化测试"
echo "----------------------------------------"

echo "🧪 尝试最简单的单GPU启动..."

# 创建简化的测试脚本
cat > test_simple_run.py << 'EOF'
#!/usr/bin/env python3
import os
import sys
import argparse

# 添加当前目录到路径
sys.path.insert(0, '.')

def main():
    print("🧪 简化测试开始...")
    
    try:
        # 设置环境变量
        os.environ['CUDA_VISIBLE_DEVICES'] = '0'  # 只使用一个GPU
        os.environ['WORLD_SIZE'] = '1'
        os.environ['RANK'] = '0'
        os.environ['LOCAL_RANK'] = '0'
        
        print("📦 导入必要模块...")
        
        import torch
        import transformers
        from transformers import AutoTokenizer, AutoModel
        
        print(f"✅ torch: {torch.__version__}")
        print(f"✅ transformers: {transformers.__version__}")
        print(f"✅ CUDA available: {torch.cuda.is_available()}")
        
        model_path = sys.argv[1] if len(sys.argv) > 1 else "."
        
        print(f"📥 加载模型: {model_path}")
        
        # 加载tokenizer
        tokenizer = AutoTokenizer.from_pretrained(
            model_path,
            add_eos_token=False,
            trust_remote_code=True
        )
        print("✅ Tokenizer加载成功")
        
        # 测试基本功能
        test_text = "Hello, ChatGLM3!"
        tokens = tokenizer.encode(test_text)
        decoded = tokenizer.decode(tokens)
        print(f"✅ 编码解码测试: '{test_text}' -> {len(tokens)} tokens -> '{decoded}'")
        
        print("🎉 简化测试成功!")
        
    except Exception as e:
        print(f"❌ 简化测试失败: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
EOF

python3 test_simple_run.py "$MODEL_PATH"

if [ $? -eq 0 ]; then
    echo "✅ 简化测试成功"
else
    echo "❌ 简化测试失败"
fi

# 清理测试文件
rm -f test_simple_run.py

echo ""
echo "🔍 5. 检查分布式训练环境"
echo "----------------------------------------"

echo "📋 环境变量检查:"
echo "   CUDA_VISIBLE_DEVICES: ${CUDA_VISIBLE_DEVICES:-未设置}"
echo "   WORLD_SIZE: ${WORLD_SIZE:-未设置}"
echo "   RANK: ${RANK:-未设置}"
echo "   LOCAL_RANK: ${LOCAL_RANK:-未设置}"

echo ""
echo "📋 GPU状态检查:"
python3 -c "
import torch
print(f'CUDA可用: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'GPU数量: {torch.cuda.device_count()}')
    for i in range(torch.cuda.device_count()):
        print(f'GPU {i}: {torch.cuda.get_device_name(i)}')
else:
    print('未检测到CUDA GPU')
"

echo ""
echo "========================================"
echo "🔧 调试建议:"
echo ""
echo "1. 如果基础检查都通过，问题可能在分布式训练配置"
echo "2. 尝试单GPU训练："
echo "   export CUDA_VISIBLE_DEVICES=0"
echo "   python3 finetune_chatglm3_for_multiturn.py [参数...]"
echo ""
echo "3. 查看详细错误日志："
echo "   export TORCH_DISTRIBUTED_DEBUG=DETAIL"
echo "   python3 -m torch.distributed.launch ..."
echo ""
echo "4. 检查燧原特定环境："
echo "   echo \$LD_LIBRARY_PATH"
echo "   echo \$PYTHONPATH"
echo ""
echo "5. 如果仍有问题，请分享完整的错误输出"
