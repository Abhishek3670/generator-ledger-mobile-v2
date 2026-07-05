import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/core/services/api_client.dart';
import 'package:ledger/data/repositories/booking_repository.dart';
import 'package:ledger/shared/models/booking.dart';

void main() {
  group('BookingRepository', () {
    test('getBookings parses list responses and sends filters', () async {
      final apiClient = _FakeApiClient(
        response: {
          'bookings': [
            {
              'booking_id': 'BK-001',
              'vendor_id': 'VEN001',
              'vendor_name': 'Abraar',
              'generator_ids': ['GEN-1', 'GEN-2'],
              'start_date': '2026-04-19T00:00:00.000Z',
              'end_date': '2026-04-21T00:00:00.000Z',
              'status': 'confirmed',
              'capacity_kva': 20,
            },
          ],
        },
      );
      final repository = BookingRepository(apiClient: apiClient);

      final bookings = await repository.getBookings(
        startDate: DateTime.utc(2026, 4, 1),
        endDate: DateTime.utc(2026, 4, 30),
        vendorId: 'VEN001',
        status: 'confirmed',
      );

      expect(apiClient.lastGetPath, BookingRepository.bookingsPath);
      expect(apiClient.lastQueryParameters, containsPair('vendorId', 'VEN001'));
      expect(
        apiClient.lastQueryParameters,
        containsPair('status', 'confirmed'),
      );
      expect(bookings.single.id, 'BK-001');
      expect(bookings.single.generators, ['GEN-1', 'GEN-2']);
      expect(bookings.single.capacity, '20 kVA');
    });

    test('createBooking posts vendor and generator ids', () async {
      final apiClient = _FakeApiClient(
        response: {
          'booking': {
            'booking_id': 'BK-002',
            'vendor_id': 'VEN002',
            'vendor_name': 'Vendor Two',
            'generator_ids': ['GEN-2'],
            'start_date': '2026-05-01T00:00:00.000Z',
            'end_date': '2026-05-02T00:00:00.000Z',
          },
        },
      );
      final repository = BookingRepository(apiClient: apiClient);

      await repository.createBooking(
        Booking(
          id: 'BK-002',
          vendorId: 'VEN002',
          vendorName: 'Vendor Two',
          generatorId: 'GEN-2',
          capacity: '45 kVA',
          date: DateTime.utc(2026, 5),
          endDate: DateTime.utc(2026, 5, 2),
          status: 'pending',
        ),
      );

      expect(apiClient.lastPostPath, BookingRepository.bookingsPath);
      expect(apiClient.lastPostData, containsPair('vendor_id', 'VEN002'));
      expect(apiClient.lastPostData, containsPair('generator_ids', ['GEN-2']));
    });

    test('updateBooking uses PATCH and deleteBooking uses DELETE', () async {
      final apiClient = _FakeApiClient(
        response: {
          'booking': {
            'booking_id': 'BK-003',
            'vendor_id': 'VEN003',
            'start_date': '2026-06-01T00:00:00.000Z',
          },
        },
      );
      final repository = BookingRepository(apiClient: apiClient);

      await repository.updateBooking(
        'BK-003',
        Booking(
          id: 'BK-003',
          vendorId: 'VEN003',
          vendorName: 'Vendor Three',
          generatorId: 'GEN-3',
          capacity: '100 kVA',
          date: DateTime.utc(2026, 6),
          status: 'confirmed',
        ),
      );
      await repository.deleteBooking('BK-003');

      expect(
        apiClient.lastPatchPath,
        '${BookingRepository.bookingsPath}/BK-003',
      );
      expect(
        apiClient.lastDeletePath,
        '${BookingRepository.bookingsPath}/BK-003',
      );
    });

    test('getBookings parses enhanced items array format', () async {
      final apiClient = _FakeApiClient(
        response: {
          'bookings': [
            {
              'id': 'BKG-20260227-00001',
              'vendor_id': 'VEN005',
              'vendor_name': 'Mallu',
              'created_at': '2026-02-27 23:56',
              'status': 'Confirmed',
              'items': [
                {
                  'generator_id': 'GEN001',
                  'capacity_kva': 125,
                },
                {
                  'generator_id': 'GEN002',
                  'capacity_kva': 75,
                },
              ],
            },
          ],
        },
      );
      final repository = BookingRepository(apiClient: apiClient);

      final bookings = await repository.getBookings();

      expect(bookings.single.id, 'BKG-20260227-00001');
      expect(bookings.single.vendorId, 'VEN005');
      expect(bookings.single.vendorName, 'Mallu');
      expect(bookings.single.generators, ['GEN001', 'GEN002']);
      expect(bookings.single.capacity, '200 kVA'); // 125 + 75
      expect(bookings.single.status, 'Confirmed');
    });
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.response});

  final Object? response;
  String? lastGetPath;
  String? lastPostPath;
  String? lastPatchPath;
  String? lastDeletePath;
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
    lastPatchPath = path;
    return fromJson(response ?? {});
  }

  @override
  Future<T> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required JsonParser<T> fromJson,
  }) async {
    lastDeletePath = path;
    return fromJson(null);
  }
}
