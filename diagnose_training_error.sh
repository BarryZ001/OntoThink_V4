#!/bin/bash
# 训练错误诊断脚本 - 彻底分析问题根源
# 适用于燧原T20环境

set -e

echo "🔍 OntoThink 训练错误诊断工具"
echo "========================================"

# 自动检测项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ONTOTHINK_ROOT="$SCRIPT_DIR"
MODEL_DIR="${ONTOTHINK_ROOT}/enflame_training/models/THUDM/chatglm3-6b"

echo "📁 项目根目录: $ONTOTHINK_ROOT"
echo "📁 模型目录: $MODEL_DIR"

# 1. 检查模型文件状态
echo ""
echo "🔍 1. 检查模型文件状态"
echo "----------------------------------------"

if [ -d "$MODEL_DIR" ]; then
    cd "$MODEL_DIR"
    echo "📁 模型目录存在"
    
    # 检查关键文件
    echo ""
    echo "📋 关键文件检查:"
    
    # tokenizer.model
    if [ -f "tokenizer.model" ]; then
        size=$(stat -c%s "tokenizer.model")
        echo "tokenizer.model: $size bytes"
        
        if [ "$size" -gt 1000000 ]; then
            echo "✅ tokenizer.model 大小正常"
            
            # 测试tokenizer功能
            echo "🧪 测试tokenizer功能..."
            python3 -c "
import sentencepiece as smp
try:
    sp = smp.SentencePieceProcessor()
    sp.load('tokenizer.model')
    print('✅ tokenizer加载成功')
    
    # 编码测试
    tokens = sp.encode('测试文本')
    decoded = sp.decode(tokens)
    print(f'✅ 编码解码正常: {len(tokens)} tokens')
except Exception as e:
    print(f'❌ tokenizer功能异常: {e}')
    exit(1)
" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                echo "✅ tokenizer功能正常"
            else
                echo "❌ tokenizer功能异常"
            fi
        else
            echo "❌ tokenizer.model过小，可能损坏"
        fi
    else
        echo "❌ tokenizer.model不存在"
    fi
    
    # 权重文件
    echo ""
    echo "📋 权重文件检查:"
    weight_count=0
    for i in {1..7}; do
        safetensor_file="model-0000${i}-of-00007.safetensors"
        pytorch_file="pytorch_model-0000${i}-of-00007.bin"
        
        if [ -f "$safetensor_file" ]; then
            size=$(stat -c%s "$safetensor_file")
            if [ "$size" -gt 100000000 ]; then
                echo "✅ $safetensor_file: $(echo $size | awk '{printf "%.1f MB", $1/1024/1024}')"
                ((weight_count++))
            else
                echo "❌ $safetensor_file: $size bytes (疑似LFS指针)"
            fi
        elif [ -f "$pytorch_file" ]; then
            size=$(stat -c%s "$pytorch_file")
            if [ "$size" -gt 100000000 ]; then
                echo "✅ $pytorch_file: $(echo $size | awk '{printf "%.1f MB", $1/1024/1024}')"
                ((weight_count++))
            else
                echo "❌ $pytorch_file: $size bytes (疑似LFS指针)"
            fi
        else
            echo "❌ 权重文件 $i 缺失"
        fi
    done
    
    echo "📊 权重文件统计: $weight_count/7"
    
    # 配置文件
    echo ""
    echo "📋 配置文件检查:"
    config_files=("config.json" "tokenizer_config.json" "modeling_chatglm.py" "tokenization_chatglm.py")
    for file in "${config_files[@]}"; do
        if [ -f "$file" ]; then
            echo "✅ $file"
        else
            echo "❌ $file 缺失"
        fi
    done
    
else
    echo "❌ 模型目录不存在: $MODEL_DIR"
fi

# 2. 检查Python环境
echo ""
echo "🔍 2. 检查Python环境"
echo "----------------------------------------"

echo "🐍 Python版本:"
python3 --version

echo ""
echo "📦 关键包检查:"
python3 -c "
packages = [
    'torch', 'transformers', 'accelerate', 'peft', 
    'sentencepiece', 'ptex', 'collie_lm', 'deepspeed'
]

for pkg in packages:
    try:
        module = __import__(pkg)
        version = getattr(module, '__version__', 'unknown')
        print(f'✅ {pkg}: {version}')
    except ImportError:
        print(f'❌ {pkg}: 未安装')
    except Exception as e:
        print(f'⚠️  {pkg}: 导入异常 - {e}')
"

# 3. 检查燧原环境
echo ""
echo "🔍 3. 检查燧原T20环境"
echo "----------------------------------------"

# 检查燧原工具包
ENFLAME_PATHS=(
    "${ONTOTHINK_ROOT}/FromEnflame/ai_development_toolkit/distributed"
    "/installer/topsrider_extracted/TopsRider_installer/ai_development_toolkit/distributed"
)

FOUND_ENFLAME=false
for path in "${ENFLAME_PATHS[@]}"; do
    if [ -d "$path" ]; then
        echo "✅ 燧原工具包: $path"
        FOUND_ENFLAME=true
        
        # 检查LLM脚本
        if [ -d "$path/llm_scripts_1.0.40/finetuning/chatglm3" ]; then
            echo "✅ ChatGLM3脚本目录存在"
            
            script_file="$path/llm_scripts_1.0.40/finetuning/chatglm3/finetune_chatglm3_for_multiturn.py"
            if [ -f "$script_file" ]; then
                echo "✅ 训练脚本存在"
            else
                echo "❌ 训练脚本缺失: $script_file"
            fi
        else
            echo "❌ ChatGLM3脚本目录缺失"
        fi
        break
    fi
done

if [ "$FOUND_ENFLAME" = false ]; then
    echo "❌ 未找到燧原工具包"
fi

# 4. 检查训练数据
echo ""
echo "🔍 4. 检查训练数据"
echo "----------------------------------------"

DATA_DIR="${ONTOTHINK_ROOT}/enflame_training/datasets/ontothink_multiturn"
if [ -d "$DATA_DIR" ]; then
    echo "✅ 数据目录存在: $DATA_DIR"
    
    if [ -f "$DATA_DIR/train.jsonl" ]; then
        line_count=$(wc -l < "$DATA_DIR/train.jsonl")
        echo "✅ 训练数据: $line_count 行"
    else
        echo "❌ 训练数据文件缺失"
    fi
else
    echo "❌ 数据目录不存在"
fi

# 5. 运行快速训练测试
echo ""
echo "🔍 5. 运行快速训练测试"
echo "----------------------------------------"

if [ -f "$MODEL_DIR/tokenizer.model" ] && [ -f "$MODEL_DIR/config.json" ]; then
    echo "🧪 测试模型加载..."
    
    cd "$MODEL_DIR"
    python3 -c "
import sys
import os
sys.path.append('.')

try:
    from transformers import AutoTokenizer, AutoModel
    
    print('📥 加载tokenizer...')
    tokenizer = AutoTokenizer.from_pretrained('.', trust_remote_code=True)
    print('✅ Tokenizer加载成功')
    
    print('📥 加载模型配置...')
    # 只加载配置，不加载权重
    from transformers import AutoConfig
    config = AutoConfig.from_pretrained('.', trust_remote_code=True)
    print('✅ 模型配置加载成功')
    
    print('🧪 测试tokenizer编码...')
    text = 'ChatGLM3测试文本'
    tokens = tokenizer.encode(text)
    decoded = tokenizer.decode(tokens)
    print(f'✅ 编码测试通过: {len(tokens)} tokens')
    print(f'   原文: {text}')
    print(f'   解码: {decoded}')
    
except Exception as e:
    print(f'❌ 模型加载测试失败: {e}')
    import traceback
    traceback.print_exc()
    sys.exit(1)
"
    
    if [ $? -eq 0 ]; then
        echo "✅ 模型加载测试通过"
    else
        echo "❌ 模型加载测试失败"
    fi
else
    echo "⚠️  跳过模型加载测试（文件缺失）"
fi

# 6. 生成修复建议
echo ""
echo "🔧 6. 修复建议"
echo "----------------------------------------"

echo "基于诊断结果，建议执行以下操作："
echo ""

# 检查主要问题
if [ ! -f "$MODEL_DIR/tokenizer.model" ] || [ "$(stat -c%s "$MODEL_DIR/tokenizer.model" 2>/dev/null || echo 0)" -lt 1000000 ]; then
    echo "🔴 主要问题: tokenizer.model缺失或损坏"
    echo "   解决方案:"
    echo "   1. 在本地Mac下载完整模型:"
    echo "      ./download_chatglm3_local.sh"
    echo "   2. 上传到服务器:"
    echo "      rsync -avz --progress -e 'ssh -p 60025' chatglm3-6b/ root@117.156.108.234:/workspace/code/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b/"
    echo ""
fi

if [ "$weight_count" -lt 7 ]; then
    echo "🔴 主要问题: 权重文件不完整 ($weight_count/7)"
    echo "   解决方案: 需要重新下载完整模型"
    echo ""
fi

echo "🔄 快速修复命令："
echo "# 1. 使用Git LFS修复工具"
echo "bash ${ONTOTHINK_ROOT}/fix_git_lfs_download.sh"
echo ""
echo "# 2. 使用完整修复工具" 
echo "bash ${ONTOTHINK_ROOT}/fix_chatglm3_complete.sh"
echo ""
echo "# 3. 手动Python下载"
echo "python3 ${ONTOTHINK_ROOT}/enflame_training/scripts/manual_download_chatglm3.py"

echo ""
echo "========================================"
echo "🏁 诊断完成"
echo ""
echo "📋 如需详细帮助，请查看:"
echo "   - download_and_upload_chatglm3.md"
echo "   - fix_chatglm3_complete.sh"
echo "   - manual_download_chatglm3.py"
