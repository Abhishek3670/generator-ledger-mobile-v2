import 'package:flutter_riverpod/flutter_riverpod.dart';

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
