import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

/// Provider for the shared ApiClient instance.
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
