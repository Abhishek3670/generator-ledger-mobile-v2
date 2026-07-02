import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/user.dart';
import '../services/mock_data_service.dart';

final userProvider = StateNotifierProvider<UserNotifier, List<User>>((ref) {
  return UserNotifier(MockDataService().getUsers());
});

class UserNotifier extends StateNotifier<List<User>> {
  UserNotifier(super.initialUsers);

  void addUser(User user) {
    state = [...state, user];
  }

  void updateUser(User user, String originalUsername) {
    state = [
      for (final existing in state)
        if (existing.username == originalUsername) user else existing,
    ];
  }

  void deleteUser(String username) {
    state = state.where((user) => user.username != username).toList();
  }
}
