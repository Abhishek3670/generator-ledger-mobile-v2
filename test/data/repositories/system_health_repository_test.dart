import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/core/exceptions/api_exception.dart';
import 'package:ledger/core/services/api_client.dart';
import 'package:ledger/data/repositories/system_health_repository.dart';
import 'package:ledger/shared/models/system_health.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.mockHealthResponse, this.mockMonitorResponse, this.shouldThrow = false});

  final dynamic mockHealthResponse;
  final dynamic mockMonitorResponse;
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
    
    // Return appropriate mock based on endpoint
    if (path == '/api/monitor/live') {
      return fromJson(mockMonitorResponse ?? {});
    } else {
      return fromJson(mockHealthResponse ?? {});
    }
  }
}

void main() {
  group('SystemHealthRepository', () {
    test('getHealth returns SystemHealth from API response', () async {
      // Arrange
      final mockHealthResponse = {
        'version': '4.0.4',
        'database': {
          'status': 'connected',
          'latency_ms': 9.27,
        }
      };
      
      final mockMonitorResponse = {
        'cpu': {'percent': 45.2},
        'memory': {'percent': 67.8},
        'temperature': {'celsius': 32.1},
      };

      final apiClient = _FakeApiClient(
        mockHealthResponse: mockHealthResponse,
        mockMonitorResponse: mockMonitorResponse,
      );
      final repository = SystemHealthRepository(apiClient: apiClient);

      // Act
      final health = await repository.getHealth();

      // Assert
      expect(health, isA<SystemHealth>());
      expect(health.cpu, equals(45.2));
      expect(health.memory, equals(67.8));
      expect(health.temperature, equals(32.1));
      expect(health.dbConnection, equals('healthy'));
      expect(health.appVersion, equals('4.0.4'));
    });

    test('getHealth handles wrapped response with "data" key', () async {
      // Arrange - Mock format for backward compatibility
      final mockResponse = {
        'data': {
          'cpu_usage': 25.5,
          'memory_usage': 50.0,
          'disk_usage': 20.0,
          'database_status': 'connected',
          'app_version': '1.2.3',
        }
      };

      final apiClient = _FakeApiClient(
        mockHealthResponse: mockResponse,
        mockMonitorResponse: {},
      );
      final repository = SystemHealthRepository(apiClient: apiClient);

      // Act
      final health = await repository.getHealth();

      // Assert
      expect(health.cpu, equals(25.5));
      expect(health.memory, equals(50.0));
      expect(health.temperature, equals(0.0)); // disk_usage not mapped to temperature anymore
      expect(health.dbConnection, equals('connected'));
      expect(health.appVersion, equals('1.2.3'));
    });

    test('getHealth handles wrapped response with "health" key', () async {
      // Arrange - Mock format for backward compatibility
      final mockResponse = {
        'health': {
          'cpu_usage': 15.0,
          'memory_usage': 40.0,
          'disk_usage': 10.0,
          'database_status': 'online',
          'app_version': '2.0.0',
        }
      };

      final apiClient = _FakeApiClient(
        mockHealthResponse: mockResponse,
        mockMonitorResponse: {},
      );
      final repository = SystemHealthRepository(apiClient: apiClient);

      // Act
      final health = await repository.getHealth();

      // Assert
      expect(health.cpu, equals(15.0));
      expect(health.memory, equals(40.0));
      expect(health.temperature, equals(0.0)); // disk_usage not mapped to temperature anymore
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
      const mockHealthResponse = 'invalid response';

      final apiClient = _FakeApiClient(
        mockHealthResponse: mockHealthResponse,
        mockMonitorResponse: {},
      );
      final repository = SystemHealthRepository(apiClient: apiClient);

      // Act & Assert
      expect(
        () => repository.getHealth(),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
