# OntoThink - 思维导图与思辨分析平台

## 项目概述

OntoThink 是一个基于人工智能的思辨分析平台，旨在帮助用户进行深度思考和知识体系构建。通过生成多角度的思辨图谱，用户可以更全面地理解复杂问题，探索不同的观点和论证。

## 功能特点

- **思辨图谱生成**：输入问题，自动生成包含多立场、论据和反问的思辨图谱
- **交互式探索**：支持节点展开/折叠、拖拽、缩放等交互操作
- **结构化展示**：清晰展示问题、立场、论据和反驳的逻辑关系
- **知识连接**：关联相关概念和知识，帮助用户建立知识网络

## 技术栈

### 前端
- React + TypeScript
- React Flow 用于图谱可视化
- Tailwind CSS 用于样式

### 后端
- Python 3.9+
- FastAPI
- PostgreSQL
- DeepSeek 模型 API

### 开发工具
- Git 版本控制
- Poetry 依赖管理
- Pre-commit 代码检查

## 快速开始

### 环境要求

- Python 3.9+
- Node.js 16+
- PostgreSQL 13+

### 安装与运行

1. 克隆仓库
```bash
git clone https://github.com/yourusername/ontothink.git
cd ontothink
```

2. 设置后端环境
```bash
# 创建并激活虚拟环境
python -m venv venv
source venv/bin/activate  # Linux/Mac
# 或
# .\venv\Scripts\activate  # Windows

# 安装依赖
cd backend
pip install -r requirements.txt

# 设置环境变量
cp .env.example .env
# 编辑 .env 文件配置数据库和其他设置
```

3. 设置前端环境
```bash
cd frontend
npm install
```

4. 运行开发服务器

后端：
```bash
cd backend
uvicorn app.main:app --reload
```

前端：
```bash
cd frontend
npm start
```

## 项目结构

```
ontothink/
├── backend/               # 后端代码
│   ├── app/              # 应用代码
│   │   ├── api/          # API 路由
│   │   ├── core/         # 核心功能
│   │   ├── db/           # 数据库相关
│   │   ├── models/       # 数据模型
│   │   ├── schemas/      # Pydantic 模型
│   │   └── services/     # 业务逻辑
│   └── tests/            # 测试代码
│
├── frontend/             # 前端代码
│   ├── public/           # 静态资源
│   └── src/              # 源代码
│       ├── components/   # React 组件
│       ├── assets/       # 资源文件
│       ├── styles/       # 样式文件
│       └── utils/        # 工具函数
│
├── data/                 # 数据文件
│   ├── raw/             # 原始数据
│   └── processed/       # 处理后的数据
│
├── scripts/             # 实用脚本
├── notebooks/           # Jupyter 笔记本
└── docs/               # 项目文档
```

## 贡献指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

## 许可证

本项目采用 MIT 许可证 - 详情请参阅 [LICENSE](LICENSE) 文件

## 致谢

- 感谢所有贡献者的代码和反馈
- 特别感谢 DeepSeek 提供的模型支持
