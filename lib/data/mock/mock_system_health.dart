import '../../shared/models/system_health.dart';

final mockSystemHealth = SystemHealth(
  cpu: 0.2,
  memory: 12.7,
  temperature: 39.9,
  dbConnection: 'postgresql://genset_user:***@postgres-db:5432/ledger_db',
  appVersion: '4.0.2',
  lastChecked: DateTime.utc(2026, 4, 20, 12, 32, 8),
  cpuTrend: const [38, 38, 38, 38, 35, 38, 38],
  memoryTrend: const [35, 35, 35, 35, 35, 35, 35],
  temperatureTrend: const [30, 30, 29, 29, 30, 20, 22, 25],
);
