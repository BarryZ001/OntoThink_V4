# ChatGLM3 本地下载 + 服务器上传方案

## 🚀 方案优势
- 利用本地Mac网络优势
- 避免服务器网络限制
- 一次下载，多次使用
- 可验证文件完整性

## 📥 第一步：本地Mac下载

### 方法1：使用我们的Python脚本下载
```bash
# 在本地Mac执行
cd /Users/barryzhang/myDev3/OntoThink_V4

# 运行智能下载脚本
python3 enflame_training/scripts/manual_download_chatglm3.py

# 下载完成后检查文件
ls -la enflame_training/models/THUDM/chatglm3-6b/
```

### 方法2：使用huggingface_hub下载
```bash
# 安装huggingface_hub
pip install huggingface_hub

# 下载模型
python3 -c "
from huggingface_hub import snapshot_download
import os

# 下载到本地
local_dir = '/Users/barryzhang/myDev3/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b'
os.makedirs(local_dir, exist_ok=True)

print('📥 开始下载ChatGLM3-6B...')
snapshot_download(
    repo_id='THUDM/chatglm3-6b',
    local_dir=local_dir,
    local_dir_use_symlinks=False,
    resume_download=True
)
print('✅ 下载完成!')
"
```

### 方法3：使用git clone + LFS
```bash
# 确保安装了git-lfs
brew install git-lfs
git lfs install

# 创建下载目录
mkdir -p /Users/barryzhang/myDev3/OntoThink_V4/enflame_training/models/THUDM
cd /Users/barryzhang/myDev3/OntoThink_V4/enflame_training/models/THUDM

# 克隆仓库
git clone https://huggingface.co/THUDM/chatglm3-6b

# 确保LFS文件下载
cd chatglm3-6b
git lfs pull
```

## 📤 第二步：验证下载文件

```bash
# 检查关键文件
cd /Users/barryzhang/myDev3/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b

echo "🔍 检查文件大小..."

# 检查tokenizer
if [ -f "tokenizer.model" ]; then
    size=$(stat -f%z "tokenizer.model")
    echo "tokenizer.model: $size bytes"
    if [ $size -gt 1000000 ]; then
        echo "✅ tokenizer.model 大小正常"
    else
        echo "❌ tokenizer.model 过小"
    fi
else
    echo "❌ tokenizer.model 不存在"
fi

# 检查权重文件
echo ""
echo "📋 权重文件检查:"
for i in {1..7}; do
    file="model-0000${i}-of-00007.safetensors"
    if [ -f "$file" ]; then
        size=$(stat -f%z "$file")
        echo "$file: $size bytes"
    else
        file="pytorch_model-0000${i}-of-00007.bin"
        if [ -f "$file" ]; then
            size=$(stat -f%z "$file")
            echo "$file: $size bytes"
        else
            echo "❌ 权重文件 $i 不存在"
        fi
    fi
done

# 检查配置文件
echo ""
echo "📋 配置文件检查:"
for file in "config.json" "tokenizer_config.json" "modeling_chatglm.py" "tokenization_chatglm.py"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file 缺失"
    fi
done
```

## 📤 第三步：上传到服务器

### 方法1：使用rsync（推荐）
```bash
# 压缩并上传
cd /Users/barryzhang/myDev3/OntoThink_V4/enflame_training/models/THUDM

# 先压缩（可选，节省传输时间）
tar -czf chatglm3-6b.tar.gz chatglm3-6b/

# 上传压缩文件
rsync -avz --progress -e "ssh -p 60025" \
    chatglm3-6b.tar.gz \
    root@117.156.108.234:/workspace/code/OntoThink_V4/enflame_training/models/THUDM/

# 或者直接上传目录（不压缩）
rsync -avz --progress -e "ssh -p 60025" \
    chatglm3-6b/ \
    root@117.156.108.234:/workspace/code/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b/
```

### 方法2：使用scp
```bash
# 上传压缩文件
scp -P 60025 -r chatglm3-6b.tar.gz \
    root@117.156.108.234:/workspace/code/OntoThink_V4/enflame_training/models/THUDM/

# 或者直接上传目录
scp -P 60025 -r chatglm3-6b \
    root@117.156.108.234:/workspace/code/OntoThink_V4/enflame_training/models/THUDM/
```

## 🖥️ 第四步：服务器端解压和验证

### 登录服务器
```bash
ssh -p 60025 root@117.156.108.234
```

### 解压文件（如果上传的是压缩包）
```bash
cd /workspace/code/OntoThink_V4/enflame_training/models/THUDM

# 解压
tar -xzf chatglm3-6b.tar.gz

# 删除压缩包
rm chatglm3-6b.tar.gz

# 检查文件
ls -la chatglm3-6b/
```

### 验证上传结果
```bash
cd /workspace/code/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b

# 检查tokenizer
python3 -c "
import sentencepiece as spm
try:
    sp = smp.SentencePieceProcessor()
    sp.load('tokenizer.model')
    print('✅ tokenizer验证通过')
except Exception as e:
    print(f'❌ tokenizer验证失败: {e}')
"

# 检查文件数量
echo "📋 文件统计:"
echo "权重文件数量: $(ls model-*.safetensors pytorch_model-*.bin 2>/dev/null | wc -l)"
echo "配置文件数量: $(ls *.json *.py 2>/dev/null | wc -l)"
echo "总文件数量: $(ls -1 | wc -l)"
```

## 🚀 第五步：开始训练

```bash
# 在服务器上执行
cd /workspace/code/OntoThink_V4

# 运行训练
python3 enflame_training/scripts/train_ontothink_enflame.py --step full
```

## 💡 优化技巧

### 1. 并行下载（如果网络允许）
```bash
# 使用aria2c并行下载
brew install aria2

# 创建下载脚本
cat > download_chatglm3.sh << 'EOF'
#!/bin/bash
BASE_URL="https://huggingface.co/THUDM/chatglm3-6b/resolve/main"
OUTPUT_DIR="/Users/barryzhang/myDev3/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b"

mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"

# 并行下载文件
aria2c -x 4 -s 4 "${BASE_URL}/config.json"
aria2c -x 4 -s 4 "${BASE_URL}/tokenizer.model"
aria2c -x 4 -s 4 "${BASE_URL}/tokenizer_config.json"
aria2c -x 4 -s 4 "${BASE_URL}/modeling_chatglm.py"
aria2c -x 4 -s 4 "${BASE_URL}/tokenization_chatglm.py"

# 下载权重文件
for i in {1..7}; do
    aria2c -x 4 -s 4 "${BASE_URL}/model-0000${i}-of-00007.safetensors"
done
EOF

chmod +x download_chatglm3.sh
./download_chatglm3.sh
```

### 2. 断点续传
```bash
# rsync支持断点续传
rsync -avz --progress --partial -e "ssh -p 60025" \
    chatglm3-6b/ \
    root@117.156.108.234:/workspace/code/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b/
```

### 3. 压缩传输
```bash
# 使用更好的压缩算法
tar -cf - chatglm3-6b | pigz | \
    ssh -p 60025 root@117.156.108.234 \
    "cd /workspace/code/OntoThink_V4/enflame_training/models/THUDM && pigz -d | tar -xf -"
```

## ⚠️ 注意事项

1. **确保有足够空间**：模型文件约13GB，确保本地和服务器都有足够空间
2. **网络稳定性**：大文件传输建议使用rsync的断点续传功能
3. **文件权限**：上传后检查文件权限是否正确
4. **路径一致性**：确保服务器路径与训练脚本预期一致

## 🔍 故障排除

### 如果上传中断
```bash
# 使用rsync恢复上传
rsync -avz --progress --partial -e "ssh -p 60025" \
    chatglm3-6b/ \
    root@117.156.108.234:/workspace/code/OntoThink_V4/enflame_training/models/THUDM/chatglm3-6b/
```

### 如果文件损坏
```bash
# 在服务器上验证文件
cd /workspace/code/OntoThink_V4
python3 enflame_training/scripts/manual_download_chatglm3.py
```
