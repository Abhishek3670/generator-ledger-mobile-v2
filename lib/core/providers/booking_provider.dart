import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/booking_repository.dart';
import '../../shared/models/booking.dart';
import '../../shared/models/calendar_event.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository();
});

final bookingProvider =
    StateNotifierProvider<BookingNotifier, AsyncValue<List<Booking>>>((
      ref,
    ) {
      return BookingNotifier(ref.watch(bookingRepositoryProvider), ref);
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
    state = await AsyncValue.guard(() async {
      return await _repository.getAllVendorBookings();
    });
  }

  /// Get bookings for a specific vendor from the cached batch data.
  List<Booking> getVendorBookings(String vendorId) {
    final data = state.valueOrNull;
    if (data == null) return [];
    return data[vendorId] ?? [];
  }
}

class BookingNotifier extends StateNotifier<AsyncValue<List<Booking>>> {
  BookingNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadBookings();
  }

  final BookingRepository _repository;
  final Ref _ref;

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
    state = await AsyncValue.guard(() async {
      final bookings = await _repository.getBookings(
        startDate: startDate,
        endDate: endDate,
        vendorId: vendorId,
        status: status,
      );
      _cachedBookings = bookings;
      return bookings;
    });
  }

  Future<void> addBooking(Booking booking) async {
    final previous = List<Booking>.of(_cachedBookings);
    _cachedBookings = [booking, ..._cachedBookings];
    state = AsyncValue.data(_cachedBookings);

    try {
      await _repository.createBooking(booking);
      _ref.invalidate(allVendorBookingsProvider);
      _ref.invalidate(calendarEventsProvider);
      _ref.invalidate(calendarDayBookingsProvider);
      await loadBookings();
    } catch (error, stackTrace) {
      _cachedBookings = previous;
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateBooking(Booking booking) async {
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
      _lastDeletedBooking = null;
    }

    final index = _cachedBookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return;

    _lastDeletedBooking = _cachedBookings[index];
    _lastDeletedIndex = index;

    _cachedBookings = List<Booking>.from(_cachedBookings)..removeAt(index);
    state = AsyncValue.data(_cachedBookings);

    _deleteTimer = Timer(const Duration(seconds: 5), () async {
      if (_lastDeletedBooking != null && _lastDeletedBooking!.id == bookingId) {
        try {
          await _repository.deleteBooking(bookingId);
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
      _deleteTimer?.cancel();
      final insertIndex = _lastDeletedIndex!.clamp(0, _cachedBookings.length);
      _cachedBookings = List<Booking>.from(_cachedBookings)
        ..insert(insertIndex, _lastDeletedBooking!);
      state = AsyncValue.data(_cachedBookings);
      _lastDeletedBooking = null;
      _lastDeletedIndex = null;
      _ref.invalidate(allVendorBookingsProvider);
      _ref.invalidate(calendarEventsProvider);
      _ref.invalidate(calendarDayBookingsProvider);
    }
  }
}
