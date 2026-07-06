import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/core/services/api_client.dart';
import 'package:ledger/data/repositories/billing_repository.dart';

void main() {
  group('BillingRepository', () {
    test('getBillingPreview constructs correct query parameters', () async {
      final startDate = DateTime(2026, 1, 1);
      final endDate = DateTime(2026, 1, 31);

      final fakeClient = _FakeApiClient(response: {'rows': []});
      final repository = BillingRepository(apiClient: fakeClient);

      await repository.getBillingPreview(
        startDate: startDate,
        endDate: endDate,
      );

      expect(fakeClient.lastGetPath, '/billing/lines');
      expect(fakeClient.lastQueryParameters, {
        'from': '2026-01-01',
        'to': '2026-01-31',
      });
    });

    test('getBillingPreview parses backend response and groups by vendor',
        () async {
      final fakeClient = _FakeApiClient(
        response: {
          'from': '2026-02-01',
          'to': '2026-02-28',
          'rows': [
            {
              'vendor_id': 'VEN005',
              'vendor_name': 'Mallu',
              'booking_id': 'BKG-20260227-00001',
              'booked_date': '2026-02-28',
              'generator_id': 'GEN001',
              'capacity_kva': 125,
              'inventory_type': 'retailer',
            },
            {
              'vendor_id': 'VEN005',
              'vendor_name': 'Mallu',
              'booking_id': 'BKG-20260228-00002',
              'booked_date': '2026-02-28',
              'generator_id': 'GEN002',
              'capacity_kva': 250,
              'inventory_type': 'retailer',
            }
          ],
          'capacities': [125, 250],
          'count': 2,
        },
      );
      final repository = BillingRepository(apiClient: fakeClient);

      final result = await repository.getBillingPreview(
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 28),
      );

      expect(result, hasLength(1)); // One vendor
      expect(result.first.vendorId, 'VEN005');
      expect(result.first.vendorName, 'Mallu');
      expect(result.first.lines, hasLength(2)); // Two bookings
    });

    test('getBillingPreview handles multiple vendors', () async {
      final fakeClient = _FakeApiClient(
        response: {
          'rows': [
            {
              'vendor_id': 'VEN001',
              'vendor_name': 'Vendor A',
              'booking_id': 'BKG-001',
              'booked_date': '2026-01-15',
              'generator_id': 'GEN001',
              'capacity_kva': 125,
              'inventory_type': 'retailer',
            },
            {
              'vendor_id': 'VEN002',
              'vendor_name': 'Vendor B',
              'booking_id': 'BKG-002',
              'booked_date': '2026-01-20',
              'generator_id': 'GEN002',
              'capacity_kva': 250,
              'inventory_type': 'rental',
            }
          ]
        },
      );
      final repository = BillingRepository(apiClient: fakeClient);

      final result = await repository.getBillingPreview(
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
      );

      expect(result, hasLength(2)); // Two vendors
      expect(result.map((s) => s.vendorId), containsAll(['VEN001', 'VEN002']));
    });

    test('getBillingPreview filters by vendor ID', () async {
      final fakeClient = _FakeApiClient(
        response: {
          'rows': [
            {
              'vendor_id': 'VEN001',
              'vendor_name': 'Vendor A',
              'booking_id': 'BKG-001',
              'booked_date': '2026-01-15',
              'generator_id': 'GEN001',
              'capacity_kva': 125,
              'inventory_type': 'retailer',
            },
            {
              'vendor_id': 'VEN002',
              'vendor_name': 'Vendor B',
              'booking_id': 'BKG-002',
              'booked_date': '2026-01-20',
              'generator_id': 'GEN002',
              'capacity_kva': 250,
              'inventory_type': 'rental',
            }
          ]
        },
      );
      final repository = BillingRepository(apiClient: fakeClient);

      final result = await repository.getBillingPreview(
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
        vendorId: 'VEN001', // Filter to only VEN001
      );

      expect(result, hasLength(1)); // Only one vendor
      expect(result.first.vendorId, 'VEN001');
    });

    test('getBillingPreview returns empty list for no rows', () async {
      final fakeClient = _FakeApiClient(
        response: {
          'from': '2026-01-01',
          'to': '2026-01-31',
          'rows': [],
          'count': 0,
        },
      );
      final repository = BillingRepository(apiClient: fakeClient);

      final result = await repository.getBillingPreview(
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
      );

      expect(result, isEmpty);
    });

    test('recordPayment sends correct data', () async {
      final fakeClient = _FakeApiClient(response: null);
      final repository = BillingRepository(apiClient: fakeClient);
      final paidAt = DateTime(2026, 1, 15, 10, 30);

      await repository.recordPayment(
        vendorId: 'VEN001',
        amount: 5000.0,
        paidAt: paidAt,
        notes: 'Cash payment',
      );

      expect(fakeClient.lastPostPath, '/api/billing/payments');
      expect(fakeClient.lastPostData, {
        'vendorId': 'VEN001',
        'amount': 5000.0,
        'paidAt': '2026-01-15T10:30:00.000',
        'notes': 'Cash payment',
      });
    });

    test('recordPayment omits null notes', () async {
      final fakeClient = _FakeApiClient(response: null);
      final repository = BillingRepository(apiClient: fakeClient);
      final paidAt = DateTime(2026, 1, 15, 10, 30);

      await repository.recordPayment(
        vendorId: 'VEN001',
        amount: 3000.0,
        paidAt: paidAt,
      );

      expect(fakeClient.lastPostData, {
        'vendorId': 'VEN001',
        'amount': 3000.0,
        'paidAt': '2026-01-15T10:30:00.000',
      });
      expect(
        (fakeClient.lastPostData as Map).containsKey('notes'),
        false,
      );
    });

    test('getBillingPreview throws on invalid response structure', () async {
      final fakeClient = _FakeApiClient(response: 'invalid');
      final repository = BillingRepository(apiClient: fakeClient);

      expect(
        () => repository.getBillingPreview(
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31),
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.response});

  final Object? response;
  String? lastGetPath;
  String? lastPostPath;
  Object? lastPostData;
  Map<String, dynamic>? lastQueryParameters;

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required JsonParser<T> fromJson,
  }) async {
    lastGetPath = path;
    lastQueryParameters = queryParameters;
    return fromJson(response ?? {});
  }

  @override
  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required JsonParser<T> fromJson,
  }) async {
    lastPostPath = path;
    lastPostData = data;
    return fromJson(response ?? {});
  }

  @override
  Future<T> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required JsonParser<T> fromJson,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<T> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required JsonParser<T> fromJson,
  }) async {
    throw UnimplementedError();
  }
}
