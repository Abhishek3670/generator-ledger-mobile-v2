class User {
  final String? userId;
  final String username;
  final String role;
  final String status;
  final DateTime? lastLogin;
  final DateTime createdAt;

  const User({
    this.userId,
    required this.username,
    required this.role,
    required this.status,
    this.lastLogin,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toMap() {
    return {
      if (userId != null) 'user_id': userId,
      'username': username,
      'role': role,
      'status': status,
      if (lastLogin != null) 'last_login': lastLogin!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      userId: (map['user_id'] ?? map['userId'])?.toString(),
      username: (map['username'] ?? '').toString(),
      role: (map['role'] ?? 'operator').toString(),
      status: (map['status'] ?? 'ACTIVE').toString(),
      lastLogin: _parseDate(map['last_login'] ?? map['lastLogin']),
      createdAt: _parseDate(
        map['created_at'] ?? map['createdAt'] ?? map['created'],
        fallback: DateTime.now(),
      )!,
    );
  }

  User copyWith({
    String? userId,
    String? username,
    String? role,
    String? status,
    DateTime? lastLogin,
    DateTime? createdAt,
  }) {
    return User(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      role: role ?? this.role,
      status: status ?? this.status,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static DateTime? _parseDate(dynamic value, {DateTime? fallback}) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return fallback;
  }
}
