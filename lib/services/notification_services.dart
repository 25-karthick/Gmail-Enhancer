// lib/services/notification_services.dart
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static const String _channelId = 'reminder_channel';
  static const String _channelName = 'Reminders';
  static const String _channelDescription = 'Email reminder notifications';

  static Future<void> initialize() async {
    // Initialize time zones
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings =
    InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        print("🔔 Notification tapped: ${response.payload}");
      },
    );

    // Android setup
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      // Create a high-importance channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
      );

      await androidPlugin?.createNotificationChannel(channel);

      // ✅ Android 13+ Permission
      await androidPlugin?.requestNotificationsPermission();
    }

    print('✅ NotificationService initialized successfully');
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    tz.initializeTimeZones();

    final now = tz.TZDateTime.now(tz.local);
    final tzScheduled = tz.TZDateTime.from(scheduledTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const platformDetails =
    NotificationDetails(android: androidDetails, iOS: iosDetails);

    if (tzScheduled.isBefore(now)) {
      await _notifications.show(id, title, body, platformDetails);
      print('⚡ Notification shown immediately (past time)');
    } else {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduled,
        platformDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );
      print('⏰ Notification scheduled for: $tzScheduled');
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    print('🗑️ Notification (id:$id) cancelled');
  }
}
