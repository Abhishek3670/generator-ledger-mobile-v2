import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/core/services/api_client.dart';
import 'package:ledger/data/repositories/vendor_repository.dart';
import 'package:ledger/shared/models/vendor.dart' as ledger_vendor;

void main() {
  group('VendorRepository', () {
    test('getVendors parses list responses from both endpoints', () async {
      final apiClient = _FakeApiClient(
        retailerResponse: [
          {
            'id': 'VEN001',
            'name': 'Mallu',
            'type': 'retailer',
            'place': 'Aligarh',
            'phone': '9876543210',
          },
        ],
        rentalResponse: [
          {
            'rental_vendor_id': 'RNV001',
            'name': 'Hotel One',
            'type': 'rental',
            'place': 'Downtown',
            'phone': '222',
          },
        ],
      );
      final repository = VendorRepository(apiClient: apiClient);

      final vendors = await repository.getVendors();

      expect(apiClient.getCallPaths, contains(VendorRepository.vendorsPath));
      expect(
        apiClient.getCallPaths,
        contains(VendorRepository.rentalVendorsPath),
      );
      expect(vendors.length, 2);
      expect(vendors[0].id, 'VEN001');
      expect(vendors[0].category, 'retailer');
      expect(vendors[1].id, 'RNV001');
      expect(vendors[1].category, 'rental');
    });

    test('getVendorById fetches all and filters client-side', () async {
      final repository = VendorRepository(
        apiClient: _FakeApiClient(
          retailerResponse: [
            {'id': 'VEN001', 'name': 'A', 'type': 'retailer'},
            {'id': 'VEN002', 'name': 'B', 'type': 'retailer'},
          ],
          rentalResponse: [],
        ),
      );

      final vendor = await repository.getVendorById('VEN002');

      expect(vendor.name, 'B');
    });

    test('createVendor posts retailer payload and parses response', () async {
      final apiClient = _FakeApiClient(
        response: {
          'success': true,
          'message': 'Vendor VEN003 created successfully',
          'vendor_id': 'VEN003',
        },
      );
      final repository = VendorRepository(apiClient: apiClient);

      final vendor = await repository.createVendor(
        const TestVendor(
          id: '',
          name: 'New Vendor',
          category: 'retailer',
          location: 'Agra',
          phone: '999',
        ),
      );

      expect(apiClient.lastPostPath, VendorRepository.vendorsPath);
      expect(apiClient.lastPostData, containsPair('vendor_name', 'New Vendor'));
      expect(apiClient.lastPostData, containsPair('vendor_place', 'Agra'));
      expect(apiClient.lastPostData, containsPair('phone', '999'));
      expect(vendor.id, 'VEN003');
    });

    test('createVendor posts rental payload to rental-vendors and parses response', () async {
      final apiClient = _FakeApiClient(
        response: {
          'success': true,
          'message': 'Rental vendor RV001 created successfully',
          'rental_vendor_id': 'RV001',
        },
      );
      final repository = VendorRepository(apiClient: apiClient);

      final vendor = await repository.createVendor(
        const TestVendor(
          id: '',
          name: 'Rental Vendor',
          category: 'rental',
          location: 'Delhi',
          phone: '888',
        ),
      );

      expect(apiClient.lastPostPath, VendorRepository.rentalVendorsPath);
      expect(apiClient.lastPostData, containsPair('vendor_name', 'Rental Vendor'));
      expect(apiClient.lastPostData, containsPair('vendor_place', 'Delhi'));
      expect(vendor.id, 'RV001');
    });

    test('updateVendor uses PATCH with correct payload', () async {
      final apiClient = _FakeApiClient(
        response: {
          'success': true,
          'message': 'Vendor VEN004 updated successfully',
          'vendor': {
            'id': 'VEN004',
            'name': 'Updated',
            'place': 'Aligarh',
            'phone': '111',
          },
        },
      );
      final repository = VendorRepository(apiClient: apiClient);

      await repository.updateVendor(
        'VEN004',
        const TestVendor(
          id: 'VEN004',
          name: 'Updated',
          category: 'retailer',
          location: 'Aligarh',
          phone: '111',
        ),
      );

      expect(apiClient.lastPatchPath, '${VendorRepository.vendorsPath}/VEN004');
    });

    test('deleteVendor calls DELETE endpoint for retailer and rental', () async {
      final apiClient = _FakeApiClient();
      final repository = VendorRepository(apiClient: apiClient);

      await repository.deleteVendor('VEN005', category: 'retailer');
      expect(apiClient.lastDeletePath, '${VendorRepository.vendorsPath}/VEN005');

      await repository.deleteVendor('RV001', category: 'rental');
      expect(apiClient.lastDeletePath, '${VendorRepository.rentalVendorsPath}/RV001');
    });
  });
}

class TestVendor extends ledger_vendor.Vendor {
  const TestVendor({
    required super.id,
    required super.name,
    required super.category,
    required super.location,
    required super.phone,
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({
    this.response,
    this.retailerResponse,
    this.rentalResponse,
  });

  final Object? response;
  final Object? retailerResponse;
  final Object? rentalResponse;
  final List<String> getCallPaths = [];
  String? lastGetPath;
  String? lastPostPath;
  String? lastPatchPath;
  String? lastDeletePath;
  Object? lastPostData;

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required JsonParser<T> fromJson,
  }) async {
    getCallPaths.add(path);
    lastGetPath = path;
    
    // Return appropriate response based on path
    if (path == VendorRepository.rentalVendorsPath && rentalResponse != null) {
      return fromJson(rentalResponse);
    } else if (path == VendorRepository.vendorsPath && retailerResponse != null) {
      return fromJson(retailerResponse);
    }
    
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
