import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ledger/core/providers/booking_provider.dart';
import 'package:ledger/core/providers/billing_provider.dart';
import 'package:ledger/core/utils/connectivity_service.dart';
import 'package:ledger/data/mock/mock_bookings.dart';
import 'package:ledger/data/repositories/booking_repository.dart';
import 'package:ledger/data/repositories/billing_repository.dart';
import 'package:ledger/shared/models/booking.dart';
import 'package:ledger/shared/models/billing.dart';
import 'package:ledger/features/billing/screens/billing_preview_screen.dart';

void main() {
  testWidgets('BillingPreviewScreen renders sticky header and bottom grand total', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        bookingRepositoryProvider.overrideWithValue(_FakeBookingRepository()),
        billingRepositoryProvider.overrideWithValue(_FakeBillingRepository()),
        connectivityProvider.overrideWith((ref) => Stream.value(ConnectivityResult.wifi)),
      ],
      child: const MaterialApp(
        home: Scaffold(body: BillingPreviewScreen()),
      ),
    ));

    // Verify fixed top header exists with back button
    expect(find.text('BACK TO DASHBOARD'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    // Verify billing title
    expect(find.text('BILLING'), findsOneWidget);
    expect(find.text('Billing Preview'), findsOneWidget);

    // Grand total starts out showing when the page loads with mock vendor data
    await tester.pumpAndSettle();

    // Verify grand total exists at the bottom
    expect(find.text('GRAND TOTAL'), findsOneWidget);
  });

  testWidgets('BillingPreviewScreen renders loading and error states', (tester) async {
    final errorRepository = _ErrorBillingRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        bookingRepositoryProvider.overrideWithValue(_FakeBookingRepository()),
        billingRepositoryProvider.overrideWithValue(errorRepository),
        connectivityProvider.overrideWith((ref) => Stream.value(ConnectivityResult.wifi)),
      ],
      child: const MaterialApp(
        home: Scaffold(body: BillingPreviewScreen()),
      ),
    ));

    // Should show loading spinner initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 150));

    // Should show error state message and Retry button
    expect(find.text('Failed to load billing data'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
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

class _FakeBillingRepository extends BillingRepository {
  @override
  Future<List<BillingSummary>> getBillingPreview({
    required DateTime startDate,
    required DateTime endDate,
    String? vendorId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return [
      BillingSummary(
        vendorId: 'VEN-1',
        vendorName: 'Mallu',
        lines: [
          BillingLine(
            booking: Booking(
              id: 'BKG-1',
              vendorId: 'VEN-1',
              vendorName: 'Mallu',
              generatorId: 'GEN-1',
              capacity: '20 kVA',
              date: DateTime.utc(2026, 4, 15),
              status: 'confirmed',
            ),
            pricePerCapacity: 1000,
          ),
        ],
      ),
    ];
  }
}

class _ErrorBillingRepository extends BillingRepository {
  @override
  Future<List<BillingSummary>> getBillingPreview({
    required DateTime startDate,
    required DateTime endDate,
    String? vendorId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    throw Exception('API connection failed');
  }
}
