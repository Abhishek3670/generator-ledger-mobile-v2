class Vendor {
  final String vendorId;
  final String name;
  final String type;
  final String location;
  final String phone;

  const Vendor({
    required String id,
    required this.name,
    required String category,
    required this.location,
    required this.phone,
  }) : vendorId = id,
       type = category;

  String get id => vendorId;
  String get category => type;

  Vendor copyWith({
    String? id,
    String? name,
    String? category,
    String? location,
    String? phone,
  }) {
    return Vendor(
      id: id ?? vendorId,
      name: name ?? this.name,
      category: category ?? type,
      location: location ?? this.location,
      phone: phone ?? this.phone,
    );
  }

  factory Vendor.fromMap(Map<String, dynamic> map) {
    final categoryValue = _string(map, ['type', 'category', 'vendor_type']);
    return Vendor(
      id: _string(map, ['vendorId', 'vendor_id', 'id']),
      name: _string(map, ['name', 'vendor_name']),
      category: categoryValue.isEmpty ? 'retailer' : categoryValue,
      location: _string(map, ['location', 'place', 'address']),
      phone: _string(map, ['phone', 'phone_number', 'mobile']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vendor_id': vendorId,
      'name': name,
      'type': type,
      'location': location,
      'phone': phone,
    };
  }

  static String _string(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String) {
        return value;
      }
      if (value != null) {
        return value.toString();
      }
    }
    return '';
  }
}
