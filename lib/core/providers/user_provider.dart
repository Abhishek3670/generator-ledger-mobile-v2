import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/user_repository.dart';
import '../../shared/models/user.dart';
import '../../shared/models/permission.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final userProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<List<User>>>((ref) {
  return UserNotifier(ref.watch(userRepositoryProvider));
});

final permissionsProvider = FutureProvider<List<Permission>>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getPermissions();
});

class UserNotifier extends StateNotifier<AsyncValue<List<User>>> {
  UserNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadUsers();
  }

  final UserRepository _repository;

  List<User> _cachedUsers = [];

  Future<void> loadUsers() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final users = await _repository.getUsers();
      _cachedUsers = users;
      return users;
    });
  }

  Future<void> addUser(User user) async {
    final previous = List<User>.of(_cachedUsers);
    _cachedUsers = [..._cachedUsers, user];
    state = AsyncValue.data(_cachedUsers);

    try {
      await _repository.createUser(user);
      await loadUsers();
    } catch (error, stackTrace) {
      _cachedUsers = previous;
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateUser(User user, String originalUsername) async {
    final previous = List<User>.of(_cachedUsers);
    _cachedUsers = [
      for (final existing in _cachedUsers)
        if (existing.username == originalUsername) user else existing,
    ];
    state = AsyncValue.data(_cachedUsers);

    try {
      // Use userId if available, otherwise fallback to username
      final id = user.userId ?? originalUsername;
      await _repository.updateUser(id, user);
      await loadUsers();
    } catch (error, stackTrace) {
      _cachedUsers = previous;
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteUser(String username) async {
    final previous = List<User>.of(_cachedUsers);
    final userToDelete = _cachedUsers.firstWhere(
      (user) => user.username == username,
      orElse: () => previous.first,
    );
    _cachedUsers = _cachedUsers
        .where((user) => user.username != username)
        .toList();
    state = AsyncValue.data(_cachedUsers);

    try {
      // Use userId if available, otherwise fallback to username
      final id = userToDelete.userId ?? username;
      await _repository.deleteUser(id);
      await loadUsers();
    } catch (error, stackTrace) {
      _cachedUsers = previous;
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

