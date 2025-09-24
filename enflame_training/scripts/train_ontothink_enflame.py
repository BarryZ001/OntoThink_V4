#!/usr/bin/env python3
"""
OntoThink 燧原T20一键训练管理器
"""

import os
import subprocess
import json
import argparse
from pathlib import Path
import time

class OntoThinkEnflameTrainer:
    def __init__(self):
        # 自动检测运行环境
        current_dir = Path.cwd()
        if "OntoThink_V4" in str(current_dir):
            # 找到项目根目录
            while current_dir.name != "OntoThink_V4" and current_dir.parent != current_dir:
                current_dir = current_dir.parent
            self.ontothink_root = current_dir
        else:
            # 默认路径
            self.ontothink_root = Path("/workspace/code/OntoThink_V4")
        
        self.enflame_root = self.ontothink_root / "enflame_training"
        self.backend_data = self.ontothink_root / "backend" / "data" / "processed"
        
    def check_environment(self) -> bool:
        """检查燧原T20环境"""
        print("🔍 检查燧原T20环境...")
        
        # 检查燧原工具包
        enflame_tools = self.ontothink_root / "FromEnflame"
        if not enflame_tools.exists():
            print("❌ 未找到燧原工具包")
            return False
        
        # 检查LLM脚本是否可用
        llm_scripts_paths = [
            enflame_tools / "ai_development_toolkit" / "distributed",
            enflame_tools / "distributed" / "llm_scripts_1.0.40",
            self.enflame_root / "llm_scripts"
        ]
        
        llm_scripts_found = False
        for llm_path in llm_scripts_paths:
            if llm_path.exists():
                print(f"✅ 找到LLM脚本目录: {llm_path}")
                llm_scripts_found = True
                break
        
        if not llm_scripts_found:
            print("⚠️  燧原LLM脚本未找到，正在配置...")
            return self.setup_environment()
        
        print("✅ 燧原T20环境检查通过")
        return True
    
    def setup_environment(self) -> bool:
        """配置燧原T20环境"""
        print("🔧 配置燧原T20环境...")
        
        setup_script = self.enflame_root / "setup_enflame_env.sh"
        if not setup_script.exists():
            print("❌ 环境配置脚本不存在")
            return False
        
        try:
            # 运行环境配置脚本
            os.chmod(setup_script, 0o755)
            result = subprocess.run([str(setup_script)], capture_output=True, text=True)
            
            if result.returncode == 0:
                print("✅ 燧原T20环境配置完成")
                return True
            else:
                print(f"❌ 环境配置失败: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ 环境配置异常: {e}")
            return False
    
    def prepare_data(self) -> bool:
        """准备训练数据"""
        print("📊 准备燧原T20训练数据...")
        
        # 检查OntoThink原始数据
        if not self.backend_data.exists():
            print("❌ 未找到OntoThink原始数据")
            return False
        
        # 检查是否已转换
        enflame_data_dir = self.enflame_root / "datasets" / "ontothink_multiturn"
        train_file = enflame_data_dir / "train.jsonl"
        
        if train_file.exists():
            print("✅ 燧原格式数据已存在")
            return True
        
        # 运行数据转换
        prepare_script = self.enflame_root / "scripts" / "prepare_enflame_data.py"
        
        cmd = [
            "python3", str(prepare_script),
            "--input_dir", str(self.backend_data),
            "--output_dir", str(enflame_data_dir),
            "--format", "multiturn"
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode == 0:
                print("✅ 数据准备完成")
                return True
            else:
                print(f"❌ 数据准备失败: {result.stderr}")
                return False
        except Exception as e:
            print(f"❌ 数据准备异常: {e}")
            return False
    
    def download_model_if_needed(self) -> bool:
        """检查并下载ChatGLM3模型"""
        model_dir = self.enflame_root / "models" / "THUDM" / "chatglm3-6b"
        
        if model_dir.exists() and (model_dir / "config.json").exists():
            print("✅ ChatGLM3-6B模型已存在")
            return True
        
        print("📥 ChatGLM3-6B模型不存在，需要下载...")
        print("💡 请手动下载ChatGLM3-6B模型到以下路径:")
        print(f"   {model_dir}")
        print("🔗 下载命令:")
        print(f"   cd {model_dir.parent}")
        print("   git clone https://huggingface.co/THUDM/chatglm3-6b")
        print("\n或使用HuggingFace Hub:")
        print("   from transformers import AutoModel")
        print("   model = AutoModel.from_pretrained('THUDM/chatglm3-6b')")
        
        return False
    
    def start_training(self) -> bool:
        """启动训练"""
        print("🚀 启动OntoThink燧原T20训练...")
        
        training_script = self.enflame_root / "scripts" / "ontothink_chatglm3_enflame.sh"
        
        if not training_script.exists():
            print("❌ 训练脚本不存在")
            return False
        
        try:
            # 设置执行权限
            os.chmod(training_script, 0o755)
            
            # 启动训练
            print("🔥 开始训练，这可能需要几个小时...")
            result = subprocess.run([str(training_script)], cwd=str(self.enflame_root))
            
            return result.returncode == 0
            
        except Exception as e:
            print(f"❌ 训练启动失败: {e}")
            return False
    
    def run_full_pipeline(self) -> bool:
        """运行完整训练流程"""
        print("🎯 OntoThink 燧原T20训练流程开始")
        print("=" * 60)
        
        steps = [
            ("检查燧原T20环境", self.check_environment),
            ("准备训练数据", self.prepare_data),
            ("检查ChatGLM3模型", self.download_model_if_needed),
            ("启动模型训练", self.start_training)
        ]
        
        for step_name, step_func in steps:
            print(f"\n📋 步骤: {step_name}")
            if not step_func():
                print(f"❌ {step_name}失败，流程终止")
                return False
            print(f"✅ {step_name}完成")
        
        print("\n🎉 OntoThink燧原T20训练流程完成！")
        return True

def main():
    parser = argparse.ArgumentParser(description="OntoThink燧原T20训练管理器")
    parser.add_argument("--step", choices=[
        "check", "prepare", "download", "train", "full"
    ], default="full", help="执行步骤")
    
    args = parser.parse_args()
    
    trainer = OntoThinkEnflameTrainer()
    
    if args.step == "check":
        trainer.check_environment()
    elif args.step == "prepare":
        trainer.prepare_data()
    elif args.step == "download":
        trainer.download_model_if_needed()
    elif args.step == "train":
        trainer.start_training()
    elif args.step == "full":
        trainer.run_full_pipeline()

if __name__ == "__main__":
    main()
