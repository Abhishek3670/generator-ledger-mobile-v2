import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/billing_repository.dart';
import '../../shared/models/billing.dart';

/// Repository provider for billing operations
final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepository();
});

/// Date range filter state for billing screen
class BillingDateRange {
  final DateTime startDate;
  final DateTime endDate;
  final String? vendorId;

  const BillingDateRange({
    required this.startDate,
    required this.endDate,
    this.vendorId,
  });

  BillingDateRange copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? vendorId,
  }) {
    return BillingDateRange(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      vendorId: vendorId ?? this.vendorId,
    );
  }
}

/// Date range state provider
final billingDateRangeProvider =
    StateProvider<BillingDateRange>((ref) {
  final now = DateTime.now();
  return BillingDateRange(
    startDate: DateTime(now.year, now.month, 1),
    endDate: DateTime(now.year, now.month + 1, 0),
  );
});

/// Billing data provider - fetches from API with current date range
final billingProvider =
    FutureProvider<List<BillingSummary>>((ref) async {
  final repository = ref.watch(billingRepositoryProvider);
  final dateRange = ref.watch(billingDateRangeProvider);

  return repository.getBillingPreview(
    startDate: dateRange.startDate,
    endDate: dateRange.endDate,
    vendorId: dateRange.vendorId,
  );
});
