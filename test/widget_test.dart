import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger/app.dart';

void main() {
  testWidgets('renders the scaffold app shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LedgerApp()));
    await tester.pumpAndSettle();

    expect(find.text('Genset Industrial Ledger'), findsOneWidget);
    expect(find.text('DASHBOARD'), findsOneWidget);
  });
}
