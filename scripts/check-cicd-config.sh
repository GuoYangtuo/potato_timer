#!/bin/bash

# CI/CD 配置检查脚本
# 用于验证 GitHub Actions 部署所需的配置是否完整

echo "🔍 检查 CI/CD 配置..."
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查计数
PASS=0
FAIL=0
WARN=0

# 检查函数
check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASS++))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAIL++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARN++))
}

echo "=== 1. 检查本地文件 ==="
echo ""

# 检查工作流文件
if [ -f ".github/workflows/android-release.yaml" ]; then
    check_pass "工作流文件存在: android-release.yaml"
else
    check_fail "工作流文件不存在: android-release.yaml"
fi

if [ -f ".github/workflows/android-build-only.yaml" ]; then
    check_pass "测试工作流文件存在: android-build-only.yaml"
else
    check_warn "测试工作流文件不存在: android-build-only.yaml (可选)"
fi

# 检查 pubspec.yaml
if [ -f "pubspec.yaml" ]; then
    check_pass "pubspec.yaml 存在"
    
    # 读取版本号
    VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //')
    if [ -n "$VERSION" ]; then
        check_pass "版本号: $VERSION"
    else
        check_fail "无法读取版本号"
    fi
else
    check_fail "pubspec.yaml 不存在"
fi

# 检查 Flutter
echo ""
echo "=== 2. 检查 Flutter 环境 ==="
echo ""

if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    check_pass "Flutter 已安装: $FLUTTER_VERSION"
else
    check_fail "Flutter 未安装"
fi

# 检查 Android SDK
if [ -d "$ANDROID_HOME" ] || [ -d "$ANDROID_SDK_ROOT" ]; then
    check_pass "Android SDK 已配置"
else
    check_warn "Android SDK 路径未设置 (本地开发需要)"
fi

echo ""
echo "=== 3. 检查服务器配置文件 ==="
echo ""

if [ -f "server/version-config.json" ]; then
    check_pass "版本配置文件存在: server/version-config.json"
else
    check_fail "版本配置文件不存在: server/version-config.json"
fi

if [ -f "server/scripts/update-version.js" ]; then
    check_pass "版本更新脚本存在: server/scripts/update-version.js"
else
    check_fail "版本更新脚本不存在: server/scripts/update-version.js"
fi

if [ -d "server/updates" ]; then
    check_pass "更新包目录存在: server/updates"
else
    check_warn "更新包目录不存在: server/updates (将在服务器上创建)"
fi

echo ""
echo "=== 4. 检查工作流配置 ==="
echo ""

if [ -f ".github/workflows/android-release.yaml" ]; then
    # 检查是否修改了默认配置
    if grep -q "your-domain.com" .github/workflows/android-release.yaml; then
        check_fail "下载 URL 未修改 (仍为 your-domain.com)"
    else
        check_pass "下载 URL 已配置"
    fi
    
    if grep -q "flutter-version: '3.24.0'" .github/workflows/android-release.yaml; then
        check_warn "Flutter 版本为默认值 3.24.0，请确认是否正确"
    else
        check_pass "Flutter 版本已自定义"
    fi
fi

echo ""
echo "=== 5. GitHub Secrets 检查提示 ==="
echo ""

echo "请在 GitHub 仓库中配置以下 Secrets:"
echo ""
echo "  1. SERVER_IP          - 服务器 IP 地址"
echo "  2. SERVER_SSH_USER    - SSH 用户名"
echo "  3. SERVER_SSH_KEY     - SSH 私钥完整内容"
echo ""
echo "配置路径: Settings → Secrets and variables → Actions"
echo ""

# 检查是否有 SSH 密钥
if [ -f "$HOME/.ssh/id_rsa" ]; then
    check_pass "本地存在 SSH 密钥: ~/.ssh/id_rsa"
    echo "  提示: 可以使用此密钥或生成新的部署专用密钥"
else
    check_warn "本地未找到默认 SSH 密钥"
    echo "  提示: 运行 'ssh-keygen -t rsa -b 4096' 生成新密钥"
fi

echo ""
echo "=== 6. 服务器要求检查提示 ==="
echo ""

echo "请确保服务器满足以下要求:"
echo ""
echo "  ✓ Node.js 已安装 (建议 v20+)"
echo "  ✓ 目录已创建: /root/potato_timer_server/"
echo "  ✓ 目录已创建: /root/potato_timer_server/updates/"
echo "  ✓ Nginx 已配置 /updates 路径"
echo "  ✓ 服务管理已配置 (systemd 或 PM2)"
echo "  ✓ SSH 公钥已添加到服务器"
echo ""

echo "=== 检查摘要 ==="
echo ""
echo -e "${GREEN}通过: $PASS${NC}"
echo -e "${YELLOW}警告: $WARN${NC}"
echo -e "${RED}失败: $FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ 本地配置检查通过！${NC}"
    echo ""
    echo "下一步:"
    echo "  1. 配置 GitHub Secrets"
    echo "  2. 配置服务器环境"
    echo "  3. 修改工作流中的域名和 Flutter 版本"
    echo "  4. 推送代码测试部署"
    echo ""
    echo "详细配置指南: .github/workflows/setup-guide.md"
    exit 0
else
    echo -e "${RED}✗ 发现 $FAIL 个问题，请修复后重试${NC}"
    exit 1
fi

