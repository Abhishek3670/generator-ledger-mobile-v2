import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../exceptions/api_exception.dart';
import 'token_storage.dart';

typedef JsonParser<T> = T Function(dynamic json);

class ApiClient {
  ApiClient({
    Dio? dio,
    TokenStorage? tokenStorage,
    VoidCallback? onUnauthorized,
  }) : _dio = dio ?? Dio(_baseOptions()),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _onUnauthorized = onUnauthorized {
    _setupInterceptors();
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final VoidCallback? _onUnauthorized;

  static BaseOptions _baseOptions() {
    return BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: ApiConfig.defaultHeaders,
    );
  }

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
          if (error.response?.statusCode == 401) {
            await _tokenStorage.deleteToken();
            _onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true, error: true),
      );
    }
  }

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

    return ApiException(
      statusCode: statusCode,
      message: _extractErrorMessage(error.response?.data),
      originalError: error,
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
