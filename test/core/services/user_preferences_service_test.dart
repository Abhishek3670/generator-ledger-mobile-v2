import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ledger/core/services/user_preferences_service.dart';

void main() {
  group('UserPreferencesService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saves and retrieves last selected vendor ID', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = UserPreferencesService(prefs);

      expect(service.getLastVendor(), isNull);

      await service.saveLastVendor('VEN-123');
      expect(service.getLastVendor(), 'VEN-123');
    });

    test('saves and retrieves last selected capacities', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = UserPreferencesService(prefs);

      expect(service.getLastSelectedCapacities(), isNull);

      await service.saveLastSelectedCapacities(['50', '100']);
      expect(service.getLastSelectedCapacities(), ['50', '100']);
    });

    test('saves and retrieves billing filters', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = UserPreferencesService(prefs);

      expect(service.getLastBillingVendorFilter(), isNull);
      expect(service.getLastBillingStatusFilter(), isNull);

      await service.saveLastBillingVendorFilter('VEN-999');
      await service.saveLastBillingStatusFilter('confirmed');

      expect(service.getLastBillingVendorFilter(), 'VEN-999');
      expect(service.getLastBillingStatusFilter(), 'confirmed');
    });

    test('saves and retrieves billing date range', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = UserPreferencesService(prefs);

      expect(service.getLastBillingDateRange(), isNull);

      final start = DateTime.utc(2026, 7, 1);
      final end = DateTime.utc(2026, 7, 31);

      await service.saveLastBillingDateRange(start, end);
      
      final range = service.getLastBillingDateRange();
      expect(range, isNotNull);
      expect(range!['start'], start);
      expect(range['end'], end);
    });

    test('clears all preferences', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = UserPreferencesService(prefs);

      await service.saveLastVendor('VEN-123');
      await service.saveLastSelectedCapacities(['50']);
      
      await service.clearAllPreferences();

      expect(service.getLastVendor(), isNull);
      expect(service.getLastSelectedCapacities(), isNull);
    });
  });
}
