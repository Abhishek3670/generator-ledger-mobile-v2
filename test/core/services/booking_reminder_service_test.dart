import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ledger/core/services/booking_reminder_service.dart';
import 'package:ledger/core/services/notification_service.dart';
import 'package:ledger/shared/models/reminder_offset.dart';

class FakeNotificationService extends NotificationService {
  final List<ScheduledCall> scheduledCalls = [];
  final List<int> cancelledIds = [];
  bool shouldSucceed = true;

  @override
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
    if (!shouldSucceed) return false;

    scheduledCalls.add(ScheduledCall(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
    ));
    return true;
  }

  @override
  Future<void> cancelNotification(int id) async {
    cancelledIds.add(id);
  }
}

class ScheduledCall {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;
  final String? payload;

  ScheduledCall({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    this.payload,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BookingReminderService Tests', () {
    late FakeNotificationService notificationService;
    late SharedPreferences prefs;
    late BookingReminderService reminderService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      notificationService = FakeNotificationService();
      reminderService = BookingReminderService(notificationService, prefs);
    });

    test('setReminder schedules notification with correct content and persists to SharedPreferences', () async {
      const bookingId = 'BK-1001';
      final futureDate = DateTime.now().add(const Duration(days: 3));
      const offset = ReminderOffset.oneDay;

      final success = await reminderService.setReminder(
        bookingId,
        futureDate,
        offset,
        vendorName: 'Apex Generators',
      );

      expect(success, isTrue);
      expect(notificationService.scheduledCalls.length, 1);

      final call = notificationService.scheduledCalls.first;
      expect(call.id, bookingId.hashCode);
      expect(call.title, 'Booking Reminder — Apex Generators');
      expect(call.body, contains('Upcoming booking for Apex Generators on'));
      expect(call.payload, bookingId);

      // Verify scheduled date is exactly futureDate - 1 day
      final expectedDate = futureDate.subtract(const Duration(days: 1));
      expect(call.scheduledDate.millisecondsSinceEpoch, expectedDate.millisecondsSinceEpoch);

      // Verify persistence with reminder_{bookingId} key
      final storedRaw = prefs.getString('reminder_$bookingId');
      expect(storedRaw, isNotNull);
      final storedData = jsonDecode(storedRaw!) as Map<String, dynamic>;
      expect(storedData['offset'], 'oneDay');
      expect(storedData['vendorName'], 'Apex Generators');

      // Verify getReminder reads back the offset
      expect(reminderService.getReminder(bookingId), ReminderOffset.oneDay);
    });

    test('setReminder falls back to "Vendor" when vendorName is omitted or empty', () async {
      const bookingId = 'BK-1002';
      final futureDate = DateTime.now().add(const Duration(days: 2));

      await reminderService.setReminder(
        bookingId,
        futureDate,
        ReminderOffset.oneHour,
      );

      final call = notificationService.scheduledCalls.first;
      expect(call.title, 'Booking Reminder — Vendor');
      expect(call.body, contains('Upcoming booking for Vendor on'));
    });

    test('setReminder returns false and does not schedule when trigger date is in the past', () async {
      const bookingId = 'BK-PAST';
      // Booking is 10 minutes in the future, but reminder offset is 1 hour before
      final closeDate = DateTime.now().add(const Duration(minutes: 10));

      final success = await reminderService.setReminder(
        bookingId,
        closeDate,
        ReminderOffset.oneHour,
      );

      expect(success, isFalse);
      expect(notificationService.scheduledCalls, isEmpty);
      expect(prefs.containsKey('reminder_$bookingId'), isFalse);
      expect(reminderService.getReminder(bookingId), isNull);
    });

    test('setting ReminderOffset.none cancels any existing reminder and clears storage', () async {
      const bookingId = 'BK-NONE';
      final futureDate = DateTime.now().add(const Duration(days: 5));

      // First set a valid reminder
      await reminderService.setReminder(
        bookingId,
        futureDate,
        ReminderOffset.thirtyMin,
      );
      expect(reminderService.getReminder(bookingId), ReminderOffset.thirtyMin);

      // Now set to none
      final success = await reminderService.setReminder(
        bookingId,
        futureDate,
        ReminderOffset.none,
      );

      expect(success, isTrue);
      expect(notificationService.cancelledIds, contains(bookingId.hashCode));
      expect(prefs.containsKey('reminder_$bookingId'), isFalse);
      expect(reminderService.getReminder(bookingId), isNull);
    });

    test('cancelReminder cancels notification and clears storage by default', () async {
      const bookingId = 'BK-CANCEL';
      final futureDate = DateTime.now().add(const Duration(days: 4));

      await reminderService.setReminder(
        bookingId,
        futureDate,
        ReminderOffset.twoDays,
      );

      await reminderService.cancelReminder(bookingId);

      expect(notificationService.cancelledIds, contains(bookingId.hashCode));
      expect(prefs.containsKey('reminder_$bookingId'), isFalse);
      expect(reminderService.getReminder(bookingId), isNull);
    });

    test('cancelNotificationOnly cancels OS notification but preserves storage for undo', () async {
      const bookingId = 'BK-UNDO';
      final futureDate = DateTime.now().add(const Duration(days: 4));

      await reminderService.setReminder(
        bookingId,
        futureDate,
        ReminderOffset.twoDays,
        vendorName: 'Delta Power',
      );

      await reminderService.cancelNotificationOnly(bookingId);

      expect(notificationService.cancelledIds, contains(bookingId.hashCode));
      // Storage must still be intact for undoDeleteBooking
      expect(reminderService.getReminder(bookingId), ReminderOffset.twoDays);
      final data = reminderService.getReminderData(bookingId);
      expect(data?['vendorName'], 'Delta Power');
    });

    test('rescheduleForBooking adjusts reminder to new start date', () async {
      const bookingId = 'BK-RESCHED';
      final initialDate = DateTime.now().add(const Duration(days: 3));
      final newDate = DateTime.now().add(const Duration(days: 10));

      await reminderService.setReminder(
        bookingId,
        initialDate,
        ReminderOffset.oneDay,
        vendorName: 'Omega Gensets',
      );

      final success = await reminderService.rescheduleForBooking(bookingId, newDate);

      expect(success, isTrue);
      expect(notificationService.cancelledIds, contains(bookingId.hashCode));
      expect(notificationService.scheduledCalls.length, 2);

      final newCall = notificationService.scheduledCalls.last;
      expect(newCall.id, bookingId.hashCode);
      expect(newCall.title, 'Booking Reminder — Omega Gensets');
      final expectedDate = newDate.subtract(const Duration(days: 1));
      expect(newCall.scheduledDate.millisecondsSinceEpoch, expectedDate.millisecondsSinceEpoch);
    });

    test('rescheduleForBooking returns false if booking has no prior reminder', () async {
      final success = await reminderService.rescheduleForBooking(
        'NON_EXISTENT',
        DateTime.now().add(const Duration(days: 2)),
      );
      expect(success, isFalse);
    });

    test('getReminder gracefully parses legacy plain text offset values', () async {
      await prefs.setString('reminder_LEGACY', 'threeHours');
      expect(reminderService.getReminder('LEGACY'), ReminderOffset.threeHours);
    });
  });
}
