# CI/CD 快速开始指南

> 5 分钟完成 GitHub Actions 自动化部署配置

## 🎯 目标

配置完成后，你只需要：
1. 修改代码
2. 推送到 GitHub
3. 自动构建、部署、更新版本 ✨

### 步骤 2: 配置 GitHub Secrets

#### 2.1 生成 SSH 密钥（如果没有）

```bash
ssh-keygen -t rsa -b 4096 -C "potato-timer-deploy" -f potato_timer_deploy_key
```

会生成两个文件：
- `potato_timer_deploy_key` - 私钥（添加到 GitHub）
- `potato_timer_deploy_key.pub` - 公钥（添加到服务器）

#### 2.2 添加公钥到服务器

```bash
# 查看公钥
cat potato_timer_deploy_key.pub

# SSH 登录服务器
ssh root@你的服务器IP

# 添加公钥
mkdir -p ~/.ssh
echo "粘贴公钥内容" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

#### 2.3 添加 Secrets 到 GitHub

1. 打开你的 GitHub 仓库
2. 点击 **Settings** → **Secrets and variables** → **Actions**
3. 点击 **New repository secret**，添加以下三个：

| 名称 | 值 |
|------|-----|
| `SERVER_IP` | 你的服务器 IP（如：`123.456.789.0`） |
| `SERVER_SSH_USER` | SSH 用户名（通常是 `root`） |
| `SERVER_SSH_KEY` | 私钥完整内容（`cat potato_timer_deploy_key` 的输出） |

### 步骤 3: 修改配置文件

#### 3.1 修改工作流配置

编辑 `.github/workflows/android-release.yaml`：

**第 29 行** - Flutter 版本：
```yaml
flutter-version: '3.24.0'  # 改为你的 Flutter 版本
```

查看你的版本：
```bash
flutter --version
```

**第 115 行** - 下载 URL：
```yaml
DOWNLOAD_URL="https://your-domain.com/updates/potato_timer_v${VERSION}.apk"
```
改为你的域名或 IP：
```yaml
DOWNLOAD_URL="https://你的域名.com/updates/potato_timer_v${VERSION}.apk"
# 或
DOWNLOAD_URL="http://123.456.789.0/updates/potato_timer_v${VERSION}.apk"
```

**第 127 行** - 服务重启命令：
```yaml
systemctl restart potato_timer_backend
```
根据你的服务管理方式修改（systemd 或 PM2）。

#### 3.2 配置服务器

SSH 登录服务器：
```bash
ssh root@你的服务器IP
```

创建目录：
```bash
mkdir -p /root/potato_timer_server/{updates,scripts,src}
```

安装 Node.js（如果未安装）：
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
node --version
```

配置 Nginx（创建 `/etc/nginx/sites-available/potato_timer`）：
```nginx
server {
    listen 80;
    server_name 你的域名.com;

    location /api/ {
        proxy_pass http://localhost:3000;
    }

    location /updates/ {
        alias /root/potato_timer_server/updates/;
        types { application/vnd.android.package-archive apk; }
    }
}
```

启用配置：
```bash
ln -s /etc/nginx/sites-available/potato_timer /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
```

## ✅ 测试部署

### 方式一：手动触发（推荐首次测试）

1. 访问 GitHub 仓库的 **Actions** 标签
2. 选择 **Android Release & Deploy**
3. 点击 **Run workflow**
4. 输入：
   - 版本号: `2`
   - 更新日志: `测试自动部署`
5. 点击 **Run workflow**

### 方式二：自动触发

```bash
# 修改版本号
# 编辑 pubspec.yaml，将 version: 1.0.0+1 改为 version: 1.0.0+2

# 提交并推送
git add .
git commit -m "test: 测试自动部署"
git push origin main
```

## 🔍 验证部署

### 1. 查看 Actions 日志

访问：`https://github.com/你的用户名/potato_timer/actions`

确保所有步骤都是绿色 ✓

### 2. 检查服务器文件

```bash
# 检查 APK
ssh root@你的服务器IP "ls -lh /root/potato_timer_server/updates/"

# 检查版本配置
ssh root@你的服务器IP "cat /root/potato_timer_server/version-config.json"
```

应该看到：
```json
{
  "version": 2,
  "downloadUrl": "https://你的域名.com/updates/potato_timer_v2.apk",
  "updateLog": "测试自动部署"
}
```

### 3. 测试 API

```bash
curl http://你的域名.com/api/version/check
```

应该返回版本信息。

### 4. 测试客户端更新

1. 启动 Flutter 应用
2. 应在 1 秒后弹出更新提示
3. 等待下载完成
4. 点击"立即更新"

## 🎉 完成！

配置成功后，以后只需要：

```bash
# 1. 修改代码
# 2. 更新版本号（可选）
# 编辑 pubspec.yaml: version: 1.0.0+3

# 3. 提交推送
git add .
git commit -m "feat: 新功能"
git push origin main

# 4. 自动完成构建和部署！
```

## 📚 详细文档

如果需要更详细的说明，请查看：

- **完整配置指南**: [`.github/workflows/setup-guide.md`](.github/workflows/setup-guide.md)
- **工作流说明**: [`.github/workflows/README.md`](.github/workflows/README.md)
- **CI/CD 总览**: [`CICD_README.md`](CICD_README.md)
- **版本更新服务**: [`server/VERSION_UPDATE_GUIDE.md`](server/VERSION_UPDATE_GUIDE.md)

## ❓ 常见问题

### Q: SSH 连接失败？

检查：
- `SERVER_IP` 是否正确
- `SERVER_SSH_KEY` 是否包含完整内容（包括 BEGIN 和 END 行）
- 服务器是否允许 SSH 连接

### Q: APK 下载 404？

检查：
- Nginx 配置是否正确
- 文件权限：`chmod 644 /root/potato_timer_server/updates/*.apk`
- 下载 URL 是否正确

### Q: 版本配置未更新？

检查：
- Node.js 是否已安装
- `scripts/update-version.js` 是否存在
- 查看 Actions 日志中的错误信息

### Q: 如何回退版本？

```bash
ssh root@你的服务器IP
cd /root/potato_timer_server
node scripts/update-version.js 1 "旧版本URL" "回退到旧版本"
```

## 🆘 需要帮助？

1. 运行配置检查脚本查看问题
2. 查看 GitHub Actions 日志
3. 查看服务器日志：`journalctl -u potato_timer_backend -f`
4. 查看详细文档

---

**祝你部署顺利！** 🚀

