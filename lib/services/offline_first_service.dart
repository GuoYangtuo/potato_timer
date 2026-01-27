import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/motivation.dart';
import '../models/goal.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'local_storage_dao.dart';
import 'sync_service.dart';

/// 离线优先服务 - 优先使用本地数据，联网时自动同步
class OfflineFirstService {
  static final OfflineFirstService _instance = OfflineFirstService._internal();
  factory OfflineFirstService() => _instance;
  OfflineFirstService._internal();

  final ApiService _api = ApiService();
  final LocalStorageDao _dao = LocalStorageDao();
  final SyncService _sync = SyncService();

  bool _isInitialized = false;

  /// 初始化服务
  Future<void> init() async {
    if (_isInitialized) return;
    
    await _api.init();
    
    // 如果已登录，启动自动同步
    if (_api.isLoggedIn) {
      _sync.startAutoSync();
      // 立即执行一次同步
      unawaited(_sync.syncAll().catchError((e) {
        debugPrint('初始同步失败: $e');
        return SyncResult(success: false, message: '初始同步失败: $e');
      }));
    }
    
    _isInitialized = true;
  }

  /// 登录后调用，启动同步
  Future<void> onLoginSuccess() async {
    _sync.startAutoSync();
    await _sync.syncAll();
  }

  /// 登出后调用，停止同步并清理本地数据
  Future<void> onLogout() async {
    _sync.stopAutoSync();
    // 可选：清理本地数据或保留
    // await DatabaseService().clearAll();
  }

  // ==================== 激励内容相关 ====================

  /// 获取公开激励（在线数据）
  Future<List<Motivation>> getPublicMotivations({
    String? type,
    String? tag,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final motivations = await _api.getPublicMotivations(
        type: type,
        tag: tag,
        page: page,
        limit: limit,
      );
      // 缓存到本地（不标记为needsSync）
      await _dao.saveMotivations(motivations);
      return motivations;
    } catch (e) {
      debugPrint('获取公开激励失败，返回本地缓存: $e');
      // 失败时返回本地缓存
      return await _dao.getMotivations(type: type, isPublic: true);
    }
  }

  /// 获取我的激励（离线优先）
  Future<List<Motivation>> getMyMotivations({
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    // 1. 先从本地读取（查询localOnly=1或authorId匹配的记录）
    final localMotivations = await _dao.getMotivations(type: type);
    
    // 2. 如果在线，后台更新
    if (_api.isLoggedIn) {
      debugPrint('在线，后台更新激励');
      _fetchAndUpdateMotivations(type);
    }
    
    return localMotivations;
  }

  /// 后台获取并更新激励
  Future<void> _fetchAndUpdateMotivations(String? type) async {
    try {
      final motivations = await _api.getMyMotivations(type: type, limit: 100);
      debugPrint('后台更新激励: $motivations');
      await _dao.saveMotivations(motivations);
    } catch (e) {
      debugPrint('后台更新激励失败: $e');
    }
  }

  /// 获取单个激励
  Future<Motivation?> getMotivation(int id) async {
    // 先从本地读取
    final local = await _dao.getMotivation(id);
    if (local != null) return local;
    
    // 本地没有，尝试从服务器获取
    try {
      final motivation = await _api.getMotivation(id);
      await _dao.saveMotivation(motivation);
      return motivation;
    } catch (e) {
      debugPrint('获取激励详情失败: $e');
      return null;
    }
  }

  /// 创建激励（离线优先）
  Future<int> createMotivation({
    String? title,
    String? content,
    required String type,
    bool isPublic = false,
    List<Map<String, dynamic>>? media,
    List<String>? tags,
  }) async {
    // 先创建本地记录
    final motivation = Motivation(
      id: DateTime.now().millisecondsSinceEpoch, // 临时ID
      title: title,
      content: content,
      type: type == 'positive' ? MotivationType.positive : MotivationType.negative,
      isPublic: isPublic,
      createdAt: DateTime.now(),
      tags: tags ?? [],
      media: media?.map((m) => MediaItem(
        id: 0,
        type: m['type'] as String,
        url: m['url'] as String,
        thumbnailUrl: m['thumbnailUrl'] as String?,
      )).toList() ?? [],
      author: _api.currentUser != null ? Author(
        id: _api.currentUser!.id,
        nickname: _api.currentUser!.nickname,
        avatarUrl: _api.currentUser!.avatarUrl,
      ) : null,
    );
    
    final localId = await _dao.saveMotivation(
      motivation,
      needsSync: true,
      localOnly: true,
    );
    
    // 如果在线，立即同步
    if (_api.isLoggedIn) {
      unawaited(_sync.syncNow());
    }
    
    return localId;
  }

  /// 更新激励
  Future<void> updateMotivation(int id, Map<String, dynamic> updates) async {
    // 先更新本地
    await _dao.updateMotivation(id, updates, needsSync: true);
    
    // 如果在线，立即调用API更新
    if (_api.isLoggedIn) {
      try {
        await _api.updateMotivation(id, updates);
        // 更新成功后，清除同步标记
        await _dao.updateMotivation(id, {'needsSync': 0}, needsSync: false);
      } catch (e) {
        debugPrint('更新激励同步失败: $e');
        // 保持 needsSync 标记，等待后续同步
      }
    }
  }

  /// 删除激励
  Future<void> deleteMotivation(int id) async {
    // 先标记本地删除
    await _dao.deleteMotivation(id, needsSync: true);
    
    // 如果在线，立即调用API删除
    if (_api.isLoggedIn) {
      try {
        await _api.deleteMotivation(id);
        // 删除成功后，从本地完全移除（不再需要同步）
        await _dao.deleteMotivation(id, needsSync: false);
      } catch (e) {
        debugPrint('删除激励同步失败: $e');
        // 保持 needsSync 标记，等待后续同步
      }
    }
  }

  /// 点赞激励
  Future<void> likeMotivation(int id) async {
    await _dao.toggleLike(id, true);
    
    if (_api.isLoggedIn) {
      try {
        await _api.likeMotivation(id);
      } catch (e) {
        debugPrint('点赞失败: $e');
        // 回滚本地状态
        await _dao.toggleLike(id, false);
        rethrow;
      }
    }
  }

  /// 取消点赞
  Future<void> unlikeMotivation(int id) async {
    await _dao.toggleLike(id, false);
    
    if (_api.isLoggedIn) {
      try {
        await _api.unlikeMotivation(id);
      } catch (e) {
        debugPrint('取消点赞失败: $e');
        // 回滚本地状态
        await _dao.toggleLike(id, true);
        rethrow;
      }
    }
  }

  /// 收藏激励
  Future<void> favoriteMotivation(int id) async {
    await _dao.toggleFavorite(id, true);
    
    if (_api.isLoggedIn) {
      try {
        await _api.favoriteMotivation(id);
      } catch (e) {
        debugPrint('收藏失败: $e');
        // 回滚本地状态
        await _dao.toggleFavorite(id, false);
        rethrow;
      }
    }
  }

  /// 取消收藏
  Future<void> unfavoriteMotivation(int id) async {
    await _dao.toggleFavorite(id, false);
    
    if (_api.isLoggedIn) {
      try {
        await _api.unfavoriteMotivation(id);
      } catch (e) {
        debugPrint('取消收藏失败: $e');
        // 回滚本地状态
        await _dao.toggleFavorite(id, true);
        rethrow;
      }
    }
  }

  /// 获取收藏列表
  Future<List<Motivation>> getFavorites({int page = 1, int limit = 20}) async {
    // 先从本地读取
    final favorites = await _dao.getFavoriteMotivations();
    
    // 如果在线，后台更新
    if (_api.isLoggedIn) {
      _fetchAndUpdateFavorites();
    }
    
    return favorites;
  }

  Future<void> _fetchAndUpdateFavorites() async {
    try {
      final favorites = await _api.getFavorites(limit: 100);
      await _dao.saveMotivations(favorites);
    } catch (e) {
      debugPrint('后台更新收藏失败: $e');
    }
  }

  // ==================== 目标相关 ====================

  /// 获取我的目标（离线优先）
  Future<List<Goal>> getMyGoals({String? type, String? status}) async {
    // 先从本地读取
    final goals = await _dao.getGoals(type: type, status: status);
    
    // 如果在线，后台更新
    if (_api.isLoggedIn) {
      _fetchAndUpdateGoals(type, status);
    }
    
    return goals;
  }

  Future<void> _fetchAndUpdateGoals(String? type, String? status) async {
    try {
      final goals = await _api.getMyGoals(type: type, status: status);
      await _dao.saveGoals(goals);
    } catch (e) {
      debugPrint('后台更新目标失败: $e');
    }
  }

  /// 获取公开目标
  Future<List<Goal>> getPublicGoals({
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final goals = await _api.getPublicGoals(type: type, page: page, limit: limit);
      await _dao.saveGoals(goals);
      return goals;
    } catch (e) {
      debugPrint('获取公开目标失败: $e');
      // 返回空列表，因为公开目标不缓存到本地
      return [];
    }
  }

  /// 获取单个目标
  Future<Goal?> getGoal(int id) async {
    // 先从本地读取
    final local = await _dao.getGoal(id);
    if (local != null) return local;
    
    // 本地没有，尝试从服务器获取
    try {
      final goal = await _api.getGoal(id);
      await _dao.saveGoal(goal);
      return goal;
    } catch (e) {
      debugPrint('获取目标详情失败: $e');
      return null;
    }
  }

  /// 创建目标（离线优先）
  Future<int> createGoal({
    required String title,
    String? description,
    required String type,
    bool isPublic = false,
    bool enableTimer = false,
    int durationMinutes = 10,
    String? reminderTime,
    int totalHours = 0,
    String? morningReminderTime,
    String? afternoonReminderTime,
    int sessionDurationMinutes = 240,
    List<int>? motivationIds,
  }) async {
    // 先创建本地记录
    final goal = Goal(
      id: DateTime.now().millisecondsSinceEpoch, // 临时ID
      title: title,
      description: description,
      type: type == 'habit' ? GoalType.habit : GoalType.mainTask,
      isPublic: isPublic,
      enableTimer: enableTimer,
      durationMinutes: durationMinutes,
      reminderTime: reminderTime,
      totalHours: totalHours,
      morningReminderTime: morningReminderTime ?? '09:00:00',
      afternoonReminderTime: afternoonReminderTime ?? '14:00:00',
      sessionDurationMinutes: sessionDurationMinutes,
      createdAt: DateTime.now(),
    );
    
    final localId = await _dao.saveGoal(goal, needsSync: true, localOnly: true);
    
    // 保存激励关联
    if (motivationIds != null && motivationIds.isNotEmpty) {
      await _dao.updateGoal(localId, {'motivationIds': motivationIds}, needsSync: false);
    }
    
    // 如果在线，立即同步
    if (_api.isLoggedIn) {
      unawaited(_sync.syncNow());
    }
    
    return localId;
  }

  /// 更新目标
  Future<void> updateGoal(int id, Map<String, dynamic> updates) async {
    // 先更新本地
    await _dao.updateGoal(id, updates, needsSync: true);
    
    // 如果在线，立即调用API更新
    if (_api.isLoggedIn) {
      try {
        await _api.updateGoal(id, updates);
        // 更新成功后，清除同步标记
        await _dao.updateGoal(id, {'needsSync': 0}, needsSync: false);
      } catch (e) {
        debugPrint('更新目标同步失败: $e');
        // 保持 needsSync 标记，等待后续同步
      }
    }
  }

  /// 删除目标
  Future<void> deleteGoal(int id) async {
    // 先标记本地删除
    await _dao.deleteGoal(id, needsSync: true);
    
    // 如果在线，立即调用API删除
    if (_api.isLoggedIn) {
      try {
        await _api.deleteGoal(id);
        // 删除成功后，从本地完全移除（不再需要同步）
        await _dao.deleteGoal(id, needsSync: false);
      } catch (e) {
        debugPrint('删除目标同步失败: $e');
        // 保持 needsSync 标记，等待后续同步
      }
    }
  }

  /// 完成目标
  Future<void> completeGoal(int id, {
    int durationMinutes = 0,
    String? notes,
  }) async {
    // 保存完成记录到本地
    await _dao.saveGoalCompletion(id, durationMinutes, notes);
    
    // 更新目标统计
    final goal = await _dao.getGoal(id);
    if (goal != null) {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final isCompletedToday = goal.lastCompletedDate == today;
      
      await _dao.updateGoal(id, {
        'lastCompletedDate': today,
        'totalCompletedDays': isCompletedToday ? goal.totalCompletedDays : goal.totalCompletedDays + 1,
        'completedHours': goal.completedHours + (durationMinutes / 60.0),
        'needsSync': 1,
      }, needsSync: false);
    }
    
    // 如果在线，立即同步
    if (_api.isLoggedIn) {
      try {
        await _api.completeGoal(id, durationMinutes: durationMinutes, notes: notes);
      } catch (e) {
        debugPrint('完成目标同步失败: $e');
      }
    }
  }

  /// 获取目标的激励内容
  Future<Map<String, dynamic>> getGoalMotivations(int goalId) async {
    final goal = await _dao.getGoal(goalId);
    if (goal != null) {
      // 返回符合页面期望的数据结构
      return {
        'goal': {
          'id': goal.id,
          'title': goal.title,
          'type': goal.type == GoalType.habit ? 'habit' : 'mainTask',
          'enableTimer': goal.enableTimer,
          'durationMinutes': goal.durationMinutes,
          'sessionDurationMinutes': goal.sessionDurationMinutes,
        },
        'motivations': goal.motivations.map((m) => {
          'id': m.id,
          'title': m.title,
          'content': m.content,
          'type': m.type == MotivationType.positive ? 'positive' : 'negative',
          'firstMediaUrl': m.firstMediaUrl,
          'firstMediaType': m.firstMediaType,
        }).toList(),
      };
    }
    
    // 本地没有，尝试从服务器获取
    try {
      return await _api.getGoalMotivations(goalId);
    } catch (e) {
      debugPrint('获取目标激励失败: $e');
      // 返回空数据结构，避免类型转换错误
      return {
        'goal': null,
        'motivations': [],
      };
    }
  }

  // ==================== 其他功能 ====================

  /// 手动触发同步
  Future<SyncResult> manualSync() async {
    return await _sync.syncAll();
  }

  /// 获取同步状态流
  Stream<SyncStatus> get syncStatusStream => _sync.syncStatusStream;

  /// 获取当前用户
  User? get currentUser => _api.currentUser;

  /// 是否已登录
  bool get isLoggedIn => _api.isLoggedIn;
}

