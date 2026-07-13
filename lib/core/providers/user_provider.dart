import 'dart:async';
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
  User? _lastDeletedUser;
  int? _lastDeletedIndex;
  Timer? _deleteTimer;

  @override
  void dispose() {
    _deleteTimer?.cancel();
    super.dispose();
  }

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
    _deleteTimer?.cancel();
    if (_lastDeletedUser != null) {
      final id = _lastDeletedUser!.userId ?? _lastDeletedUser!.username;
      await _repository.deleteUser(id);
      _lastDeletedUser = null;
    }

    final index = _cachedUsers.indexWhere((u) => u.username == username);
    if (index == -1) return;

    _lastDeletedUser = _cachedUsers[index];
    _lastDeletedIndex = index;

    _cachedUsers = List<User>.from(_cachedUsers)..removeAt(index);
    state = AsyncValue.data(_cachedUsers);

    _deleteTimer = Timer(const Duration(seconds: 5), () async {
      if (_lastDeletedUser != null && _lastDeletedUser!.username == username) {
        try {
          final id = _lastDeletedUser!.userId ?? username;
          await _repository.deleteUser(id);
          _lastDeletedUser = null;
          _lastDeletedIndex = null;
        } catch (error, stackTrace) {
          if (_lastDeletedUser != null && _lastDeletedIndex != null) {
            _cachedUsers = List<User>.from(_cachedUsers)
              ..insert(_lastDeletedIndex!.clamp(0, _cachedUsers.length), _lastDeletedUser!);
            state = AsyncValue.data(_cachedUsers);
          }
          _lastDeletedUser = null;
          _lastDeletedIndex = null;
          state = AsyncValue.error(error, stackTrace);
        }
      }
    });
  }

  void undoDeleteUser() {
    if (_lastDeletedUser != null && _lastDeletedIndex != null) {
      _deleteTimer?.cancel();
      final insertIndex = _lastDeletedIndex!.clamp(0, _cachedUsers.length);
      _cachedUsers = List<User>.from(_cachedUsers)
        ..insert(insertIndex, _lastDeletedUser!);
      state = AsyncValue.data(_cachedUsers);
      _lastDeletedUser = null;
      _lastDeletedIndex = null;
    }
  }
}

