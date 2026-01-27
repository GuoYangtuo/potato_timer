# 版本发布检查清单

在发布新版本前，请确保完成以下所有检查项。

## 📋 发布前检查

### 代码质量
- [ ] 所有功能已完成开发
- [ ] 代码已通过测试
- [ ] 没有已知的严重 Bug
- [ ] 代码已经过 Code Review
- [ ] 运行 `flutter analyze` 无错误
- [ ] 运行 `flutter test` 测试通过

### 版本信息
- [ ] 已更新 `pubspec.yaml` 中的版本号
  - 当前版本: `version: x.x.x+BUILD_NUMBER`
  - 新版本: `version: x.x.x+NEW_BUILD_NUMBER`
- [ ] 准备好更新日志内容
  - 新增功能
  - Bug 修复
  - 性能优化
  - 其他改进

### 资源文件
- [ ] 所有图片资源已优化
- [ ] 所有必需的 assets 已添加到 `pubspec.yaml`
- [ ] 检查 APK 大小是否合理（建议 < 50MB）

### 配置检查
- [ ] API 地址配置正确
- [ ] 生产环境配置正确
- [ ] 第三方服务密钥已配置

## 🔧 构建前准备

### 本地构建测试
- [ ] 本地构建 Release APK 成功
  ```bash
  flutter build apk --release
  ```
- [ ] 在真机上安装测试
- [ ] 测试主要功能正常
- [ ] 测试更新流程正常

### 签名配置（如已配置）
- [ ] Keystore 文件存在
- [ ] 签名密码正确
- [ ] Key alias 正确

## 🚀 发布流程

### 自动发布（推荐）

#### 1. 更新版本号
```bash
# 编辑 pubspec.yaml
# 将 version: 1.0.0+1 改为 version: 1.0.0+2
```

#### 2. 提交代码
```bash
git add pubspec.yaml
git commit -m "chore: bump version to 1.0.0+2"
git push origin main
```

#### 3. 等待构建完成
- [ ] 访问 GitHub Actions 查看构建状态
- [ ] 确保所有步骤都成功（绿色 ✓）
- [ ] 查看构建日志，确认无警告

### 手动发布

#### 1. 访问 GitHub Actions
- [ ] 进入仓库的 Actions 标签
- [ ] 选择 "Android Release & Deploy"
- [ ] 点击 "Run workflow"

#### 2. 填写发布信息
- [ ] 版本号: `2`（或其他版本号）
- [ ] 更新日志:
  ```
  1. 新增功能A\n2. 修复bug B\n3. 优化性能
  ```

#### 3. 开始构建
- [ ] 点击 "Run workflow" 开始
- [ ] 等待构建完成

## ✅ 发布后验证

### 服务器验证
- [ ] SSH 登录服务器检查文件
  ```bash
  ssh root@your-server-ip
  ls -lh /root/potato_timer_server/updates/
  cat /root/potato_timer_server/version-config.json
  ```
- [ ] 确认 APK 文件已上传
- [ ] 确认版本配置已更新

### API 验证
- [ ] 测试版本检查 API
  ```bash
  curl http://your-domain.com/api/version/check
  ```
- [ ] 确认返回正确的版本号
- [ ] 确认下载 URL 可访问
- [ ] 测试 APK 下载
  ```bash
  curl -I http://your-domain.com/updates/potato_timer_vX.apk
  ```

### 客户端验证
- [ ] 启动旧版本应用
- [ ] 确认弹出更新提示
- [ ] 确认显示正确的更新日志
- [ ] 测试下载功能
- [ ] 测试安装功能
- [ ] 安装后验证新版本功能

### GitHub Release
- [ ] 确认 GitHub Release 已创建
- [ ] 确认 APK 文件已附加
- [ ] 确认 Release 说明正确

## 📝 发布后任务

### 文档更新
- [ ] 更新 CHANGELOG.md（如有）
- [ ] 更新用户文档（如有变更）
- [ ] 更新 API 文档（如有变更）

### 监控
- [ ] 监控服务器日志
  ```bash
  journalctl -u potato_timer_backend -f
  # 或
  pm2 logs potato_timer
  ```
- [ ] 监控下载量
- [ ] 收集用户反馈

### 通知
- [ ] 通知团队成员
- [ ] 通知测试人员
- [ ] 发布公告（如需要）

## 🐛 回滚计划

如果发现严重问题需要回滚：

### 1. 回滚版本配置
```bash
ssh root@your-server-ip
cd /root/potato_timer_server
node scripts/update-version.js 1 "旧版本URL" "紧急回滚"
```

### 2. 修复问题
- [ ] 定位问题原因
- [ ] 修复代码
- [ ] 本地测试

### 3. 重新发布
- [ ] 更新版本号
- [ ] 重新构建和部署

## 📊 发布记录

### 版本 X 发布记录

**发布日期**: YYYY-MM-DD  
**发布人**: 姓名  
**版本号**: X  
**构建号**: X  

**更新内容**:
- 新增功能 A
- 修复 Bug B
- 优化性能 C

**验证结果**:
- [x] 构建成功
- [x] 部署成功
- [x] API 正常
- [x] 客户端更新正常

**问题记录**:
- 无

**备注**:
- 无

---

## 📌 注意事项

1. **版本号规则**
   - 构建号必须递增
   - 不要跳号
   - 记录每个版本号的用途

2. **更新日志**
   - 清晰描述变更内容
   - 突出重要功能
   - 使用用户友好的语言

3. **测试充分**
   - 在真机上测试
   - 测试主要功能
   - 测试边界情况

4. **备份重要文件**
   - 备份 Keystore
   - 备份配置文件
   - 备份旧版本 APK

5. **监控和反馈**
   - 发布后持续监控
   - 及时响应用户反馈
   - 准备好回滚方案

## 🔗 相关文档

- [CI/CD 快速开始](../CICD_QUICKSTART.md)
- [CI/CD 总览](../CICD_README.md)
- [工作流配置指南](workflows/setup-guide.md)
- [版本更新服务说明](../server/VERSION_UPDATE_GUIDE.md)

---

**记住：质量比速度更重要！** ✨

