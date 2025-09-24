#!/bin/bash
# OntoThink项目环境配置脚本
# 支持Python 3.8+和燧原T20环境

set -e

echo "🚀 OntoThink项目环境配置开始..."

# 检查Python版本
PYTHON_CMD=""
if command -v python3.8 &> /dev/null; then
    PYTHON_CMD="python3.8"
    echo "✅ 找到 Python 3.8"
elif command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
    if [[ "$PYTHON_VERSION" == "3.8" ]] || [[ "$PYTHON_VERSION" > "3.8" ]]; then
        PYTHON_CMD="python3"
        echo "✅ 找到 Python $PYTHON_VERSION"
    else
        echo "❌ 需要 Python 3.8+，当前版本: $PYTHON_VERSION"
        exit 1
    fi
else
    echo "❌ 未找到 Python 3，请安装 Python 3.8+"
    exit 1
fi

# 创建虚拟环境
echo "📦 创建Python虚拟环境..."
if [ ! -d "venv" ] || [ ! -f "venv/bin/activate" ]; then
    echo "🔧 重新创建虚拟环境..."
    rm -rf venv
    $PYTHON_CMD -m venv venv
    echo "✅ 虚拟环境创建完成"
else
    echo "✅ 虚拟环境已存在"
fi

# 激活虚拟环境
echo "🔄 激活虚拟环境..."
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    echo "✅ 虚拟环境激活成功"
else
    echo "❌ 虚拟环境激活文件不存在，跳过激活"
fi

# 升级pip
echo "📦 升级pip..."
python -m pip install --upgrade pip

# 安装基础依赖 (排除torch等燧原已提供的包)
echo "📦 安装项目依赖..."
echo "⚠️  跳过torch相关依赖，使用燧原T20环境提供的版本"
pip install -r requirements.txt

# 检查是否有燧原工具包
if [ -d "FromEnflame" ]; then
    echo "🔥 检测到燧原工具包，使用燧原专用依赖配置..."
    
    # 使用燧原专用requirements
    echo "📦 安装燧原环境专用依赖..."
    pip install -r requirements-enflame.txt
    
    # 检查燧原脚本是否存在
    ENFLAME_SCRIPT="FromEnflame/TopsRider_t2x_2.5.136_deb_amd64/ai_development_toolkit/distributed/llm_scripts_1.0.40/install_for_llm_scripts.sh"
    
    if [ -f "$ENFLAME_SCRIPT" ]; then
        echo "🛠️  运行燧原深度学习依赖安装..."
        cd FromEnflame/TopsRider_t2x_2.5.136_deb_amd64/ai_development_toolkit/distributed/llm_scripts_1.0.40/
        
        # 设置燧原环境变量
        export ENFLAME_ENABLE_EFP=true
        export ENFLAME_PT_ENABLE_HBM_INPLACE=true
        export OMP_NUM_THREADS=5
        export ECCL_MAX_NCHANNELS=2
        export ENFLAME_UMD_FLAGS="mem_alloc_retry_times=1"
        
        # 运行燧原安装脚本
        echo "🔧 安装torch_gcu, collie_lm, deepspeed等燧原专用库..."
        bash install_for_llm_scripts.sh
        
        cd ../../../../../../../../
        echo "✅ 燧原T20环境配置完成"
    else
        echo "⚠️  燧原安装脚本未找到，请确保工具包完整"
    fi
else
    echo "💡 未检测到燧原工具包，使用通用GPU环境配置"
    echo "   如需燧原T20支持，请将工具包放置到 FromEnflame/ 目录"
fi

# 安装额外的训练依赖
echo "📦 安装训练专用依赖..."
pip install -r backend/requirements-data.txt

echo ""
echo "🎉 OntoThink环境配置完成！"
echo ""
echo "📋 使用说明:"
echo "   1. 激活环境: source venv/bin/activate"
echo "   2. 启动后端: cd backend && python -m uvicorn app.main:app --reload"
echo "   3. 启动前端: cd frontend && npm install && npm start"
echo "   4. 燧原训练: python enflame_training/scripts/train_ontothink_enflame.py --step full"
echo "   5. GPU训练:  python backend/scripts/train_manager.py --step full"
echo ""
echo "✅ 环境配置完成，可以开始开发了！"
