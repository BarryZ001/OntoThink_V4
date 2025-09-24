#!/bin/bash
# 服务器端Git冲突解决脚本

echo "🔧 解决服务器端Git冲突"
echo "=================================="

# 保存当前的本地修改
echo "💾 保存本地修改..."
git stash push -m "服务器本地修改备份"

# 拉取最新代码
echo "📥 拉取最新代码..."
git pull origin main

# 如果需要恢复本地修改，可以运行：
# git stash pop

echo "✅ Git冲突已解决！"
echo "💡 如果需要恢复之前的本地修改，运行: git stash pop"
