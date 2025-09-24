#!/bin/bash
# ChatGLM3-6B 简化下载脚本 - 专为燧原T20环境设计

set -e

echo "🚀 ChatGLM3-6B 简化下载器"
echo "适用于燧原T20环境"
echo "=" * 50

# 检查并创建模型目录
BASE_DIR="/workspace/code/OntoThink_V4"
MODEL_DIR="$BASE_DIR/enflame_training/models/THUDM/chatglm3-6b"

echo "📁 目标目录: $MODEL_DIR"

# 清理现有的不完整目录
if [ -d "$MODEL_DIR" ]; then
    if [ ! -f "$MODEL_DIR/config.json" ]; then
        echo "🧹 清理不完整的下载目录..."
        rm -rf "$MODEL_DIR"
    else
        echo "✅ 检测到完整的模型，跳过下载"
        ls -la "$MODEL_DIR"
        exit 0
    fi
fi

# 创建目录并进入
mkdir -p "$MODEL_DIR"
cd "$MODEL_DIR"

echo ""
echo "📥 尝试多个下载源..."

# 方法1: ModelScope镜像（推荐）
echo "🔄 方法1: 使用ModelScope镜像..."
if git clone https://www.modelscope.cn/ZhipuAI/chatglm3-6b.git . 2>/dev/null; then
    echo "✅ ModelScope下载成功"
else
    echo "❌ ModelScope下载失败"
    
    # 方法2: HF镜像
    echo "🔄 方法2: 使用HF镜像..."
    if git clone https://hf-mirror.com/THUDM/chatglm3-6b.git . 2>/dev/null; then
        echo "✅ HF镜像下载成功"
    else
        echo "❌ HF镜像下载失败"
        
        # 方法3: 手动创建基础配置
        echo "🔄 方法3: 创建基础配置文件..."
        
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

        echo "📝 基础配置文件已创建"
        echo ""
        echo "⚠️  注意: 模型权重文件需要手动下载"
        echo "请访问以下链接下载模型权重文件:"
        echo "1. ModelScope: https://www.modelscope.cn/ZhipuAI/chatglm3-6b/files"
        echo "2. 需要下载的文件:"
        echo "   - pytorch_model-00001-of-00007.bin"
        echo "   - pytorch_model-00002-of-00007.bin"
        echo "   - pytorch_model-00003-of-00007.bin"
        echo "   - pytorch_model-00004-of-00007.bin"
        echo "   - pytorch_model-00005-of-00007.bin"
        echo "   - pytorch_model-00006-of-00007.bin"
        echo "   - pytorch_model-00007-of-00007.bin"
        echo "   - pytorch_model.bin.index.json"
        echo "   - tokenizer.model"
        echo "   - modeling_chatglm.py"
        echo "   - tokenization_chatglm.py"
        echo "   - configuration_chatglm.py"
        echo ""
        echo "💡 或者尝试使用wget直接下载:"
        echo "wget https://www.modelscope.cn/api/v1/models/ZhipuAI/chatglm3-6b/repo?Revision=master&FilePath=pytorch_model-00001-of-00007.bin"
    fi
fi

echo ""
echo "🔍 检查下载结果..."
if [ -f "config.json" ]; then
    echo "✅ config.json 存在"
    
    if ls pytorch_model*.bin >/dev/null 2>&1; then
        echo "✅ 模型权重文件存在"
        echo "🎉 ChatGLM3-6B下载完成！"
        echo ""
        echo "📋 下一步:"
        echo "cd $BASE_DIR"
        echo "python3 enflame_training/scripts/train_ontothink_enflame.py --step full"
    else
        echo "⚠️  模型权重文件缺失"
        echo "请手动下载或稍后重试"
    fi
else
    echo "❌ 下载失败，请检查网络连接"
fi

echo ""
echo "📊 当前目录内容:"
ls -la
