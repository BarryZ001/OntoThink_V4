#!/bin/bash
# ChatGLM3 完整修复工具 - 彻底解决tokenizer和模型文件问题
# 适用于燧原T20环境

set -e

echo "🔧 ChatGLM3 完整修复工具"
echo "适用于燧原T20环境"
echo "========================================"

# 自动检测项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ONTOTHINK_ROOT="$SCRIPT_DIR"
MODEL_DIR="${ONTOTHINK_ROOT}/enflame_training/models/THUDM/chatglm3-6b"

echo "📁 项目根目录: $ONTOTHINK_ROOT"
echo "📁 模型目录: $MODEL_DIR"

# 彻底清理现有模型
echo ""
echo "🧹 彻底清理现有模型文件..."
if [ -d "$MODEL_DIR" ]; then
    echo "🗑️  删除现有模型目录..."
    rm -rf "$MODEL_DIR"
fi

# 清理Hugging Face缓存
echo "🧹 清理Hugging Face缓存..."
if [ -d "$HOME/.cache/huggingface" ]; then
    rm -rf "$HOME/.cache/huggingface"
    echo "✅ Hugging Face缓存已清理"
fi

# 清理transformers缓存
echo "🧹 清理transformers缓存..."
if [ -d "$HOME/.cache/torch" ]; then
    rm -rf "$HOME/.cache/torch"
    echo "✅ Torch缓存已清理"
fi

# 创建模型目录
echo ""
echo "📁 创建模型目录..."
mkdir -p "$MODEL_DIR"
cd "$MODEL_DIR"

echo "📁 当前目录: $PWD"

# 方法1: 使用git clone (最可靠的方法)
echo ""
echo "🔄 方法1: 使用git clone直接下载..."
echo "这是最可靠的方法，会下载完整的仓库"

# 设置Git LFS环境
export GIT_LFS_SKIP_SMUDGE=0

if git clone https://huggingface.co/THUDM/chatglm3-6b . --depth 1; then
    echo "✅ Git clone成功"
    
    # 检查Git LFS
    echo "🔍 检查Git LFS状态..."
    if command -v git-lfs >/dev/null 2>&1; then
        echo "✅ Git LFS已安装"
        
        # 确保LFS文件下载
        echo "📥 确保LFS文件下载..."
        git lfs pull
        
        # 检查LFS状态
        git lfs ls-files
    else
        echo "⚠️  Git LFS未安装，尝试安装..."
        # 尝试安装git-lfs (如果可能)
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update && sudo apt-get install -y git-lfs
            git lfs install
            git lfs pull
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y git-lfs
            git lfs install
            git lfs pull
        else
            echo "❌ 无法自动安装Git LFS，继续其他方法..."
        fi
    fi
else
    echo "❌ Git clone失败，尝试其他方法..."
fi

# 检查关键文件
echo ""
echo "🔍 检查关键文件状态..."

check_file_integrity() {
    local file=$1
    local min_size=$2
    local file_desc=$3
    
    if [ -f "$file" ]; then
        local size=$(stat -c%s "$file" 2>/dev/null || echo "0")
        echo "📋 $file_desc: $size bytes"
        
        if [ "$size" -gt "$min_size" ]; then
            echo "✅ $file_desc 大小正常"
            return 0
        else
            echo "❌ $file_desc 大小异常 (可能是LFS指针文件)"
            return 1
        fi
    else
        echo "❌ $file_desc 不存在"
        return 1
    fi
}

# 检查tokenizer.model
TOKENIZER_OK=false
if check_file_integrity "tokenizer.model" 1000000 "tokenizer.model"; then
    TOKENIZER_OK=true
fi

# 检查权重文件
WEIGHTS_OK=false
if check_file_integrity "pytorch_model-00001-of-00007.bin" 100000000 "权重文件"; then
    WEIGHTS_OK=true
fi

# 如果文件不完整，尝试Python方法下载
if [ "$TOKENIZER_OK" = false ] || [ "$WEIGHTS_OK" = false ]; then
    echo ""
    echo "🔄 方法2: 使用Python huggingface_hub下载..."
    
    python3 -c "
import os
import sys
from pathlib import Path

print('🐍 Python下载方法启动...')

try:
    from huggingface_hub import snapshot_download
    print('✅ huggingface_hub可用')
    
    # 下载完整模型
    print('📥 下载完整ChatGLM3模型...')
    local_dir = Path('.')
    
    snapshot_download(
        repo_id='THUDM/chatglm3-6b',
        local_dir=local_dir,
        local_dir_use_symlinks=False,
        resume_download=True,
        force_download=False
    )
    
    print('✅ Python下载完成')
    
except ImportError:
    print('❌ huggingface_hub未安装，尝试安装...')
    import subprocess
    try:
        subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'huggingface_hub>=0.16.0'])
        print('✅ huggingface_hub安装成功，重新尝试下载...')
        
        from huggingface_hub import snapshot_download
        snapshot_download(
            repo_id='THUDM/chatglm3-6b',
            local_dir=Path('.'),
            local_dir_use_symlinks=False,
            resume_download=True
        )
        print('✅ Python下载完成')
    except Exception as e:
        print(f'❌ 安装失败: {e}')
        sys.exit(1)
        
except Exception as e:
    print(f'❌ Python下载失败: {e}')
    sys.exit(1)
"
fi

# 如果还是失败，尝试wget直接下载关键文件
echo ""
echo "🔄 方法3: 直接下载关键文件..."

download_critical_files() {
    echo "📥 下载关键文件..."
    
    # 文件URL映射
    declare -A FILE_URLS=(
        ["config.json"]="https://huggingface.co/THUDM/chatglm3-6b/resolve/main/config.json"
        ["tokenizer_config.json"]="https://huggingface.co/THUDM/chatglm3-6b/resolve/main/tokenizer_config.json"
        ["special_tokens_map.json"]="https://huggingface.co/THUDM/chatglm3-6b/resolve/main/special_tokens_map.json"
        ["tokenizer.model"]="https://huggingface.co/THUDM/chatglm3-6b/resolve/main/tokenizer.model"
        ["modeling_chatglm.py"]="https://huggingface.co/THUDM/chatglm3-6b/resolve/main/modeling_chatglm.py"
        ["tokenization_chatglm.py"]="https://huggingface.co/THUDM/chatglm3-6b/resolve/main/tokenization_chatglm.py"
        ["configuration_chatglm.py"]="https://huggingface.co/THUDM/chatglm3-6b/resolve/main/configuration_chatglm.py"
    )
    
    for file in "${!FILE_URLS[@]}"; do
        url="${FILE_URLS[$file]}"
        echo "  📄 下载 $file..."
        
        if wget -q --timeout=60 "$url" -O "$file"; then
            local size=$(stat -c%s "$file" 2>/dev/null || echo "0")
            echo "    ✅ $file 下载成功 ($size bytes)"
        else
            echo "    ⚠️  $file wget失败，尝试curl..."
            if curl -s --connect-timeout 60 "$url" -o "$file"; then
                local size=$(stat -c%s "$file" 2>/dev/null || echo "0")
                echo "    ✅ $file curl下载成功 ($size bytes)"
            else
                echo "    ❌ $file 下载失败"
            fi
        fi
    done
}

# 检查tokenizer是否还有问题
if [ ! -f "tokenizer.model" ] || [ "$(stat -c%s "tokenizer.model")" -lt 1000000 ]; then
    download_critical_files
fi

# 最终验证
echo ""
echo "🔍 最终验证..."

# 验证tokenizer功能
echo "🔧 验证tokenizer功能..."
python3 -c "
import sys
import os
sys.path.append('.')

try:
    import sentencepiece as spm
    
    # 检查文件是否存在
    if not os.path.exists('tokenizer.model'):
        print('❌ tokenizer.model文件不存在')
        sys.exit(1)
    
    # 检查文件大小
    size = os.path.getsize('tokenizer.model')
    print(f'📋 tokenizer.model大小: {size} bytes')
    
    if size < 1000000:  # 小于1MB
        print('❌ tokenizer.model文件过小，可能损坏')
        sys.exit(1)
    
    # 测试加载
    sp = smp.SentencePieceProcessor()
    sp.load('tokenizer.model')
    
    # 测试编码
    test_text = '你好，世界！'
    tokens = sp.encode(test_text)
    decoded = sp.decode(tokens)
    
    print(f'✅ tokenizer功能正常')
    print(f'   测试文本: {test_text}')
    print(f'   tokens: {tokens}')
    print(f'   解码结果: {decoded}')
    
except ImportError as e:
    print(f'❌ sentencepiece未安装: {e}')
    print('💡 尝试安装: pip install sentencepiece')
    sys.exit(1)
except Exception as e:
    print(f'❌ tokenizer测试失败: {e}')
    sys.exit(1)
" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "🎉 tokenizer验证通过!"
else
    echo "❌ tokenizer验证失败"
    
    # 最后的备选方案：从其他源下载
    echo ""
    echo "🔄 最后尝试：从ModelScope下载tokenizer..."
    
    python3 -c "
import urllib.request
import os

try:
    # ModelScope镜像URL
    url = 'https://www.modelscope.cn/api/v1/models/ZhipuAI/chatglm3-6b/repo?Revision=master&FilePath=tokenizer.model'
    
    print('📥 从ModelScope下载tokenizer.model...')
    urllib.request.urlretrieve(url, 'tokenizer.model')
    
    size = os.path.getsize('tokenizer.model')
    print(f'✅ 下载完成，大小: {size} bytes')
    
except Exception as e:
    print(f'❌ ModelScope下载失败: {e}')
"
fi

# 显示目录内容
echo ""
echo "📊 当前目录内容:"
ls -la

# 检查关键文件
echo ""
echo "🔍 关键文件检查:"
for file in "config.json" "tokenizer.model" "modeling_chatglm.py" "tokenization_chatglm.py"; do
    if [ -f "$file" ]; then
        size=$(stat -c%s "$file")
        echo "✅ $file: $size bytes"
    else
        echo "❌ $file: 缺失"
    fi
done

echo ""
echo "🎉 ChatGLM3 完整修复完成！"

# 最终的tokenizer测试
echo ""
echo "🧪 最终tokenizer测试..."
python3 -c "
try:
    import sentencepiece as smp
    sp = smp.SentencePieceProcessor()
    sp.load('tokenizer.model')
    
    # 编码测试
    text = 'ChatGLM3是一个对话语言模型'
    tokens = sp.encode(text)
    decoded = sp.decode(tokens)
    
    print('🎯 Tokenizer最终测试结果:')
    print(f'   原文: {text}')
    print(f'   Token数量: {len(tokens)}')
    print(f'   解码结果: {decoded}')
    print('✅ 所有测试通过，可以开始训练!')
    
except Exception as e:
    print(f'❌ 最终测试失败: {e}')
    print('🔧 建议手动检查tokenizer.model文件')
    exit(1)
"

echo ""
echo "📋 下一步："
echo "cd $ONTOTHINK_ROOT"
echo "python3 enflame_training/scripts/train_ontothink_enflame.py --step full"
