import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import '../../data/repositories/auth_repository.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Shared [ApiClient] instance.
///
/// Constructed first (no auth dependencies in constructor) so that
/// [authRepositoryProvider] can safely take it as a dependency without
/// creating a circular constructor chain.
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  ref.onDispose(client.dispose);
  return client;
});

/// Breaks the circular dependency between [ApiClient] and [AuthRepository].
///
/// [ApiClient] needs [AuthRepository] to call [AuthRepository.refreshAccessToken].
/// [AuthRepository] needs [ApiClient] to make HTTP calls.
///
/// Resolution: [ApiClient] is constructed first with no auth dependency.
/// This provider is read once at startup (from [main.dart] inside a
/// [ProviderScope] descendant) to inject the repository via setter.
///
/// Reading this provider is a side-effect — the `void` return value is
/// intentional.
final Provider<void> authWiringProvider = Provider<void>((ref) {
  final client = ref.read(apiClientProvider);
  final repo = ref.read(authRepositoryProvider);
  client.setAuthRepository(repo);
});
