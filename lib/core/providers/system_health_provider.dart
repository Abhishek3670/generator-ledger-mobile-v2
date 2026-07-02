import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/system_health.dart';
import '../services/mock_data_service.dart';

final systemHealthProvider =
    StateNotifierProvider<SystemHealthNotifier, SystemHealth>((ref) {
  return SystemHealthNotifier(MockDataService().getSystemHealth());
});

class SystemHealthNotifier extends StateNotifier<SystemHealth> {
  SystemHealthNotifier(super.initialHealth);

  void refresh() {
    final random = Random();
    final cpu = double.parse((0.2 + random.nextDouble() * 3).toStringAsFixed(1));
    final memory =
        double.parse((12.0 + random.nextDouble() * 2).toStringAsFixed(1));
    final temperature =
        double.parse((38.0 + random.nextDouble() * 4).toStringAsFixed(1));

    state = state.copyWith(
      cpu: cpu,
      memory: memory,
      temperature: temperature,
      lastChecked: DateTime.now(),
      cpuTrend: [...state.cpuTrend.skip(1), 40 - cpu],
      memoryTrend: [...state.memoryTrend.skip(1), 40 - memory],
      temperatureTrend: [...state.temperatureTrend.skip(1), 40 - temperature],
    );
  }
}
