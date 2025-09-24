#!/usr/bin/env python3
"""
OntoThink训练管理器
用于统一管理整个训练流程
"""

import subprocess
import argparse
import os
import json
import time
from pathlib import Path
from typing import Dict, Any
import shutil

class OntoThinkTrainingManager:
    def __init__(self, config_path: str = None):
        self.base_dir = Path("/Users/barryzhang/myDev3/OntoThink_V4")
        self.config = self.load_config(config_path)
        
    def load_config(self, config_path: str = None) -> Dict[str, Any]:
        """加载训练配置"""
        if config_path and Path(config_path).exists():
            with open(config_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        
        # 默认配置
        return {
            "model": {
                "base_model": "THUDM/chatglm3-6b",
                "output_dir": str(self.base_dir / "models" / "chatglm3-ontothink"),
                "max_seq_length": 2048
            },
            "data": {
                "raw_data_dir": str(self.base_dir / "backend" / "data" / "processed"),
                "optimized_data_dir": str(self.base_dir / "backend" / "data" / "optimized"),
                "expand_samples": 200
            },
            "training": {
                "num_gpus": 8,
                "batch_size_per_gpu": 2,
                "gradient_accumulation_steps": 4,
                "num_epochs": 3,
                "learning_rate": 5e-5,
                "use_lora": True,
                "lora_r": 64,
                "lora_alpha": 128,
                "q_lora": True
            },
            "deepseek": {
                "api_key": os.getenv("DEEPSEEK_API_KEY", "")
            }
        }
    
    def check_prerequisites(self) -> bool:
        """检查训练前提条件"""
        print("🔍 检查训练前提条件...")
        
        # 检查GPU
        try:
            result = subprocess.run(["nvidia-smi"], capture_output=True, text=True)
            if result.returncode != 0:
                print("❌ 未检测到NVIDIA GPU")
                return False
            print("✅ GPU检查通过")
        except FileNotFoundError:
            print("❌ nvidia-smi未找到")
            return False
        
        # 检查Python环境
        required_packages = ["torch", "transformers", "peft", "datasets", "bitsandbytes"]
        for package in required_packages:
            try:
                __import__(package)
                print(f"✅ {package} 已安装")
            except ImportError:
                print(f"❌ {package} 未安装")
                return False
        
        # 检查数据目录
        data_dir = Path(self.config["data"]["raw_data_dir"])
        if not data_dir.exists():
            print(f"❌ 数据目录不存在: {data_dir}")
            return False
        
        print("✅ 前提条件检查完成")
        return True
    
    def expand_training_data(self) -> bool:
        """扩展训练数据"""
        print("📈 开始扩展训练数据...")
        
        if not self.config["deepseek"]["api_key"]:
            print("⚠️  未配置DeepSeek API密钥，跳过数据扩展")
            return True
        
        script_path = self.base_dir / "backend" / "scripts" / "expand_training_data.py"
        output_path = self.base_dir / "backend" / "data" / "expanded_data.jsonl"
        
        cmd = [
            "python", str(script_path),
            "--api_key", self.config["deepseek"]["api_key"],
            "--num_samples", str(self.config["data"]["expand_samples"]),
            "--output_path", str(output_path)
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=str(self.base_dir))
            if result.returncode == 0:
                print("✅ 数据扩展完成")
                return True
            else:
                print(f"❌ 数据扩展失败: {result.stderr}")
                return False
        except Exception as e:
            print(f"❌ 数据扩展异常: {e}")
            return False
    
    def prepare_optimized_data(self) -> bool:
        """准备优化的训练数据"""
        print("🔧 准备优化的训练数据...")
        
        script_path = self.base_dir / "backend" / "scripts" / "prepare_optimized_data.py"
        
        cmd = [
            "python", str(script_path),
            "--input_dir", self.config["data"]["raw_data_dir"],
            "--output_dir", self.config["data"]["optimized_data_dir"]
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=str(self.base_dir))
            if result.returncode == 0:
                print("✅ 数据优化完成")
                return True
            else:
                print(f"❌ 数据优化失败: {result.stderr}")
                return False
        except Exception as e:
            print(f"❌ 数据优化异常: {e}")
            return False
    
    def start_training(self) -> bool:
        """启动模型训练"""
        print("🚀 启动模型训练...")
        
        # 创建输出目录
        output_dir = Path(self.config["model"]["output_dir"])
        output_dir.mkdir(parents=True, exist_ok=True)
        
        # 保存训练配置
        config_file = output_dir / "training_config.json"
        with open(config_file, 'w', encoding='utf-8') as f:
            json.dump(self.config, f, ensure_ascii=False, indent=2)
        
        # 构建训练命令
        training_script = self.base_dir / "backend" / "app" / "training" / "chatglm3_ontothink_training.py"
        
        cmd = [
            "torchrun",
            f"--nproc_per_node={self.config['training']['num_gpus']}",
            "--master_port=29500",
            str(training_script),
            "--model_name_or_path", self.config["model"]["base_model"],
            "--data_path", self.config["data"]["optimized_data_dir"],
            "--output_dir", self.config["model"]["output_dir"],
            "--num_train_epochs", str(self.config["training"]["num_epochs"]),
            "--per_device_train_batch_size", str(self.config["training"]["batch_size_per_gpu"]),
            "--gradient_accumulation_steps", str(self.config["training"]["gradient_accumulation_steps"]),
            "--learning_rate", str(self.config["training"]["learning_rate"]),
            "--max_seq_length", str(self.config["model"]["max_seq_length"]),
            "--use_lora", str(self.config["training"]["use_lora"]),
            "--lora_r", str(self.config["training"]["lora_r"]),
            "--lora_alpha", str(self.config["training"]["lora_alpha"]),
            "--q_lora", str(self.config["training"]["q_lora"]),
            "--bf16", "True",
            "--gradient_checkpointing", "True",
            "--evaluation_strategy", "steps",
            "--eval_steps", "100",
            "--save_strategy", "steps",
            "--save_steps", "200",
            "--logging_steps", "10",
            "--report_to", "tensorboard"
        ]
        
        # 设置环境变量
        env = os.environ.copy()
        env.update({
            "CUDA_VISIBLE_DEVICES": ",".join(map(str, range(self.config["training"]["num_gpus"]))),
            "NCCL_DEBUG": "INFO",
            "NCCL_IB_DISABLE": "1",
            "NCCL_P2P_DISABLE": "1"
        })
        
        # 启动训练
        log_file = output_dir / f"training_{int(time.time())}.log"
        
        try:
            with open(log_file, 'w', encoding='utf-8') as f:
                process = subprocess.Popen(
                    cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    universal_newlines=True,
                    env=env,
                    cwd=str(self.base_dir)
                )
                
                print(f"📊 训练日志: {log_file}")
                print("🔄 训练进行中...")
                
                # 实时输出日志
                for line in process.stdout:
                    print(line.rstrip())
                    f.write(line)
                    f.flush()
                
                process.wait()
                
                if process.returncode == 0:
                    print("✅ 训练完成")
                    return True
                else:
                    print(f"❌ 训练失败，返回码: {process.returncode}")
                    return False
                    
        except Exception as e:
            print(f"❌ 训练异常: {e}")
            return False
    
    def validate_model(self) -> bool:
        """验证训练后的模型"""
        print("🔍 验证训练后的模型...")
        
        script_path = self.base_dir / "backend" / "scripts" / "validate_model.py"
        model_path = self.config["model"]["output_dir"]
        test_data_path = Path(self.config["data"]["optimized_data_dir"]) / "test.jsonl"
        output_path = Path(model_path) / "validation_results.json"
        
        cmd = [
            "python", str(script_path),
            "--model_path", model_path,
            "--test_data_path", str(test_data_path) if test_data_path.exists() else "",
            "--output_path", str(output_path),
            "--base_model", self.config["model"]["base_model"]
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=str(self.base_dir))
            if result.returncode == 0:
                print("✅ 模型验证完成")
                print(result.stdout)
                return True
            else:
                print(f"❌ 模型验证失败: {result.stderr}")
                return False
        except Exception as e:
            print(f"❌ 模型验证异常: {e}")
            return False
    
    def run_full_pipeline(self) -> bool:
        """运行完整的训练流程"""
        print("🎯 开始OntoThink模型完整训练流程")
        print("=" * 60)
        
        steps = [
            ("检查前提条件", self.check_prerequisites),
            ("扩展训练数据", self.expand_training_data),
            ("准备优化数据", self.prepare_optimized_data),
            ("启动模型训练", self.start_training),
            ("验证训练模型", self.validate_model)
        ]
        
        for step_name, step_func in steps:
            print(f"\n📋 {step_name}...")
            if not step_func():
                print(f"❌ {step_name}失败，停止流程")
                return False
            print(f"✅ {step_name}完成")
        
        print("\n🎉 OntoThink模型训练流程全部完成！")
        print(f"📁 模型保存位置: {self.config['model']['output_dir']}")
        return True

def main():
    parser = argparse.ArgumentParser(description="OntoThink训练管理器")
    parser.add_argument("--config", help="训练配置文件路径")
    parser.add_argument("--step", choices=[
        "check", "expand", "prepare", "train", "validate", "full"
    ], default="full", help="执行的步骤")
    
    args = parser.parse_args()
    
    manager = OntoThinkTrainingManager(args.config)
    
    if args.step == "check":
        manager.check_prerequisites()
    elif args.step == "expand":
        manager.expand_training_data()
    elif args.step == "prepare":
        manager.prepare_optimized_data()
    elif args.step == "train":
        manager.start_training()
    elif args.step == "validate":
        manager.validate_model()
    elif args.step == "full":
        manager.run_full_pipeline()

if __name__ == "__main__":
    main()
