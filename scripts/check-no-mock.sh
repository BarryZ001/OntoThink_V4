#!/bin/bash
# OntoThink项目 - Mock使用检查脚本
# 严格禁止在项目中使用mock、fake、stub等模拟实现

set -e

echo "🔍 OntoThink Mock使用检查"
echo "========================================"

# 项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# 允许的例外目录和文件
EXCLUDE_DIRS=(
    "node_modules"
    ".git"
    "dist" 
    "build"
    "__tests__"
    "test"
    "tests"
    "venv"          # Python虚拟环境
    "env"           # Python虚拟环境
    ".venv"         # Python虚拟环境
    "__pycache__"   # Python缓存
    ".pytest_cache" # Pytest缓存
    "coverage"      # 覆盖率报告
)

EXCLUDE_FILES=(
    "*.test.*"
    "*.spec.*" 
    "jest.config.*"
    "package-lock.json"
    "yarn.lock"
    "poetry.lock"
    "Pipfile.lock"
)

# 构建排除模式
# （现在直接在find命令中使用排除条件）

echo "📁 检查目录: $PROJECT_ROOT"
echo "🔎 搜索模式: mock|Mock|fake|Fake|stub|Stub|simulate|Simulate"
echo ""

# 标记是否发现违规
VIOLATIONS_FOUND=false

# 搜索前端代码（排除第三方依赖）
echo "🎨 检查前端代码 (TypeScript/JavaScript)..."
FRONTEND_VIOLATIONS=""
if [ -d "frontend/src" ]; then
    FRONTEND_VIOLATIONS=$(find frontend/src -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" | \
        grep -v node_modules | grep -v dist | grep -v build | \
        xargs grep -l -i "mock\|fake\|stub\|simulate" 2>/dev/null || true)
fi

if [ -n "$FRONTEND_VIOLATIONS" ]; then
    echo "❌ 前端代码中发现mock使用:"
    for file in $FRONTEND_VIOLATIONS; do
        echo "  📄 $file"
        grep -n -i "mock\|fake\|stub\|simulate" "$file" | head -3 | while read line; do
            echo "    🔸 $line"
        done
        echo ""
    done
    VIOLATIONS_FOUND=true
else
    echo "✅ 前端代码检查通过"
fi

echo ""

# 搜索后端代码（排除虚拟环境和第三方库）
echo "🐍 检查后端代码 (Python)..."
BACKEND_VIOLATIONS=""
if [ -d "backend" ]; then
    BACKEND_VIOLATIONS=$(find backend -name "*.py" -not -path "*/venv/*" -not -path "*/env/*" -not -path "*/.venv/*" -not -path "*/__pycache__/*" | \
        xargs grep -l -i "mock\|fake\|stub\|simulate" 2>/dev/null || true)
fi

if [ -n "$BACKEND_VIOLATIONS" ]; then
    echo "❌ 后端代码中发现mock使用:"
    for file in $BACKEND_VIOLATIONS; do
        echo "  📄 $file"
        grep -n -i "mock\|fake\|stub\|simulate" "$file" | head -3 | while read line; do
            echo "    🔸 $line"
        done
        echo ""
    done
    VIOLATIONS_FOUND=true
else
    echo "✅ 后端代码检查通过"
fi

echo ""

# 搜索配置文件（排除锁文件和第三方依赖）
echo "⚙️  检查配置文件..."
CONFIG_VIOLATIONS=""
CONFIG_FILES=$(find . -name "*.json" -o -name "*.yaml" -o -name "*.yml" -o -name "*.toml" | \
    grep -v node_modules | grep -v .git | grep -v dist | grep -v build | grep -v venv | \
    grep -v package-lock.json | grep -v yarn.lock | grep -v poetry.lock)

if [ -n "$CONFIG_FILES" ]; then
    CONFIG_VIOLATIONS=$(echo "$CONFIG_FILES" | xargs grep -l -i "mock\|fake\|stub\|simulate" 2>/dev/null || true)
fi

if [ -n "$CONFIG_VIOLATIONS" ]; then
    echo "❌ 配置文件中发现mock使用:"
    for file in $CONFIG_VIOLATIONS; do
        echo "  📄 $file"
        grep -n -i "mock\|fake\|stub\|simulate" "$file" | head -3 | while read line; do
            echo "    🔸 $line"
        done
        echo ""
    done
    VIOLATIONS_FOUND=true
else
    echo "✅ 配置文件检查通过"
fi

echo ""

# 检查环境变量文件
echo "🌍 检查环境变量文件..."
ENV_VIOLATIONS=$(find . -name ".env*" -o -name "*.env" | \
    xargs grep -l -i "mock\|fake\|stub\|simulate" 2>/dev/null || true)

if [ -n "$ENV_VIOLATIONS" ]; then
    echo "❌ 环境变量文件中发现mock使用:"
    for file in $ENV_VIOLATIONS; do
        echo "  📄 $file"
        grep -n -i "mock\|fake\|stub\|simulate" "$file" | head -3 | while read line; do
            echo "    🔸 $line"
        done
        echo ""
    done
    VIOLATIONS_FOUND=true
else
    echo "✅ 环境变量文件检查通过"
fi

echo ""

# 检查特定的违规模式
echo "🔍 检查特定违规模式..."

# 检查硬编码的测试数据（排除第三方库）
echo "  - 检查硬编码测试数据..."
HARDCODED_DATA=""
if [ -d "frontend/src" ] || [ -d "backend" ]; then
    HARDCODED_DATA=$(find frontend/src backend -name "*.ts" -o -name "*.tsx" -o -name "*.py" 2>/dev/null | \
        grep -v venv | grep -v node_modules | \
        xargs grep -l "test.*data\|demo.*data\|sample.*data\|temp.*data" 2>/dev/null || true)
fi

if [ -n "$HARDCODED_DATA" ]; then
    echo "    ⚠️  发现可能的硬编码测试数据:"
    for file in $HARDCODED_DATA; do
        echo "      📄 $file"
    done
    echo ""
fi

# 检查TODO中的mock相关内容（排除第三方库）
echo "  - 检查TODO中的mock相关内容..."
TODO_MOCKS=""
if [ -d "frontend/src" ] || [ -d "backend" ]; then
    TODO_MOCKS=$(find frontend/src backend -name "*.ts" -o -name "*.tsx" -o -name "*.py" 2>/dev/null | \
        grep -v venv | grep -v node_modules | \
        xargs grep -l "TODO.*mock\|FIXME.*mock\|XXX.*mock" 2>/dev/null || true)
fi

if [ -n "$TODO_MOCKS" ]; then
    echo "    ⚠️  发现TODO中的mock相关内容:"
    for file in $TODO_MOCKS; do
        echo "      📄 $file"
        grep -n "TODO.*mock\|FIXME.*mock\|XXX.*mock" "$file" | while read line; do
            echo "        🔸 $line"
        done
    done
    echo ""
fi

echo ""
echo "========================================"

# 输出结果
if [ "$VIOLATIONS_FOUND" = true ]; then
    echo "❌ 检查失败: 发现mock使用违规"
    echo ""
    echo "🔧 修复建议:"
    echo "  1. 将mock实现替换为真实API调用"
    echo "  2. 连接真实数据库而不是内存数据"
    echo "  3. 使用真实外部服务集成"
    echo "  4. 查阅编码规范: docs/coding-guidelines.md"
    echo ""
    echo "📋 如果必须在测试中使用mock:"
    echo "  1. 确保代码在测试目录中"
    echo "  2. 文件名包含 .test. 或 .spec."
    echo "  3. 有对应的真实实现集成测试"
    echo ""
    exit 1
else
    echo "✅ 检查通过: 未发现mock使用违规"
    echo ""
    echo "🎉 恭喜! 项目严格遵循真实数据和真实功能实现原则"
    echo ""
    exit 0
fi
