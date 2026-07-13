import '../../core/services/api_client.dart';
import '../../shared/models/user.dart';
import '../../shared/models/permission.dart';

class UserRepository {
  UserRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  static const String usersPath = '/api/users';
  static const String permissionsPath = '/api/permissions';

  final ApiClient _apiClient;

  /// Get all users
  Future<List<User>> getUsers() async {
    return _apiClient.get<List<User>>(
      usersPath,
      fromJson: (json) => _parseUserList(json),
    );
  }

  /// Get permissions/capabilities matrix
  Future<List<Permission>> getPermissions() async {
    return _apiClient.get<List<Permission>>(
      permissionsPath,
      fromJson: (json) => _parsePermissionList(json),
    );
  }

  /// Create a new user (backend uses POST for all admin operations)
  Future<User> createUser(User user) async {
    return _apiClient.post<User>(
      usersPath,
      data: user.toMap(),
      fromJson: (json) => _parseUser(json),
    );
  }

  /// Update an existing user (backend uses POST for admin operations)
  Future<User> updateUser(String userId, User user) async {
    return _apiClient.post<User>(
      '$usersPath/$userId',
      data: user.toMap(),
      fromJson: (json) => _parseUser(json),
    );
  }

  /// Delete a user (backend uses POST for admin operations)
  Future<void> deleteUser(String userId) async {
    await _apiClient.post<void>(
      '$usersPath/$userId/delete',
      data: {},
      fromJson: (_) {},
    );
  }

  List<User> _parseUserList(dynamic json) {
    final rawList = switch (json) {
      List<dynamic> list => list,
      {'users': final List<dynamic> list} => list,
      {'data': final List<dynamic> list} => list,
      _ => throw const FormatException('Users response must contain a list'),
    };

    return rawList
        .map((item) => User.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  User _parseUser(dynamic json) {
    final rawUser = switch (json) {
      {'user': final Map<String, dynamic> user} => user,
      {'data': final Map<String, dynamic> user} => user,
      Map<String, dynamic> user => user,
      _ => throw const FormatException('User response must be an object'),
    };

    return User.fromMap(rawUser);
  }

  List<Permission> _parsePermissionList(dynamic json) {
    final rawList = switch (json) {
      List<dynamic> list => list,
      {'capabilities': final List<dynamic> list} => list,
      {'permissions': final List<dynamic> list} => list,
      {'data': final List<dynamic> list} => list,
      _ => throw const FormatException('Permissions response must contain a list'),
    };

    return rawList
        .map((item) => Permission.fromMap(item as Map<String, dynamic>))
        .toList();
  }
}
