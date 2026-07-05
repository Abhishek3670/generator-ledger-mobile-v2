import '../../core/services/api_client.dart';
import '../../core/services/token_storage.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

class AuthRepository {
  AuthRepository({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  static const String loginPath = '/login';
  static const String logoutPath = '/logout';
  static const String verifyPath = '/auth/verify';

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<LoginResponse> login(String username, String password) async {
    final request = LoginRequest(username: username, password: password);
    final response = await _apiClient.post<LoginResponse>(
      loginPath,
      data: request.toJson(),
      fromJson: LoginResponse.fromJson,
    );
    await _tokenStorage.saveToken(response.token);
    return response;
  }

  Future<void> logout() async {
    try {
      await _apiClient.delete<void>(logoutPath, fromJson: (_) {});
    } finally {
      await _tokenStorage.deleteToken();
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await _tokenStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> verifyToken() async {
    if (!await isAuthenticated()) {
      return false;
    }

    try {
      return await _apiClient.get<bool>(verifyPath, fromJson: (_) => true);
    } catch (_) {
      await _tokenStorage.deleteToken();
      return false;
    }
  }
}
