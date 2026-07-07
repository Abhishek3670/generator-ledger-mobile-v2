import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ledger/core/services/user_preferences_service.dart';
import 'package:ledger/core/services/form_defaults_service.dart';

void main() {
  group('FormDefaultsService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns correct booking defaults without preferences', () async {
      final prefs = await SharedPreferences.getInstance();
      final prefsService = UserPreferencesService(prefs);
      final service = FormDefaultsService(prefsService);

      final defaults = service.getBookingDefaults();
      expect(defaults.startDate.year, DateTime.now().year);
      expect(defaults.status, 'confirmed');
      expect(defaults.lastVendorId, isNull);
      expect(defaults.lastCapacities, isNull);
    });

    test('returns correct booking defaults with preferences', () async {
      final prefs = await SharedPreferences.getInstance();
      final prefsService = UserPreferencesService(prefs);
      final service = FormDefaultsService(prefsService);

      await prefsService.saveLastVendor('VEN-111');
      await prefsService.saveLastSelectedCapacities(['30', '50']);

      final defaults = service.getBookingDefaults();
      expect(defaults.lastVendorId, 'VEN-111');
      expect(defaults.lastCapacities, ['30', '50']);
    });

    test('returns correct generator defaults', () async {
      final prefs = await SharedPreferences.getInstance();
      final prefsService = UserPreferencesService(prefs);
      final service = FormDefaultsService(prefsService);

      final defaults = service.getGeneratorDefaults();
      expect(defaults.category, 'permanent');
      expect(defaults.status, 'active');
      expect(defaults.type, 'Diesel');
      expect(defaults.capacity, '50');
    });

    test('returns correct vendor defaults', () async {
      final prefs = await SharedPreferences.getInstance();
      final prefsService = UserPreferencesService(prefs);
      final service = FormDefaultsService(prefsService);

      final defaults = service.getVendorDefaults();
      expect(defaults.status, 'Active');
      expect(defaults.countryCode, '+91');
    });

    test('returns correct user defaults', () async {
      final prefs = await SharedPreferences.getInstance();
      final prefsService = UserPreferencesService(prefs);
      final service = FormDefaultsService(prefsService);

      final defaults = service.getUserDefaults();
      expect(defaults.role, 'operator');
      expect(defaults.status, 'ACTIVE');
    });
  });
}
