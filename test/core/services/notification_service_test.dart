import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/core/services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

class MockNotificationsPlugin implements FlutterLocalNotificationsPlugin {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  T? resolvePlatformSpecificImplementation<
      T extends FlutterLocalNotificationsPlatform>() =>
      null;

  AndroidScheduleMode? lastScheduleMode;
  int scheduleCallCount = 0;
  bool throwOnExact = false;
  bool throwOnInexact = false;
  int? cancelledId;
  bool allCancelled = false;

  @override
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    tz.TZDateTime scheduledDate,
    NotificationDetails? notificationDetails, {
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    scheduleCallCount++;
    lastScheduleMode = androidScheduleMode;
    if (androidScheduleMode == AndroidScheduleMode.exactAllowWhileIdle && throwOnExact) {
      throw Exception('SecurityException: Exact alarms not permitted');
    }
    if (androidScheduleMode == AndroidScheduleMode.inexactAllowWhileIdle && throwOnInexact) {
      throw Exception('Inexact scheduling failed');
    }
  }

  @override
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback? onDidReceiveBackgroundNotificationResponse,
  }) async {
    return true;
  }

  @override
  Future<void> cancel(int id, {String? tag}) async {
    cancelledId = id;
  }

  @override
  Future<void> cancelAll() async {
    allCancelled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService Tests', () {
    test('scheduleNotification returns false immediately if scheduledDate is in the past', () async {
      final service = NotificationService();
      final pastDate = DateTime.now().subtract(const Duration(minutes: 5));

      final result = await service.scheduleNotification(
        101,
        'Test Title',
        'Test Body',
        pastDate,
      );

      expect(result, isFalse);
    });

    test('isInitialized starts false before initialize call and true after', () async {
      final mockPlugin = MockNotificationsPlugin();
      final service = NotificationService(plugin: mockPlugin);
      expect(service.isInitialized, isFalse);

      await service.initialize();
      expect(service.isInitialized, isTrue);
    });

    test('schedules with exactAllowWhileIdle by default when supported', () async {
      final mockPlugin = MockNotificationsPlugin();
      final service = NotificationService(plugin: mockPlugin);
      final futureDate = DateTime.now().add(const Duration(hours: 2));

      final success = await service.scheduleNotification(
        201,
        'Exact Title',
        'Exact Body',
        futureDate,
      );

      expect(success, isTrue);
      expect(mockPlugin.scheduleCallCount, 1);
      expect(mockPlugin.lastScheduleMode, AndroidScheduleMode.exactAllowWhileIdle);
    });

    test('falls back gracefully to inexactAllowWhileIdle when exact scheduling throws', () async {
      final mockPlugin = MockNotificationsPlugin()..throwOnExact = true;
      final service = NotificationService(plugin: mockPlugin);
      final futureDate = DateTime.now().add(const Duration(hours: 5));

      final success = await service.scheduleNotification(
        202,
        'Fallback Title',
        'Fallback Body',
        futureDate,
      );

      expect(success, isTrue);
      expect(mockPlugin.scheduleCallCount, 2);
      expect(mockPlugin.lastScheduleMode, AndroidScheduleMode.inexactAllowWhileIdle);
    });

    test('returns false when both exact and inexact scheduling throw', () async {
      final mockPlugin = MockNotificationsPlugin()
        ..throwOnExact = true
        ..throwOnInexact = true;
      final service = NotificationService(plugin: mockPlugin);
      final futureDate = DateTime.now().add(const Duration(hours: 5));

      final success = await service.scheduleNotification(
        203,
        'Failure Title',
        'Failure Body',
        futureDate,
      );

      expect(success, isFalse);
      expect(mockPlugin.scheduleCallCount, 2);
    });

    test('cancelNotification delegates to plugin', () async {
      final mockPlugin = MockNotificationsPlugin();
      final service = NotificationService(plugin: mockPlugin);

      await service.cancelNotification(999);
      expect(mockPlugin.cancelledId, 999);
    });

    test('cancelAllNotifications delegates to plugin', () async {
      final mockPlugin = MockNotificationsPlugin();
      final service = NotificationService(plugin: mockPlugin);

      await service.cancelAllNotifications();
      expect(mockPlugin.allCancelled, isTrue);
    });
  });
}
