#!/bin/bash

echo "🔧 ChatGLM3 Tokenizer 修复工具"
echo "适用于燧原T20环境"
echo "======================================="

# 检测项目根目录
if [ -f "enflame_training/scripts/download_chatglm3_simple.sh" ]; then
    ONTOTHINK_ROOT="$(pwd)"
elif [ -f "../enflame_training/scripts/download_chatglm3_simple.sh" ]; then
    ONTOTHINK_ROOT="$(cd .. && pwd)"
else
    echo "❌ 错误: 未找到项目根目录"
    exit 1
fi

MODEL_DIR="$ONTOTHINK_ROOT/enflame_training/models/THUDM/chatglm3-6b"

echo "📁 项目根目录: $ONTOTHINK_ROOT"
echo "📁 模型目录: $MODEL_DIR"
echo

# 检查tokenizer.model文件
if [ -f "$MODEL_DIR/tokenizer.model" ]; then
    file_size=$(stat -c%s "$MODEL_DIR/tokenizer.model" 2>/dev/null || stat -f%z "$MODEL_DIR/tokenizer.model" 2>/dev/null)
    echo "📋 当前tokenizer.model大小: ${file_size} bytes"
    
    # 如果文件太小（正常应该几MB），说明损坏了
    if [ "$file_size" -lt 1000000 ]; then
        echo "⚠️  检测到tokenizer.model文件损坏（文件过小）"
        NEED_REDOWNLOAD=true
    else
        echo "✅ tokenizer.model文件大小正常"
        
        # 尝试验证文件完整性
        echo "🔍 验证tokenizer文件完整性..."
        python3 -c "
import sentencepiece as spm
try:
    sp = spm.SentencePieceProcessor()
    sp.load('$MODEL_DIR/tokenizer.model')
    print('✅ tokenizer.model文件完整性验证通过')
except Exception as e:
    print(f'❌ tokenizer.model文件损坏: {e}')
    exit(1)
" 2>/dev/null
        
        if [ $? -ne 0 ]; then
            echo "❌ tokenizer.model文件损坏，需要重新下载"
            NEED_REDOWNLOAD=true
        else
            echo "✅ tokenizer.model文件完整无损"
            NEED_REDOWNLOAD=false
        fi
    fi
else
    echo "❌ tokenizer.model文件不存在"
    NEED_REDOWNLOAD=true
fi

if [ "$NEED_REDOWNLOAD" = true ]; then
    echo
    echo "🔄 开始修复ChatGLM3模型..."
    
    # 清理损坏的模型文件
    echo "🧹 清理损坏的模型文件..."
    rm -rf "$MODEL_DIR"
    
    # 清理可能缓存的损坏文件
    echo "🧹 清理Hugging Face缓存..."
    rm -rf ~/.cache/huggingface/modules/transformers_modules/chatglm3-6b/ 2>/dev/null || true
    rm -rf /root/.cache/huggingface/modules/transformers_modules/chatglm3-6b/ 2>/dev/null || true
    
    # 重新下载完整模型
    echo "📥 重新下载ChatGLM3模型..."
    cd "$ONTOTHINK_ROOT"
    bash enflame_training/scripts/download_chatglm3_simple.sh
    
    if [ $? -eq 0 ]; then
        echo
        echo "🎉 ChatGLM3模型修复完成！"
        echo
        echo "📋 验证修复结果..."
        if [ -f "$MODEL_DIR/tokenizer.model" ]; then
            new_size=$(stat -c%s "$MODEL_DIR/tokenizer.model" 2>/dev/null || stat -f%z "$MODEL_DIR/tokenizer.model" 2>/dev/null)
            echo "✅ 新tokenizer.model大小: ${new_size} bytes"
            
            # 再次验证完整性
            python3 -c "
import sentencepiece as spm
try:
    sp = spm.SentencePieceProcessor()
    sp.load('$MODEL_DIR/tokenizer.model')
    print('✅ 修复后的tokenizer.model验证通过')
except Exception as e:
    print(f'❌ 修复失败: {e}')
    exit(1)
" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                echo "🎯 模型修复成功，可以开始训练！"
                echo
                echo "📋 下一步："
                echo "python3 enflame_training/scripts/train_ontothink_enflame.py --step full"
            else
                echo "❌ 修复验证失败，请检查网络连接后重试"
                exit 1
            fi
        else
            echo "❌ 修复失败，tokenizer.model文件仍然缺失"
            exit 1
        fi
    else
        echo "❌ 模型下载失败，请检查网络连接"
        exit 1
    fi
else
    echo "🎯 tokenizer文件正常，可以开始训练！"
    echo
    echo "📋 下一步："
    echo "python3 enflame_training/scripts/train_ontothink_enflame.py --step full"
fi
