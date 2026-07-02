import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_vendors.dart';
import '../services/mock_data_service.dart';

final vendorProvider =
    StateNotifierProvider<VendorNotifier, List<MockVendor>>((ref) {
  return VendorNotifier(MockDataService().getVendors());
});

class VendorNotifier extends StateNotifier<List<MockVendor>> {
  VendorNotifier(super.initialVendors);

  void addVendor(MockVendor vendor) {
    state = [vendor, ...state];
  }

  void updateVendor(MockVendor vendor) {
    state = [
      for (final existing in state)
        if (existing.id == vendor.id) vendor else existing,
    ];
  }

  void deleteVendor(String vendorId) {
    state = state.where((vendor) => vendor.id != vendorId).toList();
  }
}
