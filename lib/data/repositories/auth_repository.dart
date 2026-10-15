import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/services/api_client.dart';
import '../../core/services/token_storage.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

class AuthRepository {
  AuthRepository({ApiClient? apiClient, TokenStorage? tokenStorage})
      : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  static const String loginPath = '/login';
  static const String logoutPath = '/api/logout';
  static const String verifyPath = '/auth/verify';
  static const String refreshPath = '/api/refresh';

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  // ── Login / Logout ────────────────────────────────────────────────────────

  Future<LoginResponse> login(String username, String password) async {
    final request = LoginRequest(username: username, password: password);
    final response = await _apiClient.post<LoginResponse>(
      loginPath,
      data: request.toJson(),
      fromJson: LoginResponse.fromJson,
    );

    // Persist access token (always present).
    await _tokenStorage.saveToken(response.token);

    // Persist refresh token when provided by the backend.
    if (response.refreshToken != null) {
      await _tokenStorage.saveRefreshToken(response.refreshToken!);
    }

    // Cache user JSON for session restoration on next app start.
    await _tokenStorage.saveUserJson(jsonEncode(response.user.toJson()));

    return response;
  }

  Future<void> logout() async {
    try {
      await _apiClient.post<void>(logoutPath, fromJson: (_) {});
    } catch (_) {
      // Swallows backend error so local logout always succeeds.
    } finally {
      // Always clear all credentials, even if the server call fails.
      await _tokenStorage.clearAll();
    }
  }

  // ── Token queries ─────────────────────────────────────────────────────────

  Future<bool> isAuthenticated() async {
    final token = await _tokenStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> verifyToken() async {
    if (!await isAuthenticated()) return false;
    try {
      return await _apiClient.get<bool>(verifyPath, fromJson: (_) => true);
    } catch (_) {
      // verifyToken deliberately swallows errors — let the caller decide
      // whether to attempt a refresh or force login.
      return false;
    }
  }

  // ── Silent token refresh ──────────────────────────────────────────────────

  /// Silently exchanges the stored refresh token for a new access token.
  ///
  /// Returns the new access token string on success, or `null` when the
  /// session must end (refresh token absent, expired, or revoked).
  ///
  /// - **Never throws.** Callers receive `null` and must redirect to login.
  /// - On 401 / 403 from the refresh endpoint → clears all stored credentials.
  /// - On network error → returns `null` WITHOUT clearing credentials so the
  ///   user stays in-app and can retry when connectivity returns.
  Future<String?> refreshAccessToken() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      // No refresh token stored — session cannot be continued.
      return null;
    }

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        AuthRepository.refreshPath,
        data: {'refresh_token': refreshToken},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      // Extract the new access token.
      final newAccessToken =
          (response['access_token'] ?? response['token']) as String?;
      if (newAccessToken == null || newAccessToken.isEmpty) {
        await _tokenStorage.clearAll();
        return null;
      }

      await _tokenStorage.saveToken(newAccessToken);

      // Rotate the refresh token if the backend issues a new one.
      final newRefreshToken =
          (response['refresh_token'] ?? response['refreshToken']) as String?;
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _tokenStorage.saveRefreshToken(newRefreshToken);
      }

      return newAccessToken;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        // Refresh token is invalid / revoked — force the user to log in.
        await _tokenStorage.clearAll();
      }
      // For all other DioExceptions (network errors, 5xx, etc.) we do NOT
      // clear credentials — the access token may still be valid once the
      // network recovers.
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── User cache ────────────────────────────────────────────────────────────

  /// Returns the cached [User] JSON string from secure storage, or null.
  Future<String?> getCachedUserJson() => _tokenStorage.getUserJson();
}
