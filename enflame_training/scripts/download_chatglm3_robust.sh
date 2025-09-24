#!/bin/bash

echo "🚀 ChatGLM3-6B 增强版下载器"
echo "适用于燧原T20环境 - 包含完整性验证"
echo "======================================"

# 检测项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ONTOTHINK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MODEL_DIR="$ONTOTHINK_ROOT/enflame_training/models/THUDM/chatglm3-6b"

echo "📁 项目根目录: $ONTOTHINK_ROOT"
echo "📁 目标目录: $MODEL_DIR"
echo

# 创建模型目录
mkdir -p "$(dirname "$MODEL_DIR")"

# 如果目录存在且不为空，先检查是否完整
if [ -d "$MODEL_DIR" ] && [ "$(ls -A "$MODEL_DIR" 2>/dev/null)" ]; then
    echo "📋 检查现有模型文件..."
    
    # 检查关键文件
    missing_files=()
    required_files=("config.json" "tokenizer.model" "tokenizer_config.json" "modeling_chatglm.py")
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$MODEL_DIR/$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    # 检查模型权重文件
    if [ ! -f "$MODEL_DIR/pytorch_model.bin.index.json" ] && [ ! -f "$MODEL_DIR/model.safetensors.index.json" ]; then
        missing_files+=("模型权重索引文件")
    fi
    
    # 检查tokenizer.model文件大小
    if [ -f "$MODEL_DIR/tokenizer.model" ]; then
        file_size=$(stat -c%s "$MODEL_DIR/tokenizer.model" 2>/dev/null || stat -f%z "$MODEL_DIR/tokenizer.model" 2>/dev/null)
        if [ "$file_size" -lt 1000000 ]; then
            missing_files+=("tokenizer.model (文件损坏)")
        fi
    fi
    
    if [ ${#missing_files[@]} -eq 0 ]; then
        echo "✅ 现有模型文件完整，跳过下载"
        
        # 验证tokenizer完整性
        echo "🔍 验证tokenizer完整性..."
        python3 -c "
import sentencepiece as spm
try:
    sp = spm.SentencePieceProcessor()
    sp.load('$MODEL_DIR/tokenizer.model')
    print('✅ tokenizer验证通过')
except Exception as e:
    print(f'❌ tokenizer验证失败: {e}')
    exit(1)
" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "🎉 模型文件完整且有效！"
            exit 0
        else
            echo "⚠️  tokenizer验证失败，需要重新下载"
        fi
    else
        echo "⚠️  发现缺失文件: ${missing_files[*]}"
        echo "🔄 需要重新下载完整模型"
    fi
    
    # 清理不完整的下载
    echo "🧹 清理不完整的模型文件..."
    rm -rf "$MODEL_DIR"
fi

echo "📥 开始下载ChatGLM3-6B模型..."

# 下载方法函数
download_with_modelscope() {
    echo "🔄 方法1: 使用ModelScope镜像..."
    cd "$(dirname "$MODEL_DIR")"
    
    # 使用git clone下载
    if command -v git >/dev/null 2>&1; then
        git clone https://www.modelscope.cn/ZhipuAI/chatglm3-6b.git chatglm3-6b
        return $?
    else
        echo "❌ git命令不可用"
        return 1
    fi
}

download_with_huggingface() {
    echo "🔄 方法2: 使用Hugging Face官方源..."
    cd "$(dirname "$MODEL_DIR")"
    
    if command -v git >/dev/null 2>&1; then
        # 设置git lfs
        git lfs install 2>/dev/null || true
        git clone https://huggingface.co/THUDM/chatglm3-6b chatglm3-6b
        return $?
    else
        echo "❌ git命令不可用"
        return 1
    fi
}

download_with_python() {
    echo "🔄 方法3: 使用Python下载..."
    python3 << 'EOF'
import os
from huggingface_hub import snapshot_download

try:
    model_dir = os.environ.get('MODEL_DIR')
    snapshot_download(
        repo_id="THUDM/chatglm3-6b",
        local_dir=model_dir,
        local_dir_use_symlinks=False
    )
    print("✅ Python下载成功")
except Exception as e:
    print(f"❌ Python下载失败: {e}")
    exit(1)
EOF
    return $?
}

# 验证下载完整性
verify_download() {
    echo "🔍 验证下载完整性..."
    
    # 检查关键文件
    required_files=("config.json" "tokenizer.model" "tokenizer_config.json" "modeling_chatglm.py")
    for file in "${required_files[@]}"; do
        if [ ! -f "$MODEL_DIR/$file" ]; then
            echo "❌ 缺失文件: $file"
            return 1
        fi
    done
    
    # 检查模型权重
    if [ ! -f "$MODEL_DIR/pytorch_model.bin.index.json" ] && [ ! -f "$MODEL_DIR/model.safetensors.index.json" ]; then
        echo "❌ 缺失模型权重索引文件"
        return 1
    fi
    
    # 验证tokenizer.model大小
    if [ -f "$MODEL_DIR/tokenizer.model" ]; then
        file_size=$(stat -c%s "$MODEL_DIR/tokenizer.model" 2>/dev/null || stat -f%z "$MODEL_DIR/tokenizer.model" 2>/dev/null)
        if [ "$file_size" -lt 1000000 ]; then
            echo "❌ tokenizer.model文件过小，可能损坏"
            return 1
        fi
        echo "✅ tokenizer.model大小: ${file_size} bytes"
    fi
    
    # 验证tokenizer功能
    echo "🔍 验证tokenizer功能..."
    python3 -c "
import sentencepiece as spm
try:
    sp = spm.SentencePieceProcessor()
    sp.load('$MODEL_DIR/tokenizer.model')
    # 测试编码解码
    test_text = '你好，世界！'
    tokens = sp.encode(test_text)
    decoded = sp.decode(tokens)
    print(f'✅ tokenizer功能测试通过: \"{test_text}\" -> {len(tokens)} tokens')
except Exception as e:
    print(f'❌ tokenizer功能测试失败: {e}')
    exit(1)
" 2>/dev/null
    
    return $?
}

# 尝试不同的下载方法
success=false
methods=("download_with_modelscope" "download_with_huggingface" "download_with_python")

for method in "${methods[@]}"; do
    echo
    $method
    if [ $? -eq 0 ]; then
        # 验证下载
        if verify_download; then
            echo "✅ 下载并验证成功！"
            success=true
            break
        else
            echo "❌ 下载验证失败，尝试下一种方法"
            rm -rf "$MODEL_DIR" 2>/dev/null || true
        fi
    else
        echo "❌ 下载失败，尝试下一种方法"
        rm -rf "$MODEL_DIR" 2>/dev/null || true
    fi
done

if [ "$success" = true ]; then
    echo
    echo "🎉 ChatGLM3-6B下载完成！"
    echo
    echo "📋 下一步:"
    echo "cd $ONTOTHINK_ROOT"
    echo "python3 enflame_training/scripts/train_ontothink_enflame.py --step full"
    echo
    echo "📊 模型文件信息:"
    ls -la "$MODEL_DIR/" | head -20
else
    echo
    echo "❌ 所有下载方法都失败了"
    echo "请检查网络连接或手动下载模型文件"
    echo
    echo "💡 手动下载方法:"
    echo "1. 访问: https://www.modelscope.cn/ZhipuAI/chatglm3-6b"
    echo "2. 或访问: https://huggingface.co/THUDM/chatglm3-6b"
    echo "3. 下载到: $MODEL_DIR"
    exit 1
fi
