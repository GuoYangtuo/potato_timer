# 媒体缓存功能说明

## ⚠️ 重要架构说明

**URL vs LocalPath 分离设计：**
- `MediaItem.url`: 始终存储**原始网络URL**，用于同步到后端
- `MediaItem.localPath`: 存储**本地缓存路径**，仅用于离线显示
- `MediaItem.displayUrl`: 自动选择优先使用 localPath，否则使用 url
- 同步到后端时**只会使用原始URL**，不会同步设备特定的本地路径
- 这样保证了离线功能的同时，数据可以在不同设备间正确同步

## ✅ 已实现功能

### 核心功能
- ✅ 自动下载图片和视频到本地
- ✅ 离线时显示本地缓存的媒体
- ✅ 智能缓存管理（MD5文件名）
- ✅ 透明的降级策略（本地→网络）
- ✅ URL和本地路径分离，支持跨设备同步

## 📦 新增文件

### 1. 媒体缓存服务
**`lib/services/media_cache_service.dart`**
- 下载媒体文件到本地
- 管理缓存目录
- 获取本地路径
- 缓存大小管理

### 2. 缓存媒体组件
**`lib/widgets/cached_media_widget.dart`**
- `CachedMediaWidget` - 智能显示本地/网络媒体
- `CachedVideoThumbnail` - 视频缩略图显示
- 自动加载和缓存

### 3. 修改的文件
- ✅ `lib/main.dart` - 初始化媒体缓存服务
- ✅ `lib/services/local_storage_dao.dart` - 保存媒体时自动下载
- ✅ `lib/widgets/motivation_card.dart` - 使用缓存组件
- ✅ `pubspec.yaml` - 添加 crypto 依赖

## 🚀 工作原理

### 保存激励时自动缓存
```dart
// 保存激励时，自动下载媒体到本地
await dao.saveMotivation(motivation);
// 内部会自动：
// 1. 下载图片/视频到 Documents/media_cache/
// 2. 保存本地路径到数据库
// 3. 优先使用本地路径
```

### 显示媒体时自动使用缓存
```dart
// 使用缓存组件显示媒体
CachedMediaWidget(
  url: motivation.media.first.url,
  fit: BoxFit.cover,
)
// 自动逻辑：
// 1. 检查本地是否有缓存
// 2. 有缓存：直接显示本地文件
// 3. 无缓存：显示网络图片并下载到本地
// 4. 下载失败：显示网络图片
```

## 📂 缓存目录结构

```
应用文档目录/
└── media_cache/
    ├── a1b2c3d4e5f6... .jpg    (图片1)
    ├── f6e5d4c3b2a1... .jpg    (图片2)
    ├── 1234567890ab... .mp4    (视频1)
    └── ...
```

- 文件名：URL的MD5值 + 原始扩展名
- 自动创建目录
- 跨平台支持

## 💡 使用示例

### 1. 显示激励卡片中的图片
```dart
// 已自动集成，motivation_card.dart 会自动使用缓存
MotivationCard(motivation: motivation)

// 内部实现：使用 displayUrl 自动选择本地路径或网络URL
CachedMediaWidget(
  url: motivation.media.first.displayUrl,  // ✅ 优先使用本地路径
  fit: BoxFit.cover,
)
```

### 2. 手动使用缓存组件
```dart
// 显示图片（推荐方式）
CachedMediaWidget(
  url: mediaItem.displayUrl,  // ✅ 自动选择最优路径
  width: 300,
  height: 200,
  fit: BoxFit.cover,
)

// 或者直接传入URL，组件会自动处理缓存
CachedMediaWidget(
  url: imageUrl,  // 可以是网络URL或本地路径
  width: 300,
  height: 200,
  fit: BoxFit.cover,
)

// 显示视频缩略图
CachedVideoThumbnail(
  thumbnailUrl: videoThumbnailUrl,
  width: 300,
  height: 200,
)
```

### 3. MediaItem 的使用
```dart
// ✅ 正确：显示时使用 displayUrl
Widget buildImage(MediaItem media) {
  return CachedMediaWidget(url: media.displayUrl);
}

// ✅ 正确：同步到后端时使用原始 url
Map<String, dynamic> syncData(MediaItem media) {
  return {
    'type': media.type,
    'url': media.url,  // 始终是原始网络URL
    'thumbnailUrl': media.thumbnailUrl,
    // localPath 不会被序列化
  };
}

// ❌ 错误：不要在同步时使用 displayUrl
Map<String, dynamic> wrongSync(MediaItem media) {
  return {
    'url': media.displayUrl,  // ❌ 可能是本地路径，无法跨设备使用
  };
}
```

### 3. 手动管理缓存
```dart
final cache = MediaCacheService();

// 检查是否已缓存
bool isCached = await cache.isCached(url);

// 获取本地路径
String? localPath = await cache.getLocalPath(url);

// 手动下载
String? path = await cache.downloadMedia(url);

// 获取缓存大小
String size = await cache.getCacheSizeFormatted();
// 输出: "15.6 MB"

// 清空缓存
await cache.clearAllCache();
```

## 🔄 数据流程

### 保存激励流程
```
用户创建激励 + 上传图片
    ↓
保存到本地数据库
    ↓
自动下载图片到 media_cache/
    ↓
保存本地路径到数据库
```

### 显示媒体流程
```
加载激励数据
    ↓
读取媒体URL/本地路径
    ↓
优先使用本地路径
    ↓
本地文件存在？
    ├─ 是：显示本地文件 ✅
    └─ 否：显示网络图片 + 下载到本地
```

## 📊 数据库表结构

```sql
CREATE TABLE motivation_media (
  id INTEGER PRIMARY KEY,
  motivationId INTEGER NOT NULL,
  type TEXT NOT NULL,           -- 'image' or 'video'
  url TEXT NOT NULL,            -- 原始网络URL（用于同步到后端）⚠️ 始终保持网络URL
  thumbnailUrl TEXT,            -- 缩略图URL
  localPath TEXT,               -- 本地缓存路径（仅用于离线显示）⭐ 新增
  FOREIGN KEY (motivationId) REFERENCES motivations(id)
);
```

**重要说明：**
- `url` 字段：**始终存储原始网络URL**，不会被本地路径替换
- `localPath` 字段：存储本地缓存的文件路径，仅用于离线显示
- 同步到后端时，**只会同步 url 字段**，不会同步 localPath
- 这样保证了数据在不同设备间可以正确同步

## ⚡ 性能优化

### 1. 智能缓存
- 只下载一次，永久使用
- MD5文件名避免重复
- 自动清理过期缓存（可选）

### 2. 异步下载
- 不阻塞UI
- 先显示网络图片，后台下载
- 下次打开立即显示本地缓存

### 3. 降级策略
```
本地缓存 → 网络图片 → 占位符
  ↓           ↓          ↓
  最快       较慢      失败
```

## 🔧 配置选项

### 缓存目录
```dart
// 默认：应用文档目录/media_cache
// 可以修改 MediaCacheService.init() 中的路径
```

### 文件名策略
```dart
// 当前：MD5(url) + 原始扩展名
// 例如：a1b2c3d4e5f6789012345678901234.jpg
_getFileNameFromUrl(String url)
```

## 🧪 测试场景

### 场景1：首次加载（在线）
1. 打开应用，查看激励列表
2. **观察**：显示网络图片
3. 等待几秒
4. **观察**：图片自动缓存到本地
5. 下次打开：直接显示本地缓存 ⚡

### 场景2：离线查看
1. 联网时打开应用，查看几个激励
2. 关闭网络
3. 重启应用
4. **观察**：之前看过的图片正常显示 ✅
5. **效果**：离线也能看图片和视频

### 场景3：缓存管理
1. 打开设置页面
2. 查看缓存大小
3. 点击"清空缓存"
4. 确认缓存已清空

## 💾 缓存大小管理

### 查看缓存信息
```dart
final cache = MediaCacheService();

// 获取缓存大小
String size = await cache.getCacheSizeFormatted();
print('缓存大小: $size');  // "15.6 MB"

// 获取缓存文件数
int count = await cache.getCacheCount();
print('缓存文件数: $count');  // 42
```

### 清理缓存
```dart
// 清空所有缓存
await MediaCacheService().clearAllCache();

// 删除单个缓存
await MediaCacheService().deleteCache(url);
```

## ⚠️ 注意事项

### 1. 存储空间
- 缓存会占用设备存储空间
- 建议定期清理（如超过100MB）
- 可以添加自动清理策略

### 2. 首次下载
- 首次查看需要联网下载
- 下载失败会降级到网络图片
- 建议在WiFi环境下预缓存

### 3. 文件格式
- 支持所有图片格式（jpg, png, gif, webp）
- 支持视频（mp4, mov）
- 自动保留原始扩展名

## 🎯 优势

### vs 纯网络图片
- ✅ 离线可用
- ✅ 加载更快
- ✅ 节省流量
- ✅ 体验更好

### vs 手动保存
- ✅ 自动管理
- ✅ 透明缓存
- ✅ 智能降级
- ✅ 无需用户操作

## 📈 未来改进

### 可选功能
1. **自动清理**
   - 按时间清理（超过30天）
   - 按大小清理（超过500MB）
   - LRU 策略

2. **预缓存**
   - 后台预加载热门内容
   - WiFi下自动缓存
   - 智能预测用户需求

3. **压缩**
   - 图片压缩节省空间
   - 视频预览图生成
   - WebP格式转换

4. **进度显示**
   - 下载进度条
   - 缓存状态指示
   - 失败重试按钮

## 🎉 总结

### 核心改进
✅ **图片和视频支持离线显示**
✅ 自动下载和缓存
✅ 智能降级策略
✅ 透明的用户体验

### 用户体验
⚡ 离线也能看图片
📱 加载速度更快
💾 自动管理缓存
😊 无感知的优化

---

**现在图片和视频都会自动缓存到本地，离线也能正常显示！** 🎊

