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
    totalBookings: ref.watch(bookingProvider).valueOrNull?.length ?? 0,
    totalGenerators: ref.watch(generatorProvider).valueOrNull?.length ?? 0,
    totalVendors: ref.watch(vendorProvider).valueOrNull?.length ?? 0,
  );
});
