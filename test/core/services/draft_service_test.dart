import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ledger/core/services/draft_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DraftService Tests', () {
    late DraftService draftService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      draftService = DraftService();
    });

    test('saving and loading draft works correctly', () async {
      final testData = {'name': 'Test Vendor', 'location': 'Loc 1'};

      await draftService.saveDraft('vendor', testData);

      final loaded = await draftService.loadDraft('vendor');
      expect(loaded, isNotNull);
      expect(loaded!['name'], 'Test Vendor');
      expect(loaded['location'], 'Loc 1');
    });

    test('returns null when draft does not exist', () async {
      final loaded = await draftService.loadDraft('non_existent');
      expect(loaded, isNull);
    });

    test('clearing draft works correctly', () async {
      final testData = {'id': 'GEN-1'};
      await draftService.saveDraft('generator', testData);

      await draftService.clearDraft('generator');

      final loaded = await draftService.loadDraft('generator');
      expect(loaded, isNull);
    });
  });
}
