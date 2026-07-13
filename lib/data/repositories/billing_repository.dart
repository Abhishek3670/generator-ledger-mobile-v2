import '../../core/services/api_client.dart';
import '../../shared/models/billing.dart';

class BillingRepository {
  BillingRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  static const String billingLinesPath = '/api/billing/lines';
  static const String paymentsPath = '/api/billing/payments';

  final ApiClient _apiClient;

  /// Fetch billing lines from backend
  /// 
  /// Backend endpoint: GET /api/billing/lines
  /// Query parameters:
  /// - from: Starting date in YYYY-MM-DD format
  /// - to: Ending date in YYYY-MM-DD format
  /// 
  /// Response format:
  /// {
  ///   "from": "2026-02-01",
  ///   "to": "2026-02-28",
  ///   "rows": [
  ///     {
  ///       "vendor_id": "VEN005",
  ///       "vendor_name": "Mallu",
  ///       "booking_id": "BKG-20260227-00001",
  ///       "booked_date": "2026-02-28",
  ///       "generator_id": "GEN001",
  ///       "capacity_kva": 125,
  ///       "inventory_type": "retailer"
  ///     }
  ///   ],
  ///   "capacities": [125],
  ///   "count": 1
  /// }
  Future<List<BillingSummary>> getBillingPreview({
    required DateTime startDate,
    required DateTime endDate,
    String? vendorId,
  }) async {
    return _apiClient.get<List<BillingSummary>>(
      billingLinesPath,
      queryParameters: {
        'from': startDate.toIso8601String().split('T').first,
        'to': endDate.toIso8601String().split('T').first,
      },
      fromJson: (json) => _parseBillingResponse(json, vendorId),
    );
  }

  /// Record a payment transaction
  /// 
  /// POST /api/billing/payments
  /// Body: { vendorId, amount, paidAt, notes }
  Future<void> recordPayment({
    required String vendorId,
    required double amount,
    required DateTime paidAt,
    String? notes,
  }) async {
    await _apiClient.post<void>(
      paymentsPath,
      data: {
        'vendorId': vendorId,
        'amount': amount,
        'paidAt': paidAt.toIso8601String(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
      fromJson: (_) {},
    );
  }

  /// Parse backend response and convert to BillingSummary list
  /// Groups rows by vendor_id
  List<BillingSummary> _parseBillingResponse(
    dynamic json,
    String? vendorFilter,
  ) {
    // Extract rows from response
    final rows = switch (json) {
      {'rows': final List<dynamic> list} => list,
      List<dynamic> list => list, // Fallback for direct array
      _ => throw const FormatException(
          'Expected billing response with rows array'),
    };

    if (rows.isEmpty) {
      return [];
    }

    // Group rows by vendor_id
    final Map<String, List<Map<String, dynamic>>> vendorGroups = {};
    for (final row in rows) {
      final rowMap = row as Map<String, dynamic>;
      final vendorId = rowMap['vendor_id'] as String;
      
      // Apply vendor filter if specified
      if (vendorFilter != null && vendorId != vendorFilter) {
        continue;
      }

      vendorGroups.putIfAbsent(vendorId, () => []);
      vendorGroups[vendorId]!.add(rowMap);
    }

    // Convert to BillingSummary objects
    return vendorGroups.entries.map((entry) {
      final vendorId = entry.key;
      final rows = entry.value;
      final vendorName = rows.first['vendor_name'] as String;

      // Convert each row to a BillingLine
      final lines = rows.map((row) {
        return BillingLine.fromMap({
          'booking': {
            'id': row['booking_id'],
            'date': row['booked_date'],
            'generatorId': row['generator_id'],
            'capacity': row['capacity_kva'],
            'status': 'confirmed',
          },
          'pricePerCapacity': row['capacity_kva'] * 20.0, // Placeholder rate
        });
      }).toList();

      return BillingSummary(
        vendorId: vendorId,
        vendorName: vendorName,
        lines: lines,
        paidAmount: 0, // TODO: Get from backend if available
      );
    }).toList();
  }
}
