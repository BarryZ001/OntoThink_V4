#!/usr/bin/env python3
"""
OntoThink 燧原T20直接训练脚本
跳过环境检查，直接使用已配置的燧原环境
"""

import os
import subprocess
import argparse
from pathlib import Path

def get_project_root():
    """获取项目根目录"""
    current_dir = Path.cwd()
    if "OntoThink_V4" in str(current_dir):
        # 找到项目根目录
        while current_dir.name != "OntoThink_V4" and current_dir.parent != current_dir:
            current_dir = current_dir.parent
        return current_dir
    else:
        # 默认路径
        return Path("/workspace/code/OntoThink_V4")

def check_model_exists():
    """检查ChatGLM3模型是否存在"""
    base_dir = get_project_root()
    model_path = base_dir / "enflame_training/models/THUDM/chatglm3-6b"
    
    if not model_path.exists():
        print(f"❌ 模型目录不存在: {model_path}")
        return False
    
    config_file = model_path / "config.json"
    if not config_file.exists():
        print(f"❌ 模型配置文件不存在: {config_file}")
        return False
    
    print(f"✅ ChatGLM3模型检查通过: {model_path}")
    return True

def check_training_data():
    """检查训练数据是否存在"""
    base_dir = get_project_root()
    data_paths = [
        base_dir / "backend/data/processed/train.jsonl",
        base_dir / "backend/data/processed/val.jsonl"
    ]
    
    for data_path in data_paths:
        if not data_path.exists():
            print(f"❌ 训练数据不存在: {data_path}")
            return False
    
    print("✅ 训练数据检查通过")
    return True

def prepare_enflame_data():
    """准备燧原格式的训练数据"""
    print("📊 准备燧原训练数据...")
    
    base_dir = get_project_root()
    script_path = base_dir / "enflame_training/scripts/prepare_enflame_data.py"
    input_dir = base_dir / "backend/data/processed"
    output_dir = base_dir / "enflame_training/datasets/ontothink_multiturn"
    
    if (output_dir / "train.jsonl").exists():
        print("✅ 燧原格式数据已存在")
        return True
    
    cmd = [
        "python3", str(script_path),
        "--input_dir", str(input_dir),
        "--output_dir", str(output_dir),
        "--format", "multiturn"
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, cwd=str(base_dir))
        if result.returncode == 0:
            print("✅ 燧原格式数据准备完成")
            return True
        else:
            print(f"❌ 数据准备失败: {result.stderr}")
            return False
    except Exception as e:
        print(f"❌ 数据准备异常: {e}")
        return False

def start_training():
    """启动燧原训练"""
    print("🚀 启动OntoThink燧原T20训练...")
    
    base_dir = get_project_root()
    training_script = base_dir / "enflame_training/scripts/ontothink_chatglm3_enflame.sh"
    
    if not training_script.exists():
        print(f"❌ 训练脚本不存在: {training_script}")
        return False
    
    # 设置燧原环境变量
    env = os.environ.copy()
    env.update({
        "ENFLAME_ENABLE_EFP": "true",
        "ENFLAME_PT_ENABLE_HBM_INPLACE": "true",
        "OMP_NUM_THREADS": "5",
        "ECCL_MAX_NCHANNELS": "2",
        "ENFLAME_UMD_FLAGS": "mem_alloc_retry_times=1"
    })
    
    try:
        print("🔥 执行燧原训练脚本...")
        os.chmod(training_script, 0o755)
        
        # 直接运行训练脚本
        result = subprocess.run([str(training_script)], 
                              cwd=str(base_dir), 
                              env=env)
        
        return result.returncode == 0
        
    except Exception as e:
        print(f"❌ 训练启动失败: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description="OntoThink燧原T20直接训练")
    parser.add_argument("--step", choices=[
        "check", "prepare", "train", "full"
    ], default="full", help="执行步骤")
    
    args = parser.parse_args()
    
    print("🎯 OntoThink 燧原T20直接训练")
    print("=" * 60)
    
    if args.step in ["check", "full"]:
        print("\n📋 步骤: 检查模型和数据")
        if not check_model_exists():
            print("❌ 模型检查失败")
            return
        
        if not check_training_data():
            print("❌ 训练数据检查失败")
            return
    
    if args.step in ["prepare", "full"]:
        print("\n📋 步骤: 准备燧原数据")
        if not prepare_enflame_data():
            print("❌ 数据准备失败")
            return
    
    if args.step in ["train", "full"]:
        print("\n📋 步骤: 开始训练")
        if not start_training():
            print("❌ 训练失败")
            return
    
    print("\n🎉 OntoThink燧原T20训练流程完成！")

if __name__ == "__main__":
    main()
