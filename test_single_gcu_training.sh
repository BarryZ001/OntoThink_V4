#!/bin/bash
# 燧原T20单GCU训练测试脚本
# 专门针对燧原硬件的单卡训练测试

set -e

echo "🔥 燧原T20单GCU训练测试"
echo "专门针对燧原GCU硬件的训练测试"
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
        echo "✅ 找到燧原ChatGLM3脚本: $dir"
        break
    fi
done

if [ -z "$CHATGLM3_SCRIPT_DIR" ]; then
    echo "❌ 未找到燧原ChatGLM3脚本目录"
    exit 1
fi

cd "$CHATGLM3_SCRIPT_DIR"
echo "📁 当前目录: $PWD"

# 设置训练参数
MODEL_PATH="${ONTOTHINK_ROOT}/enflame_training/models/THUDM/chatglm3-6b"
TRAIN_DATA_PATH="${ONTOTHINK_ROOT}/enflame_training/datasets/ontothink_multiturn/train.jsonl"
OUTPUT_DIR="${ONTOTHINK_ROOT}/enflame_training/models/ontothink-chatglm3-6b-gcu-test"

echo ""
echo "📋 训练配置:"
echo "   模型路径: $MODEL_PATH"
echo "   训练数据: $TRAIN_DATA_PATH"
echo "   输出目录: $OUTPUT_DIR"

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 设置燧原GCU环境变量
echo ""
echo "🔧 设置燧原GCU环境..."

# 清除NVIDIA相关环境变量
unset CUDA_VISIBLE_DEVICES
unset CUDA_DEVICE_ORDER

# 设置燧原特定环境变量
export GCU_VISIBLE_DEVICES=0  # 使用第一个GCU
export COREX_VISIBLE_DEVICES=0
export DTU_VISIBLE_DEVICES=0

# 设置分布式训练参数
export WORLD_SIZE=1
export RANK=0
export LOCAL_RANK=0

# 清除可能干扰的分布式环境变量
unset MASTER_ADDR
unset MASTER_PORT

echo "🔥 燧原GCU环境设置:"
echo "   GCU_VISIBLE_DEVICES: ${GCU_VISIBLE_DEVICES}"
echo "   COREX_VISIBLE_DEVICES: ${COREX_VISIBLE_DEVICES}"
echo "   DTU_VISIBLE_DEVICES: ${DTU_VISIBLE_DEVICES}"
echo "   WORLD_SIZE: $WORLD_SIZE"
echo "   RANK: $RANK"
echo "   LOCAL_RANK: $LOCAL_RANK"

# 检查并创建训练数据
if [ ! -f "$TRAIN_DATA_PATH" ]; then
    echo ""
    echo "🔧 创建燧原训练测试数据..."
    
    # 创建数据目录
    mkdir -p "$(dirname "$TRAIN_DATA_PATH")"
    
    # 创建适合燧原环境的测试数据
    cat > "$TRAIN_DATA_PATH" << 'EOF'
{"conversations": [{"from": "human", "value": "你好"}, {"from": "gpt", "value": "你好！我是ChatGLM3，运行在燧原T20 GCU上。"}]}
{"conversations": [{"from": "human", "value": "什么是燧原T20？"}, {"from": "gpt", "value": "燧原T20是一款专为AI计算设计的GCU芯片，具有强大的并行计算能力。"}]}
{"conversations": [{"from": "human", "value": "GCU和GPU有什么区别？"}, {"from": "gpt", "value": "GCU是Graphics Compute Unit的缩写，是燧原科技专门为AI计算优化的处理器。"}]}
{"conversations": [{"from": "human", "value": "请介绍人工智能"}, {"from": "gpt", "value": "人工智能是计算机科学的重要分支，旨在创造能够模拟人类智能行为的系统。"}]}
{"conversations": [{"from": "human", "value": "深度学习是什么？"}, {"from": "gpt", "value": "深度学习是机器学习的一个子领域，使用多层神经网络来学习数据的复杂表示。"}]}
EOF
    
    echo "✅ 创建了燧原训练测试数据文件"
fi

echo ""
echo "🔥 开始燧原GCU单卡训练测试..."

# 首先验证GCU可用性
echo "🧪 验证GCU设备状态..."
python3 -c "
import torch
import sys

try:
    if hasattr(torch, 'gcu'):
        if torch.gcu.is_available():
            device_count = torch.gcu.device_count()
            print(f'✅ GCU可用，设备数量: {device_count}')
            
            # 测试第一个GCU设备
            device = torch.device('gcu:0')
            test_tensor = torch.randn(2, 3, device=device)
            print(f'✅ GCU设备测试成功: {test_tensor.shape}')
        else:
            print('❌ GCU不可用')
            sys.exit(1)
    else:
        print('❌ 当前PyTorch版本不支持GCU')
        sys.exit(1)
except Exception as e:
    print(f'❌ GCU验证失败: {e}')
    sys.exit(1)
"

if [ $? -ne 0 ]; then
    echo "❌ GCU设备验证失败，无法进行训练测试"
    exit 1
fi

echo ""
echo "🚀 启动燧原GCU训练..."
echo "⏱️  这可能需要几分钟..."

# 使用燧原优化的训练参数
python3 finetune_chatglm3_for_multiturn.py \
    --model_path "$MODEL_PATH" \
    --train_data_path "$TRAIN_DATA_PATH" \
    --output_dir "$OUTPUT_DIR" \
    --max_seq_length 512 \
    --num_train_epochs 1 \
    --per_device_train_batch_size 1 \
    --gradient_accumulation_steps 1 \
    --learning_rate 1e-5 \
    --logging_steps 1 \
    --save_steps 5 \
    --save_total_limit 1 \
    --remove_unused_columns false \
    --dataloader_pin_memory false \
    --fp16 false \
    --bf16 false \
    --report_to none \
    --evaluation_strategy no \
    --do_train \
    --overwrite_output_dir \
    --ddp_backend gloo \
    --local_rank 0 2>&1 | tee "${OUTPUT_DIR}/training.log"

TRAINING_EXIT_CODE=$?

echo ""
if [ $TRAINING_EXIT_CODE -eq 0 ]; then
    echo "🎉 燧原GCU单卡训练测试成功!"
    echo ""
    echo "✅ 这说明燧原环境基础功能正常，问题可能在于:"
    echo "   1. 多GCU分布式训练配置"
    echo "   2. 8卡并行通信设置"
    echo "   3. ECCL集合通信库配置"
    echo ""
    echo "🔧 建议下一步:"
    echo "   1. 逐步增加GCU数量测试 (2卡 -> 4卡 -> 8卡)"
    echo "   2. 检查燧原分布式训练文档"
    echo "   3. 验证ECCL通信库配置"
    echo ""
    echo "📁 训练输出目录: $OUTPUT_DIR"
    echo "📊 检查训练结果:"
    ls -la "$OUTPUT_DIR"
    
    if [ -f "$OUTPUT_DIR/training.log" ]; then
        echo ""
        echo "📋 训练日志末尾:"
        tail -10 "$OUTPUT_DIR/training.log"
    fi
    
else
    echo "❌ 燧原GCU单卡训练测试失败"
    echo ""
    echo "🔧 错误分析 (退出代码: $TRAINING_EXIT_CODE):"
    
    if [ -f "$OUTPUT_DIR/training.log" ]; then
        echo ""
        echo "📋 错误日志:"
        tail -20 "$OUTPUT_DIR/training.log"
        echo ""
        
        # 分析常见燧原错误
        if grep -q "ptex" "$OUTPUT_DIR/training.log"; then
            echo "💡 发现ptex相关错误，可能需要重新安装燧原扩展包"
        fi
        
        if grep -q "gcu" "$OUTPUT_DIR/training.log"; then
            echo "💡 发现GCU相关错误，检查燧原驱动和设备状态"
        fi
        
        if grep -q "ECCL\|eccl" "$OUTPUT_DIR/training.log"; then
            echo "💡 发现ECCL通信错误，检查燧原集合通信库"
        fi
        
        if grep -q "Memory\|memory\|OOM" "$OUTPUT_DIR/training.log"; then
            echo "💡 发现内存错误，尝试减小batch_size或seq_length"
        fi
    fi
    
    echo ""
    echo "🔧 建议的调试步骤:"
    echo "   1. bash $ONTOTHINK_ROOT/debug_enflame_gcu.sh"
    echo "   2. 检查燧原驱动状态"
    echo "   3. 重新安装燧原Python环境"
    echo "   4. 查看燧原官方文档和示例"
fi

echo ""
echo "========================================"
echo "🔥 燧原T20 GCU测试完成"

# 如果训练成功，提供多卡训练建议
if [ $TRAINING_EXIT_CODE -eq 0 ]; then
    echo ""
    echo "🚀 下一步：测试多GCU训练"
    echo ""
    echo "💡 2卡训练测试命令:"
    echo "export GCU_VISIBLE_DEVICES=0,1"
    echo "export WORLD_SIZE=2"
    echo "# 使用燧原分布式启动方式"
    echo ""
    echo "💡 8卡训练命令:"
    echo "export GCU_VISIBLE_DEVICES=0,1,2,3,4,5,6,7"
    echo "export WORLD_SIZE=8"
    echo "# 使用原始的8卡训练脚本"
fi
