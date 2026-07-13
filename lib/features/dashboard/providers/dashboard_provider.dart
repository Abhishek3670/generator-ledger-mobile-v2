import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/booking_provider.dart';
import '../../../core/providers/generator_provider.dart';
import '../../../core/providers/vendor_provider.dart';

class DashboardSummary {
  final int totalBookings;
  final int totalGenerators;
  final int totalVendors;
  final Map<String, int> generatorsByCategory;
  final Map<String, int> vendorsByCategory;

  const DashboardSummary({
    required this.totalBookings,
    required this.totalGenerators,
    required this.totalVendors,
    required this.generatorsByCategory,
    required this.vendorsByCategory,
  });
}

final dashboardSummaryProvider = Provider<DashboardSummary>((ref) {
  final allVendorBookings = ref.watch(allVendorBookingsProvider).valueOrNull ?? {};
  final seen = <String>{};
  final totalBookingsCount = allVendorBookings.values
      .expand((list) => list)
      .where((b) => seen.add(b.id))
      .length;
  final generators = ref.watch(generatorProvider).valueOrNull ?? [];
  final vendors = ref.watch(vendorProvider).valueOrNull ?? [];

  final generatorsByCategory = <String, int>{
    'retailer': 0,
    'permanent': 0,
    'emergency': 0,
  };
  for (final g in generators) {
    final cat = g.category.toLowerCase();
    generatorsByCategory[cat] = (generatorsByCategory[cat] ?? 0) + 1;
  }

  final vendorsByCategory = <String, int>{
    'retailer': 0,
    'rental': 0,
  };
  for (final v in vendors) {
    final cat = v.category.toLowerCase();
    vendorsByCategory[cat] = (vendorsByCategory[cat] ?? 0) + 1;
  }

  return DashboardSummary(
    totalBookings: totalBookingsCount,
    totalGenerators: generators.length,
    totalVendors: vendors.length,
    generatorsByCategory: generatorsByCategory,
    vendorsByCategory: vendorsByCategory,
  );
});
