# Potato Timer - 一键登录系统

基于阿里云号码认证服务的一键登录 Flutter 应用，包含 Node.js + TypeScript 后端服务。

## 功能特性

- ✅ 阿里云一键登录集成
- ✅ 自定义登录界面
- ✅ 用户信息后端存储
- ✅ RESTful API 接口

## 项目结构

```
potato_timer/
├── lib/
│   ├── main.dart              # 应用入口
│   └── pages/
│       └── login_page.dart    # 一键登录页面
├── assets/                    # 资源文件（图片、按钮等）
├── server/                    # Node.js + TypeScript 后端
│   ├── src/
│   │   └── index.ts          # 后端主文件
│   ├── package.json
│   └── tsconfig.json
└── pubspec.yaml
```

## 快速开始

### 1. Flutter 应用设置

#### 安装依赖

```bash
flutter pub get
```

#### 配置密钥

在 `lib/pages/login_page.dart` 中替换您的实际密钥：

```dart
androidSk = "您的Android密钥";
iosSk = "您的iOS密钥";
```

#### 运行应用

```bash
flutter run
```

### 2. 后端服务设置

#### 安装依赖

```bash
cd server
npm install
```

#### 配置环境变量

创建 `server/.env` 文件并配置阿里云AccessKey：

```env
PORT=3000
ALIYUN_ACCESS_KEY_ID=your_access_key_id
ALIYUN_ACCESS_KEY_SECRET=your_access_key_secret
```

**重要**: 必须配置阿里云AccessKey，服务端需要通过GetMobile接口获取手机号。

#### 启动开发服务器

```bash
npm run dev
```

服务器将在 `http://localhost:3000` 启动。

#### 构建生产版本

```bash
npm run build
npm start
```

## API 接口

### POST /api/auth/login

一键登录接口，接收 Flutter 应用发送的用户登录信息。

**请求示例:**
```json
{
  "token": "用户token（从阿里云号码认证SDK获取）"
}
```

**说明**: 客户端只发送token，服务端通过阿里云GetMobile接口获取手机号。

**响应示例:**
```json
{
  "success": true,
  "message": "登录成功",
  "data": {
    "userId": 1,
    "phoneNumber": "13800138000",
    "loginTime": "2024-01-01T00:00:00.000Z"
  }
}
```

### GET /api/user/:userId

获取指定用户信息。

### GET /api/users

获取所有用户列表（开发测试用）。

### GET /health

健康检查接口。

## 使用说明

1. **启动后端服务**
   ```bash
   cd server
   npm run dev
   ```

2. **运行 Flutter 应用**
   ```bash
   flutter run
   ```

3. **点击"开始一键登录"按钮**
   - 应用会调用阿里云一键登录 SDK
   - 用户完成授权后，登录信息会发送到后端
   - 后端存储用户信息并返回响应

## 注意事项

1. **密钥配置**: 请务必替换示例代码中的密钥为您的实际密钥
2. **网络配置**: 确保 Flutter 应用可以访问后端服务地址（默认 `http://localhost:3000`）
3. **Android 配置**: 需要在 `android/app/src/main/AndroidManifest.xml` 中配置网络权限
4. **iOS 配置**: 需要在 `ios/Runner/Info.plist` 中配置网络权限

## 开发

### Flutter 开发

```bash
flutter pub get
flutter run
```

### 后端开发

```bash
cd server
npm install
npm run dev
```

## 依赖

### Flutter 依赖

- `ali_auth`: 阿里云一键登录插件
- `fluttertoast`: 弹窗提示
- `http`: HTTP 请求

### 后端依赖

- `express`: Web 框架
- `cors`: 跨域支持
- `typescript`: TypeScript 支持

## 许可证

MIT
