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

  factory SystemHealth.fromMap(Map<String, dynamic> map) {
    // Handle two formats:
    // 1. Mock/test format: {"cpu_usage": 45.2, "memory_usage": 67.8, "database_status": "healthy"}
    // 2. Real backend format: {"version": "4.0.4", "database": {"status": "connected", "latency_ms": 9.27}}
    
    // Check if this is the real backend format (has nested "database" object)
    final database = map['database'] as Map<String, dynamic>?;
    
    if (database != null) {
      // Real backend format
      final dbStatus = database['status'] as String? ?? 'unknown';
      final dbLatency = (database['latency_ms'] as num?)?.toDouble() ?? 0.0;
      
      // Map database latency to a percentage-like metric for display
      // < 10ms = excellent (10%), 10-50ms = good (50%), > 50ms = slow (90%)
      final dbMetric = dbLatency < 10 ? 10.0 : (dbLatency < 50 ? 50.0 : 90.0);
      
      return SystemHealth(
        cpu: dbMetric, // Use database latency as a proxy metric
        memory: 0.0, // Not provided by backend
        temperature: 0.0, // Not provided by backend  
        dbConnection: dbStatus == 'connected' ? 'healthy' : dbStatus,
        appVersion: map['version'] as String? ?? '0.0.0',
        lastChecked: DateTime.now(),
        cpuTrend: const [],
        memoryTrend: const [],
        temperatureTrend: const [],
      );
    } else {
      // Mock/test format (legacy)
      return SystemHealth(
        cpu: (map['cpu_usage'] as num?)?.toDouble() ?? 0.0,
        memory: (map['memory_usage'] as num?)?.toDouble() ?? 0.0,
        temperature: (map['disk_usage'] as num?)?.toDouble() ?? 0.0,
        dbConnection: map['database_status'] as String? ?? 'unknown',
        appVersion: map['app_version'] as String? ?? '0.0.0',
        lastChecked: DateTime.now(),
        cpuTrend: const [],
        memoryTrend: const [],
        temperatureTrend: const [],
      );
    }
  }

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
