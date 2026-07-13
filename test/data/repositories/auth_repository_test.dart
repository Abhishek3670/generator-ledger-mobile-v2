import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/core/services/api_client.dart';
import 'package:ledger/core/services/token_storage.dart';
import 'package:ledger/data/repositories/auth_repository.dart';

void main() {
  group('AuthRepository', () {
    test('login posts credentials and stores returned token', () async {
      final apiClient = _FakeApiClient(
        loginResponse: {
          'token': 'jwt-token',
          'user': {'username': 'owner', 'role': 'admin'},
        },
      );
      final tokenStorage = TokenStorage(backend: _FakeTokenStorageBackend());
      final repository = AuthRepository(
        apiClient: apiClient,
        tokenStorage: tokenStorage,
      );

      final response = await repository.login('owner', 'Qwerty@345');

      expect(apiClient.lastPostPath, AuthRepository.loginPath);
      expect(apiClient.lastPostData, {
        'username': 'owner',
        'password': 'Qwerty@345',
      });
      expect(response.token, 'jwt-token');
      expect(response.user.username, 'owner');
      expect(response.user.role, 'admin');
      expect(await tokenStorage.getToken(), 'jwt-token');
    });

    test('logout deletes local token after backend logout', () async {
      final apiClient = _FakeApiClient();
      final tokenStorage = TokenStorage(backend: _FakeTokenStorageBackend());
      final repository = AuthRepository(
        apiClient: apiClient,
        tokenStorage: tokenStorage,
      );
      await tokenStorage.saveToken('jwt-token');

      await repository.logout();

      expect(apiClient.lastPostPath, AuthRepository.logoutPath);
      expect(await tokenStorage.getToken(), isNull);
    });

    test('isAuthenticated checks token presence', () async {
      final tokenStorage = TokenStorage(backend: _FakeTokenStorageBackend());
      final repository = AuthRepository(
        apiClient: _FakeApiClient(),
        tokenStorage: tokenStorage,
      );

      expect(await repository.isAuthenticated(), isFalse);

      await tokenStorage.saveToken('jwt-token');

      expect(await repository.isAuthenticated(), isTrue);
    });
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.loginResponse})
    : super(tokenStorage: TokenStorage(backend: _FakeTokenStorageBackend()));

  final Map<String, dynamic>? loginResponse;
  String? lastPostPath;
  Object? lastPostData;
  String? lastDeletePath;

  @override
  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required JsonParser<T> fromJson,
  }) async {
    lastPostPath = path;
    lastPostData = data;
    return fromJson(loginResponse ?? {});
  }

  @override
  Future<T> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required JsonParser<T> fromJson,
  }) async {
    lastDeletePath = path;
    return fromJson(null);
  }
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
