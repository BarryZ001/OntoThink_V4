#!/bin/bash
# ChatGLM3-6B 多源下载脚本

set -e

MODEL_DIR="enflame_training/models/THUDM/chatglm3-6b"
BASE_DIR=$(dirname "$0")/../..

echo "🚀 ChatGLM3-6B 多源下载脚本"
echo "目标目录: $MODEL_DIR"

# 创建模型目录
mkdir -p "$BASE_DIR/$MODEL_DIR"
cd "$BASE_DIR/$MODEL_DIR"

echo ""
echo "📁 可选的下载方式:"
echo "1. HuggingFace官方源 (国外)"
echo "2. ModelScope镜像源 (国内，推荐)"
echo "3. 手动下载核心文件"
echo "4. 使用Python下载"
echo ""

read -p "请选择下载方式 (1-4): " choice

case $choice in
    1)
        echo "📥 使用HuggingFace官方源..."
        git clone https://huggingface.co/THUDM/chatglm3-6b .
        ;;
    2)
        echo "📥 使用ModelScope镜像源 (推荐)..."
        echo "设置Git配置用于ModelScope..."
        git config --global url."https://www.modelscope.cn/".insteadOf "https://huggingface.co/"
        git clone https://www.modelscope.cn/ZhipuAI/chatglm3-6b.git .
        echo "✅ 恢复Git配置..."
        git config --global --unset url."https://www.modelscope.cn/".insteadOf
        ;;
    3)
        echo "📥 手动下载核心文件..."
        
        # 创建基础配置文件
        cat > config.json << 'EOF'
{
  "_name_or_path": "THUDM/chatglm3-6b",
  "add_bias_linear": false,
  "add_qkv_bias": true,
  "apply_residual_connection_post_layernorm": false,
  "architectures": [
    "ChatGLMModel"
  ],
  "attention_dropout": 0.0,
  "attention_softmax_in_fp32": true,
  "auto_map": {
    "AutoConfig": "configuration_chatglm.ChatGLMConfig",
    "AutoModel": "modeling_chatglm.ChatGLMForConditionalGeneration",
    "AutoModelForSeq2SeqLM": "modeling_chatglm.ChatGLMForConditionalGeneration"
  },
  "bias_dropout_fusion": true,
  "ffn_hidden_size": 13696,
  "hidden_dropout": 0.0,
  "hidden_size": 4096,
  "kv_channels": 128,
  "layernorm_epsilon": 1e-05,
  "multi_query_attention": true,
  "multi_query_group_num": 2,
  "num_attention_heads": 32,
  "num_layers": 28,
  "original_rope": true,
  "padded_vocab_size": 65024,
  "post_layer_norm": true,
  "rmsnorm": true,
  "seq_length": 8192,
  "tie_word_embeddings": false,
  "torch_dtype": "float16",
  "transformers_version": "4.30.2",
  "use_cache": true,
  "vocab_size": 65024
}
EOF

        cat > tokenizer_config.json << 'EOF'
{
  "add_bos_token": false,
  "add_eos_token": false,
  "auto_map": {
    "AutoTokenizer": [
      "tokenization_chatglm.ChatGLMTokenizer",
      null
    ]
  },
  "clean_up_tokenization_spaces": true,
  "do_lower_case": false,
  "model_max_length": 1000000000000000019884624838656,
  "padding_side": "left",
  "remove_space": false,
  "tokenizer_class": "ChatGLMTokenizer",
  "trust_remote_code": true,
  "unk_token": "<unk>",
  "use_fast": false
}
EOF

        echo "📥 下载关键文件..."
        echo "⚠️  注意：模型权重文件很大，需要手动下载"
        echo "请从以下地址手动下载模型文件:"
        echo "1. ModelScope: https://www.modelscope.cn/ZhipuAI/chatglm3-6b/files"
        echo "2. HuggingFace: https://huggingface.co/THUDM/chatglm3-6b/tree/main"
        echo ""
        echo "需要下载的文件:"
        echo "- pytorch_model-00001-of-00007.bin ~ pytorch_model-00007-of-00007.bin"
        echo "- pytorch_model.bin.index.json"
        echo "- tokenizer.model"
        echo "- modeling_chatglm.py"
        echo "- tokenization_chatglm.py"
        echo "- configuration_chatglm.py"
        ;;
    4)
        echo "📥 使用Python下载..."
        python3 << 'EOF'
import os
try:
    from modelscope import snapshot_download
    print("使用ModelScope下载...")
    model_dir = snapshot_download('ZhipuAI/chatglm3-6b', cache_dir='.')
    print(f"✅ 模型下载完成: {model_dir}")
except ImportError:
    print("ModelScope未安装，尝试使用transformers...")
    try:
        from transformers import AutoModel, AutoTokenizer
        print("使用transformers下载...")
        model = AutoModel.from_pretrained('THUDM/chatglm3-6b', trust_remote_code=True)
        tokenizer = AutoTokenizer.from_pretrained('THUDM/chatglm3-6b', trust_remote_code=True)
        model.save_pretrained('.')
        tokenizer.save_pretrained('.')
        print("✅ 模型下载完成")
    except Exception as e:
        print(f"❌ 下载失败: {e}")
        print("请尝试手动下载或使用其他方式")
EOF
        ;;
    *)
        echo "❌ 无效选择"
        exit 1
        ;;
esac

echo ""
echo "🔍 检查下载结果..."
if [ -f "config.json" ] && [ -f "tokenizer_config.json" ]; then
    echo "✅ 基础配置文件存在"
    
    if ls pytorch_model*.bin >/dev/null 2>&1 || [ -f "pytorch_model.bin" ]; then
        echo "✅ 模型权重文件存在"
        echo "🎉 ChatGLM3-6B下载完成！"
    else
        echo "⚠️  模型权重文件缺失，请手动下载"
        echo "或重新运行脚本选择其他下载方式"
    fi
else
    echo "❌ 下载未完成，请检查网络连接或尝试其他方式"
fi

echo ""
echo "📋 下载完成后的下一步:"
echo "cd /workspace/code/OntoThink_V4"
echo "python3 enflame_training/scripts/train_ontothink_enflame.py --step full"
