import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/shared/models/reminder_offset.dart';

void main() {
  group('ReminderOffset Enum Tests', () {
    test('verifies correct duration for each offset', () {
      expect(ReminderOffset.none.duration, Duration.zero);
      expect(ReminderOffset.thirtyMin.duration, const Duration(minutes: 30));
      expect(ReminderOffset.oneHour.duration, const Duration(hours: 1));
      expect(ReminderOffset.threeHours.duration, const Duration(hours: 3));
      expect(ReminderOffset.oneDay.duration, const Duration(days: 1));
      expect(ReminderOffset.twoDays.duration, const Duration(days: 2));
      expect(ReminderOffset.oneWeek.duration, const Duration(days: 7));
    });

    test('verifies display labels for user interfaces', () {
      expect(ReminderOffset.none.displayLabel, 'None');
      expect(ReminderOffset.thirtyMin.displayLabel, '30 minutes before');
      expect(ReminderOffset.oneHour.displayLabel, '1 hour before');
      expect(ReminderOffset.threeHours.displayLabel, '3 hours before');
      expect(ReminderOffset.oneDay.displayLabel, '1 day before');
      expect(ReminderOffset.twoDays.displayLabel, '2 days before');
      expect(ReminderOffset.oneWeek.displayLabel, '1 week before');
    });

    test('fromString parses valid enum names case-insensitively', () {
      expect(ReminderOffset.fromString('none'), ReminderOffset.none);
      expect(ReminderOffset.fromString('thirtyMin'), ReminderOffset.thirtyMin);
      expect(ReminderOffset.fromString('THIRTYMIN'), ReminderOffset.thirtyMin);
      expect(ReminderOffset.fromString('oneHour'), ReminderOffset.oneHour);
      expect(ReminderOffset.fromString('threeHours'), ReminderOffset.threeHours);
      expect(ReminderOffset.fromString('oneDay'), ReminderOffset.oneDay);
      expect(ReminderOffset.fromString('twoDays'), ReminderOffset.twoDays);
      expect(ReminderOffset.fromString('oneWeek'), ReminderOffset.oneWeek);
    });

    test('fromString safely returns ReminderOffset.none for null or invalid inputs', () {
      expect(ReminderOffset.fromString(null), ReminderOffset.none);
      expect(ReminderOffset.fromString(''), ReminderOffset.none);
      expect(ReminderOffset.fromString('unknown_value'), ReminderOffset.none);
    });
  });
}
