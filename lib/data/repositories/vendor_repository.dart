import '../../core/services/api_client.dart';
import '../../shared/models/vendor.dart';

class VendorRepository {
  VendorRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  static const String vendorsPath = '/api/vendors';

  final ApiClient _apiClient;

  Future<List<Vendor>> getVendors() async {
    return _apiClient.get<List<Vendor>>(
      vendorsPath,
      fromJson: (json) => _parseVendorList(json),
    );
  }

  Future<Vendor> getVendorById(String id) async {
    final vendors = await getVendors();
    return vendors.firstWhere(
      (vendor) => vendor.id == id,
      orElse: () => throw StateError('Vendor not found: $id'),
    );
  }

  Future<Vendor> createVendor(Vendor vendor) async {
    return _apiClient.post<Vendor>(
      vendorsPath,
      data: vendor.toMap(),
      fromJson: (json) => _parseVendor(json),
    );
  }

  Future<Vendor> updateVendor(String id, Vendor vendor) async {
    return _apiClient.patch<Vendor>(
      '$vendorsPath/$id',
      data: vendor.toMap(),
      fromJson: (json) => _parseVendor(json),
    );
  }

  Future<void> deleteVendor(String id) async {
    await _apiClient.delete<void>('$vendorsPath/$id', fromJson: (_) {});
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
