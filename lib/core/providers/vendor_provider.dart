import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/vendor_repository.dart';
import '../../shared/models/vendor.dart';

final vendorRepositoryProvider = Provider<VendorRepository>((ref) {
  return VendorRepository();
});

final vendorProvider =
    StateNotifierProvider<VendorNotifier, AsyncValue<List<Vendor>>>((ref) {
      return VendorNotifier(ref.watch(vendorRepositoryProvider));
    });

class VendorNotifier extends StateNotifier<AsyncValue<List<Vendor>>> {
  VendorNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadVendors();
  }

  final VendorRepository _repository;

  List<Vendor> _cachedVendors = [];

  Future<void> loadVendors() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final vendors = await _repository.getVendors();
      _cachedVendors = vendors;
      return vendors;
    });
  }

  Future<void> addVendor(Vendor vendor) async {
    await _repository.createVendor(vendor);
    await loadVendors();
  }

  Future<void> updateVendor(Vendor vendor) async {
    final previous = List<Vendor>.of(_cachedVendors);
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
