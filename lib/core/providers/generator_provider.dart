import 'dart:async';
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
  MockGenerator? _lastDeletedGenerator;
  int? _lastDeletedIndex;
  Timer? _deleteTimer;

  @override
  void dispose() {
    _deleteTimer?.cancel();
    super.dispose();
  }

  Future<void> loadGenerators({String? inventoryGroup, String? date}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final generators = await _repository.getGenerators(
        inventoryGroup: inventoryGroup,
        date: date,
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
    _deleteTimer?.cancel();
    if (_lastDeletedGenerator != null) {
      await _repository.deleteGenerator(_lastDeletedGenerator!.id);
      _lastDeletedGenerator = null;
    }

    final index = _cachedGenerators.indexWhere((g) => g.id == generatorId);
    if (index == -1) return;

    _lastDeletedGenerator = _cachedGenerators[index];
    _lastDeletedIndex = index;

    _cachedGenerators = List<MockGenerator>.from(_cachedGenerators)..removeAt(index);
    state = AsyncValue.data(_cachedGenerators);

    _deleteTimer = Timer(const Duration(seconds: 5), () async {
      if (_lastDeletedGenerator != null && _lastDeletedGenerator!.id == generatorId) {
        try {
          await _repository.deleteGenerator(generatorId);
          _lastDeletedGenerator = null;
          _lastDeletedIndex = null;
        } catch (error, stackTrace) {
          if (_lastDeletedGenerator != null && _lastDeletedIndex != null) {
            _cachedGenerators = List<MockGenerator>.from(_cachedGenerators)
              ..insert(_lastDeletedIndex!.clamp(0, _cachedGenerators.length), _lastDeletedGenerator!);
            state = AsyncValue.data(_cachedGenerators);
          }
          _lastDeletedGenerator = null;
          _lastDeletedIndex = null;
          state = AsyncValue.error(error, stackTrace);
        }
      }
    });
  }

  void undoDeleteGenerator() {
    if (_lastDeletedGenerator != null && _lastDeletedIndex != null) {
      _deleteTimer?.cancel();
      final insertIndex = _lastDeletedIndex!.clamp(0, _cachedGenerators.length);
      _cachedGenerators = List<MockGenerator>.from(_cachedGenerators)
        ..insert(insertIndex, _lastDeletedGenerator!);
      state = AsyncValue.data(_cachedGenerators);
      _lastDeletedGenerator = null;
      _lastDeletedIndex = null;
    }
  }
}
