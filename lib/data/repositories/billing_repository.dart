import '../../core/services/api_client.dart';
import '../../shared/models/billing.dart';

class BillingRepository {
  BillingRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  static const String billingPreviewPath = '/api/billing/preview';
  static const String paymentsPath = '/api/billing/payments';

  final ApiClient _apiClient;

  /// Fetch billing preview/calculation from backend
  /// 
  /// Query parameters:
  /// - startDate: ISO 8601 date string (e.g., "2026-01-01")
  /// - endDate: ISO 8601 date string (e.g., "2026-01-31")
  /// - vendorId: Optional vendor filter
  Future<List<BillingSummary>> getBillingPreview({
    required DateTime startDate,
    required DateTime endDate,
    String? vendorId,
  }) async {
    return _apiClient.get<List<BillingSummary>>(
      billingPreviewPath,
      queryParameters: _buildFilters(
        startDate: startDate,
        endDate: endDate,
        vendorId: vendorId,
      ),
      fromJson: (json) => _parseBillingSummaryList(json),
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

  Map<String, dynamic> _buildFilters({
    required DateTime startDate,
    required DateTime endDate,
    String? vendorId,
  }) {
    return {
      'startDate': startDate.toIso8601String().split('T').first,
      'endDate': endDate.toIso8601String().split('T').first,
      if (vendorId != null && vendorId.isNotEmpty) 'vendorId': vendorId,
    };
  }

  List<BillingSummary> _parseBillingSummaryList(dynamic json) {
    final rawList = switch (json) {
      List<dynamic> list => list,
      {'data': final List<dynamic> list} => list,
      {'billing': final List<dynamic> list} => list,
      {'summaries': final List<dynamic> list} => list,
      _ => throw const FormatException(
          'Billing response must be a list or wrapped object'),
    };

    return rawList
        .map((item) => BillingSummary.fromMap(item as Map<String, dynamic>))
        .toList();
  }
}
