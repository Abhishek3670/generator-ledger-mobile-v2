import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../exceptions/api_exception.dart';
import '../../data/repositories/auth_repository.dart';
import 'token_storage.dart';

typedef JsonParser<T> = T Function(dynamic json);

/// Custom Dio request extra key that prevents the 401 retry interceptor from
/// recursing on the token-refresh call itself.
const _kSkipAuthRefresh = 'skip_auth_refresh';

class ApiClient {
  ApiClient({
    Dio? dio,
    TokenStorage? tokenStorage,
    VoidCallback? onUnauthorized,
  })  : _dio = dio ?? Dio(_baseOptions()),
        _tokenStorage = tokenStorage ?? TokenStorage(),
        _onUnauthorized = onUnauthorized {
    _setupInterceptors();
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final VoidCallback? _onUnauthorized;

  // ── Auth-refresh dependency (setter-injected to break circular dep) ────────

  /// Injected by the provider layer after both [ApiClient] and [AuthRepository]
  /// are constructed.  Must be set before the first 401 can occur.
  AuthRepository? _authRepository;

  /// Called once at startup by the provider wiring layer.
  // ignore: use_setters_to_change_properties
  void setAuthRepository(AuthRepository repo) {
    _authRepository = repo;
  }

  // ── Concurrent-refresh guard ───────────────────────────────────────────────

  /// When a refresh is in progress, all subsequent 401s wait on this completer
  /// instead of each launching their own refresh call.
  Completer<String?>? _refreshCompleter;

  // ── Unauthorised listeners (unchanged public API) ─────────────────────────

  static final List<VoidCallback> _unauthorizedListeners = [];

  static void addUnauthorizedListener(VoidCallback listener) {
    _unauthorizedListeners.add(listener);
  }

  static void removeUnauthorizedListener(VoidCallback listener) {
    _unauthorizedListeners.remove(listener);
  }

  // ── Dio base options ──────────────────────────────────────────────────────

  static BaseOptions _baseOptions() {
    return BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: ApiConfig.defaultHeaders,
    );
  }

  // ── Interceptors ──────────────────────────────────────────────────────────

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode != 401) {
            handler.next(error);
            return;
          }

          // Don't retry the refresh call itself — avoid infinite loops.
          final extras = error.requestOptions.extra;
          if (extras[_kSkipAuthRefresh] == true ||
              error.requestOptions.path.contains('/refresh')) {
            _notifyUnauthorized();
            handler.next(error);
            return;
          }

          // ── Silent refresh ──────────────────────────────────────────────
          final newToken = await _attemptRefresh();

          if (newToken == null) {
            // Refresh failed — clear session and redirect to login.
            await _tokenStorage.deleteToken();
            _notifyUnauthorized();
            handler.next(error);
            return;
          }

          // Retry the original request once with the new access token.
          try {
            final retryOptions = error.requestOptions;
            retryOptions.headers['Authorization'] = 'Bearer $newToken';
            final response = await _dio.fetch<dynamic>(retryOptions);
            handler.resolve(response);
          } catch (retryError) {
            handler.next(error); // Surface the original error if retry fails.
          }
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        // requestBody / responseBody are disabled to prevent access tokens
        // and sensitive payloads from appearing in debug logs.
        LogInterceptor(
          request: true,
          requestHeader: false, // Hides Authorization header
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: true,
        ),
      );
    }
  }

  /// Ensures only one refresh call runs at a time.
  /// All concurrent 401 handlers await the same [Completer].
  Future<String?> _attemptRefresh() async {
    // If a refresh is already in progress, wait for it.
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();
    try {
      final newToken = await _authRepository?.refreshAccessToken();
      _refreshCompleter!.complete(newToken);
      return newToken;
    } catch (_) {
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  void _notifyUnauthorized() {
    _onUnauthorized?.call();
    for (final listener in List<VoidCallback>.from(_unauthorizedListeners)) {
      listener();
    }
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  void dispose() {
    _dio.close();
  }

  // ── HTTP verb helpers ─────────────────────────────────────────────────────

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required JsonParser<T> fromJson,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      );
      return fromJson(response.data);
    } on DioException catch (error) {
      throw _handleError(error);
    }
  }

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required JsonParser<T> fromJson,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return fromJson(response.data);
    } on DioException catch (error) {
      throw _handleError(error);
    }
  }

  Future<T> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required JsonParser<T> fromJson,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return fromJson(response.data);
    } on DioException catch (error) {
      throw _handleError(error);
    }
  }

  Future<T> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required JsonParser<T> fromJson,
  }) async {
    try {
      final response = await _dio.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return fromJson(response.data);
    } on DioException catch (error) {
      throw _handleError(error);
    }
  }

  Future<T> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required JsonParser<T> fromJson,
  }) async {
    try {
      final response = await _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return fromJson(response.data);
    } on DioException catch (error) {
      throw _handleError(error);
    }
  }

  // ── Error translation ─────────────────────────────────────────────────────

  ApiException _handleError(DioException error) {
    if (error.error is ApiException) {
      return error.error! as ApiException;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return ApiException.network(error);
      case DioExceptionType.badResponse:
        return _badResponseException(error);
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return ApiException(
          statusCode: error.response?.statusCode,
          message: error.message ?? 'An error occurred',
          originalError: error,
        );
    }
  }

  ApiException _badResponseException(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401) {
      return ApiException.unauthorized(error);
    }

    if (statusCode != null && statusCode >= 500) {
      return ApiException.serverError(
        statusCode: statusCode,
        originalError: error,
      );
    }

    final responseData = error.response?.data is Map<String, dynamic>
        ? error.response!.data as Map<String, dynamic>
        : null;

    return ApiException(
      statusCode: statusCode,
      message: _extractErrorMessage(error.response?.data),
      originalError: error,
      data: responseData,
    );
  }

  String _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['detail'] ?? data['error'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    return 'An error occurred';
  }
}
