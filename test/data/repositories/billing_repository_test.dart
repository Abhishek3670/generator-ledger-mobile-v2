import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/core/services/api_client.dart';
import 'package:ledger/data/repositories/billing_repository.dart';

void main() {
  group('BillingRepository', () {
    test('getBillingPreview constructs correct query parameters', () async {
      final startDate = DateTime(2026, 1, 1);
      final endDate = DateTime(2026, 1, 31);

      final fakeClient = _FakeApiClient(response: []);
      final repository = BillingRepository(apiClient: fakeClient);

      await repository.getBillingPreview(
        startDate: startDate,
        endDate: endDate,
        vendorId: 'VEN001',
      );

      expect(fakeClient.lastGetPath, '/api/billing/preview');
      expect(fakeClient.lastQueryParameters, {
        'startDate': '2026-01-01',
        'endDate': '2026-01-31',
        'vendorId': 'VEN001',
      });
    });

    test('getBillingPreview parses flat list response', () async {
      final fakeClient = _FakeApiClient(
        response: [
          {
            'vendorId': 'VEN001',
            'vendorName': 'Test Vendor',
            'lines': [
              {
                'booking': {
                  'id': 'BKG-001',
                  'vendorId': 'VEN001',
                  'vendorName': 'Test Vendor',
                  'status': 'confirmed',
                  'date': '2026-01-15',
                  'createdAt': '2026-01-15T10:00:00Z',
                  'items': [],
                },
                'pricePerCapacity': 1000.0,
              }
            ],
            'paidAmount': 500.0,
          }
        ],
      );
      final repository = BillingRepository(apiClient: fakeClient);

      final result = await repository.getBillingPreview(
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
      );

      expect(result, hasLength(1));
      expect(result.first.vendorId, 'VEN001');
      expect(result.first.vendorName, 'Test Vendor');
      expect(result.first.lines, hasLength(1));
      expect(result.first.lines.first.pricePerCapacity, 1000.0);
      expect(result.first.paidAmount, 500.0);
      expect(result.first.subtotal, 1000.0);
      expect(result.first.total, 500.0); // subtotal - paidAmount
    });

    test('getBillingPreview parses wrapped response', () async {
      final fakeClient = _FakeApiClient(
        response: {
          'data': [
            {
              'vendorId': 'VEN002',
              'vendorName': 'Another Vendor',
              'lines': [],
              'paidAmount': 0.0,
            }
          ]
        },
      );
      final repository = BillingRepository(apiClient: fakeClient);

      final result = await repository.getBillingPreview(
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
      );

      expect(result, hasLength(1));
      expect(result.first.vendorId, 'VEN002');
    });

    test('getBillingPreview handles snake_case field names', () async {
      final fakeClient = _FakeApiClient(
        response: [
          {
            'vendor_id': 'VEN003',
            'vendor_name': 'Snake Case Vendor',
            'lines': [
              {
                'booking': {
                  'id': 'BKG-002',
                  'vendorId': 'VEN003',
                  'vendorName': 'Snake Case Vendor',
                  'status': 'confirmed',
                  'date': '2026-01-20',
                  'createdAt': '2026-01-20T10:00:00Z',
                  'items': [],
                },
                'price_per_capacity': 2000.0,
              }
            ],
            'paid_amount': 1000.0,
          }
        ],
      );
      final repository = BillingRepository(apiClient: fakeClient);

      final result = await repository.getBillingPreview(
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
      );

      expect(result.first.vendorId, 'VEN003');
      expect(result.first.vendorName, 'Snake Case Vendor');
      expect(result.first.lines.first.pricePerCapacity, 2000.0);
      expect(result.first.paidAmount, 1000.0);
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
