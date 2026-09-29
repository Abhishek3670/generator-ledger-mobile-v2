import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ledger/core/providers/booking_provider.dart';
import 'package:ledger/core/providers/notification_provider.dart';
import 'package:ledger/core/services/booking_reminder_service.dart';
import 'package:ledger/core/services/notification_service.dart';
import 'package:ledger/data/repositories/booking_repository.dart';
import 'package:ledger/shared/models/booking.dart';
import 'package:ledger/shared/models/calendar_event.dart';
import 'package:ledger/shared/models/reminder_offset.dart';

class FakeNotificationService extends NotificationService {
  final List<ScheduledRecord> scheduled = [];
  final List<int> cancelled = [];

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
    scheduled.add(ScheduledRecord(
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
    cancelled.add(id);
  }

  @override
  Future<void> cancelAllNotifications() async {
    cancelled.clear();
    scheduled.clear();
  }
}

class ScheduledRecord {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;
  final String? payload;

  ScheduledRecord({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    this.payload,
  });
}

class MockBookingRepository extends BookingRepository {
  final List<Booking> bookings = [];
  final List<String> deletedIds = [];

  @override
  Future<List<Booking>> getBookings({
    DateTime? startDate,
    DateTime? endDate,
    String? vendorId,
    String? status,
  }) async {
    return List.from(bookings);
  }

  @override
  Future<Booking> createBooking(Booking booking) async {
    bookings.add(booking);
    return booking;
  }

  @override
  Future<Booking> updateBooking(String id, Booking booking) async {
    final index = bookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      bookings[index] = booking;
    }
    return booking;
  }

  @override
  Future<void> deleteBooking(String id) async {
    deletedIds.add(id);
    bookings.removeWhere((b) => b.id == id);
  }

  @override
  Future<Map<String, List<Booking>>> getAllVendorBookings() async => {};

  @override
  Future<List<CalendarEvent>> getCalendarEvents() async => [];

  @override
  Future<List<Booking>> getCalendarDayBookings(String date) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WO-103: Booking Lifecycle Reminder Integration Tests', () {
    late FakeNotificationService notificationService;
    late SharedPreferences prefs;
    late BookingReminderService reminderService;
    late MockBookingRepository mockRepository;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      notificationService = FakeNotificationService();
      reminderService = BookingReminderService(notificationService, prefs);
      mockRepository = MockBookingRepository();

      container = ProviderContainer(
        overrides: [
          bookingRepositoryProvider.overrideWithValue(mockRepository),
          notificationServiceProvider.overrideWithValue(notificationService),
          bookingReminderServiceProvider.overrideWithValue(reminderService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Scenario 1: create-with-reminder schedules OS notification and persists preference', () async {
      final notifier = container.read(bookingProvider.notifier);
      final bookingDate = DateTime.now().add(const Duration(days: 4));
      final booking = Booking(
        id: 'BK-CREATE-1',
        vendorId: 'V-101',
        vendorName: 'Apex Generators',
        generatorId: 'GEN-50',
        capacity: '50 kVA',
        date: bookingDate,
        status: 'confirmed',
        reminderOffset: ReminderOffset.oneDay,
      );

      await notifier.addBooking(booking);

      // Yield for unawaited fire-and-forget task
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Verify booking added to repo
      expect(mockRepository.bookings.any((b) => b.id == 'BK-CREATE-1'), isTrue);

      // Verify notification scheduled
      expect(notificationService.scheduled.any((s) => s.id == 'BK-CREATE-1'.hashCode), isTrue);

      // Verify preference saved in SharedPreferences
      expect(reminderService.getReminder('BK-CREATE-1'), ReminderOffset.oneDay);
    });

    test('Scenario 2: reschedule-updates-reminder auto-adjusts notification on date change', () async {
      final notifier = container.read(bookingProvider.notifier);
      final initialDate = DateTime.now().add(const Duration(days: 3));
      final booking = Booking(
        id: 'BK-RESCHED-1',
        vendorId: 'V-102',
        vendorName: 'Beacon Power',
        generatorId: 'GEN-100',
        capacity: '100 kVA',
        date: initialDate,
        status: 'confirmed',
        reminderOffset: ReminderOffset.threeHours,
      );

      await notifier.addBooking(booking);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(reminderService.getReminder('BK-RESCHED-1'), ReminderOffset.threeHours);

      // Update booking with a new date (7 days from now)
      final newDate = DateTime.now().add(const Duration(days: 7));
      final updatedBooking = booking.copyWith(date: newDate);

      await notifier.updateBooking(updatedBooking);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Notification must be cancelled and rescheduled
      expect(notificationService.cancelled, contains('BK-RESCHED-1'.hashCode));
      expect(
        notificationService.scheduled.any((s) => s.id == 'BK-RESCHED-1'.hashCode),
        isTrue,
      );

      final rescheduled = notificationService.scheduled.lastWhere((s) => s.id == 'BK-RESCHED-1'.hashCode);
      final expectedTrigger = newDate.subtract(const Duration(hours: 3));
      expect(rescheduled.scheduledDate.millisecondsSinceEpoch, expectedTrigger.millisecondsSinceEpoch);
    });

    test('Scenario 3: cancel-removes-reminder cancels notification immediately, then clears storage upon permanent delete', () async {
      final notifier = container.read(bookingProvider.notifier);
      final bookingDate = DateTime.now().add(const Duration(days: 5));
      final booking = Booking(
        id: 'BK-DEL-1',
        vendorId: 'V-103',
        vendorName: 'Volt Logistics',
        generatorId: 'GEN-250',
        capacity: '250 kVA',
        date: bookingDate,
        status: 'confirmed',
        reminderOffset: ReminderOffset.twoDays,
      );

      await notifier.addBooking(booking);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(reminderService.getReminder('BK-DEL-1'), ReminderOffset.twoDays);

      // Delete booking
      await notifier.deleteBooking('BK-DEL-1');

      // Crucial: OS notification cancelled IMMEDIATELY BEFORE the 5s timer
      expect(notificationService.cancelled, contains('BK-DEL-1'.hashCode));

      // Storage should still exist during the 5s undo window
      expect(reminderService.getReminder('BK-DEL-1'), ReminderOffset.twoDays);

      // Wait 6 seconds for permanent delete timer
      await Future<void>.delayed(const Duration(seconds: 6));

      // Now backend delete has executed and stored reminder preference is permanently cleared
      expect(mockRepository.deletedIds, contains('BK-DEL-1'));
      expect(reminderService.getReminder('BK-DEL-1'), isNull);
    });

    test('Scenario 4: undo-restores-reminder re-schedules notification with original offset', () async {
      final notifier = container.read(bookingProvider.notifier);
      final bookingDate = DateTime.now().add(const Duration(days: 10));
      final booking = Booking(
        id: 'BK-UNDO-1',
        vendorId: 'V-104',
        vendorName: 'Titan Energy',
        generatorId: 'GEN-500',
        capacity: '500 kVA',
        date: bookingDate,
        status: 'confirmed',
        reminderOffset: ReminderOffset.oneWeek,
      );

      await notifier.addBooking(booking);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Soft delete booking
      await notifier.deleteBooking('BK-UNDO-1');
      expect(notificationService.cancelled, contains('BK-UNDO-1'.hashCode));

      // Undo deletion within the 5s window
      notifier.undoDeleteBooking();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Verify booking restored in state
      expect(container.read(bookingProvider).value?.any((b) => b.id == 'BK-UNDO-1'), isTrue);

      // Verify reminder notification was re-scheduled with original offset
      final restoredScheduled = notificationService.scheduled.lastWhere((s) => s.id == 'BK-UNDO-1'.hashCode);
      expect(restoredScheduled.title, 'Booking Reminder — Titan Energy');

      final expectedTrigger = bookingDate.subtract(const Duration(days: 7));
      expect(restoredScheduled.scheduledDate.millisecondsSinceEpoch, expectedTrigger.millisecondsSinceEpoch);

      // Storage remains preserved
      expect(reminderService.getReminder('BK-UNDO-1'), ReminderOffset.oneWeek);
    });
  });

  group('WO-104: Global Multi-Trigger Lifecycle Integration Tests', () {
    late FakeNotificationService notificationService;
    late SharedPreferences prefs;
    late BookingReminderService reminderService;
    late MockBookingRepository mockRepository;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      notificationService = FakeNotificationService();
      reminderService = BookingReminderService(notificationService, prefs);
      mockRepository = MockBookingRepository();

      container = ProviderContainer(
        overrides: [
          bookingRepositoryProvider.overrideWithValue(mockRepository),
          notificationServiceProvider.overrideWithValue(notificationService),
          bookingReminderServiceProvider.overrideWithValue(reminderService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('addBooking automatically schedules multi-trigger alarms based on global settings', () async {
      // Configure global settings: 1 hour and 1 day before
      await reminderService.saveGlobalSettings(const GlobalReminderSettings(
        enabled: true,
        selectedOffsets: {ReminderOffset.oneHour, ReminderOffset.oneDay},
      ));

      final notifier = container.read(bookingProvider.notifier);
      final bookingDate = DateTime.now().add(const Duration(days: 4));
      final booking = Booking(
        id: 'BK-GLOBAL-1',
        vendorId: 'V-201',
        vendorName: 'Solaris Power',
        generatorId: 'GEN-75',
        capacity: '75 kVA',
        date: bookingDate,
        status: 'confirmed',
      );

      await notifier.addBooking(booking);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final id1Day = BookingReminderService.getNotificationId('BK-GLOBAL-1', ReminderOffset.oneDay);
      final id1Hour = BookingReminderService.getNotificationId('BK-GLOBAL-1', ReminderOffset.oneHour);

      expect(notificationService.scheduled.any((s) => s.id == id1Day), isTrue);
      expect(notificationService.scheduled.any((s) => s.id == id1Hour), isTrue);

      final call = notificationService.scheduled.firstWhere((s) => s.id == id1Day);
      final formattedDate = DateFormat('MMM dd, yyyy').format(bookingDate);
      expect(call.title, 'Booking Reminder (1 day before) — Solaris Power');
      expect(call.body, 'Upcoming 24hr booking for Solaris Power starts on $formattedDate.');
    });

    test('updateBooking with date change re-schedules global multi-trigger alarms', () async {
      await reminderService.saveGlobalSettings(const GlobalReminderSettings(
        enabled: true,
        selectedOffsets: {ReminderOffset.oneDay},
      ));

      final notifier = container.read(bookingProvider.notifier);
      final initialDate = DateTime.now().add(const Duration(days: 3));
      final booking = Booking(
        id: 'BK-GLOBAL-2',
        vendorId: 'V-202',
        vendorName: 'Prime Generators',
        generatorId: 'GEN-200',
        capacity: '200 kVA',
        date: initialDate,
        status: 'confirmed',
      );

      await notifier.addBooking(booking);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final oldId = BookingReminderService.getNotificationId('BK-GLOBAL-2', ReminderOffset.oneDay);
      expect(notificationService.scheduled.any((s) => s.id == oldId), isTrue);

      // Reschedule date to 6 days in future
      final newDate = DateTime.now().add(const Duration(days: 6));
      await notifier.updateBooking(booking.copyWith(date: newDate));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(notificationService.cancelled, contains(oldId));

      final newCall = notificationService.scheduled.lastWhere((s) => s.id == oldId);
      final expectedTrigger = newDate.subtract(const Duration(days: 1));
      expect(newCall.scheduledDate.millisecondsSinceEpoch, expectedTrigger.millisecondsSinceEpoch);
    });

    test('deleteBooking immediately cancels all multi-trigger alarms', () async {
      await reminderService.saveGlobalSettings(const GlobalReminderSettings(
        enabled: true,
        selectedOffsets: {ReminderOffset.oneHour, ReminderOffset.oneDay},
      ));

      final notifier = container.read(bookingProvider.notifier);
      final booking = Booking(
        id: 'BK-GLOBAL-DEL',
        vendorId: 'V-203',
        vendorName: 'Delta Gensets',
        generatorId: 'GEN-500',
        capacity: '500 kVA',
        date: DateTime.now().add(const Duration(days: 5)),
        status: 'confirmed',
      );

      await notifier.addBooking(booking);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await notifier.deleteBooking('BK-GLOBAL-DEL');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final id1Day = BookingReminderService.getNotificationId('BK-GLOBAL-DEL', ReminderOffset.oneDay);
      final id1Hour = BookingReminderService.getNotificationId('BK-GLOBAL-DEL', ReminderOffset.oneHour);

      expect(notificationService.cancelled, contains(id1Day));
      expect(notificationService.cancelled, contains(id1Hour));
    });

    test('undoDeleteBooking restores multi-trigger alarms for the restored booking', () async {
      await reminderService.saveGlobalSettings(const GlobalReminderSettings(
        enabled: true,
        selectedOffsets: {ReminderOffset.oneDay},
      ));

      final notifier = container.read(bookingProvider.notifier);
      final booking = Booking(
        id: 'BK-GLOBAL-UNDO',
        vendorId: 'V-204',
        vendorName: 'Echo Power',
        generatorId: 'GEN-100',
        capacity: '100 kVA',
        date: DateTime.now().add(const Duration(days: 5)),
        status: 'confirmed',
      );

      await notifier.addBooking(booking);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await notifier.deleteBooking('BK-GLOBAL-UNDO');
      notifier.undoDeleteBooking();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final id1Day = BookingReminderService.getNotificationId('BK-GLOBAL-UNDO', ReminderOffset.oneDay);
      expect(notificationService.scheduled.any((s) => s.id == id1Day), isTrue);
    });
  });
}
