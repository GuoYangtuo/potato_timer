# 土豆时钟后端服务

## 环境要求

- Node.js 18+
- MySQL 8.0+

## 安装

```bash
npm install
```

## 配置

创建 `.env` 文件并配置以下环境变量：

```env
# 服务器配置
PORT=3000
NODE_ENV=development
BASE_URL=http://localhost:3000

# 阿里云配置
ALIYUN_ACCESS_KEY_ID=your_access_key_id
ALIYUN_ACCESS_KEY_SECRET=your_access_key_secret

# 数据库配置
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=potato_timer

# JWT配置
JWT_SECRET=your_jwt_secret_key
```

## 数据库初始化

1. 创建数据库并导入表结构：

```bash
mysql -u root -p < src/database/schema.sql
```

## 运行

开发模式：
```bash
npm run dev
```

生产模式：
```bash
npm run build
npm start
```

## API 接口

### 认证

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/auth/login | 一键登录 |
| GET | /api/auth/me | 获取当前用户信息 |
| PUT | /api/auth/profile | 更新用户信息 |

### 激励内容

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/motivations/public | 获取公开激励内容列表 |
| GET | /api/motivations/my | 获取我的激励内容 |
| GET | /api/motivations/:id | 获取激励内容详情 |
| POST | /api/motivations | 创建激励内容 |
| PUT | /api/motivations/:id | 更新激励内容 |
| DELETE | /api/motivations/:id | 删除激励内容 |
| POST | /api/motivations/:id/like | 点赞 |
| DELETE | /api/motivations/:id/like | 取消点赞 |
| POST | /api/motivations/:id/favorite | 收藏 |
| DELETE | /api/motivations/:id/favorite | 取消收藏 |
| GET | /api/motivations/favorites/list | 获取收藏列表 |

### 目标

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/goals/my | 获取我的目标列表 |
| GET | /api/goals/public | 获取公开目标列表 |
| GET | /api/goals/:id | 获取目标详情 |
| POST | /api/goals | 创建目标 |
| PUT | /api/goals/:id | 更新目标 |
| DELETE | /api/goals/:id | 删除目标 |
| POST | /api/goals/:id/complete | 完成目标（记录一次完成） |
| GET | /api/goals/:id/motivations | 获取目标关联的激励内容 |

### 标签

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/tags | 获取所有可用标签 |
| GET | /api/tags/popular | 获取热门标签 |

### 文件上传

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/upload/file | 上传单个文件 |
| POST | /api/upload/files | 上传多个文件 |

## 项目结构

```
server/
├── src/
│   ├── database/
│   │   ├── db.ts          # 数据库连接
│   │   └── schema.sql     # 数据库表结构
│   ├── middleware/
│   │   └── auth.ts        # 认证中间件
│   ├── routes/
│   │   ├── auth.ts        # 认证路由
│   │   ├── goals.ts       # 目标路由
│   │   ├── motivations.ts # 激励内容路由
│   │   ├── tags.ts        # 标签路由
│   │   └── upload.ts      # 文件上传路由
│   ├── aliyun.ts          # 阿里云 API
│   └── index.ts           # 入口文件
├── uploads/               # 上传文件目录
├── package.json
└── tsconfig.json
```
