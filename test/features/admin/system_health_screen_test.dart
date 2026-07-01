import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger/features/admin/screens/system_health_screen.dart';
import 'package:ledger/features/admin/widgets/health_metric_card.dart';

void main() {
  testWidgets('SystemHealthScreen renders successfully and displays all metrics', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SystemHealthScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify title and headers
    expect(find.text('SYSTEM HEALTH'), findsOneWidget);
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
