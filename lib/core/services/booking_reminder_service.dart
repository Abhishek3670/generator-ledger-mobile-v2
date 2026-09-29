import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/reminder_offset.dart';
import 'notification_service.dart';

/// Service responsible for managing booking reminder notifications and their persistence.
class BookingReminderService {
  final NotificationService _notificationService;
  final SharedPreferences _prefs;

  BookingReminderService(this._notificationService, this._prefs);

  static String _key(String bookingId) => 'reminder_$bookingId';

  /// Sets a reminder notification for [bookingId].
  ///
  /// - If [offset] is [ReminderOffset.none], existing reminder is cancelled and cleared.
  /// - If the computed trigger time is in the past, returns `false` and does not schedule.
  /// - Otherwise, schedules the OS notification, persists configuration, and returns `true`.
  Future<bool> setReminder(
    String bookingId,
    DateTime startDate,
    ReminderOffset offset, {
    String? vendorName,
  }) async {
    if (offset == ReminderOffset.none) {
      await cancelReminder(bookingId);
      return true;
    }

    final scheduledDate = startDate.subtract(offset.duration);
    if (scheduledDate.isBefore(DateTime.now())) {
      return false;
    }

    final id = bookingId.hashCode;
    final displayName = (vendorName != null && vendorName.trim().isNotEmpty)
        ? vendorName.trim()
        : 'Vendor';
    final formattedDate = DateFormat('yyyy-MM-dd').format(startDate);

    final title = 'Booking Reminder — $displayName';
    final body = 'Upcoming booking for $displayName on $formattedDate';

    final scheduled = await _notificationService.scheduleNotification(
      id,
      title,
      body,
      scheduledDate,
      payload: bookingId,
    );

    if (scheduled) {
      final payload = jsonEncode({
        'offset': offset.name,
        'vendorName': displayName,
        'startDate': startDate.toIso8601String(),
      });
      await _prefs.setString(_key(bookingId), payload);
      return true;
    }

    return false;
  }

  /// Cancels any scheduled notification for [bookingId].
  ///
  /// If [clearStorage] is true, also removes the persisted reminder record.
  Future<void> cancelReminder(
    String bookingId, {
    bool clearStorage = true,
  }) async {
    final id = bookingId.hashCode;
    await _notificationService.cancelNotification(id);
    if (clearStorage) {
      await _prefs.remove(_key(bookingId));
    }
  }

  /// Cancels only the OS notification while keeping the stored reminder metadata intact.
  /// Useful for soft-delete with undo window.
  Future<void> cancelNotificationOnly(String bookingId) async {
    await cancelReminder(bookingId, clearStorage: false);
  }

  /// Clears only the stored reminder record for [bookingId].
  Future<void> clearReminderStorage(String bookingId) async {
    await _prefs.remove(_key(bookingId));
  }

  /// Retrieves the current [ReminderOffset] for [bookingId] from SharedPreferences.
  /// Returns `null` if no reminder is configured.
  ReminderOffset? getReminder(String bookingId) {
    final raw = _prefs.getString(_key(bookingId));
    if (raw == null || raw.isEmpty) return null;

    try {
      if (raw.startsWith('{')) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final offsetStr = decoded['offset'] as String?;
        return ReminderOffset.fromString(offsetStr);
      }
      return ReminderOffset.fromString(raw);
    } catch (_) {
      return null;
    }
  }

  /// Retrieves raw reminder metadata map (offset, vendorName, startDate) if present.
  Map<String, dynamic>? getReminderData(String bookingId) {
    final raw = _prefs.getString(_key(bookingId));
    if (raw == null || raw.isEmpty) return null;

    try {
      if (raw.startsWith('{')) {
        return jsonDecode(raw) as Map<String, dynamic>;
      }
      return {'offset': raw};
    } catch (_) {
      return null;
    }
  }

  /// Reschedules an existing reminder for [bookingId] against a [newStartDate].
  /// Cancels the old notification and schedules a new one with the original offset.
  /// Returns `false` if no prior reminder existed or if the new trigger time is in the past.
  Future<bool> rescheduleForBooking(
    String bookingId,
    DateTime newStartDate, {
    String? vendorName,
  }) async {
    final data = getReminderData(bookingId);
    if (data == null) return false;

    final offsetStr = data['offset'] as String?;
    final offset = ReminderOffset.fromString(offsetStr);
    if (offset == ReminderOffset.none) return false;

    final resolvedVendorName = vendorName ?? data['vendorName'] as String?;

    // Cancel old OS notification
    await _notificationService.cancelNotification(bookingId.hashCode);

    // Schedule new notification with new date
    return await setReminder(
      bookingId,
      newStartDate,
      offset,
      vendorName: resolvedVendorName,
    );
  }
}
