class SystemHealth {
  final double cpu;
  final double memory;
  final double temperature;
  final String dbConnection;
  final String appVersion;
  final DateTime lastChecked;
  final List<double> cpuTrend;
  final List<double> memoryTrend;
  final List<double> temperatureTrend;

  const SystemHealth({
    required this.cpu,
    required this.memory,
    required this.temperature,
    required this.dbConnection,
    required this.appVersion,
    required this.lastChecked,
    required this.cpuTrend,
    required this.memoryTrend,
    required this.temperatureTrend,
  });

  bool get isHealthy =>
      cpu < 80 && memory < 80 && temperature < 75 && dbConnection.isNotEmpty;

  SystemHealth copyWith({
    double? cpu,
    double? memory,
    double? temperature,
    String? dbConnection,
    String? appVersion,
    DateTime? lastChecked,
    List<double>? cpuTrend,
    List<double>? memoryTrend,
    List<double>? temperatureTrend,
  }) {
    return SystemHealth(
      cpu: cpu ?? this.cpu,
      memory: memory ?? this.memory,
      temperature: temperature ?? this.temperature,
      dbConnection: dbConnection ?? this.dbConnection,
      appVersion: appVersion ?? this.appVersion,
      lastChecked: lastChecked ?? this.lastChecked,
      cpuTrend: cpuTrend ?? this.cpuTrend,
      memoryTrend: memoryTrend ?? this.memoryTrend,
      temperatureTrend: temperatureTrend ?? this.temperatureTrend,
    );
  }
}
