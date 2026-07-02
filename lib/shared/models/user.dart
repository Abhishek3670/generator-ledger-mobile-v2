class User {
  final String username;
  final String role;
  final String status;
  final DateTime lastLogin;
  final DateTime createdAt;

  const User({
    required this.username,
    required this.role,
    required this.status,
    required this.lastLogin,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  Map<String, String> toMap() {
    return {
      'username': username,
      'role': role,
      'status': status,
      'lastLogin': _date(lastLogin),
      'created': _date(createdAt),
    };
  }

  static User fromMap(Map<String, String> map) {
    return User(
      username: map['username'] ?? '',
      role: map['role'] ?? 'operator',
      status: map['status'] ?? 'ACTIVE',
      lastLogin: DateTime.tryParse(map['lastLogin'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(map['created'] ?? '') ?? DateTime.now(),
    );
  }

  User copyWith({
    String? username,
    String? role,
    String? status,
    DateTime? lastLogin,
    DateTime? createdAt,
  }) {
    return User(
      username: username ?? this.username,
      role: role ?? this.role,
      status: status ?? this.status,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static String _date(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
