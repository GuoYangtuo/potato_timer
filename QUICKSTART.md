# 快速启动指南

## 前置要求

- Flutter SDK (3.10.1+)
- Node.js (16+)
- npm 或 yarn

## 步骤 1: 配置 Flutter 应用

### 1.1 安装 Flutter 依赖

```bash
flutter pub get
```

### 1.2 配置密钥

编辑 `lib/pages/login_page.dart`，替换以下密钥为您的实际密钥：

```dart
androidSk = "您的Android密钥";
iosSk = "您的iOS密钥";
```

### 1.3 配置网络权限（Android）

在 `android/app/src/main/AndroidManifest.xml` 中添加：

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### 1.4 配置网络权限（iOS）

在 `ios/Runner/Info.plist` 中添加：

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## 步骤 2: 配置后端服务

### 2.1 安装后端依赖

```bash
cd server
npm install
```

### 2.2 启动后端服务

开发模式：
```bash
npm run dev
```

生产模式：
```bash
npm run build
npm start
```

后端服务将在 `http://localhost:3000` 启动。

## 步骤 3: 运行应用

### 3.1 启动后端服务（如果未启动）

```bash
cd server
npm run dev
```

### 3.2 运行 Flutter 应用

```bash
flutter run
```

## 步骤 4: 测试登录

1. 在应用中点击"开始一键登录"按钮
2. 完成阿里云一键登录授权
3. 查看后端控制台，应该能看到用户登录信息
4. 应用界面会显示登录成功信息

## 测试 API

### 健康检查

```bash
curl http://localhost:3000/health
```

### 查看所有用户

```bash
curl http://localhost:3000/api/users
```

## 常见问题

### 1. 后端连接失败

- 确保后端服务已启动
- 检查 Flutter 应用中的 API 地址是否正确
- 对于 Android 模拟器，使用 `10.0.2.2` 代替 `localhost`
- 对于 iOS 模拟器，使用 `localhost` 或 `127.0.0.1`

### 2. 一键登录失败

- 检查密钥是否正确配置
- 确保已正确配置阿里云号码认证服务
- 查看控制台日志获取详细错误信息

### 3. 资源文件缺失

- 确保 `assets` 目录下的所有文件都已正确复制
- 检查 `pubspec.yaml` 中的资源文件配置

## 下一步

- 集成数据库存储用户信息
- 添加 JWT 认证
- 实现用户会话管理
- 添加更多业务逻辑

