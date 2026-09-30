import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    'BookingsDirectoryScreen renders successfully with all elements',
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

      // Verify FloatingSearchFAB and bottom navbar are active
      expect(find.byType(FloatingSearchFAB), findsOneWidget);

      // Verify Vendor groups render (e.g. Abraar and Ankit Singh)
      expect(find.byType(VendorBookingGroup), findsAtLeastNWidgets(2));
      expect(find.text('Abraar'), findsAtLeastNWidgets(1));
      expect(find.text('Ankit Singh'), findsAtLeastNWidgets(1));
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

    // Initially multiple vendor booking groups should exist
    expect(find.text('Abraar'), findsAtLeastNWidgets(1));
    expect(find.text('Ankit Singh'), findsAtLeastNWidgets(1));

    // Enter search text "Abraar"
    final searchInput = find.byType(TextField);
    expect(searchInput, findsOneWidget);

    await tester.enterText(searchInput, 'Abraar');
    await tester.pump();

    // Verify Ankit Singh is filtered out, and Abraar is still displayed
    expect(find.text('Abraar'), findsAtLeastNWidgets(1));
    expect(find.text('Ankit Singh'), findsNothing);

    // Clear search query
    await tester.enterText(searchInput, '');
    await tester.pump();

    // Both should reappear
    expect(find.text('Abraar'), findsAtLeastNWidgets(1));
    expect(find.text('Ankit Singh'), findsAtLeastNWidgets(1));
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
