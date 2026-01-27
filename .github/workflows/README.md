# GitHub Actions 工作流说明

## 文件说明

### `android-release.yaml`

自动构建 Android APK、上传到服务器并更新版本配置的工作流。

## 触发方式

### 1. 自动触发（推荐）

当以下文件发生变更并推送到 `main` 分支时自动触发：
- `lib/**` - Flutter 代码
- `android/**` - Android 配置
- `pubspec.yaml` - 项目配置

```bash
# 修改代码后
git add .
git commit -m "feat: 新增功能"
git push origin main
```

工作流会自动：
1. 从 `pubspec.yaml` 读取版本号（`version: x.x.x+BUILD_NUMBER`）
2. 使用 `BUILD_NUMBER` 作为版本号
3. 构建 APK 并命名为 `potato_timer_vBUILD_NUMBER.apk`
4. 上传到服务器并更新版本配置

### 2. 手动触发

在 GitHub 仓库页面：`Actions` → `Android Release & Deploy` → `Run workflow`

可以自定义：
- **版本号**：例如 `2`、`3`
- **更新日志**：使用 `\n` 分隔多行，例如：
  ```
  1. 新增目标分享功能\n2. 修复已知bug\n3. 优化性能
  ```

## 必需的 GitHub Secrets

在仓库设置中配置以下 Secrets：`Settings` → `Secrets and variables` → `Actions` → `New repository secret`

| Secret 名称 | 说明 | 示例 |
|------------|------|------|
| `SERVER_IP` | 服务器 IP 地址 | `123.456.789.0` |
| `SERVER_SSH_USER` | SSH 用户名 | `root` |
| `SERVER_SSH_KEY` | SSH 私钥 | 完整的私钥内容 |

### 生成 SSH 密钥对

如果还没有 SSH 密钥：

```bash
# 在本地生成密钥对
ssh-keygen -t rsa -b 4096 -C "github-actions" -f github_actions_key

# 将公钥添加到服务器
ssh-copy-id -i github_actions_key.pub user@your-server-ip

# 或手动添加
cat github_actions_key.pub
# 复制输出，然后在服务器上：
echo "公钥内容" >> ~/.ssh/authorized_keys

# 将私钥内容添加到 GitHub Secrets
cat github_actions_key
# 复制完整内容（包括 -----BEGIN 和 -----END 行）
```

## 服务器配置

### 1. 目录结构

确保服务器上有以下目录：

```bash
/root/potato_timer_server/
├── scripts/
│   └── update-version.js
├── updates/                    # APK 存放目录
├── version-config.json
└── [其他服务器文件]
```

### 2. 创建目录

```bash
ssh user@your-server-ip
mkdir -p /root/potato_timer_server/updates
mkdir -p /root/potato_timer_server/scripts
```

### 3. 配置下载 URL

编辑工作流文件中的下载 URL（第 115 行）：

```yaml
DOWNLOAD_URL="https://your-domain.com/updates/potato_timer_v${VERSION}.apk"
```

将 `your-domain.com` 替换为你的实际域名或 IP。

### 4. 配置服务重启命令

根据你的服务管理方式，修改第 127 行：

**使用 systemd**:
```bash
systemctl restart potato_timer_backend
```

**使用 PM2**:
```bash
pm2 restart potato_timer
```

**使用其他方式**:
```bash
# 根据实际情况修改
```

## 版本号管理

### 方式一：修改 pubspec.yaml（推荐）

```yaml
# pubspec.yaml
version: 1.0.0+2  # 将 +2 改为 +3
```

提交并推送后，工作流会自动使用版本号 `3`。

### 方式二：手动触发时指定

在 GitHub Actions 页面手动运行时，可以指定任意版本号。

## 工作流程

1. **代码检出** - 获取最新代码
2. **环境设置** - 配置 Java、Flutter、Node.js
3. **读取版本** - 从 pubspec.yaml 获取版本号
4. **构建 APK** - `flutter build apk --release`
5. **重命名文件** - `potato_timer_vX.apk`
6. **上传 APK** - 传输到服务器 `/root/potato_timer_server/updates/`
7. **上传服务器代码** - 更新服务器端代码
8. **更新版本配置** - 运行 `update-version.js` 脚本
9. **重启服务** - 使服务器配置生效
10. **创建 Release** - 在 GitHub 创建发布版本
11. **构建总结** - 显示构建信息

## 验证部署

### 1. 检查 GitHub Actions

在仓库的 `Actions` 标签页查看工作流运行状态。

### 2. 检查服务器文件

```bash
ssh user@your-server-ip

# 检查 APK 文件
ls -lh /root/potato_timer_server/updates/

# 检查版本配置
cat /root/potato_timer_server/version-config.json

# 测试 API
curl http://localhost:3000/api/version/check
```

### 3. 测试客户端更新

1. 启动 Flutter 应用
2. 应该在 1 秒后弹出更新提示
3. 等待下载完成
4. 点击"立即更新"测试安装

## 常见问题

### Q1: 构建失败 - Flutter 版本不匹配

修改工作流第 29 行的 Flutter 版本：

```yaml
flutter-version: '3.24.0'  # 改为你的 Flutter 版本
```

查看你的 Flutter 版本：
```bash
flutter --version
```

### Q2: SSH 连接失败

检查：
1. `SERVER_IP` 是否正确
2. `SERVER_SSH_USER` 是否有权限
3. `SERVER_SSH_KEY` 是否完整（包括开头和结尾的标记行）
4. 服务器防火墙是否允许 SSH 连接

### Q3: 服务器路径不存在

确保服务器上的路径与工作流中配置的一致：
- APK 上传路径：第 81 行
- 服务器文件路径：第 92 行
- 脚本执行路径：第 102 行

### Q4: 版本配置更新失败

检查：
1. `scripts/update-version.js` 是否存在
2. Node.js 是否已安装
3. 脚本是否有执行权限

```bash
chmod +x /root/potato_timer_server/scripts/update-version.js
```

### Q5: APK 下载地址无法访问

1. 确保 Nginx 或 Web 服务器配置了 `/updates` 目录的访问
2. 检查文件权限：
   ```bash
   chmod 644 /root/potato_timer_server/updates/*.apk
   ```

## 自定义配置

### 修改服务器路径

如果你的服务器路径不是 `/root/potato_timer_server/`，需要修改：

1. 第 81 行 - APK 上传目标路径
2. 第 92 行 - 服务器文件上传路径
3. 第 102 行 - SSH 脚本中的工作目录

### 添加签名配置

如果需要使用自定义签名，在第 44 步之前添加：

```yaml
- name: Decode Keystore
  run: |
    echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/keystore.jks

- name: Create key.properties
  run: |
    echo "storePassword=${{ secrets.KEYSTORE_PASSWORD }}" > android/key.properties
    echo "keyPassword=${{ secrets.KEY_PASSWORD }}" >> android/key.properties
    echo "keyAlias=${{ secrets.KEY_ALIAS }}" >> android/key.properties
    echo "storeFile=keystore.jks" >> android/key.properties
```

### 添加通知

可以在最后添加通知步骤，例如发送到钉钉、企业微信等。

## 最佳实践

1. **版本号规范**：使用 `pubspec.yaml` 中的 build number，按顺序递增
2. **更新日志**：每次发布都写清楚更新内容
3. **测试环境**：先在测试环境验证，再发布到生产环境
4. **备份 APK**：GitHub Release 会自动保存历史版本
5. **监控日志**：定期查看 Actions 运行日志

## 参考文档

- [VERSION_UPDATE_GUIDE.md](../../server/VERSION_UPDATE_GUIDE.md) - 版本更新服务详细说明
- [VERSION_UPDATE_API.md](../../VERSION_UPDATE_API.md) - API 接口文档

