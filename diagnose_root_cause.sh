#!/bin/bash
# 深入诊断根本原因 - 全面检查基础环境
# 分析为什么参数正确但训练仍然失败

echo "🔍 深入诊断根本原因 - 全面检查基础环境"
echo "========================================"

echo "📋 1. 检查4卡训练详细日志"
echo "========================="
LOG_FILE="/tmp/ontothink_4card_correct_params.log"
if [ -f "$LOG_FILE" ]; then
    echo "✅ 日志文件存在: $LOG_FILE"
    echo "📊 文件大小: $(ls -lh $LOG_FILE | awk '{print $5}')"
    echo ""
    echo "🔍 错误信息:"
    grep -A 15 -B 5 "ERROR\|Traceback\|failed.*exitcode.*1" "$LOG_FILE" | head -30
    echo ""
    echo "🔍 完整日志尾部:"
    tail -50 "$LOG_FILE"
else
    echo "❌ 日志文件不存在: $LOG_FILE"
fi

echo ""
echo "📋 2. 验证模型文件路径"
echo "====================="
MODEL_PATH="/workspace/code/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b"
echo "📁 模型路径: $MODEL_PATH"
if [ -d "$MODEL_PATH" ]; then
    echo "✅ 模型目录存在"
    echo "📊 模型文件列表:"
    ls -la "$MODEL_PATH"
    echo ""
    echo "🔍 关键文件检查:"
    if [ -f "$MODEL_PATH/config.json" ]; then
        echo "✅ config.json 存在"
    else
        echo "❌ config.json 缺失"
    fi
    if [ -f "$MODEL_PATH/tokenizer.model" ]; then
        echo "✅ tokenizer.model 存在 ($(ls -lh $MODEL_PATH/tokenizer.model | awk '{print $5}'))"
    else
        echo "❌ tokenizer.model 缺失"
    fi
    WEIGHT_FILES=$(ls "$MODEL_PATH"/pytorch_model-*.bin 2>/dev/null | wc -l)
    echo "📊 权重文件数量: $WEIGHT_FILES 个"
else
    echo "❌ 模型目录不存在"
fi

echo ""
echo "📋 3. 验证数据文件路径"
echo "====================="
DATA_PATH="/workspace/code/OntoThink_V4/enflame_training/datasets/ontothink_multiturn/train.jsonl"
echo "📁 数据路径: $DATA_PATH"
if [ -f "$DATA_PATH" ]; then
    echo "✅ 数据文件存在"
    echo "📊 文件大小: $(ls -lh $DATA_PATH | awk '{print $5}')"
    echo "📊 行数: $(wc -l < $DATA_PATH)"
    echo ""
    echo "🔍 数据格式检查 (前3行):"
    head -3 "$DATA_PATH"
else
    echo "❌ 数据文件不存在"
    echo "🔍 检查数据目录:"
    DATA_DIR="/workspace/code/OntoThink_V4/enflame_training/datasets/ontothink_multiturn"
    if [ -d "$DATA_DIR" ]; then
        echo "📁 数据目录存在，文件列表:"
        ls -la "$DATA_DIR"
    else
        echo "❌ 数据目录不存在"
    fi
fi

echo ""
echo "📋 4. 检查GCU硬件状态"
echo "====================="
echo "🔍 GCU设备检查:"
if command -v topsmi &> /dev/null; then
    echo "✅ topsmi 命令可用"
    topsmi || echo "⚠️  topsmi 执行异常"
else
    echo "❌ topsmi 命令不可用"
fi

echo ""
echo "🔍 环境变量检查:"
echo "GCU_VISIBLE_DEVICES=$GCU_VISIBLE_DEVICES"
echo "WORLD_SIZE=$WORLD_SIZE"
echo "MASTER_ADDR=$MASTER_ADDR"
echo "MASTER_PORT=$MASTER_PORT"

echo ""
echo "📋 5. 检查Python环境"
echo "===================="
echo "🐍 Python版本:"
python3.8 --version

echo ""
echo "🔍 关键模块导入测试:"
python3.8 -c "
try:
    import torch
    print('✅ torch 导入成功, 版本:', torch.__version__)
except Exception as e:
    print('❌ torch 导入失败:', e)

try:
    import transformers
    print('✅ transformers 导入成功, 版本:', transformers.__version__)
except Exception as e:
    print('❌ transformers 导入失败:', e)

try:
    import collie
    print('✅ collie 导入成功')
except Exception as e:
    print('❌ collie 导入失败:', e)

try:
    import deepspeed
    print('✅ deepspeed 导入成功, 版本:', deepspeed.__version__)
except Exception as e:
    print('❌ deepspeed 导入失败:', e)
"

echo ""
echo "📋 6. 检查燧原脚本"
echo "=================="
SCRIPT_PATH="/installer/topsrider_extracted/TopsRider_installer/ai_development_toolkit/distributed/llm_scripts_1.0.40/finetuning/chatglm3/finetune_chatglm3_for_multiturn.py"
echo "📁 脚本路径: $SCRIPT_PATH"
if [ -f "$SCRIPT_PATH" ]; then
    echo "✅ 燧原脚本存在"
    echo "🔍 脚本语法检查:"
    python3.8 -m py_compile "$SCRIPT_PATH" && echo "✅ 脚本语法正确" || echo "❌ 脚本语法错误"
else
    echo "❌ 燧原脚本不存在"
fi

echo ""
echo "📋 7. 测试基础训练脚本调用"
echo "========================="
echo "🔍 测试脚本帮助信息:"
cd "$(dirname $SCRIPT_PATH)"
python3.8 "$SCRIPT_PATH" --help 2>&1 | head -20

echo ""
echo "💡 诊断总结"
echo "==========="
echo "根据上述检查结果，可能的问题原因："
echo "1. 模型文件路径或数据文件路径不正确"
echo "2. Python环境或模块导入问题"  
echo "3. GCU硬件访问权限问题"
echo "4. 燧原脚本内部错误"
echo "5. torch.distributed.launch配置问题"
echo ""
echo "🎯 建议解决方案："
echo "1. 如果模型/数据路径有问题 → 修复路径或重新下载"
echo "2. 如果Python模块有问题 → 重新安装依赖"
echo "3. 如果硬件访问有问题 → 检查权限和驱动"
echo "4. 如果脚本有问题 → 尝试直接调用Python脚本"
echo ""
echo "📋 完整诊断完成!"
