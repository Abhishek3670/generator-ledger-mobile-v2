import 'booking.dart';

class BillingLine {
  final Booking booking;
  final double pricePerCapacity;

  const BillingLine({
    required this.booking,
    required this.pricePerCapacity,
  });

  double get lineAmount => pricePerCapacity;

  factory BillingLine.fromMap(Map<String, dynamic> json) {
    final bookingData = json['booking'] as Map<String, dynamic>? ?? json;
    
    return BillingLine(
      booking: Booking.fromMap(bookingData),
      pricePerCapacity: (json['pricePerCapacity'] ??
              json['price_per_capacity'] ??
              json['amount'] ??
              0)
          .toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'booking': booking.toMap(),
      'pricePerCapacity': pricePerCapacity,
    };
  }
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

  factory BillingSummary.fromMap(Map<String, dynamic> json) {
    final linesData = json['lines'] ?? json['items'] ?? [];
    final lines = (linesData as List<dynamic>)
        .map((item) => BillingLine.fromMap(item as Map<String, dynamic>))
        .toList();

    return BillingSummary(
      vendorId: json['vendorId'] as String? ?? json['vendor_id'] as String,
      vendorName:
          json['vendorName'] as String? ?? json['vendor_name'] as String,
      lines: lines,
      paidAmount:
          (json['paidAmount'] ?? json['paid_amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'vendorName': vendorName,
      'lines': lines.map((line) => line.toMap()).toList(),
      'paidAmount': paidAmount,
    };
  }
}

class BillingResponse {
  final List<BillingSummary> summaries;
  final List<int> capacities;

  const BillingResponse({
    required this.summaries,
    required this.capacities,
  });
}
