import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ledger/core/providers/booking_provider.dart';
import 'package:ledger/core/providers/vendor_provider.dart';
import 'package:ledger/data/mock/mock_bookings.dart';
import 'package:ledger/data/mock/mock_vendors.dart';
import 'package:ledger/data/repositories/booking_repository.dart';
import 'package:ledger/shared/models/booking.dart';
import 'package:ledger/shared/models/calendar_event.dart';
import 'package:ledger/data/repositories/vendor_repository.dart';
import 'package:ledger/features/bookings/screens/bookings_directory_screen.dart';
import 'package:ledger/features/bookings/widgets/vendor_booking_group.dart';
import 'package:ledger/shared/widgets/floating_search_fab.dart';

void main() {
  testWidgets(
    'BookingsDirectoryScreen renders successfully with all elements and defaults to current month',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingRepositoryProvider.overrideWithValue(
              _FakeBookingRepository(),
            ),
            vendorRepositoryProvider.overrideWithValue(_FakeVendorRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: BookingsDirectoryScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Title & Header
      expect(find.text('DIRECTORY'), findsOneWidget);
      expect(find.text('Bookings by Vendor'), findsOneWidget);
      expect(
        find.text('Review active reservations and manage vendor schedules.'),
        findsOneWidget,
      );

      // Verify FloatingSearchFAB is active
      expect(find.byType(FloatingSearchFAB), findsOneWidget);

      // Verify Month Filter defaults to current month
      final currentMonthStr =
          DateFormat('MMMM yyyy').format(DateTime.now()).toUpperCase();
      expect(find.text(currentMonthStr), findsOneWidget);

      // Verify current month vendor groups render
      expect(find.byType(VendorBookingGroup), findsAtLeastNWidgets(1));
      expect(find.text('Global Rentals Ltd'), findsAtLeastNWidgets(1));

      // Verify vendors not in current month are filtered out
      expect(find.text('Abraar'), findsNothing);
    },
  );

  testWidgets(
    'BookingsDirectoryScreen toggles between current month and all months',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingRepositoryProvider.overrideWithValue(
              _FakeBookingRepository(),
            ),
            vendorRepositoryProvider.overrideWithValue(_FakeVendorRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: BookingsDirectoryScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially only current month is visible
      expect(find.text('Abraar'), findsNothing);

      // Tap "ALL" toggle
      final allButton = find.byKey(const ValueKey('btn_toggle_all_months'));
      expect(allButton, findsOneWidget);
      await tester.tap(allButton);
      await tester.pumpAndSettle();

      // Verify ALL MONTHS indicator and all vendors appear
      expect(find.text('ALL MONTHS'), findsOneWidget);
      expect(find.text('Abraar'), findsAtLeastNWidgets(1));
      expect(find.text('Ankit Singh'), findsAtLeastNWidgets(1));

      // Tap "ALL" toggle again to return to current month
      await tester.tap(allButton);
      await tester.pumpAndSettle();

      final currentMonthStr =
          DateFormat('MMMM yyyy').format(DateTime.now()).toUpperCase();
      expect(find.text(currentMonthStr), findsOneWidget);
      expect(find.text('Abraar'), findsNothing);
    },
  );

  testWidgets(
    'BookingsDirectoryScreen navigates months and resets to current month',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingRepositoryProvider.overrideWithValue(
              _FakeBookingRepository(),
            ),
            vendorRepositoryProvider.overrideWithValue(_FakeVendorRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: BookingsDirectoryScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final prevMonth = DateTime(now.year, now.month - 1);
      final prevMonthStr = DateFormat('MMMM yyyy').format(prevMonth).toUpperCase();

      // Navigate to previous month
      final prevButton = find.byKey(const ValueKey('btn_prev_month'));
      expect(prevButton, findsOneWidget);
      await tester.tap(prevButton);
      await tester.pumpAndSettle();

      // Verify previous month title and reset button
      expect(find.text(prevMonthStr), findsOneWidget);
      final resetButton = find.byKey(const ValueKey('btn_reset_current_month'));
      expect(resetButton, findsOneWidget);

      // Tap reset to current month
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      final currentMonthStr = DateFormat('MMMM yyyy').format(now).toUpperCase();
      expect(find.text(currentMonthStr), findsOneWidget);
    },
  );

  testWidgets('BookingsDirectoryScreen filters by search text input', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingRepositoryProvider.overrideWithValue(_FakeBookingRepository()),
          vendorRepositoryProvider.overrideWithValue(_FakeVendorRepository()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: BookingsDirectoryScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify current month vendors exist
    expect(find.text('Global Rentals Ltd'), findsAtLeastNWidgets(1));
    expect(find.text('Apex Logistics'), findsAtLeastNWidgets(1));

    // Enter search text "Global"
    final searchInput = find.byType(TextField);
    expect(searchInput, findsOneWidget);

    await tester.enterText(searchInput, 'Global');
    await tester.pump();

    // Verify Apex Logistics is filtered out, and Global Rentals Ltd is still displayed
    expect(find.text('Global Rentals Ltd'), findsAtLeastNWidgets(1));
    expect(find.text('Apex Logistics'), findsNothing);

    // Clear search query
    await tester.enterText(searchInput, '');
    await tester.pump();

    // Both should reappear
    expect(find.text('Global Rentals Ltd'), findsAtLeastNWidgets(1));
    expect(find.text('Apex Logistics'), findsAtLeastNWidgets(1));
  });
}

class _FakeVendorRepository extends VendorRepository {
  @override
  Future<List<MockVendor>> getVendors() async => List.of(mockVendors);
}

class _FakeBookingRepository extends BookingRepository {
  @override
  Future<List<MockBooking>> getBookings({
    DateTime? startDate,
    DateTime? endDate,
    String? vendorId,
    String? status,
  }) async {
    return List.of(mockBookings);
  }

  @override
  Future<List<Booking>> getVendorBookings(String vendorId) async {
    return mockBookings.where((b) => b.vendorId == vendorId).toList();
  }

  @override
  Future<Map<String, List<Booking>>> getAllVendorBookings() async {
    final result = <String, List<Booking>>{};
    for (final booking in mockBookings) {
      result.putIfAbsent(booking.vendorId, () => []).add(booking);
    }
    return result;
  }

  @override
  Future<List<CalendarEvent>> getCalendarEvents() async {
    return [
      CalendarEvent(date: '2026-04-19', count: 1, title: '1 booking(s)'),
      CalendarEvent(date: '2026-04-20', count: 1, title: '1 booking(s)'),
      CalendarEvent(date: '2026-04-21', count: 1, title: '1 booking(s)'),
      CalendarEvent(date: '2026-05-01', count: 1, title: '1 booking(s)'),
    ];
  }

  @override
  Future<List<Booking>> getCalendarDayBookings(String date) async {
    return mockBookings.where((b) {
      final bDate = b.startDate.toIso8601String().split('T')[0];
      return bDate == date;
    }).toList();
  }
}
