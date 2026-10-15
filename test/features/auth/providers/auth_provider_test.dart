import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/core/services/api_client.dart';
import 'package:ledger/core/services/token_storage.dart';
import 'package:ledger/data/repositories/auth_repository.dart';
import 'package:ledger/features/auth/providers/auth_provider.dart';
import 'package:ledger/shared/models/user.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthNotifier - Session Restoration & Auth Lifecycle', () {
    late _FakeTokenStorageBackend storageBackend;
    late TokenStorage tokenStorage;
    late _FakeApiClient apiClient;
    late AuthRepository authRepository;

    final testUser = User(
      userId: 'usr_1',
      username: 'alice',
      role: 'admin',
      status: 'ACTIVE',
      lastLogin: DateTime.parse('2026-10-15T10:00:00Z'),
      createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
    );

    setUp(() {
      storageBackend = _FakeTokenStorageBackend();
      tokenStorage = TokenStorage(backend: storageBackend);
      apiClient = _FakeApiClient(tokenStorage: tokenStorage);
      authRepository = AuthRepository(
        apiClient: apiClient,
        tokenStorage: tokenStorage,
      );
    });

    test('restoreSession: not authenticated -> clearAuth (state is null)', () async {
      final notifier = AuthNotifier(authRepository);
      await pumpEventQueue();

      expect(notifier.state.hasValue, isTrue);
      expect(notifier.state.value, isNull);
      notifier.dispose();
    });

    test('restoreSession: authenticated + verify passes -> user loaded from cache', () async {
      await tokenStorage.saveToken('valid-access-token');
      await tokenStorage.saveUserJson(jsonEncode(testUser.toJson()));

      apiClient.onGet = (path) {
        if (path == AuthRepository.verifyPath) return true;
        return true;
      };

      final notifier = AuthNotifier(authRepository);
      await pumpEventQueue();

      expect(notifier.state.hasValue, isTrue);
      expect(notifier.state.value, isNotNull);
      expect(notifier.state.value!.username, 'alice');
      expect(notifier.state.value!.role, 'admin');
      notifier.dispose();
    });

    test(
        'restoreSession: authenticated + verify fails + refresh succeeds -> re-verify passes and user loaded',
        () async {
      await tokenStorage.saveToken('expired-access-token');
      await tokenStorage.saveRefreshToken('valid-refresh-token');
      await tokenStorage.saveUserJson(jsonEncode(testUser.toJson()));

      var verifyCallCount = 0;
      apiClient.onGet = (path) {
        if (path == AuthRepository.verifyPath) {
          verifyCallCount++;
          // First verify throws 401 (token expired), second passes after refresh
          if (verifyCallCount == 1) {
            throw DioException(
              requestOptions: RequestOptions(path: path),
              response: Response(
                statusCode: 401,
                requestOptions: RequestOptions(path: path),
              ),
              type: DioExceptionType.badResponse,
            );
          }
          return true;
        }
        return true;
      };

      apiClient.onPost = (path, data) {
        if (path == AuthRepository.refreshPath) {
          return {
            'access_token': 'renewed-access-token',
            'refresh_token': 'new-refresh-token',
          };
        }
        return <String, dynamic>{};
      };

      final notifier = AuthNotifier(authRepository);
      await pumpEventQueue();

      expect(verifyCallCount, 2);
      expect(notifier.state.hasValue, isTrue);
      expect(notifier.state.value, isNotNull);
      expect(notifier.state.value!.username, 'alice');
      expect(await tokenStorage.getToken(), 'renewed-access-token');
      notifier.dispose();
    });

    test(
        'restoreSession: authenticated + verify fails + refresh fails -> clearAuth (state is null)',
        () async {
      await tokenStorage.saveToken('expired-access-token');
      await tokenStorage.saveRefreshToken('revoked-refresh-token');
      await tokenStorage.saveUserJson(jsonEncode(testUser.toJson()));

      apiClient.onGet = (path) {
        if (path == AuthRepository.verifyPath) {
          throw DioException(
            requestOptions: RequestOptions(path: path),
            response: Response(
              statusCode: 401,
              requestOptions: RequestOptions(path: path),
            ),
            type: DioExceptionType.badResponse,
          );
        }
        return true;
      };

      apiClient.onPost = (path, data) {
        if (path == AuthRepository.refreshPath) {
          throw DioException(
            requestOptions: RequestOptions(path: path),
            response: Response(
              statusCode: 401,
              requestOptions: RequestOptions(path: path),
            ),
            type: DioExceptionType.badResponse,
          );
        }
        return <String, dynamic>{};
      };

      final notifier = AuthNotifier(authRepository);
      await pumpEventQueue();

      expect(notifier.state.hasValue, isTrue);
      expect(notifier.state.value, isNull);
      expect(await tokenStorage.getToken(), isNull);
      notifier.dispose();
    });

    test(
        'restoreSession: authenticated + verify returns 404 (non-existent backend endpoint) -> preserves cached user',
        () async {
      await tokenStorage.saveToken('valid-access-token');
      await tokenStorage.saveUserJson(jsonEncode(testUser.toJson()));

      apiClient.onGet = (path) {
        if (path == AuthRepository.verifyPath) {
          throw DioException(
            requestOptions: RequestOptions(path: path),
            response: Response(
              statusCode: 404,
              requestOptions: RequestOptions(path: path),
            ),
            type: DioExceptionType.badResponse,
          );
        }
        return true;
      };

      final notifier = AuthNotifier(authRepository);
      await pumpEventQueue();

      expect(notifier.state.hasValue, isTrue);
      expect(notifier.state.value, isNotNull);
      expect(notifier.state.value!.username, 'alice');
      notifier.dispose();
    });

    test(
        'restoreSession: cached user missing -> extracts user claims from JWT token payload',
        () async {
      // JWT token with base64url payload {"sub":"jwt_operator","role":"operator"}
      const header = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
      final payload = base64Url
          .encode(utf8.encode(jsonEncode({'sub': 'jwt_operator', 'role': 'operator'})))
          .replaceAll('=', '');
      const signature = 'fake_signature';
      final jwtToken = '$header.$payload.$signature';

      await tokenStorage.saveToken(jwtToken);
      // No cached user in storage

      final notifier = AuthNotifier(authRepository);
      await pumpEventQueue();

      expect(notifier.state.hasValue, isTrue);
      expect(notifier.state.value, isNotNull);
      expect(notifier.state.value!.username, 'jwt_operator');
      expect(notifier.state.value!.role, 'operator');
      notifier.dispose();
    });

    test('login: backend response without username -> falls back to login username', () async {
      apiClient.onPost = (path, data) {
        if (path == AuthRepository.loginPath) {
          return {
            'access_token': 'jwt_token',
            'token_type': 'bearer',
          };
        }
        return <String, dynamic>{};
      };

      final notifier = AuthNotifier(authRepository);
      await pumpEventQueue();

      await notifier.login('logged_user', 'secret');

      expect(notifier.state.hasValue, isTrue);
      expect(notifier.state.value, isNotNull);
      expect(notifier.state.value!.username, 'logged_user');

      final cachedJson = await tokenStorage.getUserJson();
      expect(cachedJson, isNotNull);
      final decoded = jsonDecode(cachedJson!) as Map<String, dynamic>;
      expect(decoded['username'], 'logged_user');
      notifier.dispose();
    });

    test('logout: clears state and removes all credentials from storage', () async {
      await tokenStorage.saveToken('active-token');
      await tokenStorage.saveRefreshToken('active-refresh');
      await tokenStorage.saveUserJson(jsonEncode(testUser.toJson()));

      final notifier = AuthNotifier(authRepository);
      await pumpEventQueue();

      await notifier.logout();

      expect(notifier.state.hasValue, isTrue);
      expect(notifier.state.value, isNull);
      expect(await tokenStorage.getToken(), isNull);
      expect(await tokenStorage.getRefreshToken(), isNull);
      expect(await tokenStorage.getUserJson(), isNull);
      notifier.dispose();
    });
  });
}

// ── Fakes ───────────────────────────────────────────────────────────────────

class _FakeApiClient extends ApiClient {
  _FakeApiClient({required TokenStorage tokenStorage})
      : super(tokenStorage: tokenStorage);

  dynamic Function(String path)? onGet;
  dynamic Function(String path, Object? data)? onPost;

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required JsonParser<T> fromJson,
  }) async {
    if (onGet != null) {
      final res = onGet!(path);
      return fromJson(res);
    }
    return fromJson(true);
  }

  @override
  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required JsonParser<T> fromJson,
  }) async {
    if (onPost != null) {
      final res = onPost!(path, data);
      return fromJson(res);
    }
    return fromJson(<String, dynamic>{});
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
