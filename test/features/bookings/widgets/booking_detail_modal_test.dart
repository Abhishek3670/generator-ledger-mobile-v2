import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ledger/core/providers/notification_provider.dart';
import 'package:ledger/core/services/booking_reminder_service.dart';
import 'package:ledger/core/services/notification_service.dart';
import 'package:ledger/core/services/user_preferences_service.dart';
import 'package:ledger/features/bookings/modals/booking_detail_modal.dart';
import 'package:ledger/shared/models/booking.dart';
import 'package:ledger/shared/models/reminder_offset.dart';

class FakeNotificationService implements NotificationService {
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
  }) async => true;

  @override
  Future<void> cancelNotification(int id) async {}

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
    vendorName: 'Aangan Dhaba',
    generatorId: 'GEN-100KVA-02',
    capacity: '100 kVA',
    date: DateTime(2026, 4, 24),
    status: 'Confirmed',
    notes: 'Main Stage',
    items: [
      BookingItem(
        generatorId: 'GEN-100KVA-02',
        capacityKva: 100,
        startDt: '2026-04-24',
        endDt: '2026-04-24',
        itemStatus: 'Confirmed',
        isEmergency: false,
        remarks: 'Main Stage',
      ),
    ],
  );

  testWidgets('renders BookingDetailModal on narrow screen (360x800) without overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
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

    // Verify vendor title and details
    expect(find.text('Aangan Dhaba'), findsOneWidget);
    expect(find.text('STATUS: '), findsOneWidget);
    expect(find.text('Confirmed'), findsNWidgets(2)); // Status badge in grid & table
    expect(find.text('BOOKED: '), findsOneWidget);
    expect(find.text('2026-04-24'), findsNWidgets(2)); // Booked date & table date
    expect(find.text('GEN-100KVA-02'), findsOneWidget);

    // Ensure no overflow errors occurred
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders BookingDetailModal on small screen (320x640) without overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
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

    expect(find.text('Aangan Dhaba'), findsOneWidget);
    expect(find.text('STATUS: '), findsOneWidget);
    expect(find.text('BOOKED: '), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
