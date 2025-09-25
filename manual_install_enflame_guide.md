# 🔧 燧原官方定制包手动安装指南

完全卸载torch后，按以下步骤手动安装燧原官方定制包。

## 🗑️ 第1步：完全卸载现有包

```bash
cd /workspace/code/OntoThink_V4
git pull origin main
bash complete_uninstall_torch.sh
```

## 📦 第2步：按顺序手动安装燧原包

### 🎯 安装位置

所有燧原包都在：`/installer/topsrider_extracted/TopsRider_installer/`

### 🔧 安装顺序（重要！）

#### 1️⃣ 安装torch_gcu（燧原PyTorch）

```bash
cd /installer/topsrider_extracted/TopsRider_installer/framework/
ls -la torch_gcu-*-py3.8-*.whl
pip3 install torch_gcu-*-py3.8-*.whl --force-reinstall --no-deps --disable-pip-version-check
```

验证安装：
```bash
python3 -c "import torch; print('torch版本:', torch.__version__); print('torch路径:', torch.__file__)"
```

#### 2️⃣ 安装ptex（燧原核心扩展）

```bash
cd /installer/topsrider_extracted/TopsRider_installer/ai_development_toolkit/distributed/
ls -la ptex-*.whl
pip3 install ptex-*.whl --force-reinstall --no-deps --disable-pip-version-check
```

验证安装：
```bash
python3 -c "import ptex; print('ptex导入成功'); print('ptex路径:', ptex.__file__)"
```

#### 3️⃣ 安装deepspeed（燧原分布式）

```bash
# 先安装必要依赖
pip3 install numpy pydantic==1.10.12 psutil packaging tqdm --no-deps --disable-pip-version-check

# 安装燧原deepspeed
pip3 install deepspeed-*.whl --force-reinstall --no-deps --disable-pip-version-check
```

验证安装：
```bash
python3 -c "import deepspeed; print('deepspeed版本:', deepspeed.__version__)"
```

#### 4️⃣ 安装collie_lm（燧原训练框架）

```bash
pip3 install collie_lm-*.whl --force-reinstall --no-deps --disable-pip-version-check
```

验证安装：
```bash
python3 -c "import collie; print('collie_lm导入成功')"
```

#### 5️⃣ 安装HuggingFace系列（燧原优化版）

```bash
cd /installer/topsrider_extracted/TopsRider_installer/ai_development_toolkit/huggingface-gcu/

# 先安装HuggingFace基础依赖
pip3 install tokenizers huggingface-hub safetensors regex requests --no-deps --disable-pip-version-check

# 安装燧原优化的transformers
pip3 install transformers-*.whl --force-reinstall --no-deps --disable-pip-version-check

# 安装燧原优化的accelerate
pip3 install accelerate-*.whl --force-reinstall --no-deps --disable-pip-version-check

# 安装燧原优化的peft
pip3 install peft-*.whl --force-reinstall --no-deps --disable-pip-version-check
```

验证安装：
```bash
python3 -c "
import transformers, accelerate, peft
print('transformers版本:', transformers.__version__)
print('accelerate版本:', accelerate.__version__)
print('peft版本:', peft.__version__)
"
```

#### 6️⃣ 安装训练相关依赖

```bash
pip3 install sentencepiece==0.1.99 einops==0.6.1 datasets --no-deps --disable-pip-version-check
```

## 🔍 第3步：全面验证安装

```bash
cd /workspace/code/OntoThink_V4
bash check_enflame_status.sh
```

期望看到：
- ✅ torch: 1.10.0+某版本
- ✅ ptex: 导入成功
- ✅ deepspeed: 0.9.2+gcu.某版本
- ✅ collie_lm: 导入成功
- ✅ transformers: 4.32.0+gcu.某版本
- ✅ accelerate: 0.22.0+gcu.某版本
- ✅ peft: 0.5.0+gcu.某版本

## 🚀 第4步：开始训练

如果所有包都安装成功：

```bash
bash train_ontothink_enflame_official.sh
```

## 💡 重要提示

### ⚠️ 安装参数说明

- `--force-reinstall`: 强制重新安装，覆盖现有版本
- `--no-deps`: 不检查依赖关系，避免版本冲突
- `--disable-pip-version-check`: 禁用pip版本检查，避免燧原版本号解析错误

### 🔧 如果某个包安装失败

1. **检查.whl文件是否存在**：
   ```bash
   ls -la /installer/topsrider_extracted/TopsRider_installer/ai_development_toolkit/distributed/*.whl
   ```

2. **手动解压安装**：
   ```bash
   cd /tmp
   unzip /path/to/package.whl
   sudo cp -r package_folder /usr/local/lib/python3.8/dist-packages/
   ```

3. **检查Python路径**：
   ```bash
   python3 -c "import sys; print('\n'.join(sys.path))"
   ```

### 🎯 成功标志

当看到以下输出时，说明安装成功：
```
🎉 燧原环境基本可用！
🚀 现在可以尝试训练: bash train_ontothink_enflame_official.sh
```

## 🆘 故障排除

如果遇到问题：

1. **重新运行卸载脚本**：确保环境完全清理
2. **检查Python版本**：必须是Python 3.8
3. **检查权限**：某些操作可能需要sudo
4. **查看详细错误**：使用 `-v` 参数查看详细输出

### 📞 需要帮助时

运行诊断脚本获取详细信息：
```bash
bash diagnose_enflame_install.sh
```
