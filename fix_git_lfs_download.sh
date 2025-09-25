#!/bin/bash
# 修复Git LFS下载问题 - 直接下载实际文件
# 适用于燧原T20环境

set -e

echo "🔧 Git LFS下载修复工具"
echo "========================================"

# 自动检测项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ONTOTHINK_ROOT="$SCRIPT_DIR"
MODEL_DIR="${ONTOTHINK_ROOT}/enflame_training/models/THUDM/chatglm3-6b"

echo "📁 项目根目录: $ONTOTHINK_ROOT"
echo "📁 模型目录: $MODEL_DIR"

# 检查是否存在Git LFS指针文件
if [ -d "$MODEL_DIR" ]; then
    echo ""
    echo "🔍 检查当前文件状态..."
    
    # 检查tokenizer.model大小
    if [ -f "$MODEL_DIR/tokenizer.model" ]; then
        TOKENIZER_SIZE=$(stat -c%s "$MODEL_DIR/tokenizer.model" 2>/dev/null || echo "0")
        echo "📋 当前tokenizer.model大小: $TOKENIZER_SIZE bytes"
        
        if [ "$TOKENIZER_SIZE" -lt 1000000 ]; then  # 小于1MB说明是指针文件
            echo "⚠️  检测到Git LFS指针文件，需要直接下载实际文件"
            NEED_DOWNLOAD=true
        else
            echo "✅ tokenizer.model文件正常"
            NEED_DOWNLOAD=false
        fi
    else
        echo "❌ tokenizer.model文件不存在"
        NEED_DOWNLOAD=true
    fi
    
    # 检查模型权重文件
    WEIGHT_FILE="$MODEL_DIR/model-00001-of-00007.safetensors"
    if [ -f "$WEIGHT_FILE" ]; then
        WEIGHT_SIZE=$(stat -c%s "$WEIGHT_FILE" 2>/dev/null || echo "0")
        echo "📋 当前权重文件大小: $WEIGHT_SIZE bytes"
        
        if [ "$WEIGHT_SIZE" -lt 1000000 ]; then  # 小于1MB说明是指针文件
            echo "⚠️  检测到Git LFS权重文件指针，需要直接下载"
            NEED_DOWNLOAD=true
        fi
    fi
else
    echo "❌ 模型目录不存在"
    NEED_DOWNLOAD=true
fi

if [ "$NEED_DOWNLOAD" != "true" ]; then
    echo "✅ 模型文件已正常，无需重新下载"
    exit 0
fi

echo ""
echo "🔄 开始使用HTTP直接下载模型文件..."

# 清理损坏的目录
if [ -d "$MODEL_DIR" ]; then
    echo "🧹 清理损坏的模型目录..."
    rm -rf "$MODEL_DIR"
fi

# 创建目录
mkdir -p "$MODEL_DIR"
cd "$MODEL_DIR"

echo "📁 切换到模型目录: $PWD"

# ModelScope HTTP下载函数
download_from_modelscope() {
    echo "🔄 方法1: 使用ModelScope HTTP直接下载..."
    
    local BASE_URL="https://www.modelscope.cn/api/v1/models/ZhipuAI/chatglm3-6b/repo?Revision=master&FilePath="
    
    # 关键文件列表
    local FILES=(
        "config.json"
        "configuration_chatglm.py" 
        "modeling_chatglm.py"
        "tokenization_chatglm.py"
        "tokenizer_config.json"
        "special_tokens_map.json"
        "MODEL_LICENSE"
        "README.md"
        "quantization.py"
        "model.safetensors.index.json"
        "pytorch_model.bin.index.json"
        "tokenizer.model"
    )
    
    # 下载配置文件
    echo "📥 下载配置文件..."
    for file in "${FILES[@]}"; do
        echo "  - 下载 $file..."
        if wget -q --timeout=60 "${BASE_URL}${file}" -O "$file"; then
            echo "    ✅ $file 下载成功"
        else
            echo "    ❌ $file 下载失败，尝试curl..."
            if curl -s --connect-timeout 60 "${BASE_URL}${file}" -o "$file"; then
                echo "    ✅ $file (curl) 下载成功"
            else
                echo "    ⚠️  $file 下载失败，跳过"
            fi
        fi
    done
    
    # 下载模型权重文件 (safetensors格式优先)
    echo "📥 下载模型权重文件..."
    local WEIGHT_FILES=(
        "model-00001-of-00007.safetensors"
        "model-00002-of-00007.safetensors" 
        "model-00003-of-00007.safetensors"
        "model-00004-of-00007.safetensors"
        "model-00005-of-00007.safetensors"
        "model-00006-of-00007.safetensors"
        "model-00007-of-00007.safetensors"
    )
    
    for weight_file in "${WEIGHT_FILES[@]}"; do
        echo "  - 下载 $weight_file..."
        if wget -q --timeout=300 "${BASE_URL}${weight_file}" -O "$weight_file"; then
            local file_size=$(stat -c%s "$weight_file" 2>/dev/null || echo "0")
            if [ "$file_size" -gt 1000000 ]; then  # 大于1MB
                echo "    ✅ $weight_file 下载成功 (${file_size} bytes)"
            else
                echo "    ⚠️  $weight_file 可能下载不完整，尝试curl..."
                if curl -s --connect-timeout 300 "${BASE_URL}${weight_file}" -o "$weight_file"; then
                    file_size=$(stat -c%s "$weight_file" 2>/dev/null || echo "0")
                    echo "    ✅ $weight_file (curl) 下载成功 (${file_size} bytes)"
                else
                    echo "    ❌ $weight_file 下载失败"
                fi
            fi
        else
            echo "    ❌ $weight_file wget失败，尝试curl..."
            if curl -s --connect-timeout 300 "${BASE_URL}${weight_file}" -o "$weight_file"; then
                local file_size=$(stat -c%s "$weight_file" 2>/dev/null || echo "0")
                echo "    ✅ $weight_file (curl) 下载成功 (${file_size} bytes)"
            else
                echo "    ❌ $weight_file 下载失败"
            fi
        fi
    done
}

# Hugging Face HTTP下载函数  
download_from_huggingface() {
    echo "🔄 方法2: 使用Hugging Face HTTP直接下载..."
    
    local BASE_URL="https://huggingface.co/THUDM/chatglm3-6b/resolve/main/"
    
    # 下载tokenizer.model (最重要)
    echo "📥 优先下载tokenizer.model..."
    if wget -q --timeout=300 "${BASE_URL}tokenizer.model" -O "tokenizer.model"; then
        local file_size=$(stat -c%s "tokenizer.model" 2>/dev/null || echo "0")
        if [ "$file_size" -gt 1000000 ]; then
            echo "    ✅ tokenizer.model 下载成功 (${file_size} bytes)"
            return 0
        else
            echo "    ⚠️  tokenizer.model 大小异常，尝试curl..."
        fi
    fi
    
    if curl -s --connect-timeout 300 "${BASE_URL}tokenizer.model" -o "tokenizer.model"; then
        local file_size=$(stat -c%s "tokenizer.model" 2>/dev/null || echo "0")
        echo "    ✅ tokenizer.model (curl) 下载成功 (${file_size} bytes)"
        return 0
    else
        echo "    ❌ tokenizer.model 下载失败"
        return 1
    fi
}

# 使用Python huggingface_hub下载
download_with_python() {
    echo "🔄 方法3: 使用Python huggingface_hub下载..."
    
    python3 -c "
import os
import sys
try:
    from huggingface_hub import hf_hub_download
    import requests
    
    print('📥 下载tokenizer.model...')
    try:
        # 尝试下载tokenizer.model
        tokenizer_path = hf_hub_download(
            repo_id='THUDM/chatglm3-6b',
            filename='tokenizer.model',
            cache_dir=None,
            local_dir='.',
            local_dir_use_symlinks=False
        )
        
        # 检查文件大小
        if os.path.exists('./tokenizer.model'):
            size = os.path.getsize('./tokenizer.model')
            if size > 1000000:  # 大于1MB
                print(f'✅ tokenizer.model 下载成功 ({size} bytes)')
                sys.exit(0)
            else:
                print(f'⚠️  tokenizer.model 大小异常 ({size} bytes)')
        
    except Exception as e:
        print(f'❌ huggingface_hub下载失败: {e}')
        
    # 备用方案：直接HTTP下载
    print('📥 尝试直接HTTP下载...')
    try:
        import urllib.request
        url = 'https://huggingface.co/THUDM/chatglm3-6b/resolve/main/tokenizer.model'
        urllib.request.urlretrieve(url, './tokenizer.model')
        
        if os.path.exists('./tokenizer.model'):
            size = os.path.getsize('./tokenizer.model')
            print(f'✅ tokenizer.model HTTP下载成功 ({size} bytes)')
            sys.exit(0)
    except Exception as e:
        print(f'❌ HTTP下载失败: {e}')
        
    sys.exit(1)
        
except ImportError:
    print('❌ 未安装huggingface_hub，跳过Python下载方法')
    sys.exit(1)
"
}

# 尝试多种下载方法
echo "🔄 尝试多种下载方法..."

# 方法1: ModelScope HTTP
download_from_modelscope

# 检查tokenizer.model是否下载成功
if [ -f "tokenizer.model" ]; then
    TOKENIZER_SIZE=$(stat -c%s "tokenizer.model")
    if [ "$TOKENIZER_SIZE" -gt 1000000 ]; then
        echo "✅ ModelScope下载成功"
    else
        echo "⚠️  ModelScope下载的tokenizer.model大小异常，尝试其他方法..."
        
        # 方法2: Hugging Face HTTP
        download_from_huggingface
        
        # 方法3: Python huggingface_hub
        if [ ! -f "tokenizer.model" ] || [ "$(stat -c%s "tokenizer.model")" -lt 1000000 ]; then
            download_with_python
        fi
    fi
else
    echo "❌ ModelScope下载失败，尝试其他方法..."
    
    # 方法2: Hugging Face HTTP  
    download_from_huggingface
    
    # 方法3: Python huggingface_hub
    if [ ! -f "tokenizer.model" ] || [ "$(stat -c%s "tokenizer.model")" -lt 1000000 ]; then
        download_with_python
    fi
fi

echo ""
echo "🔍 检查下载结果..."

# 验证关键文件
if [ -f "config.json" ]; then
    echo "✅ config.json 存在"
else
    echo "❌ config.json 缺失"
fi

if [ -f "tokenizer.model" ]; then
    FINAL_SIZE=$(stat -c%s "tokenizer.model")
    echo "✅ tokenizer.model 存在 (${FINAL_SIZE} bytes)"
    
    if [ "$FINAL_SIZE" -gt 1000000 ]; then
        echo "✅ tokenizer.model 大小正常"
    else
        echo "❌ tokenizer.model 大小异常，可能仍是指针文件"
    fi
else
    echo "❌ tokenizer.model 缺失"
fi

# 检查权重文件
WEIGHT_COUNT=0
for i in {1..7}; do
    weight_file="model-0000${i}-of-00007.safetensors"
    if [ -f "$weight_file" ]; then
        file_size=$(stat -c%s "$weight_file")
        if [ "$file_size" -gt 1000000 ]; then
            ((WEIGHT_COUNT++))
            echo "✅ $weight_file 存在且大小正常 (${file_size} bytes)"
        else
            echo "⚠️  $weight_file 存在但大小异常 (${file_size} bytes)"
        fi
    else
        echo "❌ $weight_file 缺失"
    fi
done

if [ "$WEIGHT_COUNT" -gt 0 ]; then
    echo "✅ 有 $WEIGHT_COUNT 个权重文件下载成功"
else
    echo "❌ 所有权重文件下载失败"
fi

echo ""
echo "📊 当前目录内容:"
ls -la

echo ""
echo "🎉 Git LFS下载修复完成！"

# 验证tokenizer功能
echo ""
echo "📋 验证tokenizer功能..."
if [ -f "tokenizer.model" ]; then
    FINAL_TOKENIZER_SIZE=$(stat -c%s "tokenizer.model")
    echo "✅ 最终tokenizer.model大小: $FINAL_TOKENIZER_SIZE bytes"
    
    if [ "$FINAL_TOKENIZER_SIZE" -gt 1000000 ]; then
        # 验证tokenizer完整性
        python3 -c "
import sentencepiece as smp
try:
    sp = smp.SentencePieceProcessor()
    sp.load('tokenizer.model')
    print('✅ tokenizer验证通过')
except Exception as e:
    print(f'❌ tokenizer验证失败: {e}')
    exit(1)
" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "🎉 tokenizer修复成功！可以开始训练了"
        else
            echo "❌ tokenizer功能验证失败"
        fi
    else
        echo "❌ tokenizer.model文件仍然太小"
    fi
else
    echo "❌ tokenizer.model文件仍然缺失"
fi

echo ""
echo "📋 下一步:"
echo "cd $ONTOTHINK_ROOT"
echo "python3 enflame_training/scripts/train_ontothink_enflame.py --step full"