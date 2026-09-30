import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/core/navigation/page_transitions.dart';

void main() {
  testWidgets('SlideRightTransitionPage configures CupertinoPageRoute correctly with swipeBack enabled', (WidgetTester tester) async {
    const page = SlideRightTransitionPage<void>(
      child: Text('Target Page'),
    );

    expect(page.swipeBack, isTrue);

    CupertinoPageRoute? route;

    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (context) {
            route = page.createRoute(context) as CupertinoPageRoute;
            return CupertinoButton(
              onPressed: () {
                Navigator.of(context).push(route!);
              },
              child: const Text('Push'),
            );
          },
        ),
      ),
    );

    // Initial state: not pushed yet
    expect(route!.popGestureEnabled, isFalse);

    await tester.tap(find.text('Push'));
    await tester.pumpAndSettle();

    // Now pushed and completed: should be enabled
    expect(find.text('Target Page'), findsOneWidget);
    expect(route!.popGestureEnabled, isTrue);
  });

  testWidgets('SlideRightTransitionPage configures CupertinoPageRoute correctly with swipeBack disabled', (WidgetTester tester) async {
    const page = SlideRightTransitionPage<void>(
      child: Text('Target Page'),
      swipeBack: false,
    );

    expect(page.swipeBack, isFalse);

    CupertinoPageRoute? route;

    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (context) {
            route = page.createRoute(context) as CupertinoPageRoute;
            return CupertinoButton(
              onPressed: () {
                Navigator.of(context).push(route!);
              },
              child: const Text('Push'),
            );
          },
        ),
      ),
    );

    // Initial state: not pushed yet
    expect(route!.popGestureEnabled, isFalse);

    await tester.tap(find.text('Push'));
    await tester.pumpAndSettle();

    // Now pushed and completed: should still be disabled because swipeBack is false
    expect(find.text('Target Page'), findsOneWidget);
    expect(route!.popGestureEnabled, isFalse);
  });
}
