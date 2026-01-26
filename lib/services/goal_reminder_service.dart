import 'package:flutter/material.dart';
import 'package:potato_timer/models/goal.dart';
import 'package:potato_timer/services/notification_service.dart';

/// 目标提醒服务
/// 负责管理目标的通知提醒
class GoalReminderService {
  static final GoalReminderService _instance = GoalReminderService._internal();
  factory GoalReminderService() => _instance;
  GoalReminderService._internal();

  final NotificationService _notificationService = NotificationService();

  /// 为目标设置提醒
  Future<void> scheduleGoalReminders(Goal goal) async {
    // 先取消该目标的所有现有提醒
    await cancelGoalReminders(goal.id);

    if (goal.status != GoalStatus.active) return;

    if (goal.type == GoalType.habit) {
      // 微习惯：设置每日提醒
      if (goal.reminderTime != null) {
        final timeParts = goal.reminderTime!.split(':');
        if (timeParts.length >= 2) {
          final time = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );

          await _notificationService.scheduleDailyNotification(
            id: NotificationService.generateGoalNotificationId(goal.id),
            title: '⏰ 是时候开始了！',
            body: goal.title,
            time: time,
            payload: NotificationService.createPayload('goal', goal.id),
          );
        }
      }
    } else {
      // 主线任务：设置上午和下午提醒
      final morningParts = goal.morningReminderTime.split(':');
      final afternoonParts = goal.afternoonReminderTime.split(':');

      if (morningParts.length >= 2) {
        final morningTime = TimeOfDay(
          hour: int.parse(morningParts[0]),
          minute: int.parse(morningParts[1]),
        );

        await _notificationService.scheduleDailyNotification(
          id: NotificationService.generateGoalNotificationId(goal.id, offset: 1),
          title: '🌅 上午工作时间',
          body: '继续 ${goal.title}',
          time: morningTime,
          payload: NotificationService.createPayload('goal', goal.id),
        );
      }

      if (afternoonParts.length >= 2) {
        final afternoonTime = TimeOfDay(
          hour: int.parse(afternoonParts[0]),
          minute: int.parse(afternoonParts[1]),
        );

        await _notificationService.scheduleDailyNotification(
          id: NotificationService.generateGoalNotificationId(goal.id, offset: 2),
          title: '🌤️ 下午工作时间',
          body: '继续 ${goal.title}',
          time: afternoonTime,
          payload: NotificationService.createPayload('goal', goal.id),
        );
      }
    }
  }

  /// 取消目标的所有提醒
  Future<void> cancelGoalReminders(int goalId) async {
    // 取消主提醒和可能的上午/下午提醒
    await _notificationService.cancelNotification(
      NotificationService.generateGoalNotificationId(goalId),
    );
    await _notificationService.cancelNotification(
      NotificationService.generateGoalNotificationId(goalId, offset: 1),
    );
    await _notificationService.cancelNotification(
      NotificationService.generateGoalNotificationId(goalId, offset: 2),
    );
  }

  /// 安排推迟提醒（用户点击推迟后）
  Future<void> schedulePostponeReminder(Goal goal) async {
    await _notificationService.scheduleDelayedReminder(
      id: NotificationService.generateGoalNotificationId(goal.id, offset: 10),
      title: '⏰ 别忘了！',
      body: goal.title,
      delayMinutes: 5,
      payload: NotificationService.createPayload('goal', goal.id),
    );
  }

  /// 安排未点击通知的自动重复提醒
  Future<void> scheduleAutoReminder(Goal goal) async {
    await _notificationService.scheduleDelayedReminder(
      id: NotificationService.generateGoalNotificationId(goal.id, offset: 20),
      title: '🔔 还在等什么？',
      body: '${goal.title} - 点击开始',
      delayMinutes: 5,
      payload: NotificationService.createPayload('goal', goal.id),
    );
  }

  /// 为所有活跃目标设置提醒
  Future<void> scheduleAllGoalReminders(List<Goal> goals) async {
    for (final goal in goals) {
      if (goal.status == GoalStatus.active) {
        await scheduleGoalReminders(goal);
      }
    }
  }

  /// 取消所有目标提醒
  Future<void> cancelAllReminders() async {
    await _notificationService.cancelAllNotifications();
  }
}

