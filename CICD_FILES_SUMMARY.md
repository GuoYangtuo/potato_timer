# CI/CD 文件清单

本文档列出了为 Potato Timer 项目创建的所有 CI/CD 相关文件。

## 📁 文件结构

```
potato_timer/
├── .github/
│   ├── workflows/
│   │   ├── android-release.yaml        # 主工作流：构建、部署、更新
│   │   ├── android-build-only.yaml     # 测试工作流：仅构建
│   │   ├── README.md                   # 工作流详细说明
│   │   └── setup-guide.md              # 完整配置指南
│   ├── RELEASE_CHECKLIST.md            # 发布检查清单
│   └── README.md                       # GitHub Actions 文档导航
├── scripts/
│   ├── check-cicd-config.sh            # Linux/Mac 配置检查脚本
│   └── check-cicd-config.ps1           # Windows 配置检查脚本
├── CICD_README.md                      # CI/CD 总览文档
├── CICD_QUICKSTART.md                  # 5分钟快速开始指南
├── CICD_FILES_SUMMARY.md               # 本文件
└── .gitignore                          # 已更新（添加 CI/CD 相关规则）
```

## 📄 文件说明

### 核心工作流文件

#### 1. `.github/workflows/android-release.yaml`
**用途**: 主要的自动化部署工作流

**功能**:
- ✅ 自动构建 Android APK
- ✅ 上传 APK 到服务器
- ✅ 更新版本配置
- ✅ 重启服务器服务
- ✅ 创建 GitHub Release

**触发条件**:
- 推送到 main 分支（修改 lib/、android/、pubspec.yaml）
- 手动触发

**关键配置**（需要修改）:
- 第 29 行: Flutter 版本
- 第 81 行: APK 上传路径
- 第 115 行: 下载 URL
- 第 127 行: 服务重启命令

#### 2. `.github/workflows/android-build-only.yaml`
**用途**: 仅构建 APK，不部署（用于测试）

**功能**:
- ✅ 构建 APK
- ✅ 运行测试
- ✅ 代码分析
- ✅ 上传为 Artifact

**触发条件**:
- Pull Request 到 main 分支
- 手动触发

### 文档文件

#### 3. `CICD_QUICKSTART.md` ⭐ 推荐首次阅读
**用途**: 5 分钟快速开始指南

**内容**:
- 3 步配置流程
- 快速测试部署
- 常见问题解答

**适合人群**: 首次使用者

#### 4. `CICD_README.md`
**用途**: CI/CD 完整说明文档

**内容**:
- 文件结构说明
- 工作流详细说明
- 版本号管理
- 服务器配置
- 监控和验证
- 故障排除
- 最佳实践

**适合人群**: 需要深入了解的用户

#### 5. `.github/workflows/README.md`
**用途**: 工作流使用说明

**内容**:
- 触发方式详解
- GitHub Secrets 配置
- 服务器配置要求
- 发布流程
- 测试步骤
- 常见问题

#### 6. `.github/workflows/setup-guide.md`
**用途**: 完整的配置指南

**内容**:
- 配置清单
- SSH 密钥生成
- 服务器配置步骤
- Nginx 配置示例
- Node.js 安装
- 服务管理配置
- Android 签名配置

**适合人群**: 首次配置或需要详细步骤的用户

#### 7. `.github/RELEASE_CHECKLIST.md`
**用途**: 版本发布检查清单

**内容**:
- 发布前检查项
- 构建前准备
- 发布流程
- 发布后验证
- 回滚计划
- 发布记录模板

**适合人群**: 发布新版本时使用

#### 8. `.github/README.md`
**用途**: GitHub Actions 文档导航

**内容**:
- 文档索引
- 使用场景
- 关键概念
- 工作流程图
- 常用命令

### 工具脚本

#### 9. `scripts/check-cicd-config.sh`
**用途**: Linux/Mac 配置检查脚本

**功能**:
- 检查本地文件
- 检查 Flutter 环境
- 检查服务器配置文件
- 检查工作流配置
- 提供配置建议

**使用方法**:
```bash
chmod +x scripts/check-cicd-config.sh
./scripts/check-cicd-config.sh
```

#### 10. `scripts/check-cicd-config.ps1`
**用途**: Windows PowerShell 配置检查脚本

**功能**: 与 .sh 版本相同

**使用方法**:
```powershell
.\scripts\check-cicd-config.ps1
```

### 其他文件

#### 11. `.gitignore` (已更新)
**更新内容**:
- 添加 CI/CD 相关忽略规则
- 忽略签名文件（.keystore, .jks）
- 忽略 APK/AAB 文件
- 忽略 SSH 密钥文件

## 🎯 使用流程

### 首次配置
1. 阅读 `CICD_QUICKSTART.md`
2. 运行 `scripts/check-cicd-config.ps1` 或 `.sh`
3. 按照 `.github/workflows/setup-guide.md` 配置
4. 修改 `.github/workflows/android-release.yaml` 中的配置
5. 测试部署

### 日常使用
1. 修改代码
2. 更新 `pubspec.yaml` 版本号
3. 推送到 main 分支
4. 自动构建和部署

### 发布新版本
1. 查看 `.github/RELEASE_CHECKLIST.md`
2. 完成所有检查项
3. 触发部署
4. 验证结果

## 📊 文件依赖关系

```
CICD_QUICKSTART.md (入口)
    ↓
scripts/check-cicd-config.* (检查配置)
    ↓
.github/workflows/setup-guide.md (详细配置)
    ↓
.github/workflows/android-release.yaml (执行部署)
    ↓
.github/RELEASE_CHECKLIST.md (发布验证)
```

## 🔧 需要修改的配置

### GitHub Secrets (必需)
在 GitHub 仓库中配置：
- `SERVER_IP`
- `SERVER_SSH_USER`
- `SERVER_SSH_KEY`

### 工作流文件 (必需)
在 `.github/workflows/android-release.yaml` 中修改：
- 第 29 行: Flutter 版本
- 第 115 行: 下载 URL（域名）
- 第 127 行: 服务重启命令

### 服务器配置 (必需)
- 创建目录: `/root/potato_timer_server/`
- 安装 Node.js
- 配置 Nginx
- 配置服务管理

## 📚 阅读顺序建议

### 新手用户
1. `CICD_QUICKSTART.md` - 快速了解
2. `scripts/check-cicd-config.*` - 检查配置
3. `.github/workflows/setup-guide.md` - 完整配置
4. `.github/RELEASE_CHECKLIST.md` - 发布流程

### 有经验用户
1. `CICD_README.md` - 总览
2. `.github/workflows/README.md` - 工作流说明
3. `.github/workflows/android-release.yaml` - 直接修改配置

### 故障排除
1. `scripts/check-cicd-config.*` - 自动检查
2. `.github/workflows/setup-guide.md` - 故障排除章节
3. `CICD_README.md` - 常见问题

## ✅ 配置完成标志

当你完成配置后，应该能够：

- [x] 运行配置检查脚本无错误
- [x] GitHub Secrets 已配置
- [x] 服务器环境已准备好
- [x] 工作流配置已修改
- [x] 测试部署成功
- [x] API 可以正常访问
- [x] 客户端可以检测更新

## 🎉 开始使用

所有文件已准备就绪！从 `CICD_QUICKSTART.md` 开始你的 CI/CD 之旅吧！

## 📝 维护说明

### 更新工作流
- 修改 `.github/workflows/android-release.yaml`
- 测试后提交

### 更新文档
- 保持文档与实际配置同步
- 更新版本号和日期

### 添加新功能
- 更新相关文档
- 更新检查脚本
- 更新 CHECKLIST

---

**所有文件都已创建完成！** 🎊

