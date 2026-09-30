import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/services/api_client.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../shared/models/user.dart';
import '../../../shared/widgets/app_toast.dart';

final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(apiClient: ref.watch(apiClientProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier(this._authRepository) : super(const AsyncValue.data(null)) {
    ApiClient.addUnauthorizedListener(_onApiUnauthorized);
  }

  final AuthRepository _authRepository;

  void _onApiUnauthorized() {
    clearAuth();

    // Show session expiration message via custom Top Toast
    AppToast.show(
      null,
      message: 'Session expired. Please log in again.',
      type: ToastType.warning,
    );

    // Refresh auth state in router and redirect to login
    AppRouter.refreshAuthState();
    AppRouter.router.go('/login');
  }

  @override
  void dispose() {
    ApiClient.removeUnauthorizedListener(_onApiUnauthorized);
    super.dispose();
  }

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

  void clearAuth() {
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
