# 离线优先功能迁移指南

## 概述

应用已升级为离线优先架构，所有用户数据（目标、激励）现在都会存储在本地数据库中。应用可以在离线状态下完全正常使用，在联网时会自动同步数据。

## 架构变更

### 新增组件

1. **DatabaseService** (`lib/services/database_service.dart`)
   - 管理本地 SQLite 数据库
   - 定义表结构（motivations, goals, media, tags 等）

2. **LocalStorageDao** (`lib/services/local_storage_dao.dart`)
   - 本地数据访问对象
   - 提供所有数据库 CRUD 操作
   - 管理同步状态

3. **SyncService** (`lib/services/sync_service.dart`)
   - 处理本地与服务器之间的数据同步
   - 自动每5分钟同步一次
   - 支持手动触发同步

4. **OfflineFirstService** (`lib/services/offline_first_service.dart`)
   - 离线优先的统一接口
   - 整合 ApiService 和 LocalStorageDao
   - 优先使用本地数据，后台自动同步

## 使用方法

### 初始化（已在 main.dart 中完成）

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await ApiService().init();
  await OfflineFirstService().init();  // 初始化离线优先服务
  await NotificationService().init();
  
  runApp(const MyApp());
}
```

### 在代码中使用

#### 1. 获取数据（离线优先）

```dart
// 旧方式（仅在线）
final motivations = await ApiService().getMyMotivations();

// 新方式（离线优先）
final motivations = await OfflineFirstService().getMyMotivations();
// 立即返回本地数据，如果在线会在后台更新
```

#### 2. 创建数据

```dart
// 旧方式
final id = await ApiService().createMotivation(
  title: 'Test',
  content: 'Content',
  type: 'positive',
);

// 新方式（离线支持）
final id = await OfflineFirstService().createMotivation(
  title: 'Test',
  content: 'Content',
  type: 'positive',
);
// 立即保存到本地，如果在线会自动同步到服务器
```

#### 3. 更新数据

```dart
// 旧方式
await ApiService().updateMotivation(id, {'title': 'New Title'});

// 新方式
await OfflineFirstService().updateMotivation(id, {'title': 'New Title'});
// 立即更新本地，标记为需要同步
```

#### 4. 删除数据

```dart
// 旧方式
await ApiService().deleteMotivation(id);

// 新方式
await OfflineFirstService().deleteMotivation(id);
// 软删除本地记录，在线时同步删除服务器数据
```

### 监听同步状态

```dart
OfflineFirstService().syncStatusStream.listen((status) {
  switch (status) {
    case SyncStatus.syncing:
      print('正在同步...');
      break;
    case SyncStatus.completed:
      print('同步完成');
      break;
    case SyncStatus.failed:
      print('同步失败');
      break;
    case SyncStatus.idle:
      print('空闲');
      break;
  }
});
```

### 手动触发同步

```dart
final result = await OfflineFirstService().manualSync();
if (result.success) {
  print('同步成功: ${result.message}');
} else {
  print('同步失败: ${result.message}');
}
```

## 数据同步策略

### 读取策略（离线优先）

1. **立即返回本地数据** - 无需等待网络请求
2. **后台更新** - 如果在线，在后台从服务器获取最新数据
3. **自动刷新** - 获取到新数据后更新本地缓存

### 写入策略（乐观更新）

1. **立即写入本地** - 操作立即生效，无需等待网络
2. **标记同步状态** - 将变更标记为"需要同步"
3. **自动同步** - 如果在线，立即尝试同步到服务器
4. **失败重试** - 同步失败时，数据保留在本地，等待下次自动同步

### 冲突解决

- **简单策略**：最后写入优先（Last Write Wins）
- 服务器数据始终覆盖本地数据
- 适合单用户场景

## 迁移代码

### 需要替换的地方

搜索项目中所有使用 `ApiService()` 的地方，评估是否需要改为 `OfflineFirstService()`：

**需要改为离线优先的场景：**
- 获取我的激励 `getMyMotivations()`
- 获取我的目标 `getMyGoals()`
- 获取收藏列表 `getFavorites()`
- 创建/更新/删除 激励或目标
- 完成目标 `completeGoal()`

**保持使用 ApiService 的场景：**
- 用户认证 `login()`, `loginWithPhone()`
- 获取公开内容（可选，离线服务也支持缓存）
- 文件上传 `uploadFile()`

### 示例迁移

**页面中获取数据：**

```dart
// 旧代码
class _MyPageState extends State<MyPage> {
  List<Motivation> _motivations = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final motivations = await ApiService().getMyMotivations();
      setState(() => _motivations = motivations);
    } catch (e) {
      // 网络错误时无法显示数据
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败: $e')),
      );
    }
  }
}

// 新代码
class _MyPageState extends State<MyPage> {
  List<Motivation> _motivations = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 离线优先，总是能返回数据（即使是本地缓存）
    final motivations = await OfflineFirstService().getMyMotivations();
    setState(() => _motivations = motivations);
    // 无需 try-catch，因为本地数据始终可用
  }
}
```

## 数据库结构

### 主要表

1. **motivations** - 激励内容
   - 包含同步状态字段：`needsSync`, `localOnly`, `syncError`
   - 软删除支持：`deletedAt`

2. **goals** - 目标
   - 包含同步状态字段
   - 支持微习惯和主线任务

3. **motivation_media** - 激励媒体文件
4. **motivation_tags** - 激励标签
5. **goal_completions** - 目标完成记录
6. **goal_motivations** - 目标与激励的关联

## 注意事项

1. **本地ID vs 服务器ID**
   - 离线创建的数据使用时间戳作为临时ID
   - 同步成功后，临时ID会被替换为服务器返回的真实ID

2. **媒体文件**
   - 目前媒体文件URL存储在本地，但文件本身仍托管在服务器
   - 离线时可能无法加载图片和视频
   - 未来可以扩展为缓存媒体文件到本地

3. **同步错误**
   - 同步失败的数据会记录错误信息到 `syncError` 字段
   - 下次自动同步时会重试

4. **清理数据**
   - 登出时可选择是否清理本地数据
   - 当前默认保留本地数据

## 测试建议

1. **离线测试**
   - 关闭网络，创建激励和目标
   - 确认数据正常保存和显示
   - 开启网络，确认自动同步

2. **同步测试**
   - 创建数据后立即关闭网络
   - 重启应用，确认数据仍在
   - 开启网络，确认同步到服务器

3. **冲突测试**
   - 在两个设备上同时修改同一条数据
   - 确认最后同步的数据生效

## 性能优化

1. **自动同步间隔** - 当前为5分钟，可根据需要调整
2. **批量同步** - 同步时批量处理多条记录
3. **索引优化** - 数据库已添加必要的索引

## 未来扩展

1. **冲突解决策略** - 更智能的冲突处理（如字段级合并）
2. **媒体文件缓存** - 下载并缓存图片/视频到本地
3. **增量同步** - 只同步变更的数据
4. **同步队列优化** - 优先级队列，重要数据优先同步

