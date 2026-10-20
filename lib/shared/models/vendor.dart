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
    final idValue = _string(map, ['id', 'vendorId', 'vendor_id', 'rental_vendor_id']);
    String category = categoryValue;
    if (category.isEmpty) {
      if (idValue.startsWith('RV') || idValue.startsWith('RNV')) {
        category = 'rental';
      } else {
        category = 'retailer';
      }
    }
    return Vendor(
      id: idValue,
      name: _string(map, ['name', 'vendor_name']),
      category: category,
      location: _string(map, ['location', 'place', 'vendor_place', 'address']),
      phone: _string(map, ['phone', 'phone_number', 'mobile']),
    );
  }

  Map<String, dynamic> toCreatePayload() {
    final isRental = type.toLowerCase() == 'rental';
    final payload = <String, dynamic>{
      'vendor_name': name,
      'vendor_place': location.isNotEmpty ? location : 'Civil Line',
      'phone': phone,
    };
    if (vendorId.isNotEmpty &&
        !vendorId.startsWith('VEN-') &&
        !vendorId.startsWith('RV-') &&
        !vendorId.startsWith('RNV-')) {
      if (isRental) {
        payload['rental_vendor_id'] = vendorId;
      } else {
        payload['vendor_id'] = vendorId;
      }
    }
    return payload;
  }

  Map<String, dynamic> toUpdatePayload() {
    return {
      'vendor_name': name,
      'vendor_place': location.isNotEmpty ? location : 'Civil Line',
      'phone': phone,
    };
  }

  Map<String, dynamic> toMap() {
    final isRental = type.toLowerCase() == 'rental';
    final hasRealId = vendorId.isNotEmpty &&
        !vendorId.startsWith('VEN-') &&
        !vendorId.startsWith('RV-') &&
        !vendorId.startsWith('RNV-');
    return {
      if (hasRealId) ...{
        'vendor_id': vendorId,
        if (isRental) 'rental_vendor_id': vendorId,
      },
      'name': name,
      'vendor_name': name,
      'type': type,
      'location': location,
      'vendor_place': location.isNotEmpty ? location : 'Civil Line',
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
