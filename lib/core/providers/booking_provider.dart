import 'dart:async';
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
      return BookingNotifier(ref.watch(bookingRepositoryProvider), ref);
    });

final vendorBookingsProvider =
    StateNotifierProvider.family<VendorBookingsNotifier, AsyncValue<List<Booking>>, String>((
      ref,
      vendorId,
    ) {
      return VendorBookingsNotifier(
        ref.watch(bookingRepositoryProvider),
        vendorId,
      );
    });

class VendorBookingsNotifier extends StateNotifier<AsyncValue<List<Booking>>> {
  VendorBookingsNotifier(this._repository, this.vendorId) : super(const AsyncValue.loading()) {
    loadBookings();
  }

  final BookingRepository _repository;
  final String vendorId;

  Future<void> loadBookings() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _repository.getVendorBookings(vendorId);
    });
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

    final vendorNotifier = _ref.read(vendorBookingsProvider(booking.vendorId).notifier);
    final prevVendorState = vendorNotifier.state;
    if (prevVendorState is AsyncData<List<Booking>>) {
      vendorNotifier.state = AsyncValue.data([booking, ...prevVendorState.value]);
    }

    try {
      await _repository.createBooking(booking);
      _ref.invalidate(vendorBookingsProvider(booking.vendorId));
      await loadBookings();
    } catch (error, stackTrace) {
      _cachedBookings = previous;
      state = AsyncValue.error(error, stackTrace);
      vendorNotifier.state = prevVendorState;
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

    final vendorNotifier = _ref.read(vendorBookingsProvider(booking.vendorId).notifier);
    final prevVendorState = vendorNotifier.state;
    if (prevVendorState is AsyncData<List<Booking>>) {
      vendorNotifier.state = AsyncValue.data([
        for (final existing in prevVendorState.value)
          if (existing.id == booking.id) booking else existing,
      ]);
    }

    try {
      await _repository.updateBooking(booking.id, booking);
      _ref.invalidate(vendorBookingsProvider(booking.vendorId));
      await loadBookings();
    } catch (error, stackTrace) {
      _cachedBookings = previous;
      state = AsyncValue.error(error, stackTrace);
      vendorNotifier.state = prevVendorState;
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

    final vendorId = _lastDeletedBooking!.vendorId;
    final vendorNotifier = _ref.read(vendorBookingsProvider(vendorId).notifier);
    final prevVendorState = vendorNotifier.state;
    if (prevVendorState is AsyncData<List<Booking>>) {
      vendorNotifier.state = AsyncValue.data(
        prevVendorState.value.where((b) => b.id != bookingId).toList(),
      );
    }

    _deleteTimer = Timer(const Duration(seconds: 5), () async {
      if (_lastDeletedBooking != null && _lastDeletedBooking!.id == bookingId) {
        try {
          await _repository.deleteBooking(bookingId);
          _lastDeletedBooking = null;
          _lastDeletedIndex = null;
        } catch (error, stackTrace) {
          if (_lastDeletedBooking != null && _lastDeletedIndex != null) {
            _cachedBookings = List<Booking>.from(_cachedBookings)
              ..insert(_lastDeletedIndex!.clamp(0, _cachedBookings.length), _lastDeletedBooking!);
            state = AsyncValue.data(_cachedBookings);
          }
          vendorNotifier.state = prevVendorState;
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

      final vendorId = _lastDeletedBooking!.vendorId;
      final vendorNotifier = _ref.read(vendorBookingsProvider(vendorId).notifier);
      if (vendorNotifier.state is AsyncData<List<Booking>>) {
        vendorNotifier.state = AsyncValue.data(
          [...vendorNotifier.state.value!, _lastDeletedBooking!],
        );
      }

      _lastDeletedBooking = null;
      _lastDeletedIndex = null;
    }
  }
}
