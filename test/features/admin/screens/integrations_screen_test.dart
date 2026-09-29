import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ledger/core/providers/booking_provider.dart';
import 'package:ledger/core/providers/notification_provider.dart';
import 'package:ledger/core/services/booking_reminder_service.dart';
import 'package:ledger/core/services/notification_service.dart';
import 'package:ledger/core/services/user_preferences_service.dart';
import 'package:ledger/data/repositories/booking_repository.dart';
import 'package:ledger/features/admin/screens/integrations_screen.dart';
import 'package:ledger/shared/models/booking.dart';
import 'package:ledger/shared/models/calendar_event.dart';
import 'package:ledger/shared/models/reminder_offset.dart';

class FakeNotificationService implements NotificationService {
  final List<Map<String, dynamic>> scheduled = [];
  final List<int> cancelled = [];

  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> scheduleNotification(
    int id,
    String title,
    String body,
    DateTime scheduledDate, {
    String? payload,
  }) async {
    scheduled.add({
      'id': id,
      'title': title,
      'body': body,
      'date': scheduledDate,
      'payload': payload,
    });
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

  @override
  Future<bool> requestPermissions() async => true;
}

class MockBookingRepository extends BookingRepository {
  MockBookingRepository([List<Booking>? initial])
      : bookings = List.of(initial ?? []);

  final List<Booking> bookings;

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
    final idx = bookings.indexWhere((b) => b.id == id);
    if (idx != -1) bookings[idx] = booking;
    return booking;
  }

  @override
  Future<void> deleteBooking(String id) async {
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

  late SharedPreferences prefs;
  late FakeNotificationService notificationService;
  late BookingReminderService reminderService;
  late MockBookingRepository mockRepository;

  final sampleBooking = Booking(
    id: 'BK-INT-1',
    vendorId: 'V-001',
    vendorName: 'Apex Generators',
    generatorId: 'GEN-250',
    capacity: '250 kVA',
    date: DateTime.now().add(const Duration(days: 3)),
    status: 'confirmed',
    notes: 'Hospital backup test',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    notificationService = FakeNotificationService();
    reminderService = BookingReminderService(notificationService, prefs);
    mockRepository = MockBookingRepository([sampleBooking]);
  });

  List<Override> createOverrides() {
    return [
      sharedPreferencesProvider.overrideWithValue(prefs),
      notificationServiceProvider.overrideWithValue(notificationService),
      bookingReminderServiceProvider.overrideWithValue(reminderService),
      bookingRepositoryProvider.overrideWithValue(mockRepository),
    ];
  }

  Widget buildTestScreen() {
    return ProviderScope(
      overrides: createOverrides(),
      child: const MaterialApp(
        home: Scaffold(
          body: IntegrationsScreen(),
        ),
      ),
    );
  }

  group('IntegrationsScreen: Layout & Initial State', () {
    testWidgets('renders header card, master switch, all 6 intervals, and info box', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      // Header card
      expect(find.text('INTEGRATIONS / SETTINGS'), findsOneWidget);
      expect(find.text('Booking Reminders'), findsOneWidget);
      expect(
        find.text('Configure automated reminders ahead of upcoming 24-hour generator bookings.'),
        findsOneWidget,
      );

      // Master switch card
      expect(find.text('Enable Booking Reminders'), findsOneWidget);
      expect(find.text('Active alerts for upcoming bookings'), findsOneWidget);
      final masterSwitchFinder = find.byKey(const Key('master-reminder-switch'));
      expect(masterSwitchFinder, findsOneWidget);
      final switchWidget = tester.widget<Switch>(masterSwitchFinder);
      expect(switchWidget.value, isTrue);

      // Section header
      expect(find.text('REMINDER INTERVALS (MULTI-SELECT)'), findsOneWidget);

      // 6 interval options and badges
      expect(find.text('30 minutes before'), findsOneWidget);
      expect(find.text('30m'), findsOneWidget);

      expect(find.text('1 hour before'), findsOneWidget);
      expect(find.text('1h'), findsOneWidget);

      expect(find.text('3 hours before'), findsOneWidget);
      expect(find.text('3h'), findsOneWidget);

      expect(find.text('1 day before (24 hours)'), findsOneWidget);
      expect(find.text('24h'), findsOneWidget);

      expect(find.text('2 days before (48 hours)'), findsOneWidget);
      expect(find.text('48h'), findsOneWidget);

      expect(find.text('1 week before (7 days)'), findsOneWidget);
      expect(find.text('7d'), findsOneWidget);

      // Default checkbox selection (only 1 day is selected by default)
      final checkbox24h = tester.widget<Checkbox>(
        find.byKey(const Key('interval-checkbox-oneDay')),
      );
      expect(checkbox24h.value, isTrue);

      final checkbox30m = tester.widget<Checkbox>(
        find.byKey(const Key('interval-checkbox-thirtyMin')),
      );
      expect(checkbox30m.value, isFalse);

      final checkbox1h = tester.widget<Checkbox>(
        find.byKey(const Key('interval-checkbox-oneHour')),
      );
      expect(checkbox1h.value, isFalse);

      final checkbox3h = tester.widget<Checkbox>(
        find.byKey(const Key('interval-checkbox-threeHours')),
      );
      expect(checkbox3h.value, isFalse);

      final checkbox2d = tester.widget<Checkbox>(
        find.byKey(const Key('interval-checkbox-twoDays')),
      );
      expect(checkbox2d.value, isFalse);

      final checkbox1w = tester.widget<Checkbox>(
        find.byKey(const Key('interval-checkbox-oneWeek')),
      );
      expect(checkbox1w.value, isFalse);

      // Informational container
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(
        find.textContaining('Reminders are scheduled automatically on your device'),
        findsOneWidget,
      );
    });
  });

  group('IntegrationsScreen: Master Switch Toggle', () {
    testWidgets('toggling master switch disables intervals and updates subtitle', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      final masterSwitchFinder = find.byKey(const Key('master-reminder-switch'));

      // Toggle off
      await tester.tap(masterSwitchFinder);
      await tester.pumpAndSettle();

      expect(find.text('All reminders disabled'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);

      final switchedOff = tester.widget<Switch>(masterSwitchFinder);
      expect(switchedOff.value, isFalse);

      // Checkboxes should have null onChanged when master is disabled
      final checkbox24h = tester.widget<Checkbox>(
        find.byKey(const Key('interval-checkbox-oneDay')),
      );
      expect(checkbox24h.onChanged, isNull);

      // Toggle back on
      await tester.tap(masterSwitchFinder);
      await tester.pumpAndSettle();

      expect(find.text('Active alerts for upcoming bookings'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_active), findsOneWidget);

      final switchedOn = tester.widget<Switch>(masterSwitchFinder);
      expect(switchedOn.value, isTrue);

      final checkbox24hRestored = tester.widget<Checkbox>(
        find.byKey(const Key('interval-checkbox-oneDay')),
      );
      expect(checkbox24hRestored.onChanged, isNotNull);
    });
  });

  group('IntegrationsScreen: Multi-Select Intervals', () {
    testWidgets('toggling interval checkboxes updates selected offsets and persists', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      // Check 1 hour before
      final checkbox1hFinder = find.byKey(const Key('interval-checkbox-oneHour'));
      await tester.tap(checkbox1hFinder);
      await tester.pumpAndSettle();

      final checkbox1h = tester.widget<Checkbox>(checkbox1hFinder);
      expect(checkbox1h.value, isTrue);

      // Verify persistence in SharedPreferences
      final savedSettings = reminderService.getGlobalSettings();
      expect(savedSettings.selectedOffsets.contains(ReminderOffset.oneHour), isTrue);
      expect(savedSettings.selectedOffsets.contains(ReminderOffset.oneDay), isTrue);

      // Uncheck 1 day before
      final checkbox24hFinder = find.byKey(const Key('interval-checkbox-oneDay'));
      await tester.tap(checkbox24hFinder);
      await tester.pumpAndSettle();

      final checkbox24h = tester.widget<Checkbox>(checkbox24hFinder);
      expect(checkbox24h.value, isFalse);

      final updatedSettings = reminderService.getGlobalSettings();
      expect(updatedSettings.selectedOffsets.contains(ReminderOffset.oneDay), isFalse);
      expect(updatedSettings.selectedOffsets.contains(ReminderOffset.oneHour), isTrue);

      // Check 30 minutes before
      final checkbox30mFinder = find.byKey(const Key('interval-checkbox-thirtyMin'));
      await tester.tap(checkbox30mFinder);
      await tester.pumpAndSettle();

      final checkbox30m = tester.widget<Checkbox>(checkbox30mFinder);
      expect(checkbox30m.value, isTrue);

      final multiSettings = reminderService.getGlobalSettings();
      expect(multiSettings.selectedOffsets.contains(ReminderOffset.thirtyMin), isTrue);
      expect(multiSettings.selectedOffsets.contains(ReminderOffset.oneHour), isTrue);
    });

    testWidgets('tapping row container toggles checkbox', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      // Tap on row with text "3 hours before"
      await tester.tap(find.text('3 hours before'));
      await tester.pumpAndSettle();

      final checkbox3h = tester.widget<Checkbox>(
        find.byKey(const Key('interval-checkbox-threeHours')),
      );
      expect(checkbox3h.value, isTrue);

      final saved = reminderService.getGlobalSettings();
      expect(saved.selectedOffsets.contains(ReminderOffset.threeHours), isTrue);
    });

    testWidgets('tapping interval when master switch is disabled does not toggle', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      // Disable master switch
      await tester.tap(find.byKey(const Key('master-reminder-switch')));
      await tester.pumpAndSettle();

      // Attempt to tap 1 hour interval
      await tester.tap(find.text('1 hour before'));
      await tester.pumpAndSettle();

      final checkbox1h = tester.widget<Checkbox>(
        find.byKey(const Key('interval-checkbox-oneHour')),
      );
      expect(checkbox1h.value, isFalse);

      final saved = reminderService.getGlobalSettings();
      expect(saved.selectedOffsets.contains(ReminderOffset.oneHour), isFalse);
    });
  });
}
