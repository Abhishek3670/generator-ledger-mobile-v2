class Permission {
  final String capability;
  final String label;
  final String description;
  final bool admin;
  final bool operator;

  const Permission({
    required this.capability,
    required this.label,
    required this.description,
    required this.admin,
    required this.operator,
  });

  factory Permission.fromMap(Map<String, dynamic> map) {
    return Permission(
      capability: (map['capability'] ?? '').toString(),
      label: (map['label'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      admin: map['admin'] == true || map['admin'] == 1,
      operator: map['operator'] == true || map['operator'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'capability': capability,
      'label': label,
      'description': description,
      'admin': admin,
      'operator': operator,
    };
  }
}
