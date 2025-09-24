#!/bin/bash
# OntoThink燧原T20简化环境配置脚本

set -e

echo "🔥 OntoThink燧原T20环境配置..."

# 检测Python命令
PYTHON_CMD="python3"
if command -v python3.8 &> /dev/null; then
    PYTHON_CMD="python3.8"
fi

echo "✅ 使用Python命令: $PYTHON_CMD"

# 安装基础依赖 (不使用虚拟环境)
echo "📦 安装基础Python依赖..."
$PYTHON_CMD -m pip install --upgrade pip

# 安装燧原环境专用依赖
if [ -f "requirements-enflame.txt" ]; then
    echo "📦 安装OntoThink基础依赖..."
    $PYTHON_CMD -m pip install -r requirements-enflame.txt
else
    echo "⚠️  requirements-enflame.txt not found, installing basic deps..."
    $PYTHON_CMD -m pip install fastapi uvicorn pydantic requests tqdm loguru pandas numpy
fi

# 配置燧原环境
if [ -d "FromEnflame" ]; then
    echo "🔥 配置燧原T20环境..."
    
    ENFLAME_SCRIPT="FromEnflame/TopsRider_t2x_2.5.136_deb_amd64/ai_development_toolkit/distributed/llm_scripts_1.0.40/install_for_llm_scripts.sh"
    
    if [ -f "$ENFLAME_SCRIPT" ]; then
        echo "🛠️  运行燧原依赖安装..."
        cd FromEnflame/TopsRider_t2x_2.5.136_deb_amd64/ai_development_toolkit/distributed/llm_scripts_1.0.40/
        
        # 设置燧原环境变量
        export ENFLAME_ENABLE_EFP=true
        export ENFLAME_PT_ENABLE_HBM_INPLACE=true
        export OMP_NUM_THREADS=5
        export ECCL_MAX_NCHANNELS=2
        export ENFLAME_UMD_FLAGS="mem_alloc_retry_times=1"
        
        # 运行燧原安装脚本
        echo "🔧 安装torch_gcu, collie_lm, deepspeed..."
        bash install_for_llm_scripts.sh
        
        cd ../../../../../../../../
        echo "✅ 燧原环境配置完成"
        
        # 验证燧原环境
        echo "🔍 验证燧原环境..."
        $PYTHON_CMD -c "import torch; import ptex; print('✅ torch_gcu 和 ptex 导入成功')"
        
    else
        echo "❌ 燧原安装脚本未找到: $ENFLAME_SCRIPT"
        exit 1
    fi
else
    echo "❌ 未找到燧原工具包 FromEnflame/ 目录"
    exit 1
fi

echo ""
echo "🎉 OntoThink燧原T20环境配置完成！"
echo ""
echo "📋 下一步:"
echo "   1. 下载ChatGLM3模型:"
echo "      mkdir -p enflame_training/models/THUDM/"
echo "      cd enflame_training/models/THUDM/"
echo "      git clone https://huggingface.co/THUDM/chatglm3-6b"
echo ""
echo "   2. 开始训练:"
echo "      python3 enflame_training/scripts/train_ontothink_enflame.py --step full"
echo ""
echo "✅ 燧原T20环境准备就绪！"
