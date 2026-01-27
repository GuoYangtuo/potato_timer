# GitHub Actions 快速配置指南

## 📋 配置清单

按照以下步骤完成配置，确保每一步都打勾 ✓

### 第一步：配置 GitHub Secrets

- [ ] 1. 进入 GitHub 仓库页面
- [ ] 2. 点击 `Settings` → `Secrets and variables` → `Actions`
- [ ] 3. 点击 `New repository secret` 添加以下三个密钥：

#### SERVER_IP
```
名称: SERVER_IP
值: 你的服务器IP地址（例如：123.456.789.0）
```

#### SERVER_SSH_USER
```
名称: SERVER_SSH_USER
值: SSH用户名（通常是 root）
```

#### SERVER_SSH_KEY
```
名称: SERVER_SSH_KEY
值: SSH私钥完整内容（包括 -----BEGIN 和 -----END 行）
```

### 第二步：生成 SSH 密钥（如果还没有）

在本地电脑运行：

```bash
# 生成密钥对
ssh-keygen -t rsa -b 4096 -C "github-actions-potato-timer" -f potato_timer_deploy_key

# 查看公钥（需要添加到服务器）
cat potato_timer_deploy_key.pub

# 查看私钥（需要添加到 GitHub Secrets）
cat potato_timer_deploy_key
```

### 第三步：配置服务器

SSH 登录到服务器：

```bash
ssh root@your-server-ip
```

#### 3.1 添加 SSH 公钥

```bash
# 创建 .ssh 目录（如果不存在）
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# 添加公钥到 authorized_keys
echo "你的公钥内容" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

#### 3.2 创建项目目录

```bash
# 创建主目录
mkdir -p /root/potato_timer_server

# 创建子目录
mkdir -p /root/potato_timer_server/updates
mkdir -p /root/potato_timer_server/scripts
mkdir -p /root/potato_timer_server/src

# 设置权限
chmod 755 /root/potato_timer_server
chmod 755 /root/potato_timer_server/updates
```

#### 3.3 配置 Web 服务器（Nginx 示例）

创建或编辑 Nginx 配置：

```bash
nano /etc/nginx/sites-available/potato_timer
```

添加以下配置：

```nginx
server {
    listen 80;
    server_name your-domain.com;  # 改为你的域名

    # API 代理
    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # APK 下载
    location /updates/ {
        alias /root/potato_timer_server/updates/;
        autoindex off;
        
        # 允许大文件下载
        client_max_body_size 100M;
        
        # 设置正确的 MIME 类型
        types {
            application/vnd.android.package-archive apk;
        }
        
        # 添加下载头
        add_header Content-Disposition 'attachment';
    }
}
```

启用配置并重启 Nginx：

```bash
# 创建软链接
ln -s /etc/nginx/sites-available/potato_timer /etc/nginx/sites-enabled/

# 测试配置
nginx -t

# 重启 Nginx
systemctl restart nginx
```

#### 3.4 安装 Node.js（如果未安装）

```bash
# 使用 NodeSource 安装 Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# 验证安装
node --version
npm --version
```

#### 3.5 配置服务管理

**选项 A: 使用 systemd**

创建服务文件：

```bash
nano /etc/systemd/system/potato_timer_backend.service
```

添加以下内容：

```ini
[Unit]
Description=Potato Timer Backend Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/potato_timer_server
ExecStart=/usr/bin/node /root/potato_timer_server/src/index.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

启用并启动服务：

```bash
systemctl daemon-reload
systemctl enable potato_timer_backend
systemctl start potato_timer_backend
systemctl status potato_timer_backend
```

**选项 B: 使用 PM2**

```bash
# 安装 PM2
npm install -g pm2

# 启动服务
cd /root/potato_timer_server
pm2 start src/index.js --name potato_timer

# 设置开机自启
pm2 startup
pm2 save
```

### 第四步：修改工作流配置

编辑 `.github/workflows/android-release.yaml`：

#### 4.1 修改 Flutter 版本（第 29 行）

查看你的 Flutter 版本：
```bash
flutter --version
```

修改为对应版本：
```yaml
flutter-version: '3.24.0'  # 改为你的版本
```

#### 4.2 修改下载 URL（第 115 行）

```yaml
DOWNLOAD_URL="https://your-domain.com/updates/potato_timer_v${VERSION}.apk"
```

将 `your-domain.com` 改为：
- 你的域名（推荐）：`https://potato.example.com`
- 或服务器 IP：`http://123.456.789.0`

#### 4.3 修改服务重启命令（第 127 行）

根据你选择的服务管理方式：

**systemd**:
```bash
systemctl restart potato_timer_backend
```

**PM2**:
```bash
pm2 restart potato_timer
```

### 第五步：测试配置

#### 5.1 测试 SSH 连接

```bash
# 使用私钥测试连接
ssh -i potato_timer_deploy_key root@your-server-ip

# 如果成功连接，说明密钥配置正确
```

#### 5.2 测试服务器目录

```bash
ssh root@your-server-ip "ls -la /root/potato_timer_server"
```

应该看到 `updates` 和 `scripts` 目录。

#### 5.3 手动触发工作流测试

1. 进入 GitHub 仓库的 `Actions` 标签
2. 选择 `Android Release & Deploy`
3. 点击 `Run workflow`
4. 输入测试参数：
   - 版本号: `2`
   - 更新日志: `测试自动部署功能`
5. 点击 `Run workflow` 开始

#### 5.4 查看构建日志

在 Actions 页面查看实时日志，确保每一步都成功。

#### 5.5 验证部署结果

```bash
# 检查 APK 文件
ssh root@your-server-ip "ls -lh /root/potato_timer_server/updates/"

# 检查版本配置
ssh root@your-server-ip "cat /root/potato_timer_server/version-config.json"

# 测试 API
curl http://your-domain.com/api/version/check

# 测试 APK 下载
curl -I http://your-domain.com/updates/potato_timer_v2.apk
```

### 第六步：配置 Android 签名（可选但推荐）

#### 6.1 生成签名密钥

```bash
cd android/app
keytool -genkey -v -keystore potato_timer.keystore -alias potato_timer -keyalg RSA -keysize 2048 -validity 10000
```

#### 6.2 配置 build.gradle

编辑 `android/app/build.gradle.kts`，在 `android` 块中添加：

```kotlin
signingConfigs {
    create("release") {
        storeFile = file("potato_timer.keystore")
        storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "your-password"
        keyAlias = "potato_timer"
        keyPassword = System.getenv("KEY_PASSWORD") ?: "your-password"
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        // ... 其他配置
    }
}
```

#### 6.3 添加密钥到 GitHub Secrets

```bash
# 将 keystore 文件转换为 base64
base64 -w 0 android/app/potato_timer.keystore > keystore.txt
```

在 GitHub Secrets 中添加：
- `KEYSTORE_BASE64`: keystore.txt 的内容
- `KEYSTORE_PASSWORD`: 密钥库密码
- `KEY_PASSWORD`: 密钥密码
- `KEY_ALIAS`: `potato_timer`

#### 6.4 修改工作流

在 `.github/workflows/android-release.yaml` 的第 44 步之前添加：

```yaml
- name: Decode Keystore
  run: |
    echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/potato_timer.keystore

- name: Build Android APK
  env:
    KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
    KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
  run: |
    flutter build apk --release
```

## ✅ 配置完成检查清单

完成所有配置后，确认以下各项：

- [ ] GitHub Secrets 已配置（SERVER_IP, SERVER_SSH_USER, SERVER_SSH_KEY）
- [ ] SSH 密钥已生成并添加到服务器
- [ ] 服务器目录已创建（/root/potato_timer_server）
- [ ] Nginx 已配置并可以访问 /updates 路径
- [ ] Node.js 已安装在服务器上
- [ ] 服务管理已配置（systemd 或 PM2）
- [ ] 工作流文件已修改（Flutter 版本、下载 URL、重启命令）
- [ ] 已进行测试部署并成功
- [ ] API 接口可以正常访问
- [ ] APK 文件可以下载

## 🎉 开始使用

配置完成后，你可以：

### 自动部署
```bash
# 修改代码
git add .
git commit -m "feat: 新功能"
git push origin main

# GitHub Actions 会自动构建和部署
```

### 手动部署
1. 进入 GitHub Actions
2. 运行 "Android Release & Deploy" 工作流
3. 输入版本号和更新日志

## 📞 需要帮助？

如果遇到问题，请检查：

1. **GitHub Actions 日志** - 查看具体错误信息
2. **服务器日志** - `journalctl -u potato_timer_backend -f` 或 `pm2 logs`
3. **Nginx 日志** - `/var/log/nginx/error.log`
4. **网络连接** - 确保服务器可以从 GitHub 访问

## 🔧 故障排除

### SSH 连接失败
```bash
# 测试 SSH 连接
ssh -v root@your-server-ip

# 检查服务器 SSH 日志
tail -f /var/log/auth.log
```

### APK 下载 404
```bash
# 检查文件是否存在
ls -la /root/potato_timer_server/updates/

# 检查 Nginx 配置
nginx -t
cat /etc/nginx/sites-enabled/potato_timer
```

### 版本配置未更新
```bash
# 检查脚本是否存在
ls -la /root/potato_timer_server/scripts/update-version.js

# 手动运行脚本测试
cd /root/potato_timer_server
node scripts/update-version.js 2 "http://test.com/test.apk" "测试"
```

