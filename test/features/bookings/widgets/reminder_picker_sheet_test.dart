import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ledger/core/providers/notification_provider.dart';
import 'package:ledger/core/services/booking_reminder_service.dart';
import 'package:ledger/core/services/notification_service.dart';
import 'package:ledger/core/services/user_preferences_service.dart';
import 'package:ledger/features/bookings/widgets/reminder_picker_sheet.dart';
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
  Future<void> cancelAllNotifications() async {}

  @override
  Future<bool> requestPermissions() async => true;
}

void main() {
  late SharedPreferences prefs;
  late FakeNotificationService fakeNotifications;
  late BookingReminderService reminderService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeNotifications = FakeNotificationService();
    reminderService = BookingReminderService(fakeNotifications, prefs);
  });

  List<Override> getOverrides() {
    return [
      sharedPreferencesProvider.overrideWithValue(prefs),
      notificationServiceProvider.overrideWithValue(fakeNotifications),
      bookingReminderServiceProvider.overrideWithValue(reminderService),
    ];
  }

  testWidgets('ReminderPickerSheet renders header, all options, and SET REMINDER button', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: getOverrides(),
        child: MaterialApp(
          home: Scaffold(
            body: ReminderPickerSheet(
              bookingId: 'BK-100',
              bookingDate: DateTime.now().add(const Duration(days: 5)),
              vendorName: 'Acme Power',
              onClose: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('REMINDERS'), findsOneWidget);
    expect(find.text('Set Reminder'), findsOneWidget);
    expect(find.text('NOTIFICATION TIMING'), findsOneWidget);
    expect(find.text('No Reminder'), findsOneWidget);
    expect(find.text('30 minutes before'), findsOneWidget);
    expect(find.text('1 hour before'), findsOneWidget);
    expect(find.text('3 hours before'), findsOneWidget);
    expect(find.text('1 day before'), findsOneWidget);
    expect(find.text('2 days before'), findsOneWidget);
    expect(find.text('1 week before'), findsOneWidget);
    expect(find.text('SET REMINDER'), findsOneWidget);
  });

  testWidgets('ReminderPickerSheet pre-selects initialOffset option', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: getOverrides(),
        child: MaterialApp(
          home: Scaffold(
            body: ReminderPickerSheet(
              bookingId: 'BK-100',
              bookingDate: DateTime.now().add(const Duration(days: 5)),
              vendorName: 'Acme Power',
              initialOffset: ReminderOffset.oneHour,
              onClose: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify option container exists with selection
    final oneHourOption = find.byKey(const Key('reminder-option-oneHour'));
    expect(oneHourOption, findsOneWidget);
  });

  testWidgets('Selecting an offset and pressing SET REMINDER saves reminder', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    ReminderOffset? savedOffset;
    bool closed = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: getOverrides(),
        child: MaterialApp(
          home: Scaffold(
            body: ReminderPickerSheet(
              bookingId: 'BK-100',
              bookingDate: DateTime.now().add(const Duration(days: 3)),
              vendorName: 'Acme Power',
              initialOffset: ReminderOffset.none,
              onReminderSaved: (offset) => savedOffset = offset,
              onClose: () => closed = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap 3 hours before
    await tester.tap(find.byKey(const Key('reminder-option-threeHours')));
    await tester.pumpAndSettle();

    // Tap SET REMINDER
    await tester.tap(find.byKey(const Key('reminder-set-button')));
    await tester.pumpAndSettle();

    expect(savedOffset, equals(ReminderOffset.threeHours));
    expect(closed, isTrue);
    expect(fakeNotifications.scheduled, isNotEmpty);
    expect(fakeNotifications.scheduled.first['payload'], equals('BK-100'));
  });

  testWidgets('Selecting No Reminder cancels the active reminder', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Pre-save reminder
    await reminderService.setReminder(
      'BK-200',
      DateTime.now().add(const Duration(days: 2)),
      ReminderOffset.oneDay,
    );
    expect(reminderService.getReminder('BK-200'), equals(ReminderOffset.oneDay));

    ReminderOffset? savedOffset;
    bool closed = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: getOverrides(),
        child: MaterialApp(
          home: Scaffold(
            body: ReminderPickerSheet(
              bookingId: 'BK-200',
              bookingDate: DateTime.now().add(const Duration(days: 2)),
              initialOffset: ReminderOffset.oneDay,
              onReminderSaved: (offset) => savedOffset = offset,
              onClose: () => closed = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap No Reminder
    await tester.tap(find.byKey(const Key('reminder-option-none')));
    await tester.pumpAndSettle();

    // Tap SET REMINDER
    await tester.tap(find.byKey(const Key('reminder-set-button')));
    await tester.pumpAndSettle();

    expect(savedOffset, equals(ReminderOffset.none));
    expect(closed, isTrue);
    expect(reminderService.getReminder('BK-200'), isNull);
  });

  testWidgets('Selecting an offset with scheduled date in past warns and does not schedule', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Booking is in 10 minutes, but offset is 1 hour before -> past trigger time
    final nearDate = DateTime.now().add(const Duration(minutes: 10));

    ReminderOffset? savedOffset;
    bool closed = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: getOverrides(),
        child: MaterialApp(
          home: Scaffold(
            body: ReminderPickerSheet(
              bookingId: 'BK-300',
              bookingDate: nearDate,
              initialOffset: ReminderOffset.none,
              onReminderSaved: (offset) => savedOffset = offset,
              onClose: () => closed = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap 1 hour before
    await tester.tap(find.byKey(const Key('reminder-option-oneHour')));
    await tester.pumpAndSettle();

    // Tap SET REMINDER
    await tester.tap(find.byKey(const Key('reminder-set-button')));
    await tester.pumpAndSettle();

    // Should NOT have saved or closed
    expect(savedOffset, isNull);
    expect(closed, isFalse);
    expect(fakeNotifications.scheduled, isEmpty);
  });

  testWidgets('ReminderPickerSheet.show helper displays modal sheet', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: getOverrides(),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ReminderPickerSheet.show(
                    context: context,
                    bookingId: 'BK-400',
                    bookingDate: DateTime.now().add(const Duration(days: 4)),
                  );
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    expect(find.text('Set Reminder'), findsOneWidget);
    expect(find.text('SET REMINDER'), findsOneWidget);
  });
}
