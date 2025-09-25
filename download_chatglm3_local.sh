#!/bin/bash
# ChatGLM3 本地Mac下载脚本
# 利用本地网络优势下载模型

set -e

echo "🚀 ChatGLM3 本地Mac下载器"
echo "利用本地网络优势，避免服务器网络限制"
echo "=========================================="

# 检测脚本位置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL_DIR="${SCRIPT_DIR}/enflame_training/models/THUDM/chatglm3-6b"

echo "📁 下载目录: $MODEL_DIR"

# 创建目录
mkdir -p "$MODEL_DIR"
cd "$MODEL_DIR"

echo "📁 当前目录: $PWD"

# 方法1: 尝试使用huggingface_hub (最稳定)
echo ""
echo "🔄 方法1: 使用huggingface_hub下载..."

python3 -c "
import sys
import os
from pathlib import Path

print('🐍 检查并安装huggingface_hub...')

try:
    from huggingface_hub import snapshot_download
    print('✅ huggingface_hub已安装')
except ImportError:
    print('📦 安装huggingface_hub...')
    import subprocess
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'huggingface_hub>=0.16.0'])
    from huggingface_hub import snapshot_download
    print('✅ huggingface_hub安装完成')

print('📥 开始下载ChatGLM3-6B...')
print('💡 这可能需要10-30分钟，取决于网络速度')

try:
    snapshot_download(
        repo_id='THUDM/chatglm3-6b',
        local_dir='.',
        local_dir_use_symlinks=False,
        resume_download=True,
        force_download=False
    )
    print('✅ huggingface_hub下载完成!')
except Exception as e:
    print(f'❌ huggingface_hub下载失败: {e}')
    print('💡 将尝试其他下载方法...')
    sys.exit(1)
"

HF_SUCCESS=$?

# 如果huggingface_hub失败，尝试git clone
if [ $HF_SUCCESS -ne 0 ]; then
    echo ""
    echo "🔄 方法2: 使用git clone + LFS..."
    
    # 检查git-lfs
    if ! command -v git-lfs >/dev/null 2>&1; then
        echo "📦 安装git-lfs..."
        if command -v brew >/dev/null 2>&1; then
            brew install git-lfs
        else
            echo "❌ 请手动安装git-lfs: https://git-lfs.github.io/"
            exit 1
        fi
    fi
    
    git lfs install
    
    # 清空目录重新开始
    cd ..
    rm -rf chatglm3-6b
    
    echo "📥 克隆仓库..."
    if git clone https://huggingface.co/THUDM/chatglm3-6b; then
        cd chatglm3-6b
        echo "📥 下载LFS文件..."
        git lfs pull
        echo "✅ git clone下载完成!"
    else
        echo "❌ git clone也失败了"
        exit 1
    fi
fi

# 验证下载结果
echo ""
echo "🔍 验证下载结果..."

# 检查tokenizer
if [ -f "tokenizer.model" ]; then
    size=$(stat -f%z "tokenizer.model")
    echo "📋 tokenizer.model: $size bytes"
    if [ $size -gt 1000000 ]; then
        echo "✅ tokenizer.model 大小正常"
    else
        echo "❌ tokenizer.model 过小，可能是LFS指针"
    fi
else
    echo "❌ tokenizer.model 不存在"
fi

# 检查权重文件
echo ""
echo "📋 权重文件检查:"
weight_count=0
for i in {1..7}; do
    safetensor_file="model-0000${i}-of-00007.safetensors"
    pytorch_file="pytorch_model-0000${i}-of-00007.bin"
    
    if [ -f "$safetensor_file" ]; then
        size=$(stat -f%z "$safetensor_file")
        if [ $size -gt 100000000 ]; then  # 大于100MB
            echo "✅ $safetensor_file: $(echo $size | awk '{printf "%.1f MB", $1/1024/1024}')"
            ((weight_count++))
        else
            echo "❌ $safetensor_file: $size bytes (可能是LFS指针)"
        fi
    elif [ -f "$pytorch_file" ]; then
        size=$(stat -f%z "$pytorch_file")
        if [ $size -gt 100000000 ]; then  # 大于100MB
            echo "✅ $pytorch_file: $(echo $size | awk '{printf "%.1f MB", $1/1024/1024}')"
            ((weight_count++))
        else
            echo "❌ $pytorch_file: $size bytes (可能是LFS指针)"
        fi
    else
        echo "❌ 权重文件 $i 不存在"
    fi
done

echo "📊 权重文件统计: $weight_count/7 完整"

# 检查配置文件
echo ""
echo "📋 配置文件检查:"
config_files=("config.json" "tokenizer_config.json" "special_tokens_map.json" "modeling_chatglm.py" "tokenization_chatglm.py" "configuration_chatglm.py")
config_count=0

for file in "${config_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
        ((config_count++))
    else
        echo "❌ $file 缺失"
    fi
done

echo "📊 配置文件统计: $config_count/${#config_files[@]} 完整"

# 总体评估
echo ""
echo "=========================================="
if [ $weight_count -eq 7 ] && [ $config_count -eq ${#config_files[@]} ]; then
    echo "🎉 下载完成且文件完整!"
    
    # 测试tokenizer功能
    echo ""
    echo "🧪 测试tokenizer功能..."
    python3 -c "
try:
    import sentencepiece as smp
    sp = spm.SentencePieceProcessor()
    sp.load('tokenizer.model')
    
    # 测试编码
    text = 'ChatGLM3是一个对话语言模型'
    tokens = sp.encode(text)
    decoded = sp.decode(tokens)
    
    print('✅ Tokenizer功能正常')
    print(f'   测试文本: {text}')
    print(f'   Token数量: {len(tokens)}')
    print(f'   解码结果: {decoded}')
    
except ImportError:
    print('⚠️  sentencepiece未安装，但tokenizer文件存在')
    print('   安装命令: pip install sentencepiece')
except Exception as e:
    print(f'❌ Tokenizer测试失败: {e}')
"
    
    echo ""
    echo "📤 下一步：上传到服务器"
    echo "执行以下命令："
    echo ""
    echo "# 方法1: 使用rsync上传（推荐）"
    echo "cd $(dirname "$MODEL_DIR")"
    echo "rsync -avz --progress -e \"ssh -p 60025\" chatglm3-6b/ root@117.156.108.234:/workspace/code/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b/"
    echo ""
    echo "# 方法2: 压缩后上传"
    echo "tar -czf chatglm3-6b.tar.gz chatglm3-6b/"
    echo "scp -P 60025 chatglm3-6b.tar.gz root@117.156.108.234:/workspace/code/OntoThink_V4/enflame_training/models/THUDM/"
    echo ""
    echo "📋 详细说明请查看: download_and_upload_chatglm3.md"
    
else
    echo "❌ 下载不完整，请检查网络连接后重试"
    echo "   权重文件: $weight_count/7"
    echo "   配置文件: $config_count/${#config_files[@]}"
fi

echo ""
echo "📁 模型位置: $MODEL_DIR"
echo "📊 目录大小: $(du -sh . | cut -f1)"
