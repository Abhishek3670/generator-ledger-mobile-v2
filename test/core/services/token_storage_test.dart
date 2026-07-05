import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/core/services/token_storage.dart';

void main() {
  group('TokenStorage', () {
    test('saves and reads token', () async {
      final backend = _FakeTokenStorageBackend();
      final storage = TokenStorage(backend: backend);

      await storage.saveToken('jwt-token');

      expect(await storage.getToken(), 'jwt-token');
      expect(backend.values[TokenStorage.tokenKey], 'jwt-token');
    });

    test('deletes token', () async {
      final backend = _FakeTokenStorageBackend();
      final storage = TokenStorage(backend: backend);

      await storage.saveToken('jwt-token');
      await storage.deleteToken();

      expect(await storage.getToken(), isNull);
    });
  });
}

class _FakeTokenStorageBackend implements TokenStorageBackend {
  final Map<String, String> values = {};

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> delete({required String key}) async {
    values.remove(key);
  }
}
