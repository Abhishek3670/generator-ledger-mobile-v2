import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  return FakeSharedPreferences();
});

final userPreferencesServiceProvider = Provider<UserPreferencesService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UserPreferencesService(prefs);
});

class UserPreferencesService {
  static const _lastVendorKey = 'last_selected_vendor';
  static const _lastCapacityKey = 'last_selected_capacity';
  static const _lastBillingVendorFilterKey = 'last_billing_vendor_filter';
  static const _lastBillingStatusFilterKey = 'last_billing_status_filter';
  static const _lastBillingDateRangeStartKey = 'last_billing_date_range_start';
  static const _lastBillingDateRangeEndKey = 'last_billing_date_range_end';

  final SharedPreferences _prefs;

  UserPreferencesService(this._prefs);

  Future<void> saveLastVendor(String vendorId) async {
    await _prefs.setString(_lastVendorKey, vendorId);
  }

  String? getLastVendor() {
    return _prefs.getString(_lastVendorKey);
  }

  Future<void> saveLastSelectedCapacities(List<String> capacities) async {
    await _prefs.setStringList(_lastCapacityKey, capacities);
  }

  List<String>? getLastSelectedCapacities() {
    return _prefs.getStringList(_lastCapacityKey);
  }

  Future<void> saveLastBillingVendorFilter(String vendorId) async {
    await _prefs.setString(_lastBillingVendorFilterKey, vendorId);
  }

  String? getLastBillingVendorFilter() {
    return _prefs.getString(_lastBillingVendorFilterKey);
  }

  Future<void> saveLastBillingStatusFilter(String status) async {
    await _prefs.setString(_lastBillingStatusFilterKey, status);
  }

  String? getLastBillingStatusFilter() {
    return _prefs.getString(_lastBillingStatusFilterKey);
  }

  Future<void> saveLastBillingDateRange(DateTime start, DateTime end) async {
    await _prefs.setString(_lastBillingDateRangeStartKey, start.toIso8601String());
    await _prefs.setString(_lastBillingDateRangeEndKey, end.toIso8601String());
  }

  Map<String, DateTime>? getLastBillingDateRange() {
    final startStr = _prefs.getString(_lastBillingDateRangeStartKey);
    final endStr = _prefs.getString(_lastBillingDateRangeEndKey);
    if (startStr == null || endStr == null) return null;
    try {
      return {
        'start': DateTime.parse(startStr),
        'end': DateTime.parse(endStr),
      };
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAllPreferences() async {
    await _prefs.remove(_lastVendorKey);
    await _prefs.remove(_lastCapacityKey);
    await _prefs.remove(_lastBillingVendorFilterKey);
    await _prefs.remove(_lastBillingStatusFilterKey);
    await _prefs.remove(_lastBillingDateRangeStartKey);
    await _prefs.remove(_lastBillingDateRangeEndKey);
  }
}

class FakeSharedPreferences implements SharedPreferences {
  final Map<String, Object> _values = {};

  @override
  Set<String> getKeys() => _values.keys.toSet();

  @override
  Object? get(String key) => _values[key];

  @override
  bool? getBool(String key) => _values[key] as bool?;

  @override
  double? getDouble(String key) => _values[key] as double?;

  @override
  int? getInt(String key) => _values[key] as int?;

  @override
  String? getString(String key) => _values[key] as String?;

  @override
  List<String>? getStringList(String key) => _values[key] as List<String>?;

  @override
  bool containsKey(String key) => _values.containsKey(key);

  @override
  Future<bool> setBool(String key, bool value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _values.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _values.clear();
    return true;
  }

  @override
  Future<bool> commit() async => true;

  @override
  Future<void> reload() async {}
}
