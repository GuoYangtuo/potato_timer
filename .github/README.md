# GitHub Actions 自动化部署文档

欢迎使用 Potato Timer 的自动化部署系统！

## 📚 文档导航

### 🚀 快速开始
- **[快速开始指南](../CICD_QUICKSTART.md)** ⭐ 推荐首次使用
  - 5 分钟完成配置
  - 3 步开始使用
  - 包含测试验证

### 📖 详细文档
- **[CI/CD 总览](../CICD_README.md)**
  - 完整的功能说明
  - 配置项详解
  - 故障排除指南

- **[工作流说明](workflows/README.md)**
  - 工作流详细说明
  - 触发方式
  - 执行流程

- **[配置指南](workflows/setup-guide.md)**
  - 完整的配置步骤
  - 服务器配置
  - Nginx 配置示例

### ✅ 发布管理
- **[发布检查清单](RELEASE_CHECKLIST.md)**
  - 发布前检查
  - 发布流程
  - 发布后验证

### 🔧 工具和脚本
- **配置检查脚本**
  - Windows: `scripts/check-cicd-config.ps1`
  - Linux/Mac: `scripts/check-cicd-config.sh`

### 📋 工作流文件
- **[android-release.yaml](workflows/android-release.yaml)**
  - 主工作流：构建、部署、更新版本
  - 自动触发或手动触发
  
- **[android-build-only.yaml](workflows/android-build-only.yaml)**
  - 测试工作流：仅构建 APK
  - PR 自动触发

## 🎯 使用场景

### 场景 1: 首次配置
1. 阅读 [快速开始指南](../CICD_QUICKSTART.md)
2. 运行配置检查脚本
3. 按照 [配置指南](workflows/setup-guide.md) 完成设置
4. 手动触发测试部署

### 场景 2: 日常开发
```bash
# 修改代码
git add .
git commit -m "feat: 新功能"
git push origin main
# 自动构建和部署
```

### 场景 3: 发布新版本
1. 查看 [发布检查清单](RELEASE_CHECKLIST.md)
2. 更新 `pubspec.yaml` 版本号
3. 提交并推送代码
4. 等待自动部署完成
5. 验证部署结果

### 场景 4: 紧急修复
1. 修复代码
2. 手动触发工作流
3. 填写版本号和更新日志
4. 快速发布

## 🔑 关键概念

### 版本号管理
```yaml
# pubspec.yaml
version: 1.0.0+2
#        ^^^^^ ^^
#        |     |
#        |     +-- 构建号（用作版本更新的版本号）
#        +-------- 语义化版本
```

### 工作流触发
- **自动触发**: 推送到 main 分支且修改了相关文件
- **手动触发**: 在 GitHub Actions 页面手动运行

### 部署流程
1. 构建 APK
2. 上传到服务器
3. 更新版本配置
4. 重启服务
5. 创建 GitHub Release

## ⚙️ 配置要求

### GitHub Secrets
- `SERVER_IP` - 服务器 IP
- `SERVER_SSH_USER` - SSH 用户名
- `SERVER_SSH_KEY` - SSH 私钥

### 服务器要求
- Node.js v20+
- Nginx 或其他 Web 服务器
- 目录: `/root/potato_timer_server/`

### 工作流配置
- Flutter 版本（第 29 行）
- 下载 URL（第 115 行）
- 服务重启命令（第 127 行）

## 📊 工作流程图

```
代码修改
    ↓
推送到 GitHub
    ↓
触发 GitHub Actions
    ↓
├─ 检出代码
├─ 配置环境 (Java, Flutter, Node.js)
├─ 读取版本号
├─ 构建 APK
├─ 上传到服务器
├─ 更新版本配置
├─ 重启服务
└─ 创建 Release
    ↓
部署完成
    ↓
客户端自动检测更新
```

## 🛠️ 常用命令

### 本地测试构建
```bash
flutter build apk --release
```

### 检查配置
```bash
# Windows
.\scripts\check-cicd-config.ps1

# Linux/Mac
./scripts/check-cicd-config.sh
```

### 查看服务器状态
```bash
# 检查 APK 文件
ssh root@your-server "ls -lh /root/potato_timer_server/updates/"

# 检查版本配置
ssh root@your-server "cat /root/potato_timer_server/version-config.json"

# 测试 API
curl http://your-domain.com/api/version/check
```

### 手动更新版本配置
```bash
ssh root@your-server
cd /root/potato_timer_server
node scripts/update-version.js 2 "下载URL" "更新日志"
```

## 🐛 常见问题

### Q: 构建失败？
- 检查 Flutter 版本配置
- 查看 Actions 日志
- 确认依赖安装成功

### Q: SSH 连接失败？
- 检查 Secrets 配置
- 确认 SSH 密钥正确
- 测试服务器连接

### Q: APK 下载失败？
- 检查 Nginx 配置
- 确认文件权限
- 验证下载 URL

### Q: 版本配置未更新？
- 检查 Node.js 安装
- 确认脚本存在
- 查看执行日志

## 📞 获取帮助

1. **查看文档**
   - 先查看相关文档
   - 按照故障排除步骤操作

2. **检查日志**
   - GitHub Actions 日志
   - 服务器日志
   - Nginx 日志

3. **运行检查脚本**
   - 自动检测配置问题
   - 提供修复建议

4. **提交 Issue**
   - 描述问题现象
   - 附上相关日志
   - 说明已尝试的解决方法

## 🔗 相关资源

### 内部文档
- [版本更新服务说明](../server/VERSION_UPDATE_GUIDE.md)
- [版本更新 API](../VERSION_UPDATE_API.md)
- [项目 README](../README.md)

### 外部资源
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Flutter CI/CD](https://docs.flutter.dev/deployment/cd)
- [Nginx 文档](https://nginx.org/en/docs/)

## 📝 更新日志

### 2026-01-27
- ✨ 初始版本
- ✅ 支持 Android APK 自动构建
- ✅ 支持自动部署到服务器
- ✅ 支持版本配置自动更新
- ✅ 支持 GitHub Release 创建

## 🎉 开始使用

准备好了吗？从 [快速开始指南](../CICD_QUICKSTART.md) 开始吧！

---

**祝你使用愉快！** 🚀

