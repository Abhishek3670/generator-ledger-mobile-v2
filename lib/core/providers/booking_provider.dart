import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_bookings.dart';
import '../services/mock_data_service.dart';

final bookingProvider =
    StateNotifierProvider<BookingNotifier, List<MockBooking>>((ref) {
  return BookingNotifier(MockDataService().getBookings());
});

class BookingNotifier extends StateNotifier<List<MockBooking>> {
  BookingNotifier(super.initialBookings);

  void addBooking(MockBooking booking) {
    state = [booking, ...state];
  }

  void updateBooking(MockBooking booking) {
    state = [
      for (final existing in state)
        if (existing.id == booking.id) booking else existing,
    ];
  }

  void deleteBooking(String bookingId) {
    state = state.where((booking) => booking.id != bookingId).toList();
  }
}
