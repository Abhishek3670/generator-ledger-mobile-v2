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
  Future<BillingResponse> getBillingPreview({
    required DateTime startDate,
    required DateTime endDate,
    String? vendorId,
  }) async {
    return _apiClient.get<BillingResponse>(
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

  /// Parse backend response and convert to BillingResponse
  BillingResponse _parseBillingResponse(
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

    // Extract capacities list if present
    List<int> capacitiesList = [];
    if (json is Map<String, dynamic> && json['capacities'] != null) {
      final caps = json['capacities'];
      if (caps is List) {
        capacitiesList = caps
            .map((c) => c is num ? c.toInt() : int.tryParse(c.toString()))
            .whereType<int>()
            .toList();
      }
    }

    // Sort ascending and deduplicate capacities if parsed from response
    capacitiesList = capacitiesList.toSet().toList()..sort();

    // Group rows by vendor_id
    final Map<String, List<Map<String, dynamic>>> vendorGroups = {};
    final Set<int> derivedCapacities = {};

    for (final row in rows) {
      final rowMap = row as Map<String, dynamic>;
      final vendorId = rowMap['vendor_id'] as String;
      
      // Parse capacity to derive fallback if necessary
      final capKva = rowMap['capacity_kva'] is num
          ? (rowMap['capacity_kva'] as num).toInt()
          : int.tryParse(rowMap['capacity_kva']?.toString() ?? '');
      if (capKva != null) {
        derivedCapacities.add(capKva);
      }

      // Apply vendor filter if specified
      if (vendorFilter != null && vendorId != vendorFilter) {
        continue;
      }

      vendorGroups.putIfAbsent(vendorId, () => []);
      vendorGroups[vendorId]!.add(rowMap);
    }

    // If capacities field was missing or empty, fall back to derived unique capacity values from rows
    if (capacitiesList.isEmpty) {
      capacitiesList = derivedCapacities.toList()..sort();
    }

    // Convert to BillingSummary objects
    final summaries = vendorGroups.entries.map((entry) {
      final vendorId = entry.key;
      final rows = entry.value;
      final vendorName = rows.first['vendor_name'] as String;

      // Convert each row to a BillingLine
      final lines = rows.map((row) {
        final capacityKvaVal = row['capacity_kva'] is num
            ? (row['capacity_kva'] as num).toInt()
            : int.tryParse(row['capacity_kva']?.toString() ?? '') ?? 0;
        return BillingLine.fromMap({
          'booking': {
            'id': row['booking_id'],
            'date': row['booked_date'],
            'generatorId': row['generator_id'],
            'capacity': '$capacityKvaVal kVA',
            'status': 'confirmed',
          },
          'pricePerCapacity': capacityKvaVal * 20.0, // Placeholder rate
        });
      }).toList();

      return BillingSummary(
        vendorId: vendorId,
        vendorName: vendorName,
        lines: lines,
        paidAmount: 0, // TODO: Get from backend if available
      );
    }).toList();

    return BillingResponse(
      summaries: summaries,
      capacities: capacitiesList,
    );
  }
}
