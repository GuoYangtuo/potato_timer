# 版本更新服务使用指南

## 概述

服务端已集成版本更新API，支持应用的自动更新功能。

## 目录结构

```
server/
├── src/
│   └── routes/
│       └── version.ts          # 版本更新API路由
├── updates/                     # 存放更新包的目录
│   ├── .gitkeep
│   ├── potato_timer_v2.apk     # Android安装包
│   └── potato_timer_v3.apk
├── scripts/
│   └── update-version.js       # 版本配置更新工具
├── version-config.json         # 版本配置文件
└── VERSION_UPDATE_GUIDE.md     # 本文件
```

## API接口

### 1. 检查版本更新

**接口**: `GET /api/version/check`

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "version": 2,
    "downloadUrl": "http://localhost:3000/updates/potato_timer_v2.apk",
    "updateLog": "1. 新增激励内容分享功能\n2. 修复目标提醒bug\n3. 优化应用性能"
  }
}
```

### 2. 更新版本配置（管理员接口）

**接口**: `POST /api/version/update`

**请求体**:
```json
{
  "version": 2,
  "downloadUrl": "http://localhost:3000/updates/potato_timer_v2.apk",
  "updateLog": "1. 新增功能\n2. 修复bug"
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "版本配置更新成功",
  "data": {
    "version": 2,
    "downloadUrl": "http://localhost:3000/updates/potato_timer_v2.apk",
    "updateLog": "1. 新增功能\n2. 修复bug"
  }
}
```

### 3. 获取当前版本配置

**接口**: `GET /api/version/current`

**响应格式**: 与检查更新接口相同

## 发布新版本流程

### 方法一：使用命令行工具（推荐）

1. **准备更新包**
   ```bash
   # 将编译好的APK放入 updates 目录
   cp path/to/potato_timer_v2.apk server/updates/
   ```

2. **更新版本配置**
   ```bash
   cd server
   node scripts/update-version.js 2 "http://your-server.com/updates/potato_timer_v2.apk" "1. 新增功能A\n2. 修复bug B\n3. 优化性能"
   ```

3. **验证配置**
   ```bash
   # 查看配置文件
   cat version-config.json
   ```

4. **测试**
   ```bash
   # 测试API
   curl http://localhost:3000/api/version/check
   ```

### 方法二：使用API

1. **准备更新包**（同上）

2. **调用API更新配置**
   ```bash
   curl -X POST http://localhost:3000/api/version/update \
     -H "Content-Type: application/json" \
     -d '{
       "version": 2,
       "downloadUrl": "http://your-server.com/updates/potato_timer_v2.apk",
       "updateLog": "1. 新增功能\n2. 修复bug"
     }'
   ```

### 方法三：手动编辑配置文件

直接编辑 `server/version-config.json` 文件：

```json
{
  "version": 2,
  "downloadUrl": "http://your-server.com/updates/potato_timer_v2.apk",
  "updateLog": "1. 新增功能\n2. 修复bug"
}
```

## 客户端行为

1. **自动检查**: 应用启动时自动检查版本
2. **后台下载**: 检测到新版本后自动在后台下载
3. **强制更新**: 下载完成后显示不可关闭的更新弹窗
4. **自动安装**: 用户点击"立即更新"后触发系统安装

## 注意事项

### Android

1. **文件命名**: 建议使用 `potato_timer_vX.apk` 格式
2. **下载地址**: 确保URL可访问，建议使用服务器的公网地址
3. **文件大小**: APK不宜过大，建议 < 50MB
4. **签名一致**: 新版本APK必须与旧版本使用相同的签名

### iOS

1. iOS应用无法直接安装IPA文件
2. `downloadUrl` 应该设置为App Store链接
3. 应用会提示用户前往App Store更新

### 版本号规则

- 版本号为整数，从1开始
- 只要服务端版本号 > 客户端版本号，就会触发更新
- 建议按顺序递增：1, 2, 3, 4...

## 测试步骤

1. **确保服务器运行**
   ```bash
   cd server
   npm run dev
   ```

2. **配置测试版本**
   ```bash
   node scripts/update-version.js 2 "http://localhost:3000/updates/potato_timer_v2.apk" "测试更新"
   ```

3. **准备测试APK**
   - 编译一个新版本的APK
   - 放入 `server/updates/` 目录

4. **测试API**
   ```bash
   curl http://localhost:3000/api/version/check
   ```

5. **启动客户端**
   - 运行Flutter应用
   - 应该在1秒后弹出更新提示
   - 等待下载完成
   - 点击"立即更新"

6. **验证安装**
   - 检查是否触发系统安装
   - 安装完成后检查版本号

## 常见问题

### Q1: 下载失败怎么办？

**检查项**:
- 确认 `downloadUrl` 是否可访问
- 检查网络连接
- 查看服务器日志
- 确认 `updates` 目录下有对应的文件

### Q2: 安装失败怎么办？

**检查项**:
- Android: 检查"安装未知应用"权限
- 确认APK签名与旧版本一致
- 确认APK文件完整（未损坏）
- 查看客户端日志

### Q3: 如何回退版本？

直接修改 `version-config.json`，将版本号改回旧版本号即可。但不建议这样做，因为客户端已更新的用户无法自动回退。

### Q4: 如何取消更新？

将 `version-config.json` 中的版本号设置为1或与客户端相同的版本号。

## 生产环境部署

1. **使用HTTPS**
   - 更新包下载链接使用HTTPS
   - 保证传输安全

2. **CDN加速**
   - 将更新包上传到CDN
   - 提高下载速度

3. **权限控制**
   - 对 `POST /api/version/update` 接口添加鉴权
   - 只允许管理员更新版本配置

4. **监控日志**
   - 记录版本检查和下载情况
   - 及时发现问题

5. **灰度发布**（可选）
   - 可以添加用户ID白名单机制
   - 先让部分用户更新测试

## 示例：发布版本2

```bash
# 1. 编译新版本
cd potato_timer
flutter build apk --release

# 2. 复制APK到服务器
cp build/app/outputs/flutter-apk/app-release.apk server/updates/potato_timer_v2.apk

# 3. 更新版本配置
cd server
node scripts/update-version.js 2 "http://your-domain.com/updates/potato_timer_v2.apk" "1. 新增目标分享功能\n2. 优化启动速度\n3. 修复已知bug"

# 4. 重启服务器（如果需要）
npm run dev

# 5. 测试
curl http://localhost:3000/api/version/check
```

完成！客户端下次启动时会自动检测并更新。

