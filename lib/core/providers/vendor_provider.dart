import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_vendors.dart';
import '../../data/repositories/vendor_repository.dart';

final vendorRepositoryProvider = Provider<VendorRepository>((ref) {
  return VendorRepository();
});

final vendorProvider =
    StateNotifierProvider<VendorNotifier, AsyncValue<List<MockVendor>>>((ref) {
      return VendorNotifier(ref.watch(vendorRepositoryProvider));
    });

class VendorNotifier extends StateNotifier<AsyncValue<List<MockVendor>>> {
  VendorNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadVendors();
  }

  final VendorRepository _repository;

  List<MockVendor> _cachedVendors = [];

  Future<void> loadVendors() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final vendors = await _repository.getVendors();
      _cachedVendors = vendors;
      return vendors;
    });
  }

  Future<void> addVendor(MockVendor vendor) async {
    await _repository.createVendor(vendor);
    await loadVendors();
  }

  Future<void> updateVendor(MockVendor vendor) async {
    final previous = List<MockVendor>.of(_cachedVendors);
    _cachedVendors = [
      for (final existing in _cachedVendors)
        if (existing.id == vendor.id) vendor else existing,
    ];
    state = AsyncValue.data(_cachedVendors);

    try {
      await _repository.updateVendor(vendor.id, vendor);
      await loadVendors();
    } catch (error, stackTrace) {
      _cachedVendors = previous;
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteVendor(String vendorId) async {
    await _repository.deleteVendor(vendorId);
    await loadVendors();
  }
}
