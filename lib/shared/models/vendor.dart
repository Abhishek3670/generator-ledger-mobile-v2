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
  })  : vendorId = id,
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
}
