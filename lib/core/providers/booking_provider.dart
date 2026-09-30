import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client_provider.dart';
import 'notification_provider.dart';
import '../services/booking_reminder_service.dart';
import '../../data/repositories/booking_repository.dart';
import '../../shared/models/booking.dart';
import '../../shared/models/calendar_event.dart';
import '../../shared/models/reminder_offset.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(apiClient: ref.watch(apiClientProvider));
});

final bookingProvider =
    StateNotifierProvider<BookingNotifier, AsyncValue<List<Booking>>>((
      ref,
    ) {
      return BookingNotifier(
        ref.watch(bookingRepositoryProvider),
        ref,
        reminderService: ref.watch(bookingReminderServiceProvider),
      );
    });

/// Single batch provider that fetches ALL vendor bookings in one request.
/// Returns Map<vendorId, List<Booking>> from /api/vendors/bookings/all.
final allVendorBookingsProvider =
    StateNotifierProvider<AllVendorBookingsNotifier, AsyncValue<Map<String, List<Booking>>>>((
      ref,
    ) {
      return AllVendorBookingsNotifier(ref.watch(bookingRepositoryProvider));
    });

final calendarEventsProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getCalendarEvents();
});

final calendarDayBookingsProvider = FutureProvider.family<List<Booking>, String>((ref, date) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getCalendarDayBookings(date);
});

class AllVendorBookingsNotifier extends StateNotifier<AsyncValue<Map<String, List<Booking>>>> {
  AllVendorBookingsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadBookings();
  }

  final BookingRepository _repository;

  Future<void> loadBookings() async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      return await _repository.getAllVendorBookings();
    });
    if (mounted) {
      state = result;
    }
  }

  /// Get bookings for a specific vendor from the cached batch data.
  List<Booking> getVendorBookings(String vendorId) {
    final data = state.valueOrNull;
    if (data == null) return [];
    return data[vendorId] ?? [];
  }
}

class BookingNotifier extends StateNotifier<AsyncValue<List<Booking>>> {
  BookingNotifier(
    this._repository,
    this._ref, {
    BookingReminderService? reminderService,
  })  : _reminderService = reminderService,
        super(const AsyncValue.loading()) {
    loadBookings();
  }

  final BookingRepository _repository;
  final Ref _ref;
  final BookingReminderService? _reminderService;

  BookingReminderService? get _reminder {
    if (_reminderService != null) return _reminderService;
    try {
      return _ref.read(bookingReminderServiceProvider);
    } catch (_) {
      return null;
    }
  }

  List<Booking> _cachedBookings = [];
  Booking? _lastDeletedBooking;
  int? _lastDeletedIndex;
  Timer? _deleteTimer;

  @override
  void dispose() {
    _deleteTimer?.cancel();
    super.dispose();
  }

  Future<void> loadBookings({
    DateTime? startDate,
    DateTime? endDate,
    String? vendorId,
    String? status,
  }) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      final bookings = await _repository.getBookings(
        startDate: startDate,
        endDate: endDate,
        vendorId: vendorId,
        status: status,
      );
      _cachedBookings = bookings;
      return bookings;
    });
    if (mounted) {
      state = result;
    }
  }

  Future<void> addBooking(Booking booking, [ReminderOffset? reminderOffset]) async {
    final previous = List<Booking>.of(_cachedBookings);
    _cachedBookings = [booking, ..._cachedBookings];
    state = AsyncValue.data(_cachedBookings);

    try {
      await _repository.createBooking(booking);
      _ref.invalidate(allVendorBookingsProvider);
      _ref.invalidate(calendarEventsProvider);
      _ref.invalidate(calendarDayBookingsProvider);

      // Schedule global multi-trigger reminders
      unawaited(_reminder?.scheduleRemindersForBooking(booking));

      final offset = reminderOffset ?? booking.reminderOffset;
      if (offset != null && offset != ReminderOffset.none) {
        unawaited(_reminder?.setReminder(
          booking.id,
          booking.startDate,
          offset,
          vendorName: booking.vendorName,
        ));
      }

      await loadBookings();
    } catch (error, stackTrace) {
      _cachedBookings = previous;
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateBooking(Booking booking) async {
    final oldBooking = _cachedBookings.cast<Booking?>().firstWhere(
      (b) => b?.id == booking.id,
      orElse: () => null,
    );
    final dateChanged = oldBooking != null &&
        !oldBooking.startDate.isAtSameMomentAs(booking.startDate);

    final previous = List<Booking>.of(_cachedBookings);
    _cachedBookings = [
      for (final existing in _cachedBookings)
        if (existing.id == booking.id) booking else existing,
    ];
    state = AsyncValue.data(_cachedBookings);

    try {
      await _repository.updateBooking(booking.id, booking);
      _ref.invalidate(allVendorBookingsProvider);
      _ref.invalidate(calendarEventsProvider);
      _ref.invalidate(calendarDayBookingsProvider);

      if (dateChanged) {
        unawaited(() async {
          await _reminder?.cancelRemindersForBooking(booking.id);
          await _reminder?.scheduleRemindersForBooking(booking);
        }());
        unawaited(_reminder?.rescheduleForBooking(
          booking.id,
          booking.startDate,
          vendorName: booking.vendorName,
        ));
      } else if (booking.reminderOffset != null) {
        unawaited(_reminder?.setReminder(
          booking.id,
          booking.startDate,
          booking.reminderOffset!,
          vendorName: booking.vendorName,
        ));
      }

      await loadBookings();
    } catch (error, stackTrace) {
      _cachedBookings = previous;
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteBooking(String bookingId) async {
    _deleteTimer?.cancel();
    if (_lastDeletedBooking != null) {
      await _repository.deleteBooking(_lastDeletedBooking!.id);
      unawaited(_reminder?.cancelRemindersForBooking(_lastDeletedBooking!.id));
      unawaited(_reminder?.clearReminderStorage(_lastDeletedBooking!.id));
      _lastDeletedBooking = null;
    }

    final index = _cachedBookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return;

    _lastDeletedBooking = _cachedBookings[index];
    _lastDeletedIndex = index;

    // Immediately cancel OS notifications BEFORE 5s undo timer starts
    unawaited(_reminder?.cancelRemindersForBooking(bookingId));
    unawaited(_reminder?.cancelNotificationOnly(bookingId));

    _cachedBookings = List<Booking>.from(_cachedBookings)..removeAt(index);
    state = AsyncValue.data(_cachedBookings);

    _deleteTimer = Timer(const Duration(seconds: 5), () async {
      if (_lastDeletedBooking != null && _lastDeletedBooking!.id == bookingId) {
        try {
          await _repository.deleteBooking(bookingId);
          unawaited(_reminder?.cancelRemindersForBooking(bookingId));
          unawaited(_reminder?.clearReminderStorage(bookingId));
          _lastDeletedBooking = null;
          _lastDeletedIndex = null;
          _ref.invalidate(allVendorBookingsProvider);
          _ref.invalidate(calendarEventsProvider);
          _ref.invalidate(calendarDayBookingsProvider);
        } catch (error, stackTrace) {
          if (_lastDeletedBooking != null && _lastDeletedIndex != null) {
            _cachedBookings = List<Booking>.from(_cachedBookings)
              ..insert(_lastDeletedIndex!.clamp(0, _cachedBookings.length), _lastDeletedBooking!);
            state = AsyncValue.data(_cachedBookings);
            // Re-schedule reminder on delete failure
            unawaited(_reminder?.scheduleRemindersForBooking(_lastDeletedBooking!));
            unawaited(_reminder?.rescheduleForBooking(
              _lastDeletedBooking!.id,
              _lastDeletedBooking!.startDate,
              vendorName: _lastDeletedBooking!.vendorName,
            ));
          }
          _lastDeletedBooking = null;
          _lastDeletedIndex = null;
          state = AsyncValue.error(error, stackTrace);
        }
      }
    });
  }

  void undoDeleteBooking() {
    if (_lastDeletedBooking != null && _lastDeletedIndex != null) {
      final restored = _lastDeletedBooking!;
      _deleteTimer?.cancel();
      final insertIndex = _lastDeletedIndex!.clamp(0, _cachedBookings.length);
      _cachedBookings = List<Booking>.from(_cachedBookings)
        ..insert(insertIndex, restored);
      state = AsyncValue.data(_cachedBookings);
      _lastDeletedBooking = null;
      _lastDeletedIndex = null;
      _ref.invalidate(allVendorBookingsProvider);
      _ref.invalidate(calendarEventsProvider);
      _ref.invalidate(calendarDayBookingsProvider);

      // Re-schedule reminders using global settings and legacy persisted settings
      unawaited(_reminder?.scheduleRemindersForBooking(restored));
      unawaited(_reminder?.rescheduleForBooking(
        restored.id,
        restored.startDate,
        vendorName: restored.vendorName,
      ));
    }
  }
}
