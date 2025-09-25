# OntoThink 项目编码规范

## 核心原则

### 1. 真实数据和功能实现
**严格禁止使用mock、fake、stub等模拟实现**

- ✅ **正确做法**：
  - 使用真实的API调用
  - 连接真实的数据库
  - 实现完整的业务逻辑
  - 使用真实的外部服务

- ❌ **禁止做法**：
  - 使用mock数据或mock API
  - 使用fake实现替代真实功能
  - 使用stub来模拟外部依赖
  - 在开发或生产环境中使用模拟数据

### 2. 测试环境例外
**仅在测试代码中允许适当的mock使用**

测试中的mock使用必须：
- 明确标识为测试代码
- 不影响开发和生产环境
- 只用于隔离测试单元
- 有真实实现的对应测试

## 具体规范

### 前端开发
```typescript
// ❌ 错误示例 - 使用mock数据
const mockUser = { id: '1', name: 'mock-user' };
setUser(mockUser);

// ✅ 正确示例 - 调用真实API
const userData = await authApi.getCurrentUser();
setUser(userData);
```

### 后端开发
```python
# ❌ 错误示例 - 返回mock数据
def get_user():
    return {"id": 1, "name": "mock-user"}

# ✅ 正确示例 - 查询真实数据库
def get_user(db: Session, user_id: int):
    return db.query(User).filter(User.id == user_id).first()
```

### 数据库操作
```python
# ❌ 错误示例 - 使用内存数据库模拟
fake_db = {"users": [{"id": 1, "name": "test"}]}

# ✅ 正确示例 - 连接真实数据库
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
```

### 外部服务集成
```typescript
// ❌ 错误示例 - mock外部API
const mockResponse = { status: 'success', data: [] };

// ✅ 正确示例 - 调用真实外部服务
const response = await fetch('https://api.external-service.com/data');
const data = await response.json();
```

## 开发环境配置

### 数据库
- 使用真实的PostgreSQL/MySQL数据库
- 为开发环境配置独立的数据库实例
- 使用真实的schema和数据结构

### API服务
- 前端连接到真实的后端API
- 后端连接到真实的数据库
- 使用真实的外部服务集成

### 环境变量
```bash
# 开发环境 (.env.development)
REACT_APP_API_URL=http://localhost:8000/api/v1
DATABASE_URL=postgresql://user:pass@localhost/ontothink_dev

# 生产环境 (.env.production)
REACT_APP_API_URL=https://api.ontothink.com/v1
DATABASE_URL=postgresql://user:pass@prod-db/ontothink
```

## 错误处理

### 网络错误
```typescript
// ✅ 正确处理真实的网络错误
try {
  const data = await api.fetchData();
  return data;
} catch (error) {
  if (error.response?.status === 404) {
    throw new Error('数据不存在');
  } else if (error.response?.status >= 500) {
    throw new Error('服务器错误');
  }
  throw error;
}
```

### 数据验证
```python
# ✅ 使用真实的数据验证
def validate_user_data(user_data: dict):
    if not user_data.get('email'):
        raise ValueError('邮箱地址必填')
    
    if User.query.filter_by(email=user_data['email']).first():
        raise ValueError('邮箱地址已存在')
    
    return True
```

## 测试策略

### 单元测试
- 可以使用mock来隔离测试单元
- 必须有对应的集成测试验证真实交互
- Mock的使用必须明确文档化

### 集成测试
- 使用真实的数据库（测试数据库）
- 测试真实的API端点
- 验证完整的数据流

### 端到端测试
- 使用真实的用户界面
- 连接真实的后端服务
- 模拟真实的用户操作流程

## 代码审查检查点

在代码审查时，必须检查：

1. **是否存在mock/fake/stub使用**
   - 搜索关键词：mock, Mock, fake, Fake, stub, Stub
   - 检查是否有硬编码的测试数据
   - 验证是否连接真实服务

2. **API调用是否真实**
   - 检查是否有真实的HTTP请求
   - 验证错误处理逻辑
   - 确认环境变量配置正确

3. **数据库操作是否真实**
   - 检查是否连接真实数据库
   - 验证SQL查询和ORM操作
   - 确认事务处理正确

4. **错误处理是否完整**
   - 网络错误处理
   - 数据验证错误
   - 业务逻辑错误

## 常见违规情况

### 临时解决方案
```typescript
// ❌ 禁止的临时mock
// TODO: 替换为真实API调用
const tempData = { id: 1, name: 'temp' };
```

### 开发便利性mock
```typescript
// ❌ 禁止为了开发便利使用mock
if (process.env.NODE_ENV === 'development') {
  return mockData; // 这是被禁止的
}
```

### 未完成的功能mock
```python
# ❌ 禁止用mock代替未完成功能
def complex_calculation():
    # TODO: 实现复杂计算
    return 42  # mock返回值
```

## 违规处理

1. **代码审查阶段**：直接拒绝包含mock的PR
2. **发现已合并的mock代码**：立即创建修复任务
3. **持续集成检查**：添加自动化检查脚本

## 工具和脚本

### 检查mock使用的脚本
```bash
#!/bin/bash
# check-no-mock.sh
echo "检查项目中的mock使用..."

# 搜索可能的mock使用
grep -r -i "mock\|fake\|stub" --include="*.ts" --include="*.tsx" --include="*.py" --exclude-dir=node_modules --exclude-dir=.git .

if [ $? -eq 0 ]; then
  echo "❌ 发现mock使用，请修复"
  exit 1
else
  echo "✅ 未发现mock使用"
  exit 0
fi
```

### Pre-commit钩子
```bash
#!/bin/bash
# .git/hooks/pre-commit
./scripts/check-no-mock.sh
```

## 总结

OntoThink项目坚持使用真实数据和真实功能实现，这确保了：

1. **可靠性**：开发环境与生产环境一致
2. **质量**：及早发现集成问题
3. **效率**：减少mock维护成本
4. **信心**：真实测试提供更高信心

所有开发人员必须严格遵守这一原则，任何违规都将在代码审查阶段被拒绝。
