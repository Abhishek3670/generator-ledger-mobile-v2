import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/core/services/api_client.dart';
import 'package:ledger/core/services/token_storage.dart';
import 'package:ledger/data/repositories/auth_repository.dart';

void main() {
  group('AuthRepository', () {
    late _FakeApiClient apiClient;
    late _FakeTokenStorageBackend backendStore;
    late TokenStorage tokenStorage;
    late AuthRepository repository;

    setUp(() {
      backendStore = _FakeTokenStorageBackend();
      tokenStorage = TokenStorage(backend: backendStore);
      apiClient = _FakeApiClient(tokenStorage: tokenStorage);
      repository = AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);
    });

    // ── login ────────────────────────────────────────────────────────────────

    test('login posts credentials and stores access token', () async {
      apiClient.nextPostResponse = {
        'access_token': 'access-jwt',
        'user': {'username': 'owner', 'role': 'admin'},
      };

      final response = await repository.login('owner', 'Qwerty@345');

      expect(apiClient.lastPostPath, AuthRepository.loginPath);
      expect(apiClient.lastPostData, {'username': 'owner', 'password': 'Qwerty@345'});
      expect(response.token, 'access-jwt');
      expect(response.user.username, 'owner');
      expect(await tokenStorage.getToken(), 'access-jwt');
    });

    test('login stores refresh token when backend provides it', () async {
      apiClient.nextPostResponse = {
        'access_token': 'access-jwt',
        'refresh_token': 'refresh-jwt',
        'user': {'username': 'owner', 'role': 'admin'},
      };

      await repository.login('owner', 'Qwerty@345');

      expect(await tokenStorage.getRefreshToken(), 'refresh-jwt');
    });

    test('login does not error when backend omits refresh token', () async {
      apiClient.nextPostResponse = {
        'access_token': 'access-jwt',
        'user': {'username': 'owner', 'role': 'admin'},
      };

      await expectLater(repository.login('owner', 'secret'), completes);
      expect(await tokenStorage.getRefreshToken(), isNull);
    });

    test('login caches user JSON in storage', () async {
      apiClient.nextPostResponse = {
        'access_token': 'access-jwt',
        'user': {'username': 'alice', 'role': 'admin'},
      };

      await repository.login('alice', 'secret');

      final userJson = await tokenStorage.getUserJson();
      expect(userJson, isNotNull);
      expect(userJson, contains('alice'));
    });

    // ── logout ───────────────────────────────────────────────────────────────

    test('logout calls backend and clears all credentials', () async {
      await tokenStorage.saveToken('access-jwt');
      await tokenStorage.saveRefreshToken('refresh-jwt');
      await tokenStorage.saveUserJson('{"username":"alice"}');

      await repository.logout();

      expect(apiClient.lastPostPath, AuthRepository.logoutPath);
      expect(await tokenStorage.getToken(), isNull);
      expect(await tokenStorage.getRefreshToken(), isNull);
      expect(await tokenStorage.getUserJson(), isNull);
    });

    test('logout still clears credentials even if backend call fails', () async {
      apiClient.nextPostError = Exception('network error');
      await tokenStorage.saveToken('access-jwt');
      await tokenStorage.saveRefreshToken('refresh-jwt');

      // logout() swallows backend errors and always clears local storage.
      await repository.logout();

      expect(await tokenStorage.getToken(), isNull);
      expect(await tokenStorage.getRefreshToken(), isNull);
    });

    // ── isAuthenticated ───────────────────────────────────────────────────────

    test('isAuthenticated returns false when no token stored', () async {
      expect(await repository.isAuthenticated(), isFalse);
    });

    test('isAuthenticated returns true when token stored', () async {
      await tokenStorage.saveToken('access-jwt');
      expect(await repository.isAuthenticated(), isTrue);
    });

    // ── refreshAccessToken ────────────────────────────────────────────────────

    test('refreshAccessToken returns null when no refresh token stored', () async {
      final result = await repository.refreshAccessToken();
      expect(result, isNull);
    });

    test('refreshAccessToken exchanges refresh token and returns new access token',
        () async {
      await tokenStorage.saveRefreshToken('old-refresh');
      apiClient.nextPostResponse = {
        'access_token': 'new-access',
        'refresh_token': 'new-refresh',
      };

      final result = await repository.refreshAccessToken();

      expect(result, 'new-access');
      expect(await tokenStorage.getToken(), 'new-access');
      expect(await tokenStorage.getRefreshToken(), 'new-refresh');
      expect(apiClient.lastPostPath, AuthRepository.refreshPath);
      expect(apiClient.lastPostData, {'refresh_token': 'old-refresh'});
    });

    test('refreshAccessToken updates refresh token if rotated', () async {
      await tokenStorage.saveRefreshToken('old-refresh');
      apiClient.nextPostResponse = {
        'access_token': 'new-access',
        'refresh_token': 'rotated-refresh',
      };

      await repository.refreshAccessToken();

      expect(await tokenStorage.getRefreshToken(), 'rotated-refresh');
    });

    test('refreshAccessToken returns null and clears storage on 401', () async {
      await tokenStorage.saveToken('stale-access');
      await tokenStorage.saveRefreshToken('bad-refresh');
      apiClient.nextDioError = _fakeDioError(401);

      final result = await repository.refreshAccessToken();

      expect(result, isNull);
      expect(await tokenStorage.getToken(), isNull);
      expect(await tokenStorage.getRefreshToken(), isNull);
    });

    test('refreshAccessToken returns null and clears storage on 403', () async {
      await tokenStorage.saveToken('stale-access');
      await tokenStorage.saveRefreshToken('revoked-refresh');
      apiClient.nextDioError = _fakeDioError(403);

      final result = await repository.refreshAccessToken();

      expect(result, isNull);
      expect(await tokenStorage.getToken(), isNull);
    });

    test(
        'refreshAccessToken returns null but does NOT clear storage on network error',
        () async {
      await tokenStorage.saveToken('valid-access');
      await tokenStorage.saveRefreshToken('valid-refresh');
      apiClient.nextDioError = _fakeDioError(null); // connection error, no status

      final result = await repository.refreshAccessToken();

      expect(result, isNull);
      // Credentials must be preserved so the user stays in-app.
      expect(await tokenStorage.getToken(), 'valid-access');
      expect(await tokenStorage.getRefreshToken(), 'valid-refresh');
    });

    // ── getCachedUserJson ─────────────────────────────────────────────────────

    test('getCachedUserJson returns stored JSON', () async {
      await tokenStorage.saveUserJson('{"username":"bob"}');

      expect(await repository.getCachedUserJson(), '{"username":"bob"}');
    });

    test('getCachedUserJson returns null when nothing cached', () async {
      expect(await repository.getCachedUserJson(), isNull);
    });
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

DioException _fakeDioError(int? statusCode) {
  final response = statusCode != null
      ? Response<dynamic>(
          requestOptions: RequestOptions(path: ''),
          statusCode: statusCode,
        )
      : null;
  return DioException(
    requestOptions: RequestOptions(path: ''),
    response: response,
    type: statusCode == null
        ? DioExceptionType.connectionError
        : DioExceptionType.badResponse,
  );
}

// ── Fakes ──────────────────────────────────────────────────────────────────────

class _FakeApiClient extends ApiClient {
  _FakeApiClient({required TokenStorage tokenStorage})
      : super(tokenStorage: tokenStorage);

  Map<String, dynamic>? nextPostResponse;
  Exception? nextPostError;
  DioException? nextDioError;

  String? lastPostPath;
  Object? lastPostData;

  @override
  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required JsonParser<T> fromJson,
  }) async {
    lastPostPath = path;
    lastPostData = data;

    if (nextDioError != null) {
      final err = nextDioError!;
      nextDioError = null;
      throw err;
    }
    if (nextPostError != null) {
      final err = nextPostError!;
      nextPostError = null;
      throw err;
    }
    final response = nextPostResponse ?? <String, dynamic>{};
    nextPostResponse = null;
    return fromJson(response);
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
