import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/core/exceptions/api_exception.dart';
import 'package:ledger/core/services/api_client.dart';
import 'package:ledger/data/repositories/system_health_repository.dart';
import 'package:ledger/shared/models/system_health.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.mockResponse, this.shouldThrow = false});

  final dynamic mockResponse;
  final bool shouldThrow;

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required JsonParser<T> fromJson,
  }) async {
    if (shouldThrow) {
      throw ApiException(
        statusCode: 500,
        message: 'Server error',
        originalError: DioException(
          requestOptions: RequestOptions(path: path),
        ),
      );
    }
    return fromJson(mockResponse);
  }
}

void main() {
  group('SystemHealthRepository', () {
    test('getHealth returns SystemHealth from API response', () async {
      // Arrange
      final mockResponse = {
        'cpu_usage': 45.2,
        'memory_usage': 67.8,
        'disk_usage': 32.1,
        'database_status': 'healthy',
        'app_version': '1.0.0',
      };

      final apiClient = _FakeApiClient(mockResponse: mockResponse);
      final repository = SystemHealthRepository(apiClient: apiClient);

      // Act
      final health = await repository.getHealth();

      // Assert
      expect(health, isA<SystemHealth>());
      expect(health.cpu, equals(45.2));
      expect(health.memory, equals(67.8));
      expect(health.temperature, equals(32.1));
      expect(health.dbConnection, equals('healthy'));
      expect(health.appVersion, equals('1.0.0'));
    });

    test('getHealth handles wrapped response with "data" key', () async {
      // Arrange
      final mockResponse = {
        'data': {
          'cpu_usage': 25.5,
          'memory_usage': 50.0,
          'disk_usage': 20.0,
          'database_status': 'connected',
          'app_version': '1.2.3',
        }
      };

      final apiClient = _FakeApiClient(mockResponse: mockResponse);
      final repository = SystemHealthRepository(apiClient: apiClient);

      // Act
      final health = await repository.getHealth();

      // Assert
      expect(health.cpu, equals(25.5));
      expect(health.memory, equals(50.0));
      expect(health.temperature, equals(20.0));
      expect(health.dbConnection, equals('connected'));
      expect(health.appVersion, equals('1.2.3'));
    });

    test('getHealth handles wrapped response with "health" key', () async {
      // Arrange
      final mockResponse = {
        'health': {
          'cpu_usage': 15.0,
          'memory_usage': 40.0,
          'disk_usage': 10.0,
          'database_status': 'online',
          'app_version': '2.0.0',
        }
      };

      final apiClient = _FakeApiClient(mockResponse: mockResponse);
      final repository = SystemHealthRepository(apiClient: apiClient);

      // Act
      final health = await repository.getHealth();

      // Assert
      expect(health.cpu, equals(15.0));
      expect(health.memory, equals(40.0));
      expect(health.temperature, equals(10.0));
      expect(health.dbConnection, equals('online'));
      expect(health.appVersion, equals('2.0.0'));
    });

    test('getHealth throws ApiException on network error', () async {
      // Arrange
      final apiClient = _FakeApiClient(shouldThrow: true);
      final repository = SystemHealthRepository(apiClient: apiClient);

      // Act & Assert
      expect(
        () => repository.getHealth(),
        throwsA(isA<ApiException>()),
      );
    });

    test('getHealth throws FormatException on invalid response format', () async {
      // Arrange
      const mockResponse = 'invalid response';

      final apiClient = _FakeApiClient(mockResponse: mockResponse);
      final repository = SystemHealthRepository(apiClient: apiClient);

      // Act & Assert
      expect(
        () => repository.getHealth(),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
