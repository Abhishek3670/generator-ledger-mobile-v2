import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/core/services/api_client.dart';
import 'package:ledger/data/repositories/generator_repository.dart';
import 'package:ledger/shared/models/generator.dart' as ledger_generator;

void main() {
  group('GeneratorRepository', () {
    test(
      'getGenerators parses and filters inventory groups client-side',
      () async {
        final apiClient = _FakeApiClient(
          response: {
            'generators': [
              {
                'generator_id': 'GEN-1',
                'capacity_kva': 100,
                'type': '6R',
                'inventory_group': 'retailer',
                'operational_status': 'active',
              },
              {
                'generator_id': 'GEN-2',
                'capacity_kva': 45,
                'type': 'HA',
                'inventory_group': 'permanent',
                'operational_status': 'active',
              },
            ],
          },
        );
        final repository = GeneratorRepository(apiClient: apiClient);

        final generators = await repository.getGenerators(
          inventoryGroup: 'permanent',
        );

        expect(apiClient.lastGetPath, GeneratorRepository.generatorsPath);
        expect(generators.single.id, 'GEN-2');
        expect(generators.single.capacity, '45 kVA');
      },
    );

    test('getGeneratorById fetches all and filters client-side', () async {
      final repository = GeneratorRepository(
        apiClient: _FakeApiClient(
          response: {
            'generators': [
              {'generator_id': 'GEN-1'},
              {'generator_id': 'GEN-2'},
            ],
          },
        ),
      );

      final generator = await repository.getGeneratorById('GEN-2');

      expect(generator.id, 'GEN-2');
    });

    test('createGenerator posts payload and parses response', () async {
      final apiClient = _FakeApiClient(
        response: {
          'generator': {
            'generator_id': 'GEN-3',
            'capacity': '100 kVA',
            'inventory_group': 'retailer',
          },
        },
      );
      final repository = GeneratorRepository(apiClient: apiClient);

      final generator = await repository.createGenerator(
        const TestGenerator(
          id: 'GEN-3',
          capacity: '100 kVA',
          type: '6R',
          category: 'retailer',
          status: 'active',
        ),
      );

      expect(apiClient.lastPostPath, GeneratorRepository.generatorsPath);
      expect(apiClient.lastPostData, containsPair('generator_id', 'GEN-3'));
      expect(generator.id, 'GEN-3');
    });

    test('updateGenerator uses PATCH', () async {
      final apiClient = _FakeApiClient(
        response: {
          'generator': {'generator_id': 'GEN-4'},
        },
      );
      final repository = GeneratorRepository(apiClient: apiClient);

      await repository.updateGenerator(
        'GEN-4',
        const TestGenerator(
          id: 'GEN-4',
          capacity: '125 kVA',
          type: 'SL90',
          category: 'retailer',
          status: 'active',
        ),
      );

      expect(
        apiClient.lastPatchPath,
        '${GeneratorRepository.generatorsPath}/GEN-4',
      );
    });

    test('deleteGenerator soft deletes with inactive PATCH', () async {
      final apiClient = _FakeApiClient(
        response: {
          'generator': {
            'generator_id': 'GEN-5',
            'operational_status': 'Inactive',
          },
        },
      );
      final repository = GeneratorRepository(apiClient: apiClient);

      await repository.deleteGenerator('GEN-5');

      expect(
        apiClient.lastPatchPath,
        '${GeneratorRepository.generatorsPath}/GEN-5',
      );
      expect(apiClient.lastPatchData, {'operational_status': 'Inactive'});
    });
  });
}

class TestGenerator extends ledger_generator.Generator {
  const TestGenerator({
    required super.id,
    required super.capacity,
    required super.type,
    required super.category,
    required super.status,
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.response});

  final Object? response;
  String? lastGetPath;
  String? lastPostPath;
  String? lastPatchPath;
  Object? lastPostData;
  Object? lastPatchData;

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required JsonParser<T> fromJson,
  }) async {
    lastGetPath = path;
    return fromJson(response ?? {});
  }

  @override
  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required JsonParser<T> fromJson,
  }) async {
    lastPostPath = path;
    lastPostData = data;
    return fromJson(response ?? {});
  }

  @override
  Future<T> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required JsonParser<T> fromJson,
  }) async {
    lastPatchPath = path;
    lastPatchData = data;
    return fromJson(response ?? {});
  }
}
