import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service for managing local push notifications.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _isInitialized = false;
  bool _permissionsRequested = false;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  bool get isInitialized => _isInitialized;

  /// Initializes local notification settings.
  /// Note: iOS permissions are deliberately not requested here;
  /// they are requested lazily on first reminder set.
  Future<void> initialize() async {
    if (_isInitialized) return;

    _ensureTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(initSettings);
    _isInitialized = true;
  }

  /// Requests notification permissions on iOS and Android (API 33+).
  /// Called lazily when setting a reminder.
  Future<bool?> requestPermissions() async {
    _permissionsRequested = true;

    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      return await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      return await androidPlugin.requestNotificationsPermission();
    }

    return true;
  }

  /// Schedules a notification at [scheduledDate].
  /// Returns `false` if [scheduledDate] is in the past, or if scheduling fails.
  Future<bool> scheduleNotification(
    int id,
    String title,
    String body,
    DateTime scheduledDate, {
    String? payload,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) {
      return false;
    }

    _ensureTimeZones();

    if (!_permissionsRequested) {
      await requestPermissions();
    }

    const androidDetails = AndroidNotificationDetails(
      'booking_reminders',
      'Booking Reminders',
      channelDescription: 'Notifications for upcoming booking reminders',
      importance: Importance.max,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    tz.TZDateTime scheduledTz;
    try {
      scheduledTz = tz.TZDateTime.from(scheduledDate, tz.local);
    } catch (_) {
      _ensureTimeZones();
      try {
        scheduledTz = tz.TZDateTime.from(scheduledDate, tz.local);
      } catch (_) {
        scheduledTz = tz.TZDateTime.from(scheduledDate, tz.getLocation('UTC'));
      }
    }

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTz,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      return true;
    } catch (_) {
      // Graceful fallback: If exact alarm scheduling fails (e.g. SecurityException on Android 13/14+),
      // retry with inexact scheduling so reminders are never lost.
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduledTz,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
        );
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  /// Cancels a scheduled notification by its [id].
  Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }

  /// Cancels all scheduled notifications.
  Future<void> cancelAllNotifications() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  void _ensureTimeZones() {
    try {
      tz.initializeTimeZones();
    } catch (_) {}

    try {
      tz.local;
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }
  }
}
