import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../shared/models/user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier(this._authRepository) : super(const AsyncValue.data(null));

  final AuthRepository _authRepository;

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _authRepository.login(username, password);
      state = AsyncValue.data(response.user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = const AsyncValue.data(null);
  }

  Future<bool> isAuthenticated() {
    return _authRepository.isAuthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((
  ref,
) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
