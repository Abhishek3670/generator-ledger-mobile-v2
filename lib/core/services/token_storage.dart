import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenStorageBackend {
  Future<void> write({required String key, required String value});

  Future<String?> read({required String key});

  Future<void> delete({required String key});
}

class SecureTokenStorageBackend implements TokenStorageBackend {
  const SecureTokenStorageBackend({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
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

class TokenStorage {
  TokenStorage({
    TokenStorageBackend backend = const SecureTokenStorageBackend(),
  }) : _backend = backend;

  static const String tokenKey = 'auth_token';

  final TokenStorageBackend _backend;

  Future<void> saveToken(String token) {
    return _backend.write(key: tokenKey, value: token);
  }

  Future<String?> getToken() {
    return _backend.read(key: tokenKey);
  }

  Future<void> deleteToken() {
    return _backend.delete(key: tokenKey);
  }
}
