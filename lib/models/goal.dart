import 'motivation.dart';

enum GoalType { habit, mainTask }

enum GoalStatus { active, paused, completed, archived }

class GoalMotivation {
  final int id;
  final String? title;
  final MotivationType type;
  final String? firstMediaUrl;
  final String? firstMediaType;
  final String? content;

  GoalMotivation({
    required this.id,
    this.title,
    required this.type,
    this.firstMediaUrl,
    this.firstMediaType,
    this.content,
  });

  factory GoalMotivation.fromJson(Map<String, dynamic> json) {
    return GoalMotivation(
      id: json['id'] as int,
      title: json['title'] as String?,
      type: json['type'] == 'positive' 
          ? MotivationType.positive 
          : MotivationType.negative,
      firstMediaUrl: json['firstMediaUrl'] as String?,
      firstMediaType: json['firstMediaType'] as String?,
      content: json['content'] as String?,
    );
  }
}

class GoalCompletion {
  final int id;
  final DateTime completedAt;
  final int durationMinutes;
  final String? notes;

  GoalCompletion({
    required this.id,
    required this.completedAt,
    required this.durationMinutes,
    this.notes,
  });

  factory GoalCompletion.fromJson(Map<String, dynamic> json) {
    return GoalCompletion(
      id: json['id'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      notes: json['notes'] as String?,
    );
  }
}

class Goal {
  final int id;
  final String title;
  final String? description;
  final GoalType type;
  final bool isPublic;
  
  // 微习惯相关
  final bool enableTimer;
  final int durationMinutes;
  final String? reminderTime;
  
  // 主线任务相关
  final int totalHours;
  final double completedHours;
  final String morningReminderTime;
  final String afternoonReminderTime;
  final int sessionDurationMinutes;
  
  // 通用统计
  final int streakDays;
  final int totalCompletedDays;
  final String? lastCompletedDate;
  final GoalStatus status;
  final DateTime createdAt;
  
  // 关联数据
  final List<GoalMotivation> motivations;
  final List<GoalCompletion> recentCompletions;
  
  // 作者信息（公开目标时使用）
  final Author? author;

  Goal({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.isPublic = false,
    this.enableTimer = false,
    this.durationMinutes = 10,
    this.reminderTime,
    this.totalHours = 0,
    this.completedHours = 0,
    this.morningReminderTime = '09:00:00',
    this.afternoonReminderTime = '14:00:00',
    this.sessionDurationMinutes = 240,
    this.streakDays = 0,
    this.totalCompletedDays = 0,
    this.lastCompletedDate,
    this.status = GoalStatus.active,
    required this.createdAt,
    this.motivations = const [],
    this.recentCompletions = const [],
    this.author,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: json['type'] == 'habit' ? GoalType.habit : GoalType.mainTask,
      isPublic: _parseBool(json['isPublic']),
      enableTimer: _parseBool(json['enableTimer']),
      durationMinutes: json['durationMinutes'] as int? ?? 10,
      reminderTime: json['reminderTime'] as String?,
      totalHours: json['totalHours'] as int? ?? 0,
      completedHours: (json['completedHours'] as num?)?.toDouble() ?? 0,
      morningReminderTime: json['morningReminderTime'] as String? ?? '09:00:00',
      afternoonReminderTime: json['afternoonReminderTime'] as String? ?? '14:00:00',
      sessionDurationMinutes: json['sessionDurationMinutes'] as int? ?? 240,
      streakDays: json['streakDays'] as int? ?? 0,
      totalCompletedDays: json['totalCompletedDays'] as int? ?? 0,
      lastCompletedDate: json['lastCompletedDate'] as String?,
      status: _parseStatus(json['status'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      motivations: (json['motivations'] as List<dynamic>?)
          ?.map((e) => GoalMotivation.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      recentCompletions: (json['recentCompletions'] as List<dynamic>?)
          ?.map((e) => GoalCompletion.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      author: json['author'] != null 
          ? Author.fromJson(json['author'] as Map<String, dynamic>) 
          : null,
    );
  }

  static GoalStatus _parseStatus(String? status) {
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

  /// 解析 bool 值，兼容 MySQL 返回的 0/1 和 true/false
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type == GoalType.habit ? 'habit' : 'main_task',
      'isPublic': isPublic,
      'enableTimer': enableTimer,
      'durationMinutes': durationMinutes,
      'reminderTime': reminderTime,
      'totalHours': totalHours,
      'completedHours': completedHours,
      'morningReminderTime': morningReminderTime,
      'afternoonReminderTime': afternoonReminderTime,
      'sessionDurationMinutes': sessionDurationMinutes,
      'streakDays': streakDays,
      'totalCompletedDays': totalCompletedDays,
      'lastCompletedDate': lastCompletedDate,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 获取进度百分比（主线任务用）
  double get progressPercent {
    if (type != GoalType.mainTask || totalHours <= 0) return 0;
    return (completedHours / totalHours * 100).clamp(0, 100);
  }

  /// 判断今天是否已完成
  bool get isCompletedToday {
    if (lastCompletedDate == null) return false;
    final today = DateTime.now().toIso8601String().split('T')[0];
    return lastCompletedDate == today;
  }

  Goal copyWith({
    int? id,
    String? title,
    String? description,
    GoalType? type,
    bool? isPublic,
    bool? enableTimer,
    int? durationMinutes,
    String? reminderTime,
    int? totalHours,
    double? completedHours,
    String? morningReminderTime,
    String? afternoonReminderTime,
    int? sessionDurationMinutes,
    int? streakDays,
    int? totalCompletedDays,
    String? lastCompletedDate,
    GoalStatus? status,
    DateTime? createdAt,
    List<GoalMotivation>? motivations,
    List<GoalCompletion>? recentCompletions,
    Author? author,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      isPublic: isPublic ?? this.isPublic,
      enableTimer: enableTimer ?? this.enableTimer,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      reminderTime: reminderTime ?? this.reminderTime,
      totalHours: totalHours ?? this.totalHours,
      completedHours: completedHours ?? this.completedHours,
      morningReminderTime: morningReminderTime ?? this.morningReminderTime,
      afternoonReminderTime: afternoonReminderTime ?? this.afternoonReminderTime,
      sessionDurationMinutes: sessionDurationMinutes ?? this.sessionDurationMinutes,
      streakDays: streakDays ?? this.streakDays,
      totalCompletedDays: totalCompletedDays ?? this.totalCompletedDays,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      motivations: motivations ?? this.motivations,
      recentCompletions: recentCompletions ?? this.recentCompletions,
      author: author ?? this.author,
    );
  }
}


