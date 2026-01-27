# CI/CD 配置检查脚本 (PowerShell)
# 用于验证 GitHub Actions 部署所需的配置是否完整

Write-Host "🔍 检查 CI/CD 配置..." -ForegroundColor Cyan
Write-Host ""

# 检查计数
$script:PASS = 0
$script:FAIL = 0
$script:WARN = 0

# 检查函数
function Check-Pass {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
    $script:PASS++
}

function Check-Fail {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
    $script:FAIL++
}

function Check-Warn {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
    $script:WARN++
}

Write-Host "=== 1. 检查本地文件 ===" -ForegroundColor Cyan
Write-Host ""

# 检查工作流文件
if (Test-Path ".github\workflows\android-release.yaml") {
    Check-Pass "工作流文件存在: android-release.yaml"
} else {
    Check-Fail "工作流文件不存在: android-release.yaml"
}

if (Test-Path ".github\workflows\android-build-only.yaml") {
    Check-Pass "测试工作流文件存在: android-build-only.yaml"
} else {
    Check-Warn "测试工作流文件不存在: android-build-only.yaml (可选)"
}

# 检查 pubspec.yaml
if (Test-Path "pubspec.yaml") {
    Check-Pass "pubspec.yaml 存在"
    
    # 读取版本号
    $content = Get-Content "pubspec.yaml" -Raw
    if ($content -match 'version:\s*(.+)') {
        $version = $matches[1]
        Check-Pass "版本号: $version"
    } else {
        Check-Fail "无法读取版本号"
    }
} else {
    Check-Fail "pubspec.yaml 不存在"
}

Write-Host ""
Write-Host "=== 2. 检查 Flutter 环境 ===" -ForegroundColor Cyan
Write-Host ""

# 检查 Flutter
$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if ($flutterCmd) {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    Check-Pass "Flutter 已安装: $flutterVersion"
} else {
    Check-Fail "Flutter 未安装"
}

# 检查 Android SDK
if ($env:ANDROID_HOME -or $env:ANDROID_SDK_ROOT) {
    Check-Pass "Android SDK 已配置"
} else {
    Check-Warn "Android SDK 路径未设置 (本地开发需要)"
}

Write-Host ""
Write-Host "=== 3. 检查服务器配置文件 ===" -ForegroundColor Cyan
Write-Host ""

if (Test-Path "server\version-config.json") {
    Check-Pass "版本配置文件存在: server\version-config.json"
} else {
    Check-Fail "版本配置文件不存在: server\version-config.json"
}

if (Test-Path "server\scripts\update-version.js") {
    Check-Pass "版本更新脚本存在: server\scripts\update-version.js"
} else {
    Check-Fail "版本更新脚本不存在: server\scripts\update-version.js"
}

if (Test-Path "server\updates" -PathType Container) {
    Check-Pass "更新包目录存在: server\updates"
} else {
    Check-Warn "更新包目录不存在: server\updates (将在服务器上创建)"
}

Write-Host ""
Write-Host "=== 4. 检查工作流配置 ===" -ForegroundColor Cyan
Write-Host ""

if (Test-Path ".github\workflows\android-release.yaml") {
    $workflowContent = Get-Content ".github\workflows\android-release.yaml" -Raw
    
    # 检查是否修改了默认配置
    if ($workflowContent -match "your-domain.com") {
        Check-Fail "下载 URL 未修改 (仍为 your-domain.com)"
    } else {
        Check-Pass "下载 URL 已配置"
    }
    
    if ($workflowContent -match "flutter-version: '3.24.0'") {
        Check-Warn "Flutter 版本为默认值 3.24.0，请确认是否正确"
    } else {
        Check-Pass "Flutter 版本已自定义"
    }
}

Write-Host ""
Write-Host "=== 5. GitHub Secrets 检查提示 ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "请在 GitHub 仓库中配置以下 Secrets:"
Write-Host ""
Write-Host "  1. SERVER_IP          - 服务器 IP 地址"
Write-Host "  2. SERVER_SSH_USER    - SSH 用户名"
Write-Host "  3. SERVER_SSH_KEY     - SSH 私钥完整内容"
Write-Host ""
Write-Host "配置路径: Settings → Secrets and variables → Actions"
Write-Host ""

# 检查是否有 SSH 密钥
$sshKeyPath = "$env:USERPROFILE\.ssh\id_rsa"
if (Test-Path $sshKeyPath) {
    Check-Pass "本地存在 SSH 密钥: $sshKeyPath"
    Write-Host "  提示: 可以使用此密钥或生成新的部署专用密钥"
} else {
    Check-Warn "本地未找到默认 SSH 密钥"
    Write-Host "  提示: 运行 'ssh-keygen -t rsa -b 4096' 生成新密钥"
}

Write-Host ""
Write-Host "=== 6. 服务器要求检查提示 ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "请确保服务器满足以下要求:"
Write-Host ""
Write-Host "  ✓ Node.js 已安装 (建议 v20+)"
Write-Host "  ✓ 目录已创建: /root/potato_timer_server/"
Write-Host "  ✓ 目录已创建: /root/potato_timer_server/updates/"
Write-Host "  ✓ Nginx 已配置 /updates 路径"
Write-Host "  ✓ 服务管理已配置 (systemd 或 PM2)"
Write-Host "  ✓ SSH 公钥已添加到服务器"
Write-Host ""

Write-Host "=== 检查摘要 ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "通过: $script:PASS" -ForegroundColor Green
Write-Host "警告: $script:WARN" -ForegroundColor Yellow
Write-Host "失败: $script:FAIL" -ForegroundColor Red
Write-Host ""

if ($script:FAIL -eq 0) {
    Write-Host "✓ 本地配置检查通过！" -ForegroundColor Green
    Write-Host ""
    Write-Host "下一步:"
    Write-Host "  1. 配置 GitHub Secrets"
    Write-Host "  2. 配置服务器环境"
    Write-Host "  3. 修改工作流中的域名和 Flutter 版本"
    Write-Host "  4. 推送代码测试部署"
    Write-Host ""
    Write-Host "详细配置指南: .github\workflows\setup-guide.md"
    exit 0
} else {
    Write-Host "✗ 发现 $script:FAIL 个问题，请修复后重试" -ForegroundColor Red
    exit 1
}

