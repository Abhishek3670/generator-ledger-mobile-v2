import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger/core/providers/system_health_provider.dart';
import 'package:ledger/core/services/api_client.dart';
import 'package:ledger/data/repositories/system_health_repository.dart';
import 'package:ledger/features/admin/screens/system_health_screen.dart';
import 'package:ledger/features/admin/widgets/health_metric_card.dart';
import 'package:ledger/shared/models/system_health.dart';

void main() {
  testWidgets('SystemHealthScreen renders successfully and displays all metrics', (WidgetTester tester) async {
    final mockHealth = SystemHealth(
      cpu: 45.2,
      memory: 67.8,
      temperature: 32.1,
      dbConnection: 'postgresql://localhost:5432/ledger',
      appVersion: '1.0.0',
      lastChecked: DateTime(2026, 7, 6, 2, 0, 0),
      cpuTrend: const [40.0, 42.0, 45.2],
      memoryTrend: const [65.0, 66.5, 67.8],
      temperatureTrend: const [30.0, 31.0, 32.1],
    );

    final fakeRepository = _FakeSystemHealthRepository(mockHealth);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          systemHealthRepositoryProvider.overrideWithValue(fakeRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SystemHealthScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify title and headers
    expect(find.text('Live Server Metrics'), findsOneWidget);
    expect(find.text('APPLICATION STATUS'), findsOneWidget);

    // Verify DB Connection status text exists
    expect(find.textContaining('postgresql://'), findsOneWidget);

    // Verify presence of HealthMetricCards (CPU, Memory, Temperature)
    expect(find.byType(HealthMetricCard), findsNWidgets(3));

    // Verify CPU card specific text
    expect(find.text('CPU USAGE'), findsOneWidget);

    // Verify Memory card specific text
    expect(find.text('MEMORY USAGE'), findsOneWidget);

    // Verify Temperature card specific text
    expect(find.text('TEMPERATURE'), findsOneWidget);

    // Verify status badge
    expect(find.text('Healthy'), findsOneWidget);
  });
}

class _FakeSystemHealthRepository extends SystemHealthRepository {
  _FakeSystemHealthRepository(this.mockHealth) : super(apiClient: _FakeApiClient());

  final SystemHealth mockHealth;

  @override
  Future<SystemHealth> getHealth() async {
    return mockHealth;
  }
}

class _FakeApiClient extends ApiClient {}

