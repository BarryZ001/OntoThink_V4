#!/bin/bash
# 服务器强制拉取脚本 - 解决git冲突问题
# 在服务器上运行此脚本来强制同步最新代码

echo "🔄 服务器强制拉取最新代码"
echo "========================="

# 检查是否在正确目录
if [ ! -d ".git" ]; then
    echo "❌ 错误: 当前目录不是git仓库"
    echo "请确保在 /workspace/code/OntoThink_V4 目录下运行"
    exit 1
fi

echo "📍 当前目录: $(pwd)"
echo "🔍 检查git状态..."
git status

echo ""
echo "⚠️  将要执行强制拉取操作："
echo "1. 备份本地未提交的更改到stash"
echo "2. 强制重置到远程main分支"
echo "3. 覆盖所有本地冲突文件"

echo ""
echo "💾 1. 备份本地更改..."
git stash push -m "Backup before force pull - $(date)"

echo ""
echo "📥 2. 获取远程更新..."
git fetch origin

echo ""
echo "🔄 3. 强制重置到远程分支..."
git reset --hard origin/main

echo ""
echo "🧹 4. 清理未跟踪的文件..."
git clean -fd

echo ""
echo "✅ 强制拉取完成！"
echo "==================="

echo "📋 当前分支状态:"
git log --oneline -5

echo ""
echo "📁 检查关键文件:"
if [ -f "fix_4card_ultra_memory.sh" ]; then
    echo "✅ fix_4card_ultra_memory.sh - 超级内存优化方案已更新"
else
    echo "❌ fix_4card_ultra_memory.sh 文件缺失"
fi

if [ -f "fix_single_card_stable.sh" ]; then
    echo "✅ fix_single_card_stable.sh - 单卡稳定方案已更新"
else
    echo "❌ fix_single_card_stable.sh 文件缺失"
fi

if [ -f "fix_enflame_training_official.sh" ]; then
    echo "✅ fix_enflame_training_official.sh - 燧原官方配置已更新"
else
    echo "❌ fix_enflame_training_official.sh 文件缺失"
fi

echo ""
echo "🚀 下一步操作:"
echo "1. 运行 chmod +x *.sh 给脚本添加执行权限"
echo "2. 运行 bash fix_single_card_stable.sh 测试单卡稳定方案"
echo "3. 基于4卡成功经验验证SIGILL问题是否解决"

echo ""
echo "💡 恢复备份的命令 (如果需要):"
echo "git stash list  # 查看备份"
echo "git stash pop   # 恢复最新备份"

echo ""
echo "🎉 服务器代码已强制同步到最新版本！"
