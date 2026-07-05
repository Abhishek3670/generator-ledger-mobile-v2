import '../../core/services/api_client.dart';
import '../../shared/models/system_health.dart';

class SystemHealthRepository {
  SystemHealthRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  static const String healthPath = '/api/system/health';

  final ApiClient _apiClient;

  Future<SystemHealth> getHealth() async {
    return _apiClient.get<SystemHealth>(
      healthPath,
      fromJson: (json) => _parseHealth(json),
    );
  }

  SystemHealth _parseHealth(dynamic json) {
    final rawHealth = switch (json) {
      {'health': final Map<String, dynamic> health} => health,
      {'data': final Map<String, dynamic> health} => health,
      Map<String, dynamic> health => health,
      _ => throw const FormatException('Health response must be an object'),
    };

    return SystemHealth.fromMap(rawHealth);
  }
}
