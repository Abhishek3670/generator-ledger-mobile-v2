import 'booking.dart';

class BillingLine {
  final Booking booking;
  final double pricePerCapacity;

  const BillingLine({
    required this.booking,
    required this.pricePerCapacity,
  });

  double get lineAmount => pricePerCapacity;
}

class BillingSummary {
  final String vendorId;
  final String vendorName;
  final List<BillingLine> lines;
  final double paidAmount;

  const BillingSummary({
    required this.vendorId,
    required this.vendorName,
    required this.lines,
    this.paidAmount = 0,
  });

  double get subtotal =>
      lines.fold(0, (total, line) => total + line.lineAmount);
  double get total => subtotal - paidAmount;
}
