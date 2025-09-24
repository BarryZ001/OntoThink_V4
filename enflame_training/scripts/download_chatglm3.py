#!/usr/bin/env python3
"""
ChatGLM3-6B 快速下载脚本
支持多个镜像源，适合国内网络环境
"""

import os
import sys
import subprocess
from pathlib import Path

def download_with_modelscope():
    """使用ModelScope下载（国内推荐）"""
    try:
        print("📥 尝试使用ModelScope下载...")
        
        # 先尝试安装modelscope
        subprocess.run([sys.executable, "-m", "pip", "install", "modelscope"], 
                      capture_output=True, check=False)
        
        from modelscope import snapshot_download
        
        model_dir = snapshot_download(
            'ZhipuAI/chatglm3-6b',
            cache_dir='.',
            revision='master'
        )
        
        print(f"✅ ModelScope下载完成: {model_dir}")
        return True
        
    except Exception as e:
        print(f"❌ ModelScope下载失败: {e}")
        return False

def download_with_transformers():
    """使用transformers下载"""
    try:
        print("📥 尝试使用transformers下载...")
        
        from transformers import AutoModel, AutoTokenizer
        
        print("📥 下载模型...")
        model = AutoModel.from_pretrained(
            'THUDM/chatglm3-6b', 
            trust_remote_code=True,
            torch_dtype='auto'
        )
        
        print("📥 下载tokenizer...")
        tokenizer = AutoTokenizer.from_pretrained(
            'THUDM/chatglm3-6b', 
            trust_remote_code=True
        )
        
        print("💾 保存模型...")
        model.save_pretrained('.')
        tokenizer.save_pretrained('.')
        
        print("✅ transformers下载完成")
        return True
        
    except Exception as e:
        print(f"❌ transformers下载失败: {e}")
        return False

def download_with_git_mirror():
    """使用Git镜像下载"""
    try:
        print("📥 尝试使用Git镜像下载...")
        
        # 使用国内镜像
        mirror_urls = [
            "https://hf-mirror.com/THUDM/chatglm3-6b",
            "https://www.modelscope.cn/ZhipuAI/chatglm3-6b.git"
        ]
        
        for url in mirror_urls:
            try:
                print(f"📥 尝试从 {url} 下载...")
                result = subprocess.run(
                    ["git", "clone", url, "."],
                    capture_output=True,
                    text=True,
                    timeout=300  # 5分钟超时
                )
                
                if result.returncode == 0:
                    print(f"✅ Git镜像下载完成: {url}")
                    return True
                else:
                    print(f"❌ 从 {url} 下载失败: {result.stderr}")
                    
            except subprocess.TimeoutExpired:
                print(f"⏰ 从 {url} 下载超时")
                
    except Exception as e:
        print(f"❌ Git镜像下载失败: {e}")
        
    return False

def create_basic_config():
    """创建基础配置文件（临时方案）"""
    print("📝 创建基础配置文件...")
    
    config = {
        "_name_or_path": "THUDM/chatglm3-6b",
        "architectures": ["ChatGLMModel"],
        "auto_map": {
            "AutoConfig": "configuration_chatglm.ChatGLMConfig",
            "AutoModel": "modeling_chatglm.ChatGLMForConditionalGeneration",
            "AutoModelForSeq2SeqLM": "modeling_chatglm.ChatGLMForConditionalGeneration"
        },
        "hidden_size": 4096,
        "num_layers": 28,
        "num_attention_heads": 32,
        "vocab_size": 65024,
        "torch_dtype": "float16",
        "transformers_version": "4.30.2"
    }
    
    import json
    with open('config.json', 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)
    
    tokenizer_config = {
        "auto_map": {
            "AutoTokenizer": ["tokenization_chatglm.ChatGLMTokenizer", None]
        },
        "tokenizer_class": "ChatGLMTokenizer",
        "trust_remote_code": True
    }
    
    with open('tokenizer_config.json', 'w', encoding='utf-8') as f:
        json.dump(tokenizer_config, f, indent=2, ensure_ascii=False)
    
    print("✅ 基础配置文件创建完成")

def main():
    print("🚀 ChatGLM3-6B 多源下载器")
    print("=" * 50)
    
    # 确保在正确的目录
    model_dir = Path(__file__).parent.parent / "models" / "THUDM" / "chatglm3-6b"
    
    # 如果目录存在但为空或不完整，先清理
    if model_dir.exists():
        files = list(model_dir.glob("*"))
        if not files or not any(f.name == "config.json" for f in files):
            print(f"🧹 清理不完整的目录: {model_dir}")
            import shutil
            shutil.rmtree(model_dir)
    
    model_dir.mkdir(parents=True, exist_ok=True)
    os.chdir(model_dir)
    
    print(f"📁 目标目录: {model_dir}")
    
    # 按优先级尝试不同的下载方式
    download_methods = [
        ("ModelScope (国内推荐)", download_with_modelscope),
        ("Git镜像", download_with_git_mirror),
        ("Transformers", download_with_transformers)
    ]
    
    for method_name, method_func in download_methods:
        print(f"\n🔄 尝试方式: {method_name}")
        
        if method_func():
            print(f"🎉 下载成功！使用方式: {method_name}")
            break
    else:
        print("\n❌ 所有下载方式都失败了")
        print("📝 创建基础配置文件作为临时方案...")
        create_basic_config()
        
        print("\n💡 手动下载建议:")
        print("1. 访问 https://www.modelscope.cn/ZhipuAI/chatglm3-6b/files")
        print("2. 下载所有 pytorch_model*.bin 文件")
        print("3. 下载 tokenizer.model 和相关Python文件")
        print("4. 放置到当前目录")
        
        return False
    
    # 验证下载结果
    print("\n🔍 验证下载结果...")
    required_files = ['config.json', 'tokenizer_config.json']
    model_files = list(Path('.').glob('pytorch_model*.bin'))
    
    all_good = True
    for file in required_files:
        if Path(file).exists():
            print(f"✅ {file}")
        else:
            print(f"❌ {file}")
            all_good = False
    
    if model_files:
        print(f"✅ 模型权重文件: {len(model_files)} 个")
    else:
        print("❌ 模型权重文件缺失")
        all_good = False
    
    if all_good:
        print("\n🎉 ChatGLM3-6B 下载完成！")
        print("\n📋 下一步:")
        print("cd /workspace/code/OntoThink_V4")
        print("python3 enflame_training/scripts/train_ontothink_enflame.py --step full")
    else:
        print("\n⚠️  下载不完整，请检查或重试")
    
    return all_good

if __name__ == "__main__":
    main()
