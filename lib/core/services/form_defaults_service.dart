import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_preferences_service.dart';

final formDefaultsServiceProvider = Provider<FormDefaultsService>((ref) {
  final prefsService = ref.watch(userPreferencesServiceProvider);
  return FormDefaultsService(prefsService);
});

class BookingDefaults {
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String? lastVendorId;
  final List<String>? lastCapacities;

  BookingDefaults({
    required this.startDate,
    required this.endDate,
    required this.status,
    this.lastVendorId,
    this.lastCapacities,
  });
}

class GeneratorDefaults {
  final String category;
  final String status;
  final String type;
  final String capacity;

  GeneratorDefaults({
    required this.category,
    required this.status,
    required this.type,
    required this.capacity,
  });
}

class VendorDefaults {
  final String status;
  final String countryCode;

  VendorDefaults({
    required this.status,
    required this.countryCode,
  });
}

class UserDefaults {
  final String role;
  final String status;

  UserDefaults({
    required this.role,
    required this.status,
  });
}

class FormDefaultsService {
  final UserPreferencesService _prefsService;

  FormDefaultsService(this._prefsService);

  BookingDefaults getBookingDefaults() {
    final now = DateTime.now();
    return BookingDefaults(
      startDate: now,
      endDate: now.add(const Duration(days: 4)),
      status: 'confirmed',
      lastVendorId: _prefsService.getLastVendor(),
      lastCapacities: _prefsService.getLastSelectedCapacities(),
    );
  }

  GeneratorDefaults getGeneratorDefaults() {
    return GeneratorDefaults(
      category: 'permanent',
      status: 'active',
      type: 'Diesel',
      capacity: '50',
    );
  }

  VendorDefaults getVendorDefaults() {
    return VendorDefaults(
      status: 'Active',
      countryCode: '+91',
    );
  }

  UserDefaults getUserDefaults() {
    return UserDefaults(
      role: 'operator',
      status: 'ACTIVE',
    );
  }
}
