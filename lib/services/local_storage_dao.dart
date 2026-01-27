import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import '../models/motivation.dart';
import '../models/goal.dart';
import 'database_service.dart';
import 'media_cache_service.dart';

class LocalStorageDao {
  final DatabaseService _dbService = DatabaseService();
  final MediaCacheService _mediaCache = MediaCacheService();

  // ==================== 激励内容相关 ====================

  /// 保存激励到本地
  Future<int> saveMotivation(Motivation motivation, {bool needsSync = false, bool localOnly = false}) async {
    final db = await _dbService.database;
    
    // 保存主记录
    final motivationId = await db.insert(
      'motivations',
      {
        'id': localOnly ? null : motivation.id,
        'title': motivation.title,
        'content': motivation.content,
        'type': motivation.type == MotivationType.positive ? 'positive' : 'negative',
        'isPublic': motivation.isPublic ? 1 : 0,
        'viewCount': motivation.viewCount,
        'likeCount': motivation.likeCount,
        'createdAt': motivation.createdAt.toIso8601String(),
        'authorId': motivation.author?.id,
        'authorNickname': motivation.author?.nickname,
        'authorAvatarUrl': motivation.author?.avatarUrl,
        'isLiked': motivation.isLiked ? 1 : 0,
        'isFavorited': motivation.isFavorited ? 1 : 0,
        'localOnly': localOnly ? 1 : 0,
        'needsSync': needsSync ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // 保存媒体，并下载到本地
    for (final media in motivation.media) {
      // 尝试下载媒体文件到本地
      String? localPath;
      if (media.url.startsWith('http')) {
        try {
          localPath = await _mediaCache.downloadMedia(media.url);
          debugPrint('媒体已缓存: ${media.url} -> $localPath');
        } catch (e) {
          debugPrint('媒体下载失败: ${media.url}, 错误: $e');
        }
      }
      
      await db.insert(
        'motivation_media',
        {
          'id': media.id,
          'motivationId': localOnly ? motivationId : motivation.id,
          'type': media.type,
          'url': media.url,
          'thumbnailUrl': media.thumbnailUrl,
          'localPath': localPath, // 保存本地路径
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // 保存标签
    await db.delete('motivation_tags', where: 'motivationId = ?', whereArgs: [localOnly ? motivationId : motivation.id]);
    for (final tag in motivation.tags) {
      await db.insert('motivation_tags', {
        'motivationId': localOnly ? motivationId : motivation.id,
        'tag': tag,
      });
    }

    debugPrint('保存激励: ${motivation.title} 完成');

    return localOnly ? motivationId : motivation.id;
  }

  /// 批量保存激励
  Future<void> saveMotivations(List<Motivation> motivations) async {
    for (final motivation in motivations) {
      debugPrint('保存激励: ${motivation.title}');
      await saveMotivation(motivation, needsSync: false);
    }
  }

  /// 获取本地激励列表
  Future<List<Motivation>> getMotivations({
    String? type,
    bool? isPublic,
    bool includeDeleted = false,
  }) async {
    final db = await _dbService.database;
    
    String where = includeDeleted ? '' : 'deletedAt IS NULL';
    List<dynamic> whereArgs = [];
    
    if (type != null) {
      where += where.isEmpty ? 'type = ?' : ' AND type = ?';
      whereArgs.add(type);
    }
    
    if (isPublic != null) {
      where += where.isEmpty ? 'isPublic = ?' : ' AND isPublic = ?';
      whereArgs.add(isPublic ? 1 : 0);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'motivations',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'createdAt DESC',
    );

    List<Motivation> motivations = [];
    for (final map in maps) {
      motivations.add(await _mapToMotivation(db, map));
    }
    return motivations;
  }

  /// 获取用户自己的激励列表（localOnly=1 或 authorId匹配）
  Future<List<Motivation>> getMyMotivationsByAuthorId({
    int? authorId,
    String? type,
    bool includeDeleted = false,
  }) async {
    final db = await _dbService.database;
    
    String where = includeDeleted ? '' : 'deletedAt IS NULL';
    List<dynamic> whereArgs = [];
    
    // 查询条件：localOnly=1 或者 authorId匹配
    if (authorId != null) {
      where += where.isEmpty ? '(localOnly = 1 OR authorId = ?)' : ' AND (localOnly = 1 OR authorId = ?)';
      whereArgs.add(authorId);
    } else {
      where += where.isEmpty ? 'localOnly = 1' : ' AND localOnly = 1';
    }
    
    if (type != null) {
      where += ' AND type = ?';
      whereArgs.add(type);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'motivations',
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'createdAt DESC',
    );

    List<Motivation> motivations = [];
    for (final map in maps) {
      motivations.add(await _mapToMotivation(db, map));
    }
    return motivations;
  }

  /// 获取单个激励
  Future<Motivation?> getMotivation(int id) async {
    final db = await _dbService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'motivations',
      where: 'id = ? AND deletedAt IS NULL',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return await _mapToMotivation(db, maps.first);
  }

  /// 获取我收藏的激励
  Future<List<Motivation>> getFavoriteMotivations() async {
    final db = await _dbService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'motivations',
      where: 'isFavorited = 1 AND deletedAt IS NULL',
      orderBy: 'createdAt DESC',
    );

    List<Motivation> motivations = [];
    for (final map in maps) {
      motivations.add(await _mapToMotivation(db, map));
    }
    return motivations;
  }

  /// 更新激励
  Future<void> updateMotivation(int id, Map<String, dynamic> updates, {bool needsSync = true}) async {
    final db = await _dbService.database;
    
    final Map<String, dynamic> data = Map.from(updates);
    
    // 从 updates 中提取 media 和 tags，因为它们存储在单独的表中
    final media = data.remove('media');
    final tags = data.remove('tags');
    
    data['updatedAt'] = DateTime.now().toIso8601String();
    if (needsSync) {
      data['needsSync'] = 1;
    }
    
    // 更新主表（只更新 motivations 表中存在的列）
    await db.update(
      'motivations',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    // 如果提供了 media，更新 motivation_media 表
    if (media != null && media is List) {
      // 删除旧的媒体记录
      await db.delete('motivation_media', where: 'motivationId = ?', whereArgs: [id]);
      
      // 插入新的媒体记录
      for (final item in media) {
        if (item is Map<String, dynamic>) {
          // 尝试下载媒体文件到本地
          String? localPath;
          final url = item['url'] as String?;
          if (url != null && url.startsWith('http')) {
            try {
              localPath = await _mediaCache.downloadMedia(url);
              debugPrint('媒体已缓存: $url -> $localPath');
            } catch (e) {
              debugPrint('媒体下载失败: $url, 错误: $e');
            }
          }
          
          await db.insert(
            'motivation_media',
            {
              'motivationId': id,
              'type': item['type'],
              'url': item['url'],
              'thumbnailUrl': item['thumbnailUrl'],
              'localPath': localPath,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    }
    
    // 如果提供了 tags，更新 motivation_tags 表
    if (tags != null && tags is List) {
      // 删除旧的标签记录
      await db.delete('motivation_tags', where: 'motivationId = ?', whereArgs: [id]);
      
      // 插入新的标签记录
      for (final tag in tags) {
        if (tag is String) {
          await db.insert('motivation_tags', {
            'motivationId': id,
            'tag': tag,
          });
        }
      }
    }
  }

  /// 删除激励（软删除）
  Future<void> deleteMotivation(int id, {bool needsSync = true}) async {
    final db = await _dbService.database;
    
    await db.update(
      'motivations',
      {
        'deletedAt': DateTime.now().toIso8601String(),
        'needsSync': needsSync ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 切换点赞状态
  Future<void> toggleLike(int id, bool isLiked) async {
    await updateMotivation(id, {'isLiked': isLiked ? 1 : 0});
  }

  /// 切换收藏状态
  Future<void> toggleFavorite(int id, bool isFavorited) async {
    await updateMotivation(id, {'isFavorited': isFavorited ? 1 : 0});
  }

  // ==================== 目标相关 ====================

  /// 保存目标到本地
  Future<int> saveGoal(Goal goal, {bool needsSync = false, bool localOnly = false}) async {
    final db = await _dbService.database;
    
    final goalId = await db.insert(
      'goals',
      {
        'id': localOnly ? null : goal.id,
        'title': goal.title,
        'description': goal.description,
        'type': goal.type == GoalType.habit ? 'habit' : 'main_task',
        'isPublic': goal.isPublic ? 1 : 0,
        'enableTimer': goal.enableTimer ? 1 : 0,
        'durationMinutes': goal.durationMinutes,
        'reminderTime': goal.reminderTime,
        'totalHours': goal.totalHours,
        'completedHours': goal.completedHours,
        'morningReminderTime': goal.morningReminderTime,
        'afternoonReminderTime': goal.afternoonReminderTime,
        'sessionDurationMinutes': goal.sessionDurationMinutes,
        'streakDays': goal.streakDays,
        'totalCompletedDays': goal.totalCompletedDays,
        'lastCompletedDate': goal.lastCompletedDate,
        'status': goal.status.name,
        'createdAt': goal.createdAt.toIso8601String(),
        'authorId': goal.author?.id,
        'authorNickname': goal.author?.nickname,
        'authorAvatarUrl': goal.author?.avatarUrl,
        'localOnly': localOnly ? 1 : 0,
        'needsSync': needsSync ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // 保存关联的激励
    final effectiveGoalId = localOnly ? goalId : goal.id;
    await db.delete('goal_motivations', where: 'goalId = ?', whereArgs: [effectiveGoalId]);
    for (final motivation in goal.motivations) {
      await db.insert('goal_motivations', {
        'goalId': effectiveGoalId,
        'motivationId': motivation.id,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    return effectiveGoalId;
  }

  /// 批量保存目标
  Future<void> saveGoals(List<Goal> goals) async {
    for (final goal in goals) {
      await saveGoal(goal, needsSync: false);
    }
  }

  /// 获取本地目标列表
  Future<List<Goal>> getGoals({
    String? type,
    String? status,
    bool includeDeleted = false,
  }) async {
    final db = await _dbService.database;
    
    String where = includeDeleted ? '' : 'deletedAt IS NULL';
    List<dynamic> whereArgs = [];
    
    if (type != null) {
      where += where.isEmpty ? 'type = ?' : ' AND type = ?';
      whereArgs.add(type);
    }
    
    if (status != null) {
      where += where.isEmpty ? 'status = ?' : ' AND status = ?';
      whereArgs.add(status);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'goals',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'createdAt DESC',
    );

    List<Goal> goals = [];
    for (final map in maps) {
      goals.add(await _mapToGoal(db, map));
    }
    return goals;
  }

  /// 获取单个目标
  Future<Goal?> getGoal(int id) async {
    final db = await _dbService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'goals',
      where: 'id = ? AND deletedAt IS NULL',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return await _mapToGoal(db, maps.first);
  }

  /// 更新目标
  Future<void> updateGoal(int id, Map<String, dynamic> updates, {bool needsSync = true}) async {
    final db = await _dbService.database;
    
    final Map<String, dynamic> data = Map.from(updates);
    
    // 提取 motivationIds，单独处理关联表
    List<int>? motivationIds;
    if (data.containsKey('motivationIds')) {
      motivationIds = data['motivationIds'] as List<int>?;
      data.remove('motivationIds');
    }
    
    data['updatedAt'] = DateTime.now().toIso8601String();
    if (needsSync) {
      data['needsSync'] = 1;
    }
    
    await db.update(
      'goals',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    // 更新激励关联
    if (motivationIds != null) {
      await db.delete('goal_motivations', where: 'goalId = ?', whereArgs: [id]);
      for (final motivationId in motivationIds) {
        await db.insert('goal_motivations', {
          'goalId': id,
          'motivationId': motivationId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
  }

  /// 删除目标（软删除）
  Future<void> deleteGoal(int id, {bool needsSync = true}) async {
    final db = await _dbService.database;
    
    await db.update(
      'goals',
      {
        'deletedAt': DateTime.now().toIso8601String(),
        'needsSync': needsSync ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 保存目标完成记录
  Future<int> saveGoalCompletion(int goalId, int durationMinutes, String? notes, {bool needsSync = true}) async {
    final db = await _dbService.database;
    
    return await db.insert('goal_completions', {
      'goalId': goalId,
      'completedAt': DateTime.now().toIso8601String(),
      'durationMinutes': durationMinutes,
      'notes': notes,
      'needsSync': needsSync ? 1 : 0,
    });
  }

  /// 获取目标的完成记录
  Future<List<GoalCompletion>> getGoalCompletions(int goalId, {int limit = 10}) async {
    final db = await _dbService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'goal_completions',
      where: 'goalId = ?',
      whereArgs: [goalId],
      orderBy: 'completedAt DESC',
      limit: limit,
    );

    return maps.map((map) => GoalCompletion.fromJson(map)).toList();
  }

  /// 获取目标关联的激励ID列表
  Future<List<int>> getGoalMotivationIds(int goalId) async {
    final db = await _dbService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'goal_motivations',
      columns: ['motivationId'],
      where: 'goalId = ?',
      whereArgs: [goalId],
    );

    return maps.map((map) => map['motivationId'] as int).toList();
  }

  // ==================== 同步相关 ====================

  /// 获取需要同步的激励
  Future<List<Map<String, dynamic>>> getMotivationsNeedSync() async {
    final db = await _dbService.database;
    return await db.query(
      'motivations',
      where: 'needsSync = 1',
      orderBy: 'updatedAt ASC',
    );
  }

  /// 获取需要同步的目标
  Future<List<Map<String, dynamic>>> getGoalsNeedSync() async {
    final db = await _dbService.database;
    return await db.query(
      'goals',
      where: 'needsSync = 1',
      orderBy: 'updatedAt ASC',
    );
  }

  /// 标记激励为已同步
  Future<void> markMotivationSynced(int localId, int? serverId) async {
    final db = await _dbService.database;
    await db.update(
      'motivations',
      {
        'id': serverId ?? localId,
        'needsSync': 0,
        'localOnly': 0,
        'syncError': null,
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  /// 标记目标为已同步
  Future<void> markGoalSynced(int localId, int? serverId) async {
    final db = await _dbService.database;
    await db.update(
      'goals',
      {
        'id': serverId ?? localId,
        'needsSync': 0,
        'localOnly': 0,
        'syncError': null,
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  /// 记录同步错误
  Future<void> recordSyncError(String table, int id, String error) async {
    final db = await _dbService.database;
    await db.update(
      table,
      {'syncError': error},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 辅助方法 ====================

  Future<Motivation> _mapToMotivation(Database db, Map<String, dynamic> map) async {
    // 获取媒体
    final mediaList = await db.query(
      'motivation_media',
      where: 'motivationId = ?',
      whereArgs: [map['id']],
    );
    
    // 转换媒体，保持原始URL不变，本地路径单独存储
    final media = <MediaItem>[];
    for (final m in mediaList) {
      media.add(MediaItem(
        id: m['id'] as int,
        type: m['type'] as String,
        url: m['url'] as String, // 始终使用原始网络URL
        thumbnailUrl: m['thumbnailUrl'] as String?,
        localPath: m['localPath'] as String?, // 本地缓存路径
      ));
    }

    // 获取标签
    final tagsList = await db.query(
      'motivation_tags',
      where: 'motivationId = ?',
      whereArgs: [map['id']],
    );
    
    final tags = tagsList.map((t) => t['tag'] as String).toList();

    // 构建作者信息
    Author? author;
    if (map['authorId'] != null) {
      author = Author(
        id: map['authorId'] as int,
        nickname: map['authorNickname'] as String?,
        avatarUrl: map['authorAvatarUrl'] as String?,
      );
    }

    return Motivation(
      id: map['id'] as int,
      title: map['title'] as String?,
      content: map['content'] as String?,
      type: map['type'] == 'positive' ? MotivationType.positive : MotivationType.negative,
      isPublic: map['isPublic'] == 1,
      viewCount: map['viewCount'] as int? ?? 0,
      likeCount: map['likeCount'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      author: author,
      media: media,
      tags: tags,
      isLiked: map['isLiked'] == 1,
      isFavorited: map['isFavorited'] == 1,
    );
  }

  Future<Goal> _mapToGoal(Database db, Map<String, dynamic> map) async {
    // 获取关联的激励
    final motivationsList = await db.rawQuery('''
      SELECT m.* FROM motivations m
      INNER JOIN goal_motivations gm ON m.id = gm.motivationId
      WHERE gm.goalId = ? AND m.deletedAt IS NULL
    ''', [map['id']]);
    
    final motivations = <GoalMotivation>[];
    for (final m in motivationsList) {
      // 获取第一个媒体
      final mediaList = await db.query(
        'motivation_media',
        where: 'motivationId = ?',
        whereArgs: [m['id']],
        limit: 1,
      );
      
      // 优先使用本地路径，如果没有则使用原始URL
      String? mediaUrl;
      if (mediaList.isNotEmpty) {
        final localPath = mediaList.first['localPath'] as String?;
        mediaUrl = localPath ?? mediaList.first['url'] as String?;
      }
      
      motivations.add(GoalMotivation(
        id: m['id'] as int,
        title: m['title'] as String?,
        type: m['type'] == 'positive' ? MotivationType.positive : MotivationType.negative,
        firstMediaUrl: mediaUrl,
        firstMediaType: mediaList.isNotEmpty ? mediaList.first['type'] as String? : null,
        content: m['content'] as String?,
      ));
    }

    // 获取最近的完成记录
    final recentCompletions = await getGoalCompletions(map['id'] as int, limit: 10);

    // 构建作者信息
    Author? author;
    if (map['authorId'] != null) {
      author = Author(
        id: map['authorId'] as int,
        nickname: map['authorNickname'] as String?,
        avatarUrl: map['authorAvatarUrl'] as String?,
      );
    }

    return Goal(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      type: map['type'] == 'habit' ? GoalType.habit : GoalType.mainTask,
      isPublic: map['isPublic'] == 1,
      enableTimer: map['enableTimer'] == 1,
      durationMinutes: map['durationMinutes'] as int? ?? 10,
      reminderTime: map['reminderTime'] as String?,
      totalHours: map['totalHours'] as int? ?? 0,
      completedHours: (map['completedHours'] as num?)?.toDouble() ?? 0,
      morningReminderTime: map['morningReminderTime'] as String? ?? '09:00:00',
      afternoonReminderTime: map['afternoonReminderTime'] as String? ?? '14:00:00',
      sessionDurationMinutes: map['sessionDurationMinutes'] as int? ?? 240,
      streakDays: map['streakDays'] as int? ?? 0,
      totalCompletedDays: map['totalCompletedDays'] as int? ?? 0,
      lastCompletedDate: map['lastCompletedDate'] as String?,
      status: _parseGoalStatus(map['status'] as String?),
      createdAt: DateTime.parse(map['createdAt'] as String),
      motivations: motivations,
      recentCompletions: recentCompletions,
      author: author,
    );
  }

  GoalStatus _parseGoalStatus(String? status) {
    switch (status) {
      case 'active':
        return GoalStatus.active;
      case 'paused':
        return GoalStatus.paused;
      case 'completed':
        return GoalStatus.completed;
      case 'archived':
        return GoalStatus.archived;
      default:
        return GoalStatus.active;
    }
  }
}

