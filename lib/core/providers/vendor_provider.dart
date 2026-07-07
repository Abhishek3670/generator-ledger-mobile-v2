import 'dart:async';
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
  Vendor? _lastDeletedVendor;
  int? _lastDeletedIndex;
  Timer? _deleteTimer;

  @override
  void dispose() {
    _deleteTimer?.cancel();
    super.dispose();
  }

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
    _deleteTimer?.cancel();
    if (_lastDeletedVendor != null) {
      await _repository.deleteVendor(_lastDeletedVendor!.id);
      _lastDeletedVendor = null;
    }

    final index = _cachedVendors.indexWhere((v) => v.id == vendorId);
    if (index == -1) return;

    _lastDeletedVendor = _cachedVendors[index];
    _lastDeletedIndex = index;

    _cachedVendors = List<Vendor>.from(_cachedVendors)..removeAt(index);
    state = AsyncValue.data(_cachedVendors);

    _deleteTimer = Timer(const Duration(seconds: 5), () async {
      if (_lastDeletedVendor != null && _lastDeletedVendor!.id == vendorId) {
        try {
          await _repository.deleteVendor(vendorId);
          _lastDeletedVendor = null;
          _lastDeletedIndex = null;
        } catch (error, stackTrace) {
          if (_lastDeletedVendor != null && _lastDeletedIndex != null) {
            _cachedVendors = List<Vendor>.from(_cachedVendors)
              ..insert(_lastDeletedIndex!.clamp(0, _cachedVendors.length), _lastDeletedVendor!);
            state = AsyncValue.data(_cachedVendors);
          }
          _lastDeletedVendor = null;
          _lastDeletedIndex = null;
          state = AsyncValue.error(error, stackTrace);
        }
      }
    });
  }

  void undoDeleteVendor() {
    if (_lastDeletedVendor != null && _lastDeletedIndex != null) {
      _deleteTimer?.cancel();
      final insertIndex = _lastDeletedIndex!.clamp(0, _cachedVendors.length);
      _cachedVendors = List<Vendor>.from(_cachedVendors)
        ..insert(insertIndex, _lastDeletedVendor!);
      state = AsyncValue.data(_cachedVendors);
      _lastDeletedVendor = null;
      _lastDeletedIndex = null;
    }
  }
}
