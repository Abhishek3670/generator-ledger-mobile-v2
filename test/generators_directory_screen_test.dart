import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger/core/providers/generator_provider.dart';
import 'package:ledger/data/mock/mock_generators.dart';
import 'package:ledger/data/repositories/generator_repository.dart';
import 'package:ledger/features/generators/screens/generators_directory_screen.dart';
import 'package:ledger/features/generators/widgets/inventory_group_section.dart';
import 'package:ledger/shared/widgets/floating_search_fab.dart';
import 'package:ledger/shared/widgets/expandable_fab_menu.dart';

void main() {
  testWidgets(
    'GeneratorsDirectoryScreen renders successfully with all elements',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            generatorRepositoryProvider.overrideWithValue(
              _FakeGeneratorRepository(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: GeneratorsDirectoryScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Title & Header
      expect(find.text('DIRECTORY'), findsOneWidget);
      expect(find.text('Generators'), findsOneWidget);

      // Verify Compact Date Filter Pill
      expect(find.text('All Dates'), findsOneWidget);

      // Verify Inventory sections
      expect(find.byType(InventoryGroupSection), findsNWidgets(3));
      expect(find.text('Retailer Genset'), findsOneWidget);
      expect(find.text('Permanent Genset'), findsOneWidget);
      expect(find.text('Emergency Genset'), findsOneWidget);

      // Verify ExpandableFABMenu and FloatingSearchFAB
      expect(find.byType(ExpandableFABMenu), findsOneWidget);
      expect(find.byType(FloatingSearchFAB), findsOneWidget);
    },
  );

  testWidgets('GeneratorsDirectoryScreen filters list using search field query', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          generatorRepositoryProvider.overrideWithValue(
            _FakeGeneratorRepository(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: GeneratorsDirectoryScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initially all mock items render
    expect(find.text('GEN-100KVA-02'), findsOneWidget);
    expect(find.text('GEN-45KVA-HA-11'), findsOneWidget);

    // Filter using search text
    final searchInput = find.descendant(
      of: find.byType(FloatingSearchFAB),
      matching: find.byType(TextField),
    );
    expect(searchInput, findsOneWidget);

    await tester.enterText(searchInput, 'GEN-45KVA');
    await tester.pump();

    // Verify only the permanent genset matching is displayed, and others are gone
    expect(find.text('GEN-45KVA-HA-11'), findsOneWidget);
    expect(find.text('GEN-100KVA-02'), findsNothing);
  });

  testWidgets(
    'GeneratorsDirectoryScreen FAB menu expands and shows all three options',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            generatorRepositoryProvider.overrideWithValue(
              _FakeGeneratorRepository(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: GeneratorsDirectoryScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the FAB to expand the menu
      final fabFinder = find.byType(ExpandableFABMenu);
      expect(fabFinder, findsOneWidget);
      await tester.tap(fabFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify all three action items are displayed in the overlay
      expect(find.text('NEW RETAILER'), findsOneWidget);
      expect(find.text('NEW PERMANENT'), findsOneWidget);
      expect(find.text('EMERGENCY'), findsOneWidget);
    },
  );

  testWidgets(
    'InventoryGroupSection renders title row with ellipsis without overflow on narrow width',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 250,
              child: InventoryGroupSection(
                title: 'Very Long Retailer Genset Category Name That Should Ellipsize',
                description: 'Test description',
                category: 'retailer',
                generators: [],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final textFinder = find.text('Very Long Retailer Genset Category Name That Should Ellipsize');
      expect(textFinder, findsOneWidget);
      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.maxLines, equals(1));
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
    },
  );

  testWidgets(
    'GeneratorsDirectoryScreen includes bottom SizedBox of height 88 for search FAB clearance',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            generatorRepositoryProvider.overrideWithValue(
              _FakeGeneratorRepository(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: GeneratorsDirectoryScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sizedBoxFinder = find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.height == 88,
      );
      expect(sizedBoxFinder, findsOneWidget);
    },
  );

  testWidgets(
    'InventoryGroupSection handles extreme system font scaling (2.5x) without overflow',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2.5),
            ),
            child: child!,
          ),
          home: const Scaffold(
            body: SizedBox(
              width: 320,
              child: InventoryGroupSection(
                title: 'Retailer Genset',
                description: 'Test description',
                category: 'retailer',
                generators: [],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}

class _FakeGeneratorRepository extends GeneratorRepository {
  @override
  Future<List<MockGenerator>> getGenerators({String? inventoryGroup, String? date}) async {
    final generators = List<MockGenerator>.of(mockGenerators);
    if (inventoryGroup == null) {
      return generators;
    }
    return generators
        .where((generator) => generator.inventoryGroup == inventoryGroup)
        .toList();
  }

  @override
  Future<MockGenerator> createGenerator(MockGenerator generator) async =>
      generator;

  @override
  Future<MockGenerator> updateGenerator(
    String id,
    MockGenerator generator,
  ) async => generator;

  @override
  Future<MockGenerator> deleteGenerator(String id) async {
    return mockGenerators.firstWhere((generator) => generator.id == id);
  }
}
