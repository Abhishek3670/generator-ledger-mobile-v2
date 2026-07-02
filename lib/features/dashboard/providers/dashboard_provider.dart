import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/booking_provider.dart';
import '../../../core/providers/generator_provider.dart';
import '../../../core/providers/vendor_provider.dart';

class DashboardSummary {
  final int totalBookings;
  final int totalGenerators;
  final int totalVendors;

  const DashboardSummary({
    required this.totalBookings,
    required this.totalGenerators,
    required this.totalVendors,
  });
}

final dashboardSummaryProvider = Provider<DashboardSummary>((ref) {
  return DashboardSummary(
    totalBookings: ref.watch(bookingProvider).length,
    totalGenerators: ref.watch(generatorProvider).length,
    totalVendors: ref.watch(vendorProvider).length,
  );
});
