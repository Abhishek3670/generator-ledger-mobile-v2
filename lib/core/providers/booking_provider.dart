import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/booking_repository.dart';
import '../../shared/models/booking.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository();
});

final bookingProvider =
    StateNotifierProvider<BookingNotifier, AsyncValue<List<Booking>>>((
      ref,
    ) {
      return BookingNotifier(ref.watch(bookingRepositoryProvider));
    });

class BookingNotifier extends StateNotifier<AsyncValue<List<Booking>>> {
  BookingNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadBookings();
  }

  final BookingRepository _repository;

  List<Booking> _cachedBookings = [];

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
      await loadBookings();
    } catch (error, stackTrace) {
      _cachedBookings = previous;
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteBooking(String bookingId) async {
    final previous = List<Booking>.of(_cachedBookings);
    _cachedBookings = _cachedBookings
        .where((booking) => booking.id != bookingId)
        .toList();
    state = AsyncValue.data(_cachedBookings);

    try {
      await _repository.deleteBooking(bookingId);
      await loadBookings();
    } catch (error, stackTrace) {
      _cachedBookings = previous;
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
