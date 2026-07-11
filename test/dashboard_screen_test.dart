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
    expect(find.text('CALENDAR'), findsOneWidget);
    expect(find.text('Vendor Bookings'), findsOneWidget);

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
  Future<List<MockGenerator>> getGenerators({String? inventoryGroup}) async {
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
}

