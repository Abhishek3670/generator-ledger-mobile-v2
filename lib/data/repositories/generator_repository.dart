import '../../core/services/api_client.dart';
import '../../shared/models/generator.dart';

class GeneratorRepository {
  GeneratorRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  static const String generatorsPath = '/api/generators';

  final ApiClient _apiClient;

  Future<List<Generator>> getGenerators({String? inventoryGroup, String? date}) async {
    final queryParams = <String, dynamic>{};
    if (date != null && date.isNotEmpty) {
      queryParams['date'] = date;
    }

    final generators = await _apiClient.get<List<Generator>>(
      generatorsPath,
      queryParameters: queryParams.isEmpty ? null : queryParams,
      fromJson: (json) => _parseGeneratorList(json),
    );

    if (inventoryGroup == null || inventoryGroup.isEmpty) {
      return generators;
    }

    return generators
        .where((generator) => generator.inventoryGroup == inventoryGroup)
        .toList();
  }

  Future<Generator> getGeneratorById(String id) async {
    final generators = await getGenerators();
    return generators.firstWhere(
      (generator) => generator.id == id,
      orElse: () => throw StateError('Generator not found: $id'),
    );
  }

  Future<Generator> createGenerator(Generator generator) async {
    return _apiClient.post<Generator>(
      generatorsPath,
      data: generator.toMap(),
      fromJson: (json) => _parseGenerator(json),
    );
  }

  Future<Generator> updateGenerator(String id, Generator generator) async {
    return _apiClient.patch<Generator>(
      '$generatorsPath/$id',
      data: generator.toMap(),
      fromJson: (json) => _parseGenerator(json),
    );
  }

  Future<Generator> deleteGenerator(String id) async {
    return _apiClient.patch<Generator>(
      '$generatorsPath/$id',
      data: const {'operational_status': 'Inactive'},
      fromJson: (json) => _parseGenerator(json),
    );
  }

  List<Generator> _parseGeneratorList(dynamic json) {
    final rawList = switch (json) {
      List<dynamic> list => list,
      {'generators': final List<dynamic> list} => list,
      {'data': final List<dynamic> list} => list,
      {'items': final List<dynamic> list} => list,
      _ => throw const FormatException('Generators response must be a list'),
    };

    return rawList
        .map((item) => Generator.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Generator _parseGenerator(dynamic json) {
    final rawGenerator = switch (json) {
      {'generator': final Map<String, dynamic> generator} => generator,
      {'data': final Map<String, dynamic> generator} => generator,
      Map<String, dynamic> generator => generator,
      _ => throw const FormatException('Generator response must be an object'),
    };

    return Generator.fromMap(rawGenerator);
  }
}
