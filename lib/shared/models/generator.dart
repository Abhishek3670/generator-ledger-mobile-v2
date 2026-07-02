class Generator {
  final String generatorId;
  final String capacity;
  final String type;
  final String inventoryGroup;
  final String status;
  final String? assignedVendor;

  const Generator({
    required String id,
    required this.capacity,
    required this.type,
    required String category,
    required this.status,
    this.assignedVendor,
  })  : generatorId = id,
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
  }) {
    return Generator(
      id: id ?? generatorId,
      capacity: capacity ?? this.capacity,
      type: type ?? this.type,
      category: category ?? inventoryGroup,
      status: status ?? this.status,
      assignedVendor: assignedVendor ?? this.assignedVendor,
    );
  }
}
