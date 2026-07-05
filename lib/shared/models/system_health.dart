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
    // Handle merged data from two sources:
    // 1. /api/system/health: {"version": "4.0.4", "database": {"status": "connected", "latency_ms": 9.27}}
    // 2. /api/monitor/live: {"cpu_usage": 12.4, "memory_usage": 45.2, "temperature": 48.0}
    // 3. Mock/test format: {"cpu_usage": 45.2, "memory_usage": 67.8, "database_status": "healthy"}
    
    // Check if this is the real backend format (has nested "database" object)
    final database = map['database'] as Map<String, dynamic>?;
    
    // Get actual metrics (from /api/monitor/live or mock)
    final cpuUsage = (map['cpu_usage'] as num?)?.toDouble() ?? 0.0;
    final memoryUsage = (map['memory_usage'] as num?)?.toDouble() ?? 0.0;
    final temp = (map['temperature'] as num?)?.toDouble() ?? 0.0;
    
    // Get database connection status
    String dbConnection;
    if (database != null) {
      // Real backend format
      final dbStatus = database['status'] as String? ?? 'unknown';
      dbConnection = dbStatus == 'connected' ? 'healthy' : dbStatus;
    } else {
      // Mock format
      dbConnection = map['database_status'] as String? ?? 'unknown';
    }
    
    // Get app version
    final appVersion = map['version'] as String? ?? 
                       map['app_version'] as String? ?? 
                       '0.0.0';
    
    return SystemHealth(
      cpu: cpuUsage,
      memory: memoryUsage,
      temperature: temp,
      dbConnection: dbConnection,
      appVersion: appVersion,
      lastChecked: DateTime.now(),
      cpuTrend: const [],
      memoryTrend: const [],
      temperatureTrend: const [],
    );
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
