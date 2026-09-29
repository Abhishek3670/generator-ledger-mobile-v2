import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ledger/core/providers/notification_provider.dart';
import 'package:ledger/core/services/booking_reminder_service.dart';
import 'package:ledger/core/services/notification_service.dart';
import 'package:ledger/core/services/user_preferences_service.dart';
import 'package:ledger/core/theme/app_colors.dart';
import 'package:ledger/features/bookings/modals/add_booking_modal.dart';
import 'package:ledger/features/bookings/modals/booking_detail_modal.dart';
import 'package:ledger/features/bookings/widgets/booking_list_item.dart';
import 'package:ledger/features/bookings/widgets/reminder_picker_sheet.dart';
import 'package:ledger/features/dashboard/widgets/compact_booking_row.dart';
import 'package:ledger/shared/models/booking.dart';
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

  final testBooking = Booking(
    id: 'BK-TEST-1',
    vendorId: 'V-001',
    vendorName: 'Apex Generators',
    generatorId: 'GEN-500',
    capacity: '500 kVA',
    date: DateTime.now().add(const Duration(days: 4)),
    status: 'confirmed',
    notes: 'Urgent setup',
  );

  group('BookingDetailModal Reminder Actions', () {
    testWidgets('shows notification_add_outlined icon when no reminder is active', (
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
              body: BookingDetailModal(
                booking: testBooking,
                onClose: () {},
                onEdit: () {},
                initialReminderOffset: ReminderOffset.none,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final reminderButton = find.byKey(const Key('booking-detail-reminder-button'));
      expect(reminderButton, findsOneWidget);

      final icon = tester.widget<Icon>(
        find.descendant(of: reminderButton, matching: find.byType(Icon)),
      );
      expect(icon.icon, equals(Icons.notification_add_outlined));
      expect(icon.color, equals(AppColors.textSecondary));

      final iconButton = tester.widget<IconButton>(reminderButton);
      expect(iconButton.tooltip, equals('Set Reminder'));
    });

    testWidgets('shows notifications_active amber icon when reminder is active', (
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
              body: BookingDetailModal(
                booking: testBooking,
                onClose: () {},
                onEdit: () {},
                initialReminderOffset: ReminderOffset.oneHour,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final reminderButton = find.byKey(const Key('booking-detail-reminder-button'));
      expect(reminderButton, findsOneWidget);

      final icon = tester.widget<Icon>(
        find.descendant(of: reminderButton, matching: find.byType(Icon)),
      );
      expect(icon.icon, equals(Icons.notifications_active));
      expect(icon.color, equals(AppColors.accent));

      final iconButton = tester.widget<IconButton>(reminderButton);
      expect(iconButton.tooltip, equals('Change Reminder'));
    });

    testWidgets('tapping bell icon opens ReminderPickerSheet', (
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
              body: BookingDetailModal(
                booking: testBooking,
                onClose: () {},
                onEdit: () {},
                initialReminderOffset: ReminderOffset.none,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ReminderPickerSheet), findsNothing);

      await tester.tap(find.byKey(const Key('booking-detail-reminder-button')));
      await tester.pumpAndSettle();

      expect(find.byType(ReminderPickerSheet), findsOneWidget);
      expect(find.text('Set Reminder'), findsOneWidget);
    });
  });

  group('AddBookingModal Reminder Selector', () {
    testWidgets('does not display REMINDER (Optional) dropdown selector', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: getOverrides(),
          child: MaterialApp(
            home: Scaffold(
              body: AddBookingModal(
                onClose: () {},
                onSave: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('REMINDER (Optional)'), findsNothing);
      expect(find.byKey(const Key('add-booking-reminder-selector')), findsNothing);
    });
  });

  group('BookingListItem Reminder Indicator', () {
    testWidgets('does not show bell indicator when hasReminder is false', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: getOverrides(),
          child: MaterialApp(
            home: Scaffold(
              body: BookingListItem(
                booking: testBooking,
                hasReminder: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_active), findsNothing);
    });

    testWidgets('shows small accent bell indicator when hasReminder is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: getOverrides(),
          child: MaterialApp(
            home: Scaffold(
              body: BookingListItem(
                booking: testBooking,
                hasReminder: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bellFinder = find.byIcon(Icons.notifications_active);
      expect(bellFinder, findsOneWidget);

      final icon = tester.widget<Icon>(bellFinder);
      expect(icon.size, equals(14));
      expect(icon.color, equals(AppColors.accent));
    });
  });

  group('CompactBookingRow Reminder Indicator', () {
    testWidgets('does not show bell indicator when hasReminder is false', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: getOverrides(),
          child: MaterialApp(
            home: Scaffold(
              body: CompactBookingRow(
                booking: testBooking,
                hasReminder: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_active), findsNothing);
    });

    testWidgets('shows subtle accent bell indicator when hasReminder is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: getOverrides(),
          child: MaterialApp(
            home: Scaffold(
              body: CompactBookingRow(
                booking: testBooking,
                hasReminder: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bellFinder = find.byIcon(Icons.notifications_active);
      expect(bellFinder, findsOneWidget);

      final icon = tester.widget<Icon>(bellFinder);
      expect(icon.size, equals(13));
      expect(icon.color, equals(AppColors.accent));
    });
  });
}
