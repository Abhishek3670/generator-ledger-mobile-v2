import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger/core/providers/booking_provider.dart';
import 'package:ledger/core/providers/generator_provider.dart';
import 'package:ledger/core/providers/vendor_provider.dart';
import 'package:ledger/data/mock/mock_bookings.dart';
import 'package:ledger/data/mock/mock_generators.dart';
import 'package:ledger/data/mock/mock_vendors.dart';
import 'package:ledger/data/repositories/booking_repository.dart';
import 'package:ledger/data/repositories/generator_repository.dart';
import 'package:ledger/data/repositories/vendor_repository.dart';
import 'package:ledger/shared/models/booking.dart';
import 'package:ledger/shared/models/calendar_event.dart';
import 'package:ledger/features/dashboard/screens/dashboard_screen.dart';
import 'package:ledger/features/dashboard/widgets/stats_grid.dart';
import 'package:ledger/features/dashboard/widgets/calendar_view.dart';
import 'package:ledger/features/dashboard/widgets/daily_bookings_list.dart';

void main() {
  testWidgets('DashboardScreen renders successfully with all sub-widgets', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vendorRepositoryProvider.overrideWithValue(_FakeVendorRepository()),
          generatorRepositoryProvider.overrideWithValue(
            _FakeGeneratorRepository(),
          ),
          bookingRepositoryProvider.overrideWithValue(_FakeBookingRepository()),
        ],
        child: const MaterialApp(home: Scaffold(body: DashboardScreen())),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Dashboard Scaffold components
    expect(find.byType(DashboardScreen), findsOneWidget);

    // Verify StatsGrid exists
    expect(find.byType(StatsGrid), findsOneWidget);
    expect(find.text('8 confirmed'), findsOneWidget);
    expect(find.textContaining('active'), findsOneWidget);
    expect(find.textContaining('partners'), findsOneWidget);

    // Verify CalendarView exists
    expect(find.byType(CalendarView), findsOneWidget);

    // Verify DailyBookingsList exists
    expect(find.byType(DailyBookingsList), findsOneWidget);
    expect(find.textContaining('Bookings:'), findsOneWidget);
    expect(find.textContaining('VIEW ALL'), findsOneWidget);
  });
}

class _FakeVendorRepository extends VendorRepository {
  @override
  Future<List<MockVendor>> getVendors() async => List.of(mockVendors);
}

class _FakeGeneratorRepository extends GeneratorRepository {
  @override
  Future<List<MockGenerator>> getGenerators({String? inventoryGroup, String? date}) async {
    return List.of(mockGenerators);
  }
}

class _FakeBookingRepository extends BookingRepository {
  @override
  Future<List<Booking>> getBookings({
    DateTime? startDate,
    DateTime? endDate,
    String? vendorId,
    String? status,
  }) async {
    return List.of(mockBookings);
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

