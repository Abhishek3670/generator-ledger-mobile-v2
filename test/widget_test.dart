import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/app.dart';

void main() {
  testWidgets('renders the scaffold app shell', (tester) async {
    await tester.pumpWidget(const LedgerApp());
    await tester.pump();

    expect(find.text('DASHBOARD'), findsNWidgets(2));
  });
}
