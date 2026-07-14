import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ledger/app.dart';
import 'package:ledger/core/routing/app_router.dart';
import 'package:ledger/core/services/token_storage.dart';
import 'package:ledger/core/providers/booking_provider.dart';
import 'package:ledger/core/providers/generator_provider.dart';
import 'package:ledger/core/providers/vendor_provider.dart';
import 'package:ledger/core/providers/billing_provider.dart';
import 'package:ledger/core/utils/connectivity_service.dart';
import 'package:ledger/data/mock/mock_bookings.dart';
import 'package:ledger/data/mock/mock_generators.dart';
import 'package:ledger/data/mock/mock_vendors.dart';
import 'package:ledger/data/repositories/booking_repository.dart';
import 'package:ledger/data/repositories/generator_repository.dart';
import 'package:ledger/data/repositories/vendor_repository.dart';
import 'package:ledger/data/repositories/billing_repository.dart';
import 'package:ledger/shared/models/booking.dart';
import 'package:ledger/shared/models/billing.dart';
import 'package:ledger/shared/models/calendar_event.dart';
import 'package:ledger/shared/widgets/side_navigation_drawer.dart';

void main() {
  setUp(() {
    AppRouter.tokenStorage = TokenStorage(backend: _FakeTokenStorageBackend());
  });

  List<Override> getOverrides() {
    return [
      vendorRepositoryProvider.overrideWithValue(_FakeVendorRepository()),
      generatorRepositoryProvider.overrideWithValue(_FakeGeneratorRepository()),
      bookingRepositoryProvider.overrideWithValue(_FakeBookingRepository()),
      billingRepositoryProvider.overrideWithValue(_FakeBillingRepository()),
      connectivityProvider.overrideWith((ref) => Stream.value(ConnectivityResult.wifi)),
    ];
  }

  testWidgets('unauthenticated launch renders login screen', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: getOverrides(),
      child: const LedgerApp(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byType(SideNavigationDrawer), findsNothing);
  });

  testWidgets(
    'authenticated app shell has centered Genset title and profile icon opens drawer',
    (tester) async {
      await AppRouter.tokenStorage.saveToken('jwt-token');

      await tester.pumpWidget(ProviderScope(
        overrides: getOverrides(),
        child: const LedgerApp(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Genset'), findsOneWidget);

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.centerTitle, isTrue);

      final appBarProfileIcon = find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(CircleAvatar),
      );
      expect(appBarProfileIcon, findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);

      // Tap profile avatar to open drawer
      await tester.tap(appBarProfileIcon);
      await tester.pumpAndSettle();
      expect(find.byType(SideNavigationDrawer), findsOneWidget);
    },
  );
}

class _FakeTokenStorageBackend implements TokenStorageBackend {
  final Map<String, String> values = {};

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> delete({required String key}) async {
    values.remove(key);
  }
}

class _FakeVendorRepository extends VendorRepository {
  @override
  Future<List<MockVendor>> getVendors() async => List.of(mockVendors);
}

class _FakeGeneratorRepository extends GeneratorRepository {
  @override
  Future<List<MockGenerator>> getGenerators({String? inventoryGroup}) async => List.of(mockGenerators);
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

class _FakeBillingRepository extends BillingRepository {
  @override
  Future<BillingResponse> getBillingPreview({
    required DateTime startDate,
    required DateTime endDate,
    String? vendorId,
  }) async {
    return const BillingResponse(summaries: [], capacities: []);
  }
}
