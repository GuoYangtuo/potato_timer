# 离线功能快速开始指南

## 🎉 新功能概述

应用现在支持完整的离线功能！您可以：

- ✅ 离线创建、编辑、删除激励和目标
- ✅ 所有数据自动保存到本地数据库
- ✅ 联网时自动同步到服务器
- ✅ 更快的响应速度（本地优先）

## 📱 立即体验

### 1. 安装依赖（已完成）

```bash
flutter pub get
```

### 2. 运行应用

```bash
flutter run
```

### 3. 测试离线功能

#### 场景1：离线创建激励

1. 断开网络连接
2. 在应用中创建新的激励内容
3. 激励会立即保存到本地
4. 恢复网络连接
5. 数据会自动同步到服务器

#### 场景2：离线创建目标

1. 断开网络
2. 创建新目标（微习惯或主线任务）
3. 目标保存在本地
4. 联网后自动同步

#### 场景3：查看离线数据

1. 创建一些激励和目标
2. 完全关闭应用
3. 断开网络
4. 重新打开应用
5. 所有数据仍然可用

## 🔧 开发者指南

### 在现有代码中使用

只需将 `ApiService()` 替换为 `OfflineFirstService()`：

```dart
// 旧代码
final motivations = await ApiService().getMyMotivations();

// 新代码（支持离线）
final motivations = await OfflineFirstService().getMyMotivations();
```

### 完整示例

参考 `lib/examples/offline_usage_example.dart` 文件，包含：

- 完整的离线功能演示页面
- 同步状态监听
- 错误处理
- 实际集成示例

### 运行示例页面

在应用中添加导航到示例页面：

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => OfflineUsageExamplePage(),
  ),
);
```

## 🧪 运行测试

```bash
# 运行离线功能测试
flutter test test/offline_test.dart

# 运行所有测试
flutter test
```

## 📚 详细文档

- **迁移指南**: `OFFLINE_MIGRATION_GUIDE.md` - 详细的API和使用说明
- **功能总结**: `OFFLINE_README.md` - 完整的功能清单
- **代码示例**: `lib/examples/offline_usage_example.dart` - 实际代码示例

## 🎯 核心 API

### 获取数据（离线优先）

```dart
final service = OfflineFirstService();

// 获取我的激励（立即返回本地数据）
final motivations = await service.getMyMotivations();

// 获取我的目标
final goals = await service.getMyGoals();

// 获取收藏
final favorites = await service.getFavorites();
```

### 创建数据（离线支持）

```dart
// 创建激励（即使离线也能创建）
final id = await service.createMotivation(
  title: '我的激励',
  content: '内容',
  type: 'positive',
);

// 创建目标
final goalId = await service.createGoal(
  title: '每天锻炼',
  type: 'habit',
  enableTimer: true,
  durationMinutes: 10,
);
```

### 更新和删除

```dart
// 更新
await service.updateMotivation(id, {'title': '新标题'});

// 删除
await service.deleteMotivation(id);
```

### 监听同步状态

```dart
service.syncStatusStream.listen((status) {
  switch (status) {
    case SyncStatus.syncing:
      // 正在同步
      break;
    case SyncStatus.completed:
      // 同步完成
      break;
    case SyncStatus.failed:
      // 同步失败
      break;
  }
});
```

### 手动触发同步

```dart
final result = await service.manualSync();
if (result.success) {
  print('同步成功');
} else {
  print('同步失败: ${result.message}');
}
```

## 💡 最佳实践

### 1. 优先使用离线服务

对于用户自己的数据，始终使用 `OfflineFirstService`：

```dart
✅ await OfflineFirstService().getMyMotivations();
❌ await ApiService().getMyMotivations();
```

### 2. 处理同步状态

在UI中显示同步状态，让用户知道数据是否已同步：

```dart
StreamBuilder<SyncStatus>(
  stream: OfflineFirstService().syncStatusStream,
  builder: (context, snapshot) {
    if (snapshot.data == SyncStatus.syncing) {
      return CircularProgressIndicator();
    }
    return Icon(Icons.cloud_done);
  },
)
```

### 3. 无需错误处理

离线服务总是能返回数据（本地缓存），所以大多数情况不需要 try-catch：

```dart
// 简洁的代码
final motivations = await OfflineFirstService().getMyMotivations();
setState(() => _motivations = motivations);
```

### 4. 用户操作立即生效

所有写入操作立即保存到本地，用户体验更流畅：

```dart
await OfflineFirstService().createMotivation(...);
// 立即更新UI，无需等待网络
await _refreshList();
```

## 🔍 调试技巧

### 查看本地数据库

数据库文件位置（Android）：
```
/data/data/com.example.potato_timer/databases/potato_timer.db
```

### 查看同步日志

应用会在控制台打印同步日志：

```
flutter run
# 查看同步相关日志
```

### 强制同步

在应用中添加同步按钮：

```dart
ElevatedButton(
  onPressed: () async {
    final result = await OfflineFirstService().manualSync();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  },
  child: Text('立即同步'),
)
```

## 🐛 常见问题

### Q: 离线创建的数据会丢失吗？

A: 不会！所有数据都保存在本地数据库中，即使重启应用也不会丢失。联网后会自动同步到服务器。

### Q: 多设备之间如何同步？

A: 每个设备都会将数据同步到服务器。当你在另一台设备上打开应用时，会自动从服务器拉取最新数据。

### Q: 如果同时在两个设备上修改怎么办？

A: 目前使用"最后写入优先"策略，最后同步到服务器的修改会覆盖之前的修改。

### Q: 如何清理本地数据？

A: 可以调用：
```dart
await DatabaseService().clearAll();
```

### Q: 同步失败怎么办？

A: 同步失败的数据会保留在本地，应用会在5分钟后自动重试。你也可以手动触发同步。

## 📞 需要帮助？

- 查看 `OFFLINE_MIGRATION_GUIDE.md` 了解更多细节
- 参考 `lib/examples/offline_usage_example.dart` 查看示例代码
- 查看各服务类的注释文档

## 🚀 下一步

1. ✅ 阅读本指南
2. ✅ 运行应用测试离线功能
3. ✅ 查看示例代码
4. ✅ 在项目中替换 ApiService 为 OfflineFirstService
5. ✅ 添加同步状态UI（可选）

祝开发愉快！🎉

