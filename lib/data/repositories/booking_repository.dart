import '../../core/services/api_client.dart';
import '../../shared/models/booking.dart';
import '../../shared/models/calendar_event.dart';

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

  Future<List<Booking>> getVendorBookings(String vendorId) async {
    return _apiClient.get<List<Booking>>(
      '/api/vendors/$vendorId/bookings',
      fromJson: (json) => _parseVendorBookingsResponse(json),
    );
  }

  /// Fetches all vendor bookings in a single batch request.
  /// Prevents connection pool exhaustion from per-vendor calls.
  Future<Map<String, List<Booking>>> getAllVendorBookings() async {
    return _apiClient.get<Map<String, List<Booking>>>(
      '/api/vendors/bookings/all',
      fromJson: (json) => _parseAllVendorBookingsResponse(json),
    );
  }

  Future<List<CalendarEvent>> getCalendarEvents() async {
    return _apiClient.get<List<CalendarEvent>>(
      '/api/calendar/events',
      fromJson: (json) => (json as List)
          .map((e) => CalendarEvent.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<Booking>> getCalendarDayBookings(String date) async {
    return _apiClient.get<List<Booking>>(
      '/api/calendar/day',
      queryParameters: {'date': date},
      fromJson: (json) => _parseCalendarDayResponse(json, date),
    );
  }

  List<Booking> _parseCalendarDayResponse(dynamic json, String date) {
    final rawMap = json as Map<String, dynamic>;
    final rawList = rawMap['vendors'] as List<dynamic>? ?? [];
    final List<Booking> result = [];
    
    for (final vendorData in rawList) {
      final vendor = vendorData as Map<String, dynamic>;
      final vendorId = vendor['vendor_id']?.toString() ?? '';
      final vendorName = vendor['vendor_name']?.toString() ?? '';
      final bookingsRaw = vendor['bookings'] as List<dynamic>? ?? [];
      
      for (final item in bookingsRaw) {
        final itemMap = Map<String, dynamic>.from(item as Map);
        itemMap.putIfAbsent('vendor_id', () => vendorId);
        itemMap.putIfAbsent('vendor_name', () => vendorName);
        itemMap.putIfAbsent('start_date', () => date);
        itemMap.putIfAbsent('end_date', () => date);
        itemMap.putIfAbsent('status', () => 'confirmed');
        result.add(Booking.fromMap(itemMap));
      }
    }
    return result;
  }

  Map<String, List<Booking>> _parseAllVendorBookingsResponse(dynamic json) {
    final rawMap = json as Map<String, dynamic>;
    final vendors = rawMap['vendors'] as List<dynamic>? ?? [];
    final result = <String, List<Booking>>{};

    for (final vendorData in vendors) {
      final vendor = vendorData as Map<String, dynamic>;
      final vendorId = vendor['vendor_id']?.toString() ?? '';
      final vendorName = vendor['vendor_name']?.toString() ?? '';
      final bookingsRaw = vendor['bookings'] as List<dynamic>? ?? [];

      result[vendorId] = bookingsRaw.map((item) {
        final itemMap = Map<String, dynamic>.from(item as Map);
        itemMap.putIfAbsent('vendor_id', () => vendorId);
        itemMap.putIfAbsent('vendor_name', () => vendorName);
        return Booking.fromMap(itemMap);
      }).toList();
    }

    return result;
  }

  List<Booking> _parseVendorBookingsResponse(dynamic json) {
    final rawMap = json as Map<String, dynamic>;
    final vendorId = rawMap['vendor_id']?.toString() ?? '';
    final vendorName = rawMap['vendor_name']?.toString() ?? '';
    
    final bookingsRaw = rawMap['bookings'] as List<dynamic>? ?? [];
    return bookingsRaw
        .map((item) {
          final itemMap = Map<String, dynamic>.from(item as Map);
          itemMap.putIfAbsent('vendor_id', () => vendorId);
          itemMap.putIfAbsent('vendor_name', () => vendorName);
          return Booking.fromMap(itemMap);
        })
        .toList();
  }

  Future<Booking> createBooking(Booking booking) async {
    // Backend returns {success, booking_id, message, is_merged, total_items}
    // not a full booking object. We return the original booking with the server-assigned ID.
    final response = await _apiClient.post<Map<String, dynamic>>(
      bookingsPath,
      data: booking.toMap(),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    final serverId = response['booking_id']?.toString() ?? booking.id;
    return booking.copyWith(id: serverId);
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
