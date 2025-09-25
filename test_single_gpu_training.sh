#!/bin/bash
# 单GPU训练测试脚本 - 绕过分布式训练问题
# 适用于燧原T20环境

set -e

echo "🚀 单GPU训练测试"
echo "绕过分布式训练复杂性，直接测试基础训练功能"
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

# 设置训练参数
MODEL_PATH="${ONTOTHINK_ROOT}/enflame_training/models/THUDM/chatglm3-6b"
TRAIN_DATA_PATH="${ONTOTHINK_ROOT}/enflame_training/datasets/ontothink_multiturn/train.jsonl"
OUTPUT_DIR="${ONTOTHINK_ROOT}/enflame_training/models/ontothink-chatglm3-6b-test"

echo ""
echo "📋 训练配置:"
echo "   模型路径: $MODEL_PATH"
echo "   训练数据: $TRAIN_DATA_PATH"
echo "   输出目录: $OUTPUT_DIR"

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 设置单GPU环境变量
export CUDA_VISIBLE_DEVICES=0
export WORLD_SIZE=1
export RANK=0
export LOCAL_RANK=0

# 清除可能干扰的分布式环境变量
unset MASTER_ADDR
unset MASTER_PORT

echo ""
echo "🔧 环境设置:"
echo "   CUDA_VISIBLE_DEVICES: $CUDA_VISIBLE_DEVICES"
echo "   WORLD_SIZE: $WORLD_SIZE"
echo "   RANK: $RANK"
echo "   LOCAL_RANK: $LOCAL_RANK"

# 检查数据文件
if [ ! -f "$TRAIN_DATA_PATH" ]; then
    echo "❌ 训练数据文件不存在: $TRAIN_DATA_PATH"
    echo "🔧 创建测试数据..."
    
    # 创建数据目录
    mkdir -p "$(dirname "$TRAIN_DATA_PATH")"
    
    # 创建简单的测试数据
    cat > "$TRAIN_DATA_PATH" << 'EOF'
{"conversations": [{"from": "human", "value": "你好"}, {"from": "gpt", "value": "你好！我是ChatGLM3，很高兴为您服务。"}]}
{"conversations": [{"from": "human", "value": "什么是人工智能？"}, {"from": "gpt", "value": "人工智能是计算机科学的一个分支，旨在创建能够执行通常需要人类智能的任务的系统。"}]}
{"conversations": [{"from": "human", "value": "请介绍一下机器学习"}, {"from": "gpt", "value": "机器学习是人工智能的一个子领域，它使用算法和统计模型让计算机系统能够从数据中学习和改进。"}]}
EOF
    
    echo "✅ 创建了测试数据文件"
fi

echo ""
echo "🚀 开始单GPU训练测试..."
echo "⏱️  这可能需要几分钟..."

# 使用最简单的参数进行测试
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
    --save_steps 10 \
    --save_total_limit 1 \
    --remove_unused_columns false \
    --dataloader_pin_memory false \
    --fp16 false \
    --report_to none \
    --evaluation_strategy no \
    --do_train \
    --overwrite_output_dir

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 单GPU训练测试成功!"
    echo ""
    echo "✅ 这说明基础训练功能正常，问题可能在于:"
    echo "   1. 分布式训练配置"
    echo "   2. 8GPU并行设置"
    echo "   3. 燧原T20多卡通信"
    echo ""
    echo "🔧 建议尝试:"
    echo "   1. 修改训练脚本，使用较少的GPU"
    echo "   2. 检查多卡通信设置"
    echo "   3. 逐步增加GPU数量测试"
    echo ""
    echo "📁 测试输出目录: $OUTPUT_DIR"
    echo "📊 检查输出文件:"
    ls -la "$OUTPUT_DIR"
    
else
    echo ""
    echo "❌ 单GPU训练测试也失败"
    echo ""
    echo "🔧 这表明问题可能在于:"
    echo "   1. 模型文件仍有问题"
    echo "   2. Python环境依赖"
    echo "   3. 燧原T20特定配置"
    echo ""
    echo "💡 下一步调试:"
    echo "   bash $ONTOTHINK_ROOT/debug_training_detailed.sh"
fi
