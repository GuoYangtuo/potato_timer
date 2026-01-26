import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // 通知点击回调
  Function(String? payload)? onNotificationTap;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        onNotificationTap?.call(response.payload);
      },
    );

    // 请求权限
    if (Platform.isAndroid) {
      await _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  /// 立即显示通知
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'potato_timer_channel',
      '土豆时钟提醒',
      channelDescription: '目标提醒通知',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// 安排定时通知（使用zonedSchedule确保进程被杀死后仍能提醒）
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'potato_timer_channel',
      '土豆时钟提醒',
      channelDescription: '目标提醒通知',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// 安排每日重复通知
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'potato_timer_daily_channel',
      '土豆时钟每日提醒',
      channelDescription: '每日目标提醒通知',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 计算下一个提醒时间
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  /// 安排推迟提醒（5分钟后）
  Future<void> scheduleDelayedReminder({
    required int id,
    required String title,
    required String body,
    int delayMinutes = 5,
    String? payload,
  }) async {
    final scheduledTime = DateTime.now().add(Duration(minutes: delayMinutes));
    await scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      payload: payload,
    );
  }

  /// 取消指定通知
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// 获取待处理的通知
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// 生成目标相关的通知ID
  /// 为了避免ID冲突，使用目标ID * 100 + 偏移量
  static int generateGoalNotificationId(int goalId, {int offset = 0}) {
    return goalId * 100 + offset;
  }

  /// 解析通知payload
  static Map<String, dynamic>? parsePayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final parts = payload.split(':');
      if (parts.length >= 2) {
        return {
          'type': parts[0],
          'goalId': int.tryParse(parts[1]),
        };
      }
    } catch (e) {
      // 解析失败
    }
    return null;
  }

  /// 创建通知payload
  static String createPayload(String type, int goalId) {
    return '$type:$goalId';
  }
}


