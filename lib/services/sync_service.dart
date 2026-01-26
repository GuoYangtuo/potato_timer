import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/motivation.dart';
import 'local_storage_dao.dart';
import 'api_service.dart';

/// 同步服务 - 负责本地数据与服务器的同步
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final LocalStorageDao _dao = LocalStorageDao();
  final ApiService _api = ApiService();
  
  bool _isSyncing = false;
  Timer? _autoSyncTimer;

  /// 同步状态流
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  /// 启动自动同步（每5分钟同步一次）
  void startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      syncAll();
    });
  }

  /// 停止自动同步
  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  /// 执行完整同步
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: '正在同步中...');
    }

    if (!_api.isLoggedIn) {
      return SyncResult(success: false, message: '未登录，无法同步');
    }

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      // 1. 先拉取服务器数据到本地
      await _pullFromServer();
      
      // 2. 再推送本地变更到服务器
      await _pushToServer();
      
      _syncStatusController.add(SyncStatus.completed);
      return SyncResult(success: true, message: '同步完成');
    } catch (e) {
      debugPrint('同步失败: $e');
      _syncStatusController.add(SyncStatus.failed);
      return SyncResult(success: false, message: '同步失败: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// 从服务器拉取数据
  Future<void> _pullFromServer() async {
    try {
      // 拉取我的激励
      final motivations = await _api.getMyMotivations(limit: 100);
      await _dao.saveMotivations(motivations);

      // 拉取我的目标
      final goals = await _api.getMyGoals();
      await _dao.saveGoals(goals);

      // 拉取我的收藏
      final favorites = await _api.getFavorites(limit: 100);
      await _dao.saveMotivations(favorites);
    } catch (e) {
      debugPrint('从服务器拉取数据失败: $e');
      // 不抛出异常，继续执行推送
    }
  }

  /// 推送本地变更到服务器
  Future<void> _pushToServer() async {
    // 推送激励
    await _syncMotivations();
    
    // 推送目标
    await _syncGoals();
  }

  /// 同步激励数据
  Future<void> _syncMotivations() async {
    final motivations = await _dao.getMotivationsNeedSync();
    
    for (final motivationMap in motivations) {
      try {
        final id = motivationMap['id'] as int;
        final localOnly = motivationMap['localOnly'] == 1;
        final deletedAt = motivationMap['deletedAt'] as String?;

        if (deletedAt != null) {
          // 删除操作
          if (!localOnly) {
            await _api.deleteMotivation(id);
          }
          await _dao.markMotivationSynced(id, null);
        } else if (localOnly) {
          // 新建操作 - 需要读取完整的Motivation对象以获取tags和media
          final motivation = await _dao.getMotivation(id);
          if (motivation != null) {
            final serverId = await _api.createMotivation(
              title: motivation.title,
              content: motivation.content,
              type: motivation.type == MotivationType.positive ? 'positive' : 'negative',
              isPublic: motivation.isPublic,
              tags: motivation.tags,
              media: motivation.media.map((m) => {
                'type': m.type,
                'url': m.url,
                'thumbnailUrl': m.thumbnailUrl,
              }).toList(),
            );
            await _dao.markMotivationSynced(id, serverId);
          }
        } else {
          // 更新操作 - 同样需要读取完整对象
          final motivation = await _dao.getMotivation(id);
          if (motivation != null) {
            await _api.updateMotivation(id, {
              'title': motivation.title,
              'content': motivation.content,
              'type': motivation.type == MotivationType.positive ? 'positive' : 'negative',
              'isPublic': motivation.isPublic,
              'tags': motivation.tags,
              'media': motivation.media.map((m) => {
                'type': m.type,
                'url': m.url,
                'thumbnailUrl': m.thumbnailUrl,
              }).toList(),
            });
            await _dao.markMotivationSynced(id, null);
          }
        }
      } catch (e) {
        debugPrint('同步激励失败 ID=${motivationMap['id']}: $e');
        await _dao.recordSyncError('motivations', motivationMap['id'] as int, e.toString());
      }
    }
  }

  /// 同步目标数据
  Future<void> _syncGoals() async {
    final goals = await _dao.getGoalsNeedSync();
    
    for (final goalMap in goals) {
      try {
        final id = goalMap['id'] as int;
        final localOnly = goalMap['localOnly'] == 1;
        final deletedAt = goalMap['deletedAt'] as String?;

        if (deletedAt != null) {
          // 删除操作
          if (!localOnly) {
            await _api.deleteGoal(id);
          }
          await _dao.markGoalSynced(id, null);
        } else if (localOnly) {
          // 新建操作
          final serverId = await _api.createGoal(
            title: goalMap['title'] as String,
            description: goalMap['description'] as String?,
            type: goalMap['type'] as String,
            isPublic: goalMap['isPublic'] == 1,
            enableTimer: goalMap['enableTimer'] == 1,
            durationMinutes: goalMap['durationMinutes'] as int? ?? 10,
            reminderTime: goalMap['reminderTime'] as String?,
            totalHours: goalMap['totalHours'] as int? ?? 0,
            morningReminderTime: goalMap['morningReminderTime'] as String?,
            afternoonReminderTime: goalMap['afternoonReminderTime'] as String?,
            sessionDurationMinutes: goalMap['sessionDurationMinutes'] as int? ?? 240,
          );
          await _dao.markGoalSynced(id, serverId);
        } else {
          // 更新操作
          await _api.updateGoal(id, {
            'title': goalMap['title'],
            'description': goalMap['description'],
            'status': goalMap['status'],
            'enableTimer': goalMap['enableTimer'] == 1,
            'durationMinutes': goalMap['durationMinutes'],
            'reminderTime': goalMap['reminderTime'],
          });
          await _dao.markGoalSynced(id, null);
        }
      } catch (e) {
        debugPrint('同步目标失败 ID=${goalMap['id']}: $e');
        await _dao.recordSyncError('goals', goalMap['id'] as int, e.toString());
      }
    }
  }

  /// 手动触发同步（在用户操作后立即同步）
  Future<void> syncNow() async {
    if (_api.isLoggedIn) {
      await syncAll();
    }
  }

  void dispose() {
    stopAutoSync();
    _syncStatusController.close();
  }
}

enum SyncStatus {
  idle,
  syncing,
  completed,
  failed,
}

class SyncResult {
  final bool success;
  final String message;

  SyncResult({required this.success, required this.message});
}

