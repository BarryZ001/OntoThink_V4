#!/bin/bash
# 快速修复燧原路径 - 基于确认的服务器路径
# 服务器燧原工具包路径：/installer/topsrider_extracted/TopsRider_installer/ai_development_toolkit

echo "🎯 快速修复燧原路径 - 基于确认的服务器路径"
echo "============================================"

# 确认的燧原工具包路径
CONFIRMED_TOOLKIT_ROOT="/installer/topsrider_extracted/TopsRider_installer/ai_development_toolkit"
CHATGLM3_SCRIPT_DIR="${CONFIRMED_TOOLKIT_ROOT}/distributed/llm_scripts_1.0.40/finetuning/chatglm3"
TRAINING_SCRIPT="${CHATGLM3_SCRIPT_DIR}/finetune_chatglm3_for_multiturn.py"

echo "📋 1. 验证燧原工具包路径"
echo "======================"
echo "🔍 工具包根目录: $CONFIRMED_TOOLKIT_ROOT"
echo "🔍 ChatGLM3脚本目录: $CHATGLM3_SCRIPT_DIR"
echo "🔍 训练脚本: $TRAINING_SCRIPT"

if [ -d "$CONFIRMED_TOOLKIT_ROOT" ]; then
    echo "✅ 燧原工具包根目录存在"
else
    echo "❌ 燧原工具包根目录不存在: $CONFIRMED_TOOLKIT_ROOT"
    exit 1
fi

if [ -d "$CHATGLM3_SCRIPT_DIR" ]; then
    echo "✅ ChatGLM3脚本目录存在"
else
    echo "❌ ChatGLM3脚本目录不存在: $CHATGLM3_SCRIPT_DIR"
    exit 1
fi

if [ -f "$TRAINING_SCRIPT" ]; then
    echo "✅ 训练脚本存在"
else
    echo "❌ 训练脚本不存在: $TRAINING_SCRIPT"
    exit 1
fi

echo ""
echo "📋 2. 修复FromEnflame符号链接"
echo "=========================="
if [ -L "FromEnflame" ]; then
    echo "🔄 移除旧的FromEnflame链接"
    rm FromEnflame
fi

echo "🔗 创建新的FromEnflame链接指向: $CONFIRMED_TOOLKIT_ROOT"
ln -s "$CONFIRMED_TOOLKIT_ROOT" FromEnflame

if [ -L "FromEnflame" ] && [ -d "$(readlink FromEnflame)" ]; then
    echo "✅ FromEnflame链接创建成功"
    echo "   指向: $(readlink FromEnflame)"
else
    echo "❌ FromEnflame链接创建失败"
    exit 1
fi

echo ""
echo "📋 3. 立即测试基础训练能力"
echo "========================"
echo "🚀 运行已知成功配置 - ladder_shape修复 + 4卡并行"

# 设置分布式环境变量 (继承所有成功配置)
export MASTER_ADDR=localhost
export MASTER_PORT=29500
export WORLD_SIZE=4      # 使用4张GCU卡
export RANK=0            # 当前进程的全局rank (由torch.distributed.launch管理)
export LOCAL_RANK=0      # 当前进程的本地rank (由torch.distributed.launch管理)
export GCU_VISIBLE_DEVICES="0,1,2,3" # 明确指定使用第0,1,2,3张GCU卡
export PTEX_DDP_BACKEND=eccl

# 设置其他燧原环境变量 (继承所有成功配置)
export ENFLAME_ENABLE_EFP=true
export ENFLAME_PT_ENABLE_HBM_INPLACE=false # 禁用原地操作
export OMP_NUM_THREADS=1 # 最小线程数
export ECCL_MAX_NCHANNELS=1 # 最小通信通道
export ENFLAME_UMD_FLAGS="mem_alloc_retry_times=1"
export ECCL_BUFFSIZE=8388608 # 8MB通信缓冲区

# 设置训练参数 - 继承所有成功配置
export PRETRAINED_MODEL_PATH="/workspace/code/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b"
export TRAIN_FILE="/workspace/code/OntoThink_V4/enflame_training/datasets/ontothink_multiturn/train.jsonl"
export MAX_TOKENS="128" # 超大幅减少序列长度
export TP_SIZE="1" # 禁用Tensor Parallelism
export DP_SIZE="1" # 禁用Data Parallelism
export PP_SIZE="4" # 启用4卡流水线并行
export MICRO_BATCH_SIZE="1" # 保持最小
export GARDIENT_ACCUMULATION_STEPS="1" # 无梯度累积，最小化优化器状态内存
export TRAIN_EPOCHS="1"
export MAX_STEPS="5" # 训练5步，验证环境恢复

# 创建DeepSpeed配置文件 (继承成功配置)
DEEPSPEED_CONFIG_PATH="/tmp/deepspeed_path_fixed.json"
cat <<EOF > "$DEEPSPEED_CONFIG_PATH"
{
  "fp16": {
    "enabled": true,
    "initial_scale_power": 12
  },
  "zero_optimization": {
    "stage": 1,
    "offload_optimizer": {
      "device": "cpu",
      "pin_memory": true
    }
  },
  "monitor_config": {
    "enabled": true,
    "tensorboard": {
      "enabled": true,
      "output_path": "./ds_logs/tensorboard",
      "job_name": ""
    },
    "wandb": {
      "enabled": false,
      "team": "00index",
      "project": "collie",
      "group": "summary",
      "job_name": ""
    },
    "csv_monitor": {
      "enabled": false,
      "job_name": "$(date +%Y-%m-%d-%H-%M-%S)"
    }
  },
  "train_micro_batch_size_per_gpu": 1,
  "gradient_accumulation_steps": 1
}
EOF
echo "✅ DeepSpeed配置文件已创建: $DEEPSPEED_CONFIG_PATH"

echo ""
echo "🎯 环境配置："
echo "  硬件: 4张GCU (GCU_VISIBLE_DEVICES=$GCU_VISIBLE_DEVICES)"
echo "  并行: 流水线并行 (TP=$TP_SIZE, DP=$DP_SIZE, PP=$PP_SIZE)"
echo "  内存: 超级优化 (tokens=$MAX_TOKENS, batch=$MICRO_BATCH_SIZE, accum=$GARDIENT_ACCUMULATION_STEPS)"
echo "  步骤: MAX_STEPS=$MAX_STEPS (验证环境恢复)"
echo "  🔧 Bug修复: --ladder_shape false (字符串参数)"
echo "  ✅ 路径修复: 使用确认的燧原工具包路径"

echo ""
echo "🚀 启动路径修复后的基础训练测试"
echo "==============================="
echo "日志将输出到 /tmp/ontothink_path_fixed.log"

# 切换到脚本目录并运行
(cd "$CHATGLM3_SCRIPT_DIR" && \
    python3.8 -u -m torch.distributed.launch \
        --nproc_per_node="$WORLD_SIZE" \
        --standalone \
        --use_env "$TRAINING_SCRIPT" \
        --model_path "$PRETRAINED_MODEL_PATH" \
        --train_file "$TRAIN_FILE" \
        --tp_size "$TP_SIZE" \
        --dp_size "$DP_SIZE" \
        --pp_size "$PP_SIZE" \
        --train_micro_batch_size "$MICRO_BATCH_SIZE" \
        --gradient_accumulation_steps "$GARDIENT_ACCUMULATION_STEPS" \
        --max_tokens "$MAX_TOKENS" \
        --train_epochs "$TRAIN_EPOCHS" \
        --max_steps "$MAX_STEPS" \
        --deepspeed "$DEEPSPEED_CONFIG_PATH" \
        --ladder_shape "false" \
        &> /tmp/ontothink_path_fixed.log)

echo ""
echo "🔍 路径修复测试完成。请查看日志文件: /tmp/ontothink_path_fixed.log"
echo ""

echo "🔍 修复结果分析"
echo "================"
ERROR_LOG=$(grep -E "ERROR|Traceback|Failures" /tmp/ontothink_path_fixed.log || true)
if [ -n "$ERROR_LOG" ]; then
    echo "❌ 发现错误:"
    echo "$ERROR_LOG"
else
    echo "✅ 未发现明显错误"
fi

MEMORY_ERRORS=$(grep -c "topsMalloc.*failed\|Check failed.*topsSuccess" /tmp/ontothink_path_fixed.log)
ECCL_SUCCESS=$(grep -c "ecclCommInitRank success!" /tmp/ontothink_path_fixed.log)
TRAINING_STEPS=$(grep -c "step.*loss" /tmp/ontothink_path_fixed.log)
MODEL_COMPILED=$(grep -c "HLIR Compile Finish" /tmp/ontothink_path_fixed.log)

echo "📊 关键指标检查:"
echo "  💾 内存错误: $MEMORY_ERRORS 次"
echo "  🔗 ECCL成功初始化: $ECCL_SUCCESS 次"
echo "  📈 训练步骤: $TRAINING_STEPS 次"
echo "  ⚡ 模型编译: $MODEL_COMPILED 次"

if [ $MEMORY_ERRORS -eq 0 ] && [ $ECCL_SUCCESS -gt 0 ] && [ $TRAINING_STEPS -gt 0 ] && [ $MODEL_COMPILED -gt 0 ]; then
    echo ""
    echo "🎉🎉🎉 路径修复完全成功！"
    echo "✅ 燧原环境完全恢复"
    echo "✅ 所有成功配置有效"
    echo "✅ OntoThink训练环境正常"
    echo ""
    echo "🚀 现在可以运行扩展训练了！"
    echo "下一步: 基于恢复的环境重新运行扩展配置"
else
    echo ""
    echo "⚠️  路径修复成功，但训练仍需调试"
    echo "📊 检查上述指标，可能需要进一步优化"
fi

echo ""
echo "💡 路径修复总结"
echo "==============="
echo "🎯 修复内容:"
echo "  ✅ 确认燧原工具包路径: $CONFIRMED_TOOLKIT_ROOT"
echo "  ✅ 重建FromEnflame符号链接"
echo "  ✅ 验证训练脚本可访问性"
echo "  ✅ 运行基础训练测试"

echo "🎯 如果测试成功:"
echo "  - 燧原环境完全恢复"
echo "  - 可以重新运行扩展训练"
echo "  - OntoThink项目回到正轨"

echo ""
echo "📋 完整日志: /tmp/ontothink_path_fixed.log"
echo ""
echo "🎉 路径修复脚本执行完成！"
