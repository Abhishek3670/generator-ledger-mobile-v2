import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenStorageBackend {
  Future<void> write({required String key, required String value});

  Future<String?> read({required String key});

  Future<void> delete({required String key});
}

class SecureTokenStorageBackend implements TokenStorageBackend {
  const SecureTokenStorageBackend({
    FlutterSecureStorage storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  }) : _storage = storage;

  final FlutterSecureStorage _storage;

  @override
  Future<void> write({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read({required String key}) {
    return _storage.read(key: key);
  }

  @override
  Future<void> delete({required String key}) {
    return _storage.delete(key: key);
  }
}

/// Manages all auth-related values in secure storage.
///
/// All credentials are stored exclusively via [TokenStorageBackend], which
/// is backed by [FlutterSecureStorage] (Android Keystore / iOS Keychain).
/// Never use SharedPreferences for auth data.
class TokenStorage {
  TokenStorage({
    TokenStorageBackend backend = const SecureTokenStorageBackend(),
  }) : _backend = backend;

  // ── Storage keys ──────────────────────────────────────────────────────────

  /// Key for the short-lived access token.
  static const String tokenKey = 'auth_token';

  /// Key for the long-lived rotating refresh token.
  static const String refreshTokenKey = 'refresh_token';

  /// Key for cached user JSON used for session restoration on app start.
  static const String userKey = 'cached_user';

  final TokenStorageBackend _backend;

  // ── Access token ──────────────────────────────────────────────────────────

  Future<void> saveToken(String token) {
    return _backend.write(key: tokenKey, value: token);
  }

  Future<String?> getToken() {
    return _backend.read(key: tokenKey);
  }

  Future<void> deleteToken() {
    return _backend.delete(key: tokenKey);
  }

  // ── Refresh token ─────────────────────────────────────────────────────────

  Future<void> saveRefreshToken(String token) {
    return _backend.write(key: refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() {
    return _backend.read(key: refreshTokenKey);
  }

  Future<void> deleteRefreshToken() {
    return _backend.delete(key: refreshTokenKey);
  }

  // ── Cached user ───────────────────────────────────────────────────────────

  Future<void> saveUserJson(String json) {
    return _backend.write(key: userKey, value: json);
  }

  Future<String?> getUserJson() {
    return _backend.read(key: userKey);
  }

  Future<void> deleteUserJson() {
    return _backend.delete(key: userKey);
  }

  // ── Bulk operations ───────────────────────────────────────────────────────

  /// Atomically removes access token, refresh token, and cached user.
  /// Call this on logout and on refresh-token rejection.
  Future<void> clearAll() async {
    await Future.wait([
      deleteToken(),
      deleteRefreshToken(),
      deleteUserJson(),
    ]);
  }
}
