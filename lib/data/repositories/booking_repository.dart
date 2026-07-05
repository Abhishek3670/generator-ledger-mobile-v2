import '../../core/services/api_client.dart';
import '../../shared/models/booking.dart';

class BookingRepository {
  BookingRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  static const String bookingsPath = '/api/bookings';

  final ApiClient _apiClient;

  Future<List<Booking>> getBookings({
    DateTime? startDate,
    DateTime? endDate,
    String? vendorId,
    String? status,
  }) async {
    return _apiClient.get<List<Booking>>(
      bookingsPath,
      queryParameters: _filters(
        startDate: startDate,
        endDate: endDate,
        vendorId: vendorId,
        status: status,
      ),
      fromJson: (json) => _parseBookingList(json),
    );
  }

  Future<Booking> createBooking(Booking booking) async {
    return _apiClient.post<Booking>(
      bookingsPath,
      data: booking.toMap(),
      fromJson: (json) => _parseBooking(json),
    );
  }

  Future<Booking> updateBooking(String id, Booking booking) async {
    return _apiClient.patch<Booking>(
      '$bookingsPath/$id',
      data: booking.toMap(),
      fromJson: (json) => _parseBooking(json),
    );
  }

  Future<void> deleteBooking(String id) async {
    await _apiClient.delete<void>('$bookingsPath/$id', fromJson: (_) {});
  }

  Map<String, dynamic>? _filters({
    DateTime? startDate,
    DateTime? endDate,
    String? vendorId,
    String? status,
  }) {
    final filters = <String, dynamic>{
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
      if (vendorId != null && vendorId.isNotEmpty) 'vendorId': vendorId,
      if (status != null && status.isNotEmpty) 'status': status,
    };
    return filters.isEmpty ? null : filters;
  }

  List<Booking> _parseBookingList(dynamic json) {
    final rawList = switch (json) {
      List<dynamic> list => list,
      {'bookings': final List<dynamic> list} => list,
      {'data': final List<dynamic> list} => list,
      {'items': final List<dynamic> list} => list,
      _ => throw const FormatException('Bookings response must be a list'),
    };

    return rawList
        .map((item) => Booking.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Booking _parseBooking(dynamic json) {
    final rawBooking = switch (json) {
      {'booking': final Map<String, dynamic> booking} => booking,
      {'data': final Map<String, dynamic> booking} => booking,
      Map<String, dynamic> booking => booking,
      _ => throw const FormatException('Booking response must be an object'),
    };

    return Booking.fromMap(rawBooking);
  }
}
