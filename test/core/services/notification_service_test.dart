import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/core/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService Tests', () {
    test('scheduleNotification returns false immediately if scheduledDate is in the past', () async {
      final service = NotificationService();
      final pastDate = DateTime.now().subtract(const Duration(minutes: 5));

      final result = await service.scheduleNotification(
        101,
        'Test Title',
        'Test Body',
        pastDate,
      );

      expect(result, isFalse);
    });

    test('isInitialized starts false before initialize call', () {
      final service = NotificationService();
      expect(service.isInitialized, isFalse);
    });
  });
}
