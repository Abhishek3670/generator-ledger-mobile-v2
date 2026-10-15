import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_client_provider.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/services/api_client.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../shared/models/user.dart';
import '../../../shared/widgets/app_toast.dart';

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final repo = AuthRepository(apiClient: client);
  client.setAuthRepository(repo);
  return repo;
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier(this._authRepository) : super(const AsyncValue.data(null)) {
    ApiClient.addUnauthorizedListener(_onApiUnauthorized);
    // Attempt to restore the previous session without requiring re-login.
    _restoreSession();
  }

  final AuthRepository _authRepository;

  // ── Session restoration ───────────────────────────────────────────────────

  /// Called once on construction.  Tries to restore an existing session from
  /// FlutterSecureStorage without requiring the user to log in again.
  ///
  /// Flow:
  ///   1. No stored access token → stay on login screen.
  ///   2. Stored token + backend verify OK → load cached user → authenticated.
  ///   3. Stored token + verify fails + refresh succeeds → re-verify → load user.
  ///   4. Stored token + verify fails + refresh fails → force login.
  Future<void> _restoreSession() async {
    // Guard: if another call already moved state away from loading, bail out.
    if (!mounted) return;

    final hasToken = await _authRepository.isAuthenticated();
    if (!hasToken) {
      if (mounted) state = const AsyncValue.data(null);
      return;
    }

    if (mounted) state = const AsyncValue.loading();

    final verified = await _authRepository.verifyToken();
    if (verified) {
      await _loadCachedUser();
      return;
    }

    // Access token may be expired — attempt a silent refresh.
    final newToken = await _authRepository.refreshAccessToken();
    if (newToken == null) {
      // Refresh failed (revoked / expired / absent) — force login.
      if (mounted) state = const AsyncValue.data(null);
      return;
    }

    // Re-verify with the new access token.
    final reVerified = await _authRepository.verifyToken();
    if (reVerified) {
      await _loadCachedUser();
    } else {
      if (mounted) state = const AsyncValue.data(null);
    }
  }

  /// Reads the user JSON cached in FlutterSecureStorage and updates state.
  Future<void> _loadCachedUser() async {
    if (!mounted) return;
    try {
      final json = await _authRepository.getCachedUserJson();
      if (json != null) {
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        final user = User.fromMap(decoded);
        if (mounted) state = AsyncValue.data(user);
        return;
      }
    } catch (_) {
      // Corrupted cache — fall through to null state (login screen).
    }
    if (mounted) state = const AsyncValue.data(null);
  }

  // ── 401 listener ─────────────────────────────────────────────────────────

  void _onApiUnauthorized() {
    clearAuth();

    AppToast.show(
      null,
      message: 'Session expired. Please log in again.',
      type: ToastType.warning,
    );

    AppRouter.refreshAuthState();
    AppRouter.router.go('/login');
  }

  // ── Public interface ──────────────────────────────────────────────────────

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
    // logout() calls clearAll() internally — access + refresh + cached user.
    await _authRepository.logout();
    clearAuth();
  }

  void clearAuth() {
    state = const AsyncValue.data(null);
  }

  Future<bool> isAuthenticated() {
    return _authRepository.isAuthenticated();
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    ApiClient.removeUnauthorizedListener(_onApiUnauthorized);
    super.dispose();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
