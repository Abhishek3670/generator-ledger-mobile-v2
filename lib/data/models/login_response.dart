import '../../shared/models/user.dart';

class LoginResponse {
  const LoginResponse({required this.token, required this.user});

  final String token;
  final User user;

  factory LoginResponse.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Login response must be a JSON object');
    }

    // Backend returns "access_token", try both "token" and "access_token"
    final token = json['token'] ?? json['access_token'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('Login response is missing token (tried both "token" and "access_token")');
    }

    final rawUser = json['user'];
    if (rawUser is Map<String, dynamic>) {
      return LoginResponse(token: token, user: _userFromJson(rawUser));
    }

    return LoginResponse(token: token, user: _userFromJson(json));
  }

  static User _userFromJson(Map<String, dynamic> json) {
    return User(
      username: _string(json, ['username', 'name', 'email']),
      role: _string(json, ['role'], fallback: 'operator'),
      status: _string(json, ['status'], fallback: 'ACTIVE'),
      lastLogin: _date(json, ['lastLogin', 'last_login']),
      createdAt: _date(json, ['createdAt', 'created_at', 'created']),
    );
  }

  static String _string(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return fallback;
  }

  static DateTime _date(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return DateTime.now();
  }
}
