import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/core/services/api_client.dart';
import 'package:ledger/data/repositories/user_repository.dart';
import 'package:ledger/shared/models/user.dart';

void main() {
  group('UserRepository', () {
    test('getUsers parses list responses', () async {
      final apiClient = _FakeApiClient(
        response: {
          'users': [
            {
              'user_id': 'U001',
              'username': 'admin',
              'role': 'admin',
              'status': 'ACTIVE',
              'created_at': '2026-01-01T00:00:00.000Z',
              'last_login': '2026-07-05T10:00:00.000Z',
            },
            {
              'user_id': 'U002',
              'username': 'operator1',
              'role': 'operator',
              'status': 'ACTIVE',
              'created_at': '2026-02-01T00:00:00.000Z',
              'last_login': '2026-07-04T15:30:00.000Z',
            },
          ],
        },
      );
      final repository = UserRepository(apiClient: apiClient);

      final users = await repository.getUsers();

      expect(apiClient.lastGetPath, UserRepository.usersPath);
      expect(users.length, 2);
      expect(users[0].username, 'admin');
      expect(users[0].role, 'admin');
      expect(users[0].userId, 'U001');
      expect(users[1].username, 'operator1');
      expect(users[1].role, 'operator');
    });

    test('getPermissions parses capabilities list', () async {
      final apiClient = _FakeApiClient(
        response: {
          'capabilities': [
            {
              'capability': 'view_dashboard',
              'label': 'View Dashboard',
              'description': 'Access to main dashboard',
              'admin': true,
              'operator': true,
            },
            {
              'capability': 'manage_users',
              'label': 'Manage Users',
              'description': 'Create, update, delete users',
              'admin': true,
              'operator': false,
            },
          ],
        },
      );
      final repository = UserRepository(apiClient: apiClient);

      final permissions = await repository.getPermissions();

      expect(apiClient.lastGetPath, UserRepository.permissionsPath);
      expect(permissions.length, 2);
      expect(permissions[0].capability, 'view_dashboard');
      expect(permissions[0].admin, true);
      expect(permissions[0].operator, true);
      expect(permissions[1].capability, 'manage_users');
      expect(permissions[1].admin, true);
      expect(permissions[1].operator, false);
    });

    test('createUser posts to users endpoint', () async {
      final apiClient = _FakeApiClient(
        response: {
          'user': {
            'user_id': 'U003',
            'username': 'newuser',
            'role': 'operator',
            'status': 'ACTIVE',
            'created_at': '2026-07-06T00:00:00.000Z',
          },
        },
      );
      final repository = UserRepository(apiClient: apiClient);

      final newUser = User(
        username: 'newuser',
        role: 'operator',
        status: 'ACTIVE',
        createdAt: DateTime.utc(2026, 7, 6),
      );

      final result = await repository.createUser(newUser);

      expect(apiClient.lastPostPath, UserRepository.usersPath);
      expect(apiClient.lastPostData, containsPair('username', 'newuser'));
      expect(apiClient.lastPostData, containsPair('role', 'operator'));
      expect(result.username, 'newuser');
      expect(result.userId, 'U003');
    });

    test('updateUser posts to user-specific endpoint', () async {
      final apiClient = _FakeApiClient(
        response: {
          'user': {
            'user_id': 'U001',
            'username': 'admin',
            'role': 'admin',
            'status': 'INACTIVE',
            'created_at': '2026-01-01T00:00:00.000Z',
          },
        },
      );
      final repository = UserRepository(apiClient: apiClient);

      final updatedUser = User(
        userId: 'U001',
        username: 'admin',
        role: 'admin',
        status: 'INACTIVE',
        createdAt: DateTime.utc(2026, 1, 1),
      );

      await repository.updateUser('U001', updatedUser);

      expect(apiClient.lastPostPath, '${UserRepository.usersPath}/U001');
      expect(apiClient.lastPostData, containsPair('status', 'INACTIVE'));
    });

    test('deleteUser posts to delete endpoint', () async {
      final apiClient = _FakeApiClient(response: {});
      final repository = UserRepository(apiClient: apiClient);

      await repository.deleteUser('U002');

      expect(apiClient.lastPostPath, '${UserRepository.usersPath}/U002/delete');
    });
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.response});

  final Object? response;
  String? lastGetPath;
  String? lastPostPath;
  Object? lastPostData;

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required JsonParser<T> fromJson,
  }) async {
    lastGetPath = path;
    return fromJson(response ?? {});
  }

  @override
  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required JsonParser<T> fromJson,
  }) async {
    lastPostPath = path;
    lastPostData = data;
    return fromJson(response ?? {});
  }
}
