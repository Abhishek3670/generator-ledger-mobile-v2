import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/billing.dart';
import 'booking_provider.dart';

final billingProvider = Provider<List<BillingSummary>>((ref) {
  final bookings = ref.watch(bookingProvider).valueOrNull ?? [];
  final confirmed = bookings.where((booking) => booking.status == 'confirmed');
  final grouped = <String, List<BillingLine>>{};

  for (final booking in confirmed) {
    grouped
        .putIfAbsent(booking.vendorId, () => [])
        .add(BillingLine(booking: booking, pricePerCapacity: 0));
  }

  return grouped.entries.map((entry) {
    final first = entry.value.first.booking;
    return BillingSummary(
      vendorId: entry.key,
      vendorName: first.vendorName,
      lines: entry.value,
    );
  }).toList();
});
