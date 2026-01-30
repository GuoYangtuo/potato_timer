# 🔐 Release 签名配置指南

## 📋 配置步骤

### 1. 生成 Release Keystore（本地执行一次）

```bash
cd android/app
keytool -genkey -v -keystore release.keystore -alias potato_timer -keyalg RSA -keysize 2048 -validity 10000
```

**记录以下信息：**
- Keystore 密码（storePassword）
- Key 密码（keyPassword）
- Key 别名（keyAlias）：`potato_timer`

### 2. 创建本地签名配置文件

在项目根目录创建 `android/key.properties`：

```properties
storePassword=你的keystore密码
keyPassword=你的key密码
keyAlias=potato_timer
storeFile=app/release.keystore
```

⚠️ **注意：** 此文件已在 `.gitignore` 中，不会提交到 Git。

### 3. 配置 GitHub Secrets（用于 CI/CD）

进入 GitHub 仓库设置：**Settings** → **Secrets and variables** → **Actions**

添加以下 4 个 secrets：

#### 3.1 生成 Keystore 的 Base64 编码

```bash
# Windows PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/release.keystore"))

# Linux/macOS
base64 android/app/release.keystore | tr -d '\n'
```

#### 3.2 添加 Secrets

| Secret 名称 | 值 | 说明 |
|------------|---|------|
| `RELEASE_KEYSTORE_BASE64` | 上面生成的 Base64 字符串 | Keystore 文件 |
| `KEYSTORE_PASSWORD` | 你的 keystore 密码 | Keystore 密码 |
| `KEY_PASSWORD` | 你的 key 密码 | Key 密码 |
| `KEY_ALIAS` | `potato_timer` | Key 别名 |

### 4. 获取新的签名信息（用于阿里云配置）

```bash
# 获取 SHA1 和 SHA256（用于阿里云后台）
keytool -list -v -keystore android/app/release.keystore -alias potato_timer
```

**重要信息：**
- SHA1 指纹
- SHA256 指纹

### 5. 更新阿里云号码认证配置

1. 登录 [阿里云号码认证控制台](https://yundun.console.aliyun.com/)
2. 创建新应用或更新现有应用：
   - **应用包名**：`com.guoyangtuo.potatoclock1`
   - **签名 SHA1**：使用上面获取的 SHA1
   - **签名 SHA256**：使用上面获取的 SHA256
3. 获取新的 **Secret Key**
4. 更新 `lib/config/env_config.dart` 中的生产环境 Secret：
   ```dart
   defaultValue: '新的Secret值'
   ```

## ✅ 验证配置

### 本地测试
```bash
flutter build apk --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=BASE_URL=http://8.141.116.178:3000
```

### 检查签名
```bash
# 查看 APK 签名信息
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
```

## 🔒 安全注意事项

1. ✅ **已做的安全措施：**
   - `release.keystore` 在 `.gitignore` 中
   - `key.properties` 在 `.gitignore` 中
   - GitHub Secrets 加密存储

2. ⚠️ **请务必：**
   - 备份 `release.keystore` 到安全位置
   - 记录所有密码到密码管理器
   - 不要将 keystore 提交到 Git

3. 🚨 **如果丢失 keystore：**
   - 无法再发布应用更新
   - 需要修改包名重新上架

## 📊 配置对比

| 环境 | 签名方式 | 阿里云 Secret | 用途 |
|------|---------|--------------|------|
| 开发环境 | debug.keystore | 开发环境 Secret | 本地调试 |
| 生产环境 | release.keystore | 生产环境 Secret | 正式发布 |

## 🎯 下次部署

配置完成后，下次 push 到 main 分支或手动触发 workflow，将自动使用 release 签名构建 APK。

