import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/reminder_offset.dart';
import '../services/booking_reminder_service.dart';
import '../services/notification_service.dart';
import '../services/user_preferences_service.dart';

/// Provider for the singleton or shared [NotificationService].
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Provider for [BookingReminderService], combining notification capabilities
/// with persisted user preferences.
final bookingReminderServiceProvider = Provider<BookingReminderService>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return BookingReminderService(notificationService, prefs);
});

/// State notifier managing global reminder settings reactively.
class GlobalReminderSettingsNotifier extends StateNotifier<GlobalReminderSettings> {
  final BookingReminderService _reminderService;

  GlobalReminderSettingsNotifier(this._reminderService)
      : super(_reminderService.getGlobalSettings());

  Future<void> toggleEnabled(bool enabled) async {
    final updated = state.copyWith(enabled: enabled);
    state = updated;
    await _reminderService.saveGlobalSettings(updated);
  }

  Future<void> toggleOffset(ReminderOffset offset) async {
    final current = Set<ReminderOffset>.from(state.selectedOffsets);
    if (current.contains(offset)) {
      current.remove(offset);
    } else {
      current.add(offset);
    }
    final updated = state.copyWith(selectedOffsets: current);
    state = updated;
    await _reminderService.saveGlobalSettings(updated);
  }

  Future<void> setOffsets(Set<ReminderOffset> offsets) async {
    final updated = state.copyWith(selectedOffsets: offsets);
    state = updated;
    await _reminderService.saveGlobalSettings(updated);
  }

  Future<void> updateSettings(GlobalReminderSettings newSettings) async {
    state = newSettings;
    await _reminderService.saveGlobalSettings(newSettings);
  }
}

/// Provider exposing [GlobalReminderSettings] state to the app UI.
final globalReminderSettingsProvider =
    StateNotifierProvider<GlobalReminderSettingsNotifier, GlobalReminderSettings>((ref) {
  final reminderService = ref.watch(bookingReminderServiceProvider);
  return GlobalReminderSettingsNotifier(reminderService);
});
