#!/bin/bash
# 服务器端模型验证脚本
# 验证上传的ChatGLM3模型是否完整可用

set -e

echo "🔍 ChatGLM3 上传模型验证工具"
echo "适用于燧原T20服务器环境"
echo "========================================"

# 自动检测项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ONTOTHINK_ROOT="$SCRIPT_DIR"
MODEL_DIR="${ONTOTHINK_ROOT}/enflame_training/models/THUDM/chatglm3-6b"

echo "📁 项目根目录: $ONTOTHINK_ROOT"
echo "📁 模型目录: $MODEL_DIR"

if [ ! -d "$MODEL_DIR" ]; then
    echo "❌ 模型目录不存在: $MODEL_DIR"
    echo ""
    echo "💡 请先上传模型文件:"
    echo "   方法1: rsync上传"
    echo "   方法2: 解压tar.gz文件"
    echo "   详见: download_and_upload_chatglm3.md"
    exit 1
fi

cd "$MODEL_DIR"

echo ""
echo "🔍 1. 文件完整性检查"
echo "----------------------------------------"

# 检查tokenizer
echo "📋 Tokenizer检查:"
if [ -f "tokenizer.model" ]; then
    size=$(stat -c%s "tokenizer.model")
    echo "tokenizer.model: $size bytes"
    
    if [ "$size" -gt 1000000 ]; then
        echo "✅ tokenizer.model 大小正常"
        TOKENIZER_OK=true
    else
        echo "❌ tokenizer.model 过小"
        TOKENIZER_OK=false
    fi
else
    echo "❌ tokenizer.model 不存在"
    TOKENIZER_OK=false
fi

# 检查权重文件
echo ""
echo "📋 权重文件检查:"
WEIGHT_COUNT=0
TOTAL_SIZE=0

for i in {1..7}; do
    safetensor_file="model-0000${i}-of-00007.safetensors"
    pytorch_file="pytorch_model-0000${i}-of-00007.bin"
    
    if [ -f "$safetensor_file" ]; then
        size=$(stat -c%s "$safetensor_file")
        TOTAL_SIZE=$((TOTAL_SIZE + size))
        
        if [ "$size" -gt 100000000 ]; then
            size_mb=$(echo "$size" | awk '{printf "%.1f MB", $1/1024/1024}')
            echo "✅ $safetensor_file: $size_mb"
            ((WEIGHT_COUNT++))
        else
            echo "❌ $safetensor_file: $size bytes (疑似LFS指针)"
        fi
    elif [ -f "$pytorch_file" ]; then
        size=$(stat -c%s "$pytorch_file")
        TOTAL_SIZE=$((TOTAL_SIZE + size))
        
        if [ "$size" -gt 100000000 ]; then
            size_mb=$(echo "$size" | awk '{printf "%.1f MB", $1/1024/1024}')
            echo "✅ $pytorch_file: $size_mb"
            ((WEIGHT_COUNT++))
        else
            echo "❌ $pytorch_file: $size bytes (疑似LFS指针)"
        fi
    else
        echo "❌ 权重文件 $i 不存在"
    fi
done

echo "📊 权重文件统计: $WEIGHT_COUNT/7"
total_gb=$(echo "$TOTAL_SIZE" | awk '{printf "%.2f GB", $1/1024/1024/1024}')
echo "📊 权重文件总大小: $total_gb"

WEIGHTS_OK=false
if [ "$WEIGHT_COUNT" -eq 7 ]; then
    WEIGHTS_OK=true
    echo "✅ 权重文件完整"
else
    echo "❌ 权重文件不完整"
fi

# 检查配置文件
echo ""
echo "📋 配置文件检查:"
config_files=(
    "config.json"
    "tokenizer_config.json" 
    "special_tokens_map.json"
    "modeling_chatglm.py"
    "tokenization_chatglm.py"
    "configuration_chatglm.py"
)

CONFIG_COUNT=0
for file in "${config_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
        ((CONFIG_COUNT++))
    else
        echo "❌ $file 缺失"
    fi
done

echo "📊 配置文件统计: $CONFIG_COUNT/${#config_files[@]}"

# 2. 功能性测试
echo ""
echo "🔍 2. 功能性测试"
echo "----------------------------------------"

if [ "$TOKENIZER_OK" = true ]; then
    echo "🧪 测试sentencepiece tokenizer..."
    python3 -c "
import sentencepiece as smp
try:
    sp = smp.SentencePieceProcessor()
    sp.load('tokenizer.model')
    
    # 编码测试
    test_texts = [
        '你好，世界！',
        'ChatGLM3是一个对话语言模型',
        'Hello, how are you?',
        '人工智能技术发展迅速'
    ]
    
    for text in test_texts:
        tokens = sp.encode(text)
        decoded = sp.decode(tokens)
        if decoded.strip() == text.strip():
            print(f'✅ 编码解码正常: \"{text}\" ({len(tokens)} tokens)')
        else:
            print(f'❌ 编码解码异常: \"{text}\" -> \"{decoded}\"')
    
    print('✅ SentencePiece tokenizer功能正常')
    
except Exception as e:
    print(f'❌ SentencePiece tokenizer测试失败: {e}')
    exit(1)
" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "✅ SentencePiece tokenizer测试通过"
    else
        echo "❌ SentencePiece tokenizer测试失败"
    fi
    
    echo ""
    echo "🧪 测试transformers tokenizer..."
    python3 -c "
import sys
import os
sys.path.append('.')

try:
    from transformers import AutoTokenizer
    
    print('📥 加载tokenizer...')
    tokenizer = AutoTokenizer.from_pretrained('.', trust_remote_code=True)
    print('✅ Transformers tokenizer加载成功')
    
    # 编码测试
    test_texts = [
        '你好，ChatGLM3！',
        'How are you today?',
        '请介绍一下人工智能的发展历程。'
    ]
    
    for text in test_texts:
        tokens = tokenizer.encode(text)
        decoded = tokenizer.decode(tokens, skip_special_tokens=True)
        print(f'✅ 编码解码测试: \"{text}\" ({len(tokens)} tokens)')
        if decoded.strip() != text.strip():
            print(f'   ⚠️  解码结果: \"{decoded}\"')
    
    print('✅ Transformers tokenizer功能正常')
    
except Exception as e:
    print(f'❌ Transformers tokenizer测试失败: {e}')
    import traceback
    traceback.print_exc()
    sys.exit(1)
" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "✅ Transformers tokenizer测试通过"
        TOKENIZER_FUNCTIONAL=true
    else
        echo "❌ Transformers tokenizer测试失败"
        TOKENIZER_FUNCTIONAL=false
    fi
else
    echo "⚠️  跳过tokenizer功能测试（文件问题）"
    TOKENIZER_FUNCTIONAL=false
fi

# 3. 模型配置测试
echo ""
echo "🔍 3. 模型配置测试"
echo "----------------------------------------"

if [ -f "config.json" ]; then
    echo "🧪 测试模型配置加载..."
    python3 -c "
import sys
import os
sys.path.append('.')

try:
    from transformers import AutoConfig
    
    print('📥 加载模型配置...')
    config = AutoConfig.from_pretrained('.', trust_remote_code=True)
    
    print(f'✅ 模型配置加载成功')
    print(f'   模型类型: {config.model_type}')
    print(f'   隐藏层大小: {config.hidden_size}')
    print(f'   层数: {config.num_layers}')
    print(f'   注意力头数: {config.num_attention_heads}')
    print(f'   词汇表大小: {config.vocab_size}')
    
except Exception as e:
    print(f'❌ 模型配置加载失败: {e}')
    sys.exit(1)
"

    if [ $? -eq 0 ]; then
        echo "✅ 模型配置测试通过"
        CONFIG_FUNCTIONAL=true
    else
        echo "❌ 模型配置测试失败"
        CONFIG_FUNCTIONAL=false
    fi
else
    echo "⚠️  跳过模型配置测试（config.json缺失）"
    CONFIG_FUNCTIONAL=false
fi

# 4. 综合评估
echo ""
echo "🔍 4. 综合评估"
echo "========================================"

echo "📊 检查结果汇总:"
echo "   Tokenizer文件: $([ "$TOKENIZER_OK" = true ] && echo "✅ 正常" || echo "❌ 异常")"
echo "   权重文件: $([ "$WEIGHTS_OK" = true ] && echo "✅ 完整 ($WEIGHT_COUNT/7)" || echo "❌ 不完整 ($WEIGHT_COUNT/7)")"
echo "   配置文件: $([ "$CONFIG_COUNT" -eq ${#config_files[@]} ] && echo "✅ 完整 ($CONFIG_COUNT/${#config_files[@]})" || echo "❌ 不完整 ($CONFIG_COUNT/${#config_files[@]})")"
echo "   Tokenizer功能: $([ "$TOKENIZER_FUNCTIONAL" = true ] && echo "✅ 正常" || echo "❌ 异常")"
echo "   模型配置: $([ "$CONFIG_FUNCTIONAL" = true ] && echo "✅ 正常" || echo "❌ 异常")"

echo ""
if [ "$TOKENIZER_OK" = true ] && [ "$WEIGHTS_OK" = true ] && [ "$TOKENIZER_FUNCTIONAL" = true ] && [ "$CONFIG_FUNCTIONAL" = true ]; then
    echo "🎉 模型验证通过！可以开始训练"
    echo ""
    echo "🚀 下一步：开始训练"
    echo "cd $ONTOTHINK_ROOT"
    echo "python3 enflame_training/scripts/train_ontothink_enflame.py --step full"
    
    exit 0
else
    echo "❌ 模型验证失败"
    echo ""
    echo "🔧 修复建议:"
    
    if [ "$TOKENIZER_OK" = false ]; then
        echo "   1. Tokenizer文件问题 - 重新上传tokenizer.model"
    fi
    
    if [ "$WEIGHTS_OK" = false ]; then
        echo "   2. 权重文件不完整 - 重新上传完整模型"
    fi
    
    if [ "$TOKENIZER_FUNCTIONAL" = false ]; then
        echo "   3. Tokenizer功能异常 - 检查Python环境和依赖"
    fi
    
    if [ "$CONFIG_FUNCTIONAL" = false ]; then
        echo "   4. 模型配置异常 - 重新上传配置文件"
    fi
    
    echo ""
    echo "💡 快速修复命令:"
    echo "   bash $ONTOTHINK_ROOT/fix_chatglm3_complete.sh"
    echo "   python3 $ONTOTHINK_ROOT/enflame_training/scripts/manual_download_chatglm3.py"
    
    exit 1
fi
