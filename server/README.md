# Potato Timer 后端服务

一键登录系统的 Node.js + TypeScript 后端服务。

## 功能

- 接收 Flutter 应用发送的一键登录信息
- 存储和管理用户登录数据
- 提供用户信息查询接口

## 安装

```bash
npm install
```

## 开发

```bash
npm run dev
```

## 构建

```bash
npm run build
```

## 运行

```bash
npm start
```

## API 接口

### POST /api/auth/login
一键登录接口

**请求体:**
```json
{
  "token": "用户token（从阿里云号码认证SDK获取）"
}
```

**说明**: 客户端只需要发送token，服务端会通过阿里云GetMobile接口获取手机号。

**响应:**
```json
{
  "success": true,
  "message": "登录成功",
  "data": {
    "userId": 1,
    "phoneNumber": "13800138000",
    "loginTime": "2024-01-01T00:00:00.000Z",
    "tokenPreview": "..."
  }
}
```

### GET /api/user/:userId
获取用户信息

### GET /api/users
获取所有用户列表（开发测试用）

### GET /health
健康检查

## 环境变量

创建 `.env` 文件并配置以下参数：

```env
# 服务器端口
PORT=3000

# 阿里云AccessKey配置（必需）
ALIYUN_ACCESS_KEY_ID=your_access_key_id
ALIYUN_ACCESS_KEY_SECRET=your_access_key_secret
```

**重要**: 请务必配置阿里云AccessKey，否则无法调用GetMobile接口获取手机号。

