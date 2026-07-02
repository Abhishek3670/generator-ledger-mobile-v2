import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_generators.dart';
import '../services/mock_data_service.dart';

final generatorProvider =
    StateNotifierProvider<GeneratorNotifier, List<MockGenerator>>((ref) {
  return GeneratorNotifier(MockDataService().getGenerators());
});

class GeneratorNotifier extends StateNotifier<List<MockGenerator>> {
  GeneratorNotifier(super.initialGenerators);

  void addGenerator(MockGenerator generator) {
    state = [generator, ...state];
  }

  void updateGenerator(MockGenerator generator) {
    state = [
      for (final existing in state)
        if (existing.id == generator.id) generator else existing,
    ];
  }

  void deleteGenerator(String generatorId) {
    state = state.where((generator) => generator.id != generatorId).toList();
  }
}
