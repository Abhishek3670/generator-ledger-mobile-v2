import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/core/services/token_storage.dart';

void main() {
  group('TokenStorage', () {
    late _FakeTokenStorageBackend backend;
    late TokenStorage storage;

    setUp(() {
      backend = _FakeTokenStorageBackend();
      storage = TokenStorage(backend: backend);
    });

    // ── Access token ─────────────────────────────────────────────────────────

    test('saves and reads access token', () async {
      await storage.saveToken('access-token');

      expect(await storage.getToken(), 'access-token');
      expect(backend.values[TokenStorage.tokenKey], 'access-token');
    });

    test('deletes access token', () async {
      await storage.saveToken('access-token');
      await storage.deleteToken();

      expect(await storage.getToken(), isNull);
    });

    // ── Refresh token ────────────────────────────────────────────────────────

    test('saves and reads refresh token', () async {
      await storage.saveRefreshToken('refresh-token');

      expect(await storage.getRefreshToken(), 'refresh-token');
      expect(backend.values[TokenStorage.refreshTokenKey], 'refresh-token');
    });

    test('deletes refresh token', () async {
      await storage.saveRefreshToken('refresh-token');
      await storage.deleteRefreshToken();

      expect(await storage.getRefreshToken(), isNull);
    });

    // ── Cached user ──────────────────────────────────────────────────────────

    test('saves and reads user JSON', () async {
      await storage.saveUserJson('{"username":"alice"}');

      expect(await storage.getUserJson(), '{"username":"alice"}');
    });

    test('deletes user JSON', () async {
      await storage.saveUserJson('{"username":"alice"}');
      await storage.deleteUserJson();

      expect(await storage.getUserJson(), isNull);
    });

    // ── clearAll ─────────────────────────────────────────────────────────────

    test('clearAll removes access token, refresh token, and cached user', () async {
      await storage.saveToken('access-token');
      await storage.saveRefreshToken('refresh-token');
      await storage.saveUserJson('{"username":"alice"}');

      await storage.clearAll();

      expect(await storage.getToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.getUserJson(), isNull);
    });

    test('clearAll is idempotent when storage is already empty', () async {
      // Should not throw.
      await expectLater(storage.clearAll(), completes);
    });
  });
}

// ── Fake backend ──────────────────────────────────────────────────────────────

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
