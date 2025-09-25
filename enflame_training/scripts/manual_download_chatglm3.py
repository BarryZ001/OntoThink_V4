#!/usr/bin/env python3
"""
ChatGLM3 手动下载脚本 - 彻底解决下载问题
适用于燧原T20环境
"""

import os
import sys
import hashlib
import urllib.request
import urllib.error
from pathlib import Path
import json
import time

def print_status(message, status="info"):
    """打印带状态的消息"""
    symbols = {
        "info": "📋",
        "success": "✅", 
        "error": "❌",
        "warning": "⚠️",
        "progress": "🔄"
    }
    print(f"{symbols.get(status, '📋')} {message}")

def download_file_with_progress(url, filepath, timeout=300):
    """下载文件并显示进度"""
    try:
        print_status(f"下载: {os.path.basename(filepath)}", "progress")
        
        # 创建请求
        req = urllib.request.Request(url)
        req.add_header('User-Agent', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36')
        
        with urllib.request.urlopen(req, timeout=timeout) as response:
            total_size = int(response.headers.get('content-length', 0))
            
            with open(filepath, 'wb') as f:
                downloaded = 0
                chunk_size = 8192
                
                while True:
                    chunk = response.read(chunk_size)
                    if not chunk:
                        break
                    
                    f.write(chunk)
                    downloaded += len(chunk)
                    
                    if total_size > 0:
                        percent = (downloaded / total_size) * 100
                        print(f"\r  进度: {percent:.1f}% ({downloaded}/{total_size} bytes)", end="", flush=True)
                
                print()  # 换行
        
        # 验证文件大小
        actual_size = os.path.getsize(filepath)
        if total_size > 0 and actual_size != total_size:
            print_status(f"文件大小不匹配: 期望{total_size}, 实际{actual_size}", "warning")
        else:
            print_status(f"下载完成: {actual_size} bytes", "success")
        
        return True
        
    except Exception as e:
        print_status(f"下载失败: {e}", "error")
        return False

def verify_file_integrity(filepath, min_size=None, expected_size=None):
    """验证文件完整性"""
    if not os.path.exists(filepath):
        print_status(f"文件不存在: {filepath}", "error")
        return False
    
    size = os.path.getsize(filepath)
    
    if min_size and size < min_size:
        print_status(f"文件过小: {size} < {min_size}", "error")
        return False
    
    if expected_size and size != expected_size:
        print_status(f"文件大小不匹配: {size} != {expected_size}", "warning")
    
    print_status(f"文件大小正常: {size} bytes", "success")
    return True

def test_tokenizer(model_dir):
    """测试tokenizer功能"""
    tokenizer_path = os.path.join(model_dir, "tokenizer.model")
    
    try:
        import sentencepiece as spm
        
        print_status("测试tokenizer功能...", "progress")
        
        # 加载tokenizer
        sp = spm.SentencePieceProcessor()
        sp.load(tokenizer_path)
        
        # 测试编码解码
        test_texts = [
            "你好，世界！",
            "ChatGLM3 is a conversational language model.",
            "人工智能技术发展迅速。",
            "What is the meaning of life?"
        ]
        
        for text in test_texts:
            tokens = sp.encode(text)
            decoded = sp.decode(tokens)
            
            if decoded.strip() != text.strip():
                print_status(f"编码解码不一致: '{text}' -> '{decoded}'", "warning")
            else:
                print_status(f"测试通过: '{text}' ({len(tokens)} tokens)", "success")
        
        print_status("Tokenizer功能验证通过!", "success")
        return True
        
    except ImportError:
        print_status("sentencepiece未安装", "error")
        print_status("请安装: pip install sentencepiece", "info")
        return False
    except Exception as e:
        print_status(f"Tokenizer测试失败: {e}", "error")
        return False

def main():
    print("🚀 ChatGLM3 手动下载器")
    print("适用于燧原T20环境")
    print("=" * 50)
    
    # 确定模型目录
    script_dir = Path(__file__).parent
    model_dir = script_dir.parent / "models" / "THUDM" / "chatglm3-6b"
    
    print_status(f"目标目录: {model_dir}", "info")
    
    # 创建目录
    model_dir.mkdir(parents=True, exist_ok=True)
    os.chdir(model_dir)
    
    print_status(f"工作目录: {os.getcwd()}", "info")
    
    # 定义需要下载的文件
    files_to_download = {
        "config.json": {
            "urls": [
                "https://huggingface.co/THUDM/chatglm3-6b/resolve/main/config.json",
                "https://www.modelscope.cn/api/v1/models/ZhipuAI/chatglm3-6b/repo?Revision=master&FilePath=config.json"
            ],
            "min_size": 100,
            "critical": True
        },
        "tokenizer_config.json": {
            "urls": [
                "https://huggingface.co/THUDM/chatglm3-6b/resolve/main/tokenizer_config.json",
                "https://www.modelscope.cn/api/v1/models/ZhipuAI/chatglm3-6b/repo?Revision=master&FilePath=tokenizer_config.json"
            ],
            "min_size": 100,
            "critical": True
        },
        "special_tokens_map.json": {
            "urls": [
                "https://huggingface.co/THUDM/chatglm3-6b/resolve/main/special_tokens_map.json",
                "https://www.modelscope.cn/api/v1/models/ZhipuAI/chatglm3-6b/repo?Revision=master&FilePath=special_tokens_map.json"
            ],
            "min_size": 10,
            "critical": True
        },
        "tokenizer.model": {
            "urls": [
                "https://huggingface.co/THUDM/chatglm3-6b/resolve/main/tokenizer.model",
                "https://www.modelscope.cn/api/v1/models/ZhipuAI/chatglm3-6b/repo?Revision=master&FilePath=tokenizer.model"
            ],
            "min_size": 1000000,  # 至少1MB
            "critical": True
        },
        "modeling_chatglm.py": {
            "urls": [
                "https://huggingface.co/THUDM/chatglm3-6b/resolve/main/modeling_chatglm.py",
                "https://www.modelscope.cn/api/v1/models/ZhipuAI/chatglm3-6b/repo?Revision=master&FilePath=modeling_chatglm.py"
            ],
            "min_size": 10000,
            "critical": True
        },
        "tokenization_chatglm.py": {
            "urls": [
                "https://huggingface.co/THUDM/chatglm3-6b/resolve/main/tokenization_chatglm.py", 
                "https://www.modelscope.cn/api/v1/models/ZhipuAI/chatglm3-6b/repo?Revision=master&FilePath=tokenization_chatglm.py"
            ],
            "min_size": 5000,
            "critical": True
        },
        "configuration_chatglm.py": {
            "urls": [
                "https://huggingface.co/THUDM/chatglm3-6b/resolve/main/configuration_chatglm.py",
                "https://www.modelscope.cn/api/v1/models/ZhipuAI/chatglm3-6b/repo?Revision=master&FilePath=configuration_chatglm.py"
            ],
            "min_size": 1000,
            "critical": True
        }
    }
    
    # 下载文件
    success_count = 0
    total_files = len(files_to_download)
    
    for filename, file_info in files_to_download.items():
        print(f"\n📄 处理文件: {filename}")
        
        # 检查文件是否已存在且有效
        if verify_file_integrity(filename, file_info["min_size"]):
            print_status(f"{filename} 已存在且有效，跳过下载", "success")
            success_count += 1
            continue
        
        # 尝试下载
        downloaded = False
        for i, url in enumerate(file_info["urls"]):
            print_status(f"尝试源 {i+1}/{len(file_info['urls'])}: {url.split('/')[-1]}", "progress")
            
            if download_file_with_progress(url, filename):
                if verify_file_integrity(filename, file_info["min_size"]):
                    downloaded = True
                    success_count += 1
                    break
                else:
                    print_status("下载的文件无效，删除并尝试下一个源", "warning")
                    try:
                        os.remove(filename)
                    except:
                        pass
            
            time.sleep(1)  # 避免请求过快
        
        if not downloaded:
            print_status(f"所有源都失败: {filename}", "error")
            if file_info["critical"]:
                print_status("这是关键文件，下载失败可能影响训练", "error")
    
    # 总结
    print(f"\n{'='*50}")
    print_status(f"下载完成: {success_count}/{total_files} 文件成功", "info")
    
    if success_count == total_files:
        print_status("所有文件下载成功!", "success")
        
        # 测试tokenizer
        if test_tokenizer(model_dir):
            print_status("ChatGLM3模型准备就绪，可以开始训练!", "success")
            return 0
        else:
            print_status("Tokenizer测试失败，请检查", "error")
            return 1
    else:
        print_status("部分文件下载失败", "error")
        return 1

if __name__ == "__main__":
    sys.exit(main())
