#!/bin/bash
# OntoThink 燧原T20环境配置脚本

set -e

echo "🚀 配置OntoThink燧原T20训练环境..."

# 设置基础路径
ONTOTHINK_ROOT="/Users/barryzhang/myDev3/OntoThink_V4"
ENFLAME_ROOT="${ONTOTHINK_ROOT}/FromEnflame/TopsRider_t2x_2.5.136_deb_amd64/ai_development_toolkit/distributed"
TRAINING_ROOT="${ONTOTHINK_ROOT}/enflame_training"

# 创建训练目录结构
mkdir -p ${TRAINING_ROOT}/{models,datasets,logs,configs,scripts}

# 创建符号链接到燧原工具包
ln -sf ${ENFLAME_ROOT}/llm_scripts_1.0.40 ${TRAINING_ROOT}/llm_scripts

echo "📁 创建目录结构完成"

# 复制并修改环境配置
cd ${TRAINING_ROOT}/llm_scripts

# 设置燧原T20环境变量
export ENFLAME_ENABLE_EFP=true
export ENFLAME_PT_ENABLE_HBM_INPLACE=true
export OMP_NUM_THREADS=5
export ECCL_MAX_NCHANNELS=2
export ENFLAME_UMD_FLAGS="mem_alloc_retry_times=1"

echo "🔧 燧原T20环境变量配置完成"

# 安装燧原专用依赖包
echo "📦 安装燧原T20训练依赖..."
./install_for_llm_scripts.sh

echo "✅ OntoThink燧原T20环境配置完成！"
echo "📍 训练根目录: ${TRAINING_ROOT}"
echo "🛠️  工具包链接: ${TRAINING_ROOT}/llm_scripts"
