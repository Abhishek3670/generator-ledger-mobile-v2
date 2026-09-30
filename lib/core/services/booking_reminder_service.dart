import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/booking.dart';
import '../../shared/models/reminder_offset.dart';
import 'notification_service.dart';

/// Service responsible for managing booking reminder notifications and their persistence.
class BookingReminderService {
  final NotificationService _notificationService;
  final SharedPreferences _prefs;

  BookingReminderService(this._notificationService, this._prefs);

  static const String keyGlobalEnabled = 'global_reminders_enabled';
  static const String keyGlobalOffsets = 'global_reminder_offsets';

  static String _key(String bookingId) => 'reminder_$bookingId';

  /// Generates a deterministic, positive 31-bit notification ID for a given (bookingId, offset) pair.
  static int getNotificationId(String bookingId, ReminderOffset offset) {
    return '${bookingId}_${offset.name}'.hashCode & 0x7FFFFFFF;
  }

  // ==========================================
  // Global Multi-Trigger Settings & Scheduling
  // ==========================================

  /// Retrieves global reminder settings from SharedPreferences.
  /// Defaults to enabled: true with 1 day before (24hr) active.
  GlobalReminderSettings getGlobalSettings() {
    final enabled = _prefs.getBool(keyGlobalEnabled) ?? true;
    final list = _prefs.getStringList(keyGlobalOffsets);
    Set<ReminderOffset> offsets = {ReminderOffset.oneDay};
    if (list != null) {
      offsets = list
          .map((e) => ReminderOffset.fromString(e))
          .where((o) => o != ReminderOffset.none)
          .toSet();
      if (offsets.isEmpty && enabled) {
        offsets = {ReminderOffset.oneDay};
      }
    }
    return GlobalReminderSettings(
      enabled: enabled,
      selectedOffsets: offsets,
    );
  }

  /// Persists global reminder settings to SharedPreferences.
  Future<void> saveGlobalSettings(GlobalReminderSettings settings) async {
    await _prefs.setBool(keyGlobalEnabled, settings.enabled);
    await _prefs.setStringList(
      keyGlobalOffsets,
      settings.selectedOffsets.map((o) => o.name).toList(),
    );
  }

  /// Schedules notifications for [booking] across all active global reminder offsets.
  /// Returns the number of successfully scheduled notifications.
  Future<int> scheduleRemindersForBooking(
    Booking booking, [
    GlobalReminderSettings? settings,
  ]) async {
    final activeSettings = settings ?? getGlobalSettings();
    if (!activeSettings.enabled) {
      return 0;
    }

    final displayName = booking.vendorName.trim().isNotEmpty
        ? booking.vendorName.trim()
        : 'Vendor';
    final formattedDate = DateFormat('MMM dd, yyyy').format(booking.startDate);

    // Record active reminder metadata only if not already customized
    if (!_prefs.containsKey(_key(booking.id))) {
      final primaryOffset = (booking.reminderOffset != null &&
              booking.reminderOffset != ReminderOffset.none)
          ? booking.reminderOffset!
          : (activeSettings.selectedOffsets.contains(ReminderOffset.oneDay)
              ? ReminderOffset.oneDay
              : activeSettings.selectedOffsets
                      .where((o) => o != ReminderOffset.none)
                      .firstOrNull ??
                  ReminderOffset.oneDay);
      final payload = jsonEncode({
        'offset': primaryOffset.name,
        'vendorName': displayName,
        'startDate': booking.startDate.toIso8601String(),
      });
      await _prefs.setString(_key(booking.id), payload);
    }

    int count = 0;
    for (final offset in activeSettings.selectedOffsets) {
      if (offset == ReminderOffset.none) continue;

      final triggerTime = booking.startDate.subtract(offset.duration);
      if (triggerTime.isAfter(DateTime.now())) {
        final id = getNotificationId(booking.id, offset);
        final title = 'Booking Reminder (${offset.displayLabel}) — $displayName';
        final body =
            'Upcoming 24hr booking for $displayName starts on $formattedDate.';

        final scheduled = await _notificationService.scheduleNotification(
          id,
          title,
          body,
          triggerTime,
          payload: booking.id,
        );
        if (scheduled) {
          count++;
        }
      }
    }
    return count;
  }

  /// Cancels all scheduled reminder triggers across all offsets for [bookingId].
  Future<void> cancelRemindersForBooking(String bookingId) async {
    for (final offset in ReminderOffset.values) {
      final id = getNotificationId(bookingId, offset);
      await _notificationService.cancelNotification(id);
    }
    // Also cancel legacy single-id notification
    await _notificationService.cancelNotification(bookingId.hashCode);
  }

  /// Resyncs all reminders: updates settings if provided, cancels existing alarms,
  /// and schedules active offsets for all upcoming bookings.
  Future<int> resyncAllReminders(
    List<Booking> bookings, [
    GlobalReminderSettings? newSettings,
  ]) async {
    if (newSettings != null) {
      await saveGlobalSettings(newSettings);
    }
    final activeSettings = newSettings ?? getGlobalSettings();

    // Cancel all existing notifications
    await _notificationService.cancelAllNotifications();

    if (!activeSettings.enabled) {
      return 0;
    }

    int totalScheduled = 0;
    final now = DateTime.now();
    for (final booking in bookings) {
      if (booking.startDate.isAfter(now.subtract(const Duration(days: 7)))) {
        totalScheduled += await scheduleRemindersForBooking(booking, activeSettings);
      }
    }
    return totalScheduled;
  }

  // ==========================================
  // Single-Offset / Legacy Methods (Backward Compatible)
  // ==========================================

  /// Sets a single reminder notification for [bookingId].
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

  /// Cancels scheduled notification for [bookingId].
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
  Future<void> cancelNotificationOnly(String bookingId) async {
    await cancelReminder(bookingId, clearStorage: false);
  }

  /// Clears only the stored reminder record for [bookingId].
  Future<void> clearReminderStorage(String bookingId) async {
    await _prefs.remove(_key(bookingId));
  }

  /// Checks whether reminders are active for [booking].
  /// Returns `true` if global reminders are enabled and the booking is upcoming
  /// (i.e. [Booking.startDate] is after now), or if an active reminder is configured.
  bool hasRemindersForBooking(
    Booking booking, [
    GlobalReminderSettings? settings,
  ]) {
    final raw = _prefs.getString(_key(booking.id));
    if (raw != null && raw.isNotEmpty) {
      try {
        final offset = raw.startsWith('{')
            ? ReminderOffset.fromString(
                (jsonDecode(raw) as Map<String, dynamic>)['offset'] as String?)
            : ReminderOffset.fromString(raw);
        if (offset != ReminderOffset.none) return true;
      } catch (_) {}
    }

    final activeSettings = settings ?? getGlobalSettings();
    if (!activeSettings.enabled || activeSettings.selectedOffsets.isEmpty) {
      return false;
    }

    return booking.startDate.isAfter(DateTime.now());
  }

  /// Retrieves the current [ReminderOffset] for [bookingId] from SharedPreferences.
  /// If a legacy per-booking offset exists in SharedPreferences, it is returned.
  /// If [booking] is provided and global reminders are active, returns the primary
  /// active offset (e.g. `oneDay`), or null if global reminders are disabled or if
  /// [booking] is in the past.
  ReminderOffset? getReminder(
    String bookingId, [
    Booking? booking,
    GlobalReminderSettings? settings,
  ]) {
    final raw = _prefs.getString(_key(bookingId));
    if (raw != null && raw.isNotEmpty) {
      try {
        if (raw.startsWith('{')) {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          final offsetStr = decoded['offset'] as String?;
          final offset = ReminderOffset.fromString(offsetStr);
          if (offset != ReminderOffset.none) return offset;
        } else {
          final offset = ReminderOffset.fromString(raw);
          if (offset != ReminderOffset.none) return offset;
        }
      } catch (_) {}
    }

    final activeSettings = settings ?? getGlobalSettings();
    if (!activeSettings.enabled || activeSettings.selectedOffsets.isEmpty) {
      return null;
    }

    if (booking != null) {
      if (!hasRemindersForBooking(booking, activeSettings)) {
        return null;
      }
      if (activeSettings.selectedOffsets.contains(ReminderOffset.oneDay)) {
        return ReminderOffset.oneDay;
      }
      return activeSettings.selectedOffsets
          .where((o) => o != ReminderOffset.none)
          .firstOrNull;
    }

    return null;
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
