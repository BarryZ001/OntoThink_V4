#!/bin/bash
# 紧急修复燧原环境路径 - 恢复训练能力
# 基于我们已知的成功配置重新建立环境

echo "🚨 紧急修复燧原环境路径 - 恢复训练能力"
echo "========================================"

echo "📋 1. 检查当前燧原环境状态"
echo "========================="
echo "🔍 检查FromEnflame链接:"
if [ -L "FromEnflame" ]; then
    echo "✅ FromEnflame符号链接存在"
    LINK_TARGET=$(readlink FromEnflame)
    echo "   指向: $LINK_TARGET"
    if [ -d "$LINK_TARGET" ]; then
        echo "   ✅ 目标目录存在"
    else
        echo "   ❌ 目标目录不存在"
    fi
else
    echo "❌ FromEnflame符号链接不存在"
fi

echo ""
echo "🔍 搜索燧原工具包位置:"
POSSIBLE_PATHS=(
    "/opt/topsrider"
    "/usr/local/topsrider"
    "/installer/topsrider_extracted"
    "/workspace/topsrider"
    "/home/topsrider"
    "$(pwd)/FromEnflame"
)

FOUND_PATH=""
for path in "${POSSIBLE_PATHS[@]}"; do
    echo "   检查: $path"
    if [ -d "$path" ]; then
        echo "   ✅ 目录存在"
        # 查找ChatGLM3脚本
        SCRIPT_FOUND=$(find "$path" -name "finetune_chatglm3_for_multiturn.py" 2>/dev/null | head -1)
        if [ -n "$SCRIPT_FOUND" ]; then
            echo "   🎯 找到ChatGLM3脚本: $SCRIPT_FOUND"
            FOUND_PATH="$path"
            break
        else
            echo "   ⚠️  未找到ChatGLM3脚本"
        fi
    else
        echo "   ❌ 目录不存在"
    fi
done

echo ""
echo "📋 2. 恢复燧原环境"
echo "================="
if [ -n "$FOUND_PATH" ]; then
    echo "✅ 找到燧原工具包: $FOUND_PATH"
    
    # 重新创建FromEnflame链接
    if [ -L "FromEnflame" ]; then
        echo "🔄 移除旧的FromEnflame链接"
        rm FromEnflame
    fi
    
    echo "🔗 创建新的FromEnflame链接"
    ln -s "$FOUND_PATH" FromEnflame
    
    if [ -L "FromEnflame" ]; then
        echo "✅ FromEnflame链接创建成功"
        echo "   指向: $(readlink FromEnflame)"
    else
        echo "❌ FromEnflame链接创建失败"
    fi
    
else
    echo "❌ 未找到燧原工具包，需要重新安装"
    echo ""
    echo "🚀 建议解决方案:"
    echo "================"
    echo "1. 🔍 检查燧原工具包是否需要重新安装"
    echo "2. 📥 重新下载燧原TopsRider工具包"
    echo "3. 🔧 重新运行安装脚本"
    exit 1
fi

echo ""
echo "📋 3. 验证恢复效果"
echo "================="
TRAINING_SCRIPT=$(find FromEnflame -name "finetune_chatglm3_for_multiturn.py" 2>/dev/null | head -1)
if [ -n "$TRAINING_SCRIPT" ]; then
    echo "✅ 找到训练脚本: $TRAINING_SCRIPT"
    
    # 更新所有脚本中的路径变量
    echo ""
    echo "🔧 更新脚本中的燧原路径"
    echo "======================"
    
    SCRIPT_DIR=$(dirname "$TRAINING_SCRIPT")
    TOOLKIT_ROOT=$(echo "$SCRIPT_DIR" | sed 's|/distributed/llm_scripts.*||')
    
    echo "   脚本目录: $SCRIPT_DIR"
    echo "   工具包根目录: $TOOLKIT_ROOT"
    
    # 创建路径修复脚本
    cat > fix_all_script_paths.sh << EOF
#!/bin/bash
# 批量修复所有脚本中的燧原路径
echo "🔧 批量修复脚本路径"
find . -name "*.sh" -type f -exec grep -l "ENFLAME_TOOLKIT_ROOT.*=.*installer" {} \; | while read script; do
    echo "   修复: \$script"
    sed -i 's|ENFLAME_TOOLKIT_ROOT="/installer[^"]*"|ENFLAME_TOOLKIT_ROOT="$TOOLKIT_ROOT"|g' "\$script"
done
echo "✅ 路径修复完成"
EOF
    chmod +x fix_all_script_paths.sh
    
    echo "✅ 路径修复脚本已创建"
    
else
    echo "❌ 仍未找到训练脚本"
fi

echo ""
echo "📋 4. 测试基础训练能力"
echo "===================="
if [ -n "$TRAINING_SCRIPT" ]; then
    echo "🎯 基础配置测试 (5步训练)"
    
    # 创建简化的测试脚本
    cat > test_basic_training.sh << EOF
#!/bin/bash
# 测试基础训练能力 - 确认环境恢复
CHATGLM3_SCRIPT_DIR="\$(dirname "$TRAINING_SCRIPT")"
TRAINING_SCRIPT="$TRAINING_SCRIPT"

echo "🚀 测试基础训练 - 确认燧原环境恢复"
echo "=================================="

# 基础环境变量 (继承成功配置)
export MASTER_ADDR=localhost
export MASTER_PORT=29500
export WORLD_SIZE=4
export GCU_VISIBLE_DEVICES="0,1,2,3"
export PTEX_DDP_BACKEND=eccl
export ENFLAME_ENABLE_EFP=true
export ENFLAME_PT_ENABLE_HBM_INPLACE=false
export OMP_NUM_THREADS=1
export ECCL_MAX_NCHANNELS=1
export ECCL_BUFFSIZE=8388608

# 基础训练参数
export PRETRAINED_MODEL_PATH="/workspace/code/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b"
export TRAIN_FILE="/workspace/code/OntoThink_V4/enflame_training/datasets/ontothink_multiturn/train.jsonl"

echo "✅ 环境变量设置完成"
echo "🚀 启动基础测试训练..."

(cd "\$CHATGLM3_SCRIPT_DIR" && \\
    python3.8 -u -m torch.distributed.launch \\
        --nproc_per_node=4 \\
        --standalone \\
        --use_env "\$TRAINING_SCRIPT" \\
        --model_path "\$PRETRAINED_MODEL_PATH" \\
        --train_file "\$TRAIN_FILE" \\
        --tp_size 1 \\
        --dp_size 1 \\
        --pp_size 4 \\
        --train_micro_batch_size 1 \\
        --gradient_accumulation_steps 1 \\
        --max_tokens 128 \\
        --train_epochs 1 \\
        --max_steps 5 \\
        --ladder_shape "false" \\
        &> /tmp/test_basic_training.log)

echo "🔍 基础测试完成，检查结果:"
if grep -q "ecclCommInitRank success!" /tmp/test_basic_training.log; then
    echo "✅ ECCL初始化成功"
else
    echo "❌ ECCL初始化失败"
fi

if grep -q "HLIR Compile Finish" /tmp/test_basic_training.log; then
    echo "✅ 模型编译成功"
else
    echo "❌ 模型编译失败"
fi
EOF
    chmod +x test_basic_training.sh
    
    echo "✅ 基础测试脚本已创建: test_basic_training.sh"
    echo ""
    echo "🎯 运行基础测试以确认环境恢复:"
    echo "bash test_basic_training.sh"
    
else
    echo "❌ 无法创建测试脚本，燧原环境仍未恢复"
fi

echo ""
echo "💡 恢复总结"
echo "==========="
if [ -n "$TRAINING_SCRIPT" ]; then
    echo "🎉 燧原环境路径已恢复！"
    echo "✅ 训练脚本: $TRAINING_SCRIPT"
    echo "✅ FromEnflame链接: $(readlink FromEnflame 2>/dev/null || echo '未创建')"
    echo ""
    echo "🚀 下一步行动:"
    echo "1. 运行基础测试: bash test_basic_training.sh"
    echo "2. 确认训练成功后，重新尝试扩展配置"
    echo "3. 基于恢复的环境继续OntoThink训练"
else
    echo "❌ 燧原环境恢复失败"
    echo "🔧 需要重新安装燧原工具包"
fi

echo ""
echo "📋 恢复脚本执行完成!"
