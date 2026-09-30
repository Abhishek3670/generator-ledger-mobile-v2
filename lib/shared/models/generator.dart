class Generator {
  final String generatorId;
  final String capacity;
  final String type;
  final String inventoryGroup;
  final String status;
  final String? assignedVendor;
  final String? bookingStatus;

  const Generator({
    required String id,
    required this.capacity,
    required this.type,
    required String category,
    required this.status,
    this.assignedVendor,
    this.bookingStatus,
  }) : generatorId = id,
       inventoryGroup = category;

  String get id => generatorId;
  String get category => inventoryGroup;

  Generator copyWith({
    String? id,
    String? capacity,
    String? type,
    String? category,
    String? status,
    String? assignedVendor,
    String? bookingStatus,
  }) {
    return Generator(
      id: id ?? generatorId,
      capacity: capacity ?? this.capacity,
      type: type ?? this.type,
      category: category ?? inventoryGroup,
      status: status ?? this.status,
      assignedVendor: assignedVendor ?? this.assignedVendor,
      bookingStatus: bookingStatus ?? this.bookingStatus,
    );
  }

  factory Generator.fromMap(Map<String, dynamic> map) {
    return Generator(
      id: _string(map, ['generatorId', 'generator_id', 'id']),
      capacity: _capacity(map),
      type: _string(map, ['type', 'model', 'engine_type']),
      category: _string(map, ['inventoryGroup', 'inventory_group', 'inventory_type', 'category']),
      status: _string(map, ['status', 'operational_status']),
      assignedVendor: _nullableString(map, [
        'assignedVendor',
        'assigned_vendor',
        'assigned_vendor_name',
        'rental_vendor_name',
      ]),
      bookingStatus: _nullableString(map, ['booking_status', 'bookingStatus']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'generator_id': generatorId,
      'capacity': capacity,
      'type': type,
      'inventory_group': inventoryGroup,
      'operational_status': status,
      if (assignedVendor != null) 'assigned_vendor': assignedVendor,
      if (bookingStatus != null) 'booking_status': bookingStatus,
    };
  }

  static String _capacity(Map<String, dynamic> map) {
    final value = map['capacity'] ?? map['capacity_kva'] ?? map['kva'];
    if (value is num) {
      return '${value.toString()} kVA';
    }
    if (value is String && value.isNotEmpty) {
      return value.toLowerCase().contains('kva') ? value : '$value kVA';
    }
    return '';
  }

  static String _string(Map<String, dynamic> map, List<String> keys) {
    return _nullableString(map, keys) ?? '';
  }

  static String? _nullableString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String) {
        return value;
      }
      if (value != null) {
        return value.toString();
      }
    }
    return null;
  }
}
