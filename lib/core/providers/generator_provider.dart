import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_generators.dart';
import '../../data/repositories/generator_repository.dart';

final generatorRepositoryProvider = Provider<GeneratorRepository>((ref) {
  return GeneratorRepository();
});

final generatorProvider =
    StateNotifierProvider<GeneratorNotifier, AsyncValue<List<MockGenerator>>>((
      ref,
    ) {
      return GeneratorNotifier(ref.watch(generatorRepositoryProvider));
    });

class GeneratorNotifier extends StateNotifier<AsyncValue<List<MockGenerator>>> {
  GeneratorNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadGenerators();
  }

  final GeneratorRepository _repository;

  List<MockGenerator> _cachedGenerators = [];

  Future<void> loadGenerators({String? inventoryGroup}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final generators = await _repository.getGenerators(
        inventoryGroup: inventoryGroup,
      );
      _cachedGenerators = generators;
      return generators;
    });
  }

  Future<void> addGenerator(MockGenerator generator) async {
    await _repository.createGenerator(generator);
    await loadGenerators();
  }

  Future<void> updateGenerator(MockGenerator generator) async {
    final previous = List<MockGenerator>.of(_cachedGenerators);
    _cachedGenerators = [
      for (final existing in _cachedGenerators)
        if (existing.id == generator.id) generator else existing,
    ];
    state = AsyncValue.data(_cachedGenerators);

    try {
      await _repository.updateGenerator(generator.id, generator);
      await loadGenerators();
    } catch (error, stackTrace) {
      _cachedGenerators = previous;
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteGenerator(String generatorId) async {
    await _repository.deleteGenerator(generatorId);
    await loadGenerators();
  }
}
