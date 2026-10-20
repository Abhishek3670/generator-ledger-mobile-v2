import '../../core/services/api_client.dart';
import '../../shared/models/vendor.dart';

class VendorRepository {
  VendorRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  static const String vendorsPath = '/api/vendors';
  static const String rentalVendorsPath = '/api/rental-vendors';

  final ApiClient _apiClient;

  Future<List<Vendor>> getVendors() async {
    // Fetch from both endpoints and merge
    final retailerVendorsFuture = _apiClient.get<List<Vendor>>(
      vendorsPath,
      fromJson: (json) => _parseVendorList(json),
    );
    
    final rentalVendorsFuture = _apiClient.get<List<Vendor>>(
      rentalVendorsPath,
      fromJson: (json) => _parseVendorList(json),
    );

    // Wait for both requests to complete
    final results = await Future.wait([
      retailerVendorsFuture,
      rentalVendorsFuture,
    ]);

    // Merge the lists
    return [...results[0], ...results[1]];
  }

  Future<Vendor> getVendorById(String id) async {
    final vendors = await getVendors();
    return vendors.firstWhere(
      (vendor) => vendor.id == id,
      orElse: () => throw StateError('Vendor not found: $id'),
    );
  }

  Future<Vendor> createVendor(Vendor vendor) async {
    final isRental = vendor.category.toLowerCase() == 'rental';
    final endpoint = isRental ? rentalVendorsPath : vendorsPath;

    return _apiClient.post<Vendor>(
      endpoint,
      data: vendor.toCreatePayload(),
      fromJson: (json) => _parseCreateResponse(json, vendor),
    );
  }

  Future<Vendor> updateVendor(String id, Vendor vendor) async {
    final isRental = vendor.category.toLowerCase() == 'rental' ||
        id.startsWith('RV') ||
        id.startsWith('RNV');
    final endpoint = isRental ? '$rentalVendorsPath/$id' : '$vendorsPath/$id';

    return _apiClient.patch<Vendor>(
      endpoint,
      data: vendor.toUpdatePayload(),
      fromJson: (json) => _parseVendor(json),
    );
  }

  Future<void> deleteVendor(String id, {String? category}) async {
    final isRental = (category?.toLowerCase() == 'rental') ||
        id.startsWith('RV') ||
        id.startsWith('RNV');
    final endpoint = isRental ? '$rentalVendorsPath/$id' : '$vendorsPath/$id';
    await _apiClient.delete<void>(endpoint, fromJson: (_) {});
  }

  Vendor _parseCreateResponse(dynamic json, Vendor original) {
    if (json is Map<String, dynamic>) {
      if (json['vendor'] is Map<String, dynamic>) {
        return Vendor.fromMap(json['vendor'] as Map<String, dynamic>);
      }
      final createdId = (json['vendor_id'] ?? json['rental_vendor_id'] ?? json['id'] ?? '').toString();
      if (createdId.isNotEmpty) {
        return original.copyWith(id: createdId);
      }
      return Vendor.fromMap(json);
    }
    return original;
  }

  List<Vendor> _parseVendorList(dynamic json) {
    final rawList = switch (json) {
      List<dynamic> list => list,
      {'vendors': final List<dynamic> list} => list,
      {'data': final List<dynamic> list} => list,
      {'items': final List<dynamic> list} => list,
      _ => throw const FormatException('Vendors response must be a list'),
    };

    return rawList
        .map((item) => Vendor.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Vendor _parseVendor(dynamic json) {
    final rawVendor = switch (json) {
      {'vendor': final Map<String, dynamic> vendor} => vendor,
      {'data': final Map<String, dynamic> vendor} => vendor,
      Map<String, dynamic> vendor => vendor,
      _ => throw const FormatException('Vendor response must be an object'),
    };

    return Vendor.fromMap(rawVendor);
  }
}
