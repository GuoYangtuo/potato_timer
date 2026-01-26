# 版本更新API文档

## 概述

本文档描述了应用版本更新功能所需的服务端API接口。

## API接口

### 1. 检查版本更新

**接口地址**: `GET /api/version/check`

**请求方式**: GET

**请求头**:
```
Content-Type: application/json
Authorization: Bearer {token} (可选)
```

**响应格式**:

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "version": 2,
    "downloadUrl": "https://your-server.com/updates/potato_timer_v2.apk",
    "updateLog": "1. 新增功能A\n2. 修复bug B\n3. 优化性能"
  }
}
```

**字段说明**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| version | int | 是 | 版本号（整数），客户端会比较此值与本地版本号 |
| downloadUrl | string | 是 | 更新包下载地址（Android为APK，iOS为App Store链接） |
| updateLog | string | 否 | 更新日志，显示给用户 |

**版本号说明**:
- 版本号为单个整数
- 只要服务端返回的版本号大于客户端当前版本号，就会触发更新
- 客户端初始版本号为1

**示例代码 (Node.js/Express)**:

```javascript
// GET /api/version/check
router.get('/version/check', (req, res) => {
  res.json({
    code: 200,
    message: 'success',
    data: {
      version: 2,
      downloadUrl: 'https://your-server.com/updates/potato_timer_v2.apk',
      updateLog: '1. 新增激励内容分享功能\n2. 修复目标提醒bug\n3. 优化应用性能'
    }
  });
});
```

## 更新包部署

### Android (APK)

1. 将编译好的APK文件放在服务器的静态文件目录
2. 确保APK文件可以通过HTTP/HTTPS访问
3. 推荐使用HTTPS以保证安全性

**示例目录结构**:
```
server/
├── public/
│   └── updates/
│       ├── potato_timer_v2.apk
│       ├── potato_timer_v3.apk
│       └── ...
└── ...
```

### iOS (IPA)

iOS应用的更新需要通过App Store或TestFlight进行：

1. 将更新包提交到App Store Connect
2. downloadUrl字段返回App Store链接
3. 应用会提示用户前往App Store更新

**示例**:
```json
{
  "version": 2,
  "downloadUrl": "https://apps.apple.com/app/id你的应用ID",
  "updateLog": "请前往App Store更新"
}
```

## 客户端行为

1. **检查时机**: 应用启动时自动检查
2. **下载方式**: 后台自动下载（不影响用户使用）
3. **安装提示**: 下载完成后弹出更新弹窗
4. **强制更新**: 弹窗不可关闭，用户必须点击更新按钮

## 注意事项

1. **版本号管理**: 服务端需要维护当前最新版本号
2. **下载链接**: 确保下载链接长期有效
3. **文件大小**: 建议APK大小不超过100MB
4. **网络考虑**: 大文件下载可能需要较长时间
5. **错误处理**: 如果版本检查失败，不影响应用正常使用

## 测试步骤

1. 确保客户端当前版本为1
2. 服务端返回版本2的更新信息
3. 启动应用，应该自动弹出更新弹窗
4. 等待下载完成
5. 点击"立即更新"按钮
6. 验证APK是否正确安装

## 安全建议

1. 使用HTTPS传输
2. 对APK进行签名验证
3. 考虑添加APK文件的MD5/SHA256校验
4. 限制下载频率，防止恶意攻击

