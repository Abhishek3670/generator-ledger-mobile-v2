import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/system_health_repository.dart';
import '../../shared/models/system_health.dart';

final systemHealthRepositoryProvider = Provider<SystemHealthRepository>((ref) {
  return SystemHealthRepository();
});

final systemHealthProvider =
    StateNotifierProvider<SystemHealthNotifier, AsyncValue<SystemHealth>>((ref) {
  final repository = ref.watch(systemHealthRepositoryProvider);
  return SystemHealthNotifier(repository);
});

class SystemHealthNotifier extends StateNotifier<AsyncValue<SystemHealth>> {
  SystemHealthNotifier(this._repository) : super(const AsyncValue.loading()) {
    _fetchHealth();
  }

  final SystemHealthRepository _repository;
  Timer? _pollingTimer;
  final List<SystemHealth> _history = [];
  static const int _maxHistorySize = 20;
  static const Duration _pollingInterval = Duration(seconds: 30);

  Future<void> _fetchHealth() async {
    try {
      final health = await _repository.getHealth();
      _addToHistory(health);
      state = AsyncValue.data(_buildHealthWithTrends(health));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void _addToHistory(SystemHealth health) {
    _history.add(health);
    if (_history.length > _maxHistorySize) {
      _history.removeAt(0);
    }
  }

  SystemHealth _buildHealthWithTrends(SystemHealth latest) {
    if (_history.isEmpty) {
      return latest;
    }

    return latest.copyWith(
      cpuTrend: _history.map((h) => h.cpu).toList(),
      memoryTrend: _history.map((h) => h.memory).toList(),
      temperatureTrend: _history.map((h) => h.temperature).toList(),
    );
  }

  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      _fetchHealth();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> refresh() async {
    await _fetchHealth();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

