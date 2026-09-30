import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger/core/providers/vendor_provider.dart';
import 'package:ledger/core/providers/generator_provider.dart';
import 'package:ledger/shared/models/vendor.dart';
import 'package:ledger/data/mock/mock_generators.dart';
import 'package:ledger/data/repositories/vendor_repository.dart';
import 'package:ledger/data/repositories/generator_repository.dart';

class MockVendorRepository extends VendorRepository {
  final List<Vendor> vendors = [
    const Vendor(id: 'v1', name: 'Vendor 1', category: 'retailer', location: 'Loc 1', phone: '123'),
  ];
  final List<String> deletedIds = [];

  @override
  Future<List<Vendor>> getVendors() async => vendors;

  @override
  Future<void> deleteVendor(String id) async {
    deletedIds.add(id);
    vendors.removeWhere((v) => v.id == id);
  }
}

class MockGeneratorRepository extends GeneratorRepository {
  final List<MockGenerator> generators = [
    const MockGenerator(id: 'g1', capacity: '125 kVA', type: 'Silent', category: 'retailer', status: 'available'),
  ];
  final List<String> deletedIds = [];

  @override
  Future<List<MockGenerator>> getGenerators({String? inventoryGroup, String? date}) async => generators;

  @override
  Future<MockGenerator> deleteGenerator(String id) async {
    deletedIds.add(id);
    final generator = generators.firstWhere((g) => g.id == id);
    generators.removeWhere((g) => g.id == id);
    return generator;
  }
}

void main() {
  group('Undo/Redo Provider Tests', () {
    test('VendorNotifier delete & undo works correctly', () async {
      final mockRepo = MockVendorRepository();
      final container = ProviderContainer(
        overrides: [
          vendorRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(vendorProvider.notifier);
      await notifier.loadVendors();

      // Verify initial state
      expect(container.read(vendorProvider).value?.length, 1);

      // Perform delete
      await notifier.deleteVendor('v1');
      expect(container.read(vendorProvider).value?.isEmpty, true);
      expect(mockRepo.deletedIds.isEmpty, true); // Not deleted on backend yet

      // Undo delete
      notifier.undoDeleteVendor();
      expect(container.read(vendorProvider).value?.length, 1);
      expect(container.read(vendorProvider).value?.first.id, 'v1');

      // Wait 6 seconds (timeout is 5s)
      await Future.delayed(const Duration(seconds: 6));
      expect(mockRepo.deletedIds.isEmpty, true); // No deletion on backend since we undid it
    });

    test('VendorNotifier delete permanently after timeout', () async {
      final mockRepo = MockVendorRepository();
      final container = ProviderContainer(
        overrides: [
          vendorRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(vendorProvider.notifier);
      await notifier.loadVendors();

      // Perform delete
      await notifier.deleteVendor('v1');
      expect(container.read(vendorProvider).value?.isEmpty, true);

      // Wait 6 seconds
      await Future.delayed(const Duration(seconds: 6));
      expect(mockRepo.deletedIds.contains('v1'), true); // Deleted on backend
    });

    test('GeneratorNotifier delete & undo works correctly', () async {
      final mockRepo = MockGeneratorRepository();
      final container = ProviderContainer(
        overrides: [
          generatorRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(generatorProvider.notifier);
      await notifier.loadGenerators();

      expect(container.read(generatorProvider).value?.length, 1);

      await notifier.deleteGenerator('g1');
      expect(container.read(generatorProvider).value?.isEmpty, true);
      expect(mockRepo.deletedIds.isEmpty, true);

      notifier.undoDeleteGenerator();
      expect(container.read(generatorProvider).value?.length, 1);
      expect(container.read(generatorProvider).value?.first.id, 'g1');

      await Future.delayed(const Duration(seconds: 6));
      expect(mockRepo.deletedIds.isEmpty, true);
    });
  });
}
