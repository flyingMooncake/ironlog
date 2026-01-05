import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      linux: linuxSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions on iOS
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - could navigate to workout screen
  }

  Future<void> scheduleRestTimerNotification({
    required int seconds,
    String? exerciseName,
  }) async {
    await initialize();

    // Cancel any existing rest timer notification
    await cancelRestTimerNotification();

    final scheduledDate = DateTime.now().add(Duration(seconds: seconds));

    final androidDetails = AndroidNotificationDetails(
      'rest_timer',
      'Rest Timer',
      channelDescription: 'Notifications for rest timer completion',
      importance: Importance.high,
      priority: Priority.high,
      sound: const RawResourceAndroidNotificationSound('rest_complete'),
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    );

    const iosDetails = DarwinNotificationDetails(
      sound: 'rest_complete.aiff',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final body = exerciseName != null
        ? 'Rest complete! Ready for your next set of $exerciseName'
        : 'Rest complete! Ready for your next set';

    try {
      await _notifications.zonedSchedule(
        0, // notification id for rest timer
        'Rest Timer Complete',
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      // Fallback to simple notification if timezone not configured
      await _notifications.show(
        0,
        'Rest Timer Complete',
        body,
        details,
      );
    }
  }

  Future<void> cancelRestTimerNotification() async {
    await _notifications.cancel(0);
  }

  Future<void> showWorkoutSavedNotification() async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'workout_state',
      'Workout State',
      channelDescription: 'Notifications for workout state changes',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1, // notification id for workout state
      'Workout Saved',
      'Your workout progress has been saved',
      details,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
