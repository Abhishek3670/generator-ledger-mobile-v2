import '../../shared/models/user.dart';

class LoginResponse {
  const LoginResponse({
    required this.token,
    required this.user,
    this.refreshToken,
  });

  /// Short-lived access token.
  final String token;

  /// The authenticated user.
  final User user;

  /// Long-lived rotating refresh token, if the backend provides one.
  /// Absent when the server does not (yet) issue refresh tokens.
  final String? refreshToken;

  factory LoginResponse.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Login response must be a JSON object');
    }

    // Backend returns "access_token"; also accept bare "token" for compatibility.
    final token = json['access_token'] ?? json['token'];
    if (token is! String || token.isEmpty) {
      throw const FormatException(
        'Login response is missing token (tried "access_token" and "token")',
      );
    }

    // Refresh token is optional — backends that don't support it simply omit it.
    final refresh = json['refresh_token'] ?? json['refreshToken'];
    final refreshToken = (refresh is String && refresh.isNotEmpty) ? refresh : null;

    final rawUser = json['user'];
    final user = rawUser is Map<String, dynamic>
        ? User.fromMap(rawUser)
        : _userFromJson(json);

    return LoginResponse(token: token, user: user, refreshToken: refreshToken);
  }

  // Kept for backward-compat with tests that pass a flat map without a "user" key.
  static User _userFromJson(Map<String, dynamic> json) {
    return User.fromMap(json);
  }
}
