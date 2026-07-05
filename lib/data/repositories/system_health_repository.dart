import '../../core/services/api_client.dart';
import '../../shared/models/system_health.dart';

class SystemHealthRepository {
  SystemHealthRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  static const String healthPath = '/api/system/health';
  static const String monitorPath = '/api/monitor/live';

  final ApiClient _apiClient;

  Future<SystemHealth> getHealth() async {
    // Fetch both basic health and live monitoring metrics
    final healthFuture = _apiClient.get<Map<String, dynamic>>(
      healthPath,
      fromJson: (json) => _extractHealth(json),
    );
    
    final monitorFuture = _apiClient.get<Map<String, dynamic>>(
      monitorPath,
      fromJson: (json) => _extractMonitor(json),
    );

    // Wait for both requests to complete
    final results = await Future.wait([healthFuture, monitorFuture]);
    final healthData = results[0];
    final monitorData = results[1];

    // Merge the data
    final mergedData = {
      ...healthData,
      ...monitorData,
    };

    return SystemHealth.fromMap(mergedData);
  }

  Map<String, dynamic> _extractHealth(dynamic json) {
    final rawHealth = switch (json) {
      {'health': final Map<String, dynamic> health} => health,
      {'data': final Map<String, dynamic> health} => health,
      Map<String, dynamic> health => health,
      _ => throw const FormatException('Health response must be an object'),
    };

    return rawHealth;
  }

  Map<String, dynamic> _extractMonitor(dynamic json) {
    if (json is! Map<String, dynamic>) {
      // If monitor endpoint is not available or returns invalid format,
      // return empty map (metrics will default to 0)
      return {};
    }

    // Extract CPU, memory, temperature from monitor response
    final cpu = json['cpu'] as Map<String, dynamic>?;
    final memory = json['memory'] as Map<String, dynamic>?;
    final temperature = json['temperature'] as Map<String, dynamic>?;

    return {
      'cpu_usage': cpu?['percent'] as num? ?? 0.0,
      'memory_usage': memory?['percent'] as num? ?? 0.0,
      'temperature': temperature?['celsius'] as num? ?? 0.0,
    };
  }
}
