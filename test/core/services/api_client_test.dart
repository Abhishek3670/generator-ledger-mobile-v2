import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/core/exceptions/api_exception.dart';
import 'package:ledger/core/services/api_client.dart';
import 'package:ledger/core/services/token_storage.dart';

void main() {
  group('ApiClient', () {
    test('adds bearer token when present', () async {
      final adapter = _FakeHttpClientAdapter(response: {'ok': true});
      final tokenStorage = TokenStorage(backend: _FakeTokenStorageBackend());
      await tokenStorage.saveToken('jwt-token');
      final client = _client(adapter, tokenStorage: tokenStorage);

      final response = await client.get<Map<String, dynamic>>(
        '/vendors',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      expect(response['ok'], isTrue);
      expect(adapter.lastOptions?.headers['Authorization'], 'Bearer jwt-token');
    });

    test('does not add bearer token when storage is empty', () async {
      final adapter = _FakeHttpClientAdapter(response: {'ok': true});
      final client = _client(adapter);

      await client.get<Map<String, dynamic>>(
        '/vendors',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      expect(
        adapter.lastOptions?.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('post sends request body and parses response', () async {
      final adapter = _FakeHttpClientAdapter(response: {'id': 7});
      final client = _client(adapter);

      final response = await client.post<Map<String, dynamic>>(
        '/vendors',
        data: {'name': 'Vendor'},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      expect(response['id'], 7);
      expect(adapter.lastOptions?.method, 'POST');
      expect(adapter.lastBody, {'name': 'Vendor'});
    });

    test('put, patch, and delete methods parse successful responses', () async {
      final putAdapter = _FakeHttpClientAdapter(response: {'updated': true});
      final patchAdapter = _FakeHttpClientAdapter(response: {'patched': true});
      final deleteAdapter = _FakeHttpClientAdapter(response: {'deleted': true});

      final putResponse = await _client(putAdapter).put<Map<String, dynamic>>(
        '/vendors/1',
        data: {'name': 'Updated'},
        fromJson: (json) => json as Map<String, dynamic>,
      );
      final patchResponse = await _client(patchAdapter)
          .patch<Map<String, dynamic>>(
            '/vendors/1',
            data: {'name': 'Patched'},
            fromJson: (json) => json as Map<String, dynamic>,
          );
      final deleteResponse = await _client(deleteAdapter)
          .delete<Map<String, dynamic>>(
            '/vendors/1',
            fromJson: (json) => json as Map<String, dynamic>,
          );

      expect(putResponse['updated'], isTrue);
      expect(putAdapter.lastOptions?.method, 'PUT');
      expect(patchResponse['patched'], isTrue);
      expect(patchAdapter.lastOptions?.method, 'PATCH');
      expect(deleteResponse['deleted'], isTrue);
      expect(deleteAdapter.lastOptions?.method, 'DELETE');
    });

    test('401 deletes token and invokes unauthorized callback', () async {
      var unauthorizedCalled = false;
      final adapter = _FakeHttpClientAdapter(
        response: {'detail': 'Expired'},
        statusCode: 401,
      );
      final backend = _FakeTokenStorageBackend();
      final tokenStorage = TokenStorage(backend: backend);
      await tokenStorage.saveToken('jwt-token');
      final client = _client(
        adapter,
        tokenStorage: tokenStorage,
        onUnauthorized: () => unauthorizedCalled = true,
      );

      await expectLater(
        client.get<Map<String, dynamic>>(
          '/protected',
          fromJson: (json) => json as Map<String, dynamic>,
        ),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            401,
          ),
        ),
      );

      expect(await tokenStorage.getToken(), isNull);
      expect(unauthorizedCalled, isTrue);
    });

    test('network errors become ApiException.network', () async {
      final adapter = _FakeHttpClientAdapter(
        exceptionType: DioExceptionType.connectionError,
      );
      final client = _client(adapter);

      await expectLater(
        client.get<Map<String, dynamic>>(
          '/vendors',
          fromJson: (json) => json as Map<String, dynamic>,
        ),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', isNull)
              .having((error) => error.message, 'message', contains('Network')),
        ),
      );
    });

    test('server errors become ApiException.serverError', () async {
      final adapter = _FakeHttpClientAdapter(
        response: {'message': 'Nope'},
        statusCode: 500,
      );
      final client = _client(adapter);

      await expectLater(
        client.get<Map<String, dynamic>>(
          '/vendors',
          fromJson: (json) => json as Map<String, dynamic>,
        ),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 500)
              .having((error) => error.message, 'message', contains('Server')),
        ),
      );
    });
  });
}

ApiClient _client(
  _FakeHttpClientAdapter adapter, {
  TokenStorage? tokenStorage,
  void Function()? onUnauthorized,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://example.test/api',
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  )..httpClientAdapter = adapter;

  return ApiClient(
    dio: dio,
    tokenStorage:
        tokenStorage ?? TokenStorage(backend: _FakeTokenStorageBackend()),
    onUnauthorized: onUnauthorized,
  );
}

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter({
    this.response,
    this.statusCode = 200,
    this.exceptionType,
  });

  final Object? response;
  final int statusCode;
  final DioExceptionType? exceptionType;

  RequestOptions? lastOptions;
  Object? lastBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    lastBody = await _readRequestBody(requestStream);

    if (exceptionType != null) {
      throw DioException(
        requestOptions: options,
        type: exceptionType!,
        message: 'Network failure',
      );
    }

    return ResponseBody.fromString(
      jsonEncode(response ?? {}),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}

  Future<Object?> _readRequestBody(Stream<List<int>>? stream) async {
    if (stream == null) {
      return null;
    }

    final bytes = <int>[];
    await for (final chunk in stream) {
      bytes.addAll(chunk);
    }
    if (bytes.isEmpty) {
      return null;
    }
    return jsonDecode(utf8.decode(bytes));
  }
}

class _FakeTokenStorageBackend implements TokenStorageBackend {
  final Map<String, String> values = {};

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> delete({required String key}) async {
    values.remove(key);
  }
}
