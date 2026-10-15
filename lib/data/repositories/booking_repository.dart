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

  List<CalendarEvent>? _cachedCalendarEvents;

  void clearCalendarCache() {
    _cachedCalendarEvents = null;
  }

  Future<List<CalendarEvent>> getCalendarEvents() async {

    try {
      final events = await _apiClient.get<List<CalendarEvent>>(
        '/api/calendar/events',
        fromJson: (json) {
          final list = switch (json) {
            List<dynamic> l => l,
            {'events': final List<dynamic> l} => l,
            {'data': final List<dynamic> l} => l,
            {'calendar_events': final List<dynamic> l} => l,
            _ => <dynamic>[],
          };
          return list
              .whereType<Map<String, dynamic>>()
              .map((e) => CalendarEvent.fromMap(e))
              .toList();
        },
      );
      _cachedCalendarEvents = events;
      return events;
    } catch (_) {
      if (_cachedCalendarEvents != null) {
        return _cachedCalendarEvents!;
      }
      rethrow;
    }
  }

  Future<List<Booking>> getCalendarDayBookings(String date) async {
    return _apiClient.get<List<Booking>>(
      '/api/calendar/day',
      queryParameters: {'date': date},
      fromJson: (json) => _parseCalendarDayResponse(json, date),
    );
  }

  List<Booking> _parseCalendarDayResponse(dynamic json, String date) {
    if (json is! Map<String, dynamic>) {
      if (json is List) {
        return json
            .whereType<Map<String, dynamic>>()
            .map((e) => Booking.fromMap(e))
            .toList();
      }
      return [];
    }
    final rawMap = json;
    final rawList = rawMap['vendors'] as List<dynamic>? ??
        rawMap['bookings'] as List<dynamic>? ??
        [];
    final List<Booking> result = [];
    
    for (final vendorData in rawList) {
      final vendor = vendorData as Map<String, dynamic>;
      final vendorId = vendor['vendor_id']?.toString() ?? '';
      final vendorName = vendor['vendor_name']?.toString() ?? '';
      final bookingsRaw = vendor['bookings'] as List<dynamic>? ?? [];
      
      for (final bookingRaw in bookingsRaw) {
        final bMap = Map<String, dynamic>.from(bookingRaw as Map);
        final bookingId = (bMap['booking_id'] ?? bMap['id'] ?? '').toString();
        final itemsRaw = bMap['items'] as List<dynamic>? ?? [];
        
        if (itemsRaw.isEmpty) {
          bMap.putIfAbsent('vendor_id', () => vendorId);
          bMap.putIfAbsent('vendor_name', () => vendorName);
          bMap.putIfAbsent('start_date', () => date);
          bMap.putIfAbsent('end_date', () => date);
          bMap.putIfAbsent('status', () => 'confirmed');
          result.add(Booking.fromMap(bMap));
        } else {
          for (final item in itemsRaw) {
            final itemData = Map<String, dynamic>.from(item as Map);
            final genId = (itemData['generator_id'] ?? itemData['generator'] ?? '').toString();
            final capKva = itemData['capacity_kva'] ?? itemData['capacity'];
            String capacityStr = 'N/A';
            if (capKva is num) {
              final isWhole = capKva.truncateToDouble() == capKva;
              capacityStr = '${capKva.toStringAsFixed(isWhole ? 0 : 1)} kVA';
            } else if (capKva is String && capKva.isNotEmpty) {
              capacityStr = capKva;
            }
            final bookingItem = BookingItem.fromMap(itemData);

            final startDtStr = (itemData['start_dt'] ?? itemData['startDate'] ?? date).toString();
            final endDtStr = (itemData['end_dt'] ?? itemData['endDate'] ?? date).toString();
            final startDate = DateTime.tryParse(startDtStr.split(' ')[0]) ?? DateTime.parse(date);
            final endDate = DateTime.tryParse(endDtStr.split(' ')[0]) ?? startDate;

            result.add(Booking(
              id: bookingId,
              vendorId: vendorId,
              vendorName: vendorName.isEmpty ? 'Unknown Vendor' : vendorName,
              generatorId: genId,
              capacity: capacityStr,
              date: startDate,
              endDate: endDate,
              status: (itemData['item_status'] ?? bMap['status'] ?? 'confirmed').toString(),
              notes: (itemData['remarks'] ?? bMap['notes'] ?? '').toString(),
              items: [bookingItem],
            ));
          }
        }
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
