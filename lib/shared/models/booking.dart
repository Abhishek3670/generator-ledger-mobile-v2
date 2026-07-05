class Booking {
  final String bookingId;
  final String vendorId;
  final String vendorName;
  final List<String> generators;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String notes;
  final String capacity;

  Booking({
    required String id,
    required this.vendorId,
    required this.vendorName,
    required String generatorId,
    required this.capacity,
    required DateTime date,
    required this.status,
    this.notes = '',
    DateTime? endDate,
  }) : bookingId = id,
       generators = [generatorId],
       startDate = date,
       endDate = endDate ?? date;

  String get id => bookingId;
  String get generatorId => generators.isEmpty ? '' : generators.first;
  DateTime get date => startDate;

  Booking.withGenerators({
    required this.bookingId,
    required this.vendorId,
    required this.vendorName,
    required this.generators,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.notes,
    required this.capacity,
  });

  Booking copyWith({
    String? id,
    String? vendorId,
    String? vendorName,
    String? generatorId,
    List<String>? generators,
    String? capacity,
    DateTime? date,
    DateTime? endDate,
    String? status,
    String? notes,
  }) {
    return Booking.withGenerators(
      bookingId: id ?? bookingId,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      generators: generators ?? [generatorId ?? this.generatorId],
      startDate: date ?? startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      capacity: capacity ?? this.capacity,
    );
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    // First, try to parse from new 'items' array format
    List<String> generators = [];
    double totalCapacity = 0.0;
    
    final items = map['items'];
    if (items is List && items.isNotEmpty) {
      for (final item in items) {
        if (item is Map<String, dynamic>) {
          final genId = item['generator_id']?.toString();
          if (genId != null && genId.isNotEmpty) {
            generators.add(genId);
          }
          final capacity = item['capacity_kva'];
          if (capacity is num) {
            totalCapacity += capacity.toDouble();
          }
        }
      }
    }
    
    // Fallback to legacy generator_ids field if items not present
    if (generators.isEmpty) {
      final rawGenerators = map['generator_ids'] ?? map['generators'];
      generators = switch (rawGenerators) {
        List<dynamic> values => values.map((value) => value.toString()).toList(),
        String value when value.isNotEmpty => [value],
        _ => [
          (map['generator_id'] ?? map['generatorId'] ?? map['generator'] ?? '')
              .toString(),
        ],
      }..removeWhere((value) => value.isEmpty);
    }

    // Handle both created_at and date fields for start date
    final startDate = _parseDate(
      map['start_date'] ?? map['startDate'] ?? map['date'] ?? map['created_at'],
    );
    final endDate = _parseDate(
      map['end_date'] ?? map['endDate'] ?? map['date'] ?? map['created_at'],
      fallback: startDate,
    );

    // Handle vendor name - if missing, show vendor ID
    final vendorId = (map['vendor_id'] ?? map['vendorId'] ?? '').toString();
    final vendorName = (map['vendor_name'] ?? map['vendorName'] ?? vendorId).toString();

    // Capacity: prefer items total, then map fields, then N/A
    String capacityStr;
    if (totalCapacity > 0) {
      final isWhole = totalCapacity.truncateToDouble() == totalCapacity;
      capacityStr = '${totalCapacity.toStringAsFixed(isWhole ? 0 : 1)} kVA';
    } else {
      capacityStr = _capacityFromMap(map);
    }

    return Booking.withGenerators(
      bookingId: (map['booking_id'] ?? map['bookingId'] ?? map['id'] ?? '')
          .toString(),
      vendorId: vendorId,
      vendorName: vendorName.isEmpty ? 'Unknown Vendor' : vendorName,
      generators: generators.isEmpty ? ['N/A'] : generators,
      startDate: startDate,
      endDate: endDate,
      status: (map['status'] ?? 'pending').toString(),
      notes: (map['notes'] ?? '').toString(),
      capacity: capacityStr,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'booking_id': bookingId,
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      'generator_ids': generators,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status,
      'notes': notes,
      'capacity': capacity,
    };
  }

  static DateTime _parseDate(dynamic value, {DateTime? fallback}) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }
    if (fallback != null) {
      return fallback;
    }
    throw const FormatException('Booking date is required');
  }

  static String _capacityFromMap(Map<String, dynamic> map) {
    final value = map['capacity'] ?? map['capacity_kva'] ?? map['capacityKva'];
    if (value is num) {
      final isWhole = value.truncateToDouble() == value;
      return '${value.toStringAsFixed(isWhole ? 0 : 1)} kVA';
    }
    if (value is String && value.isNotEmpty) {
      return value;
    }
    // Default capacity if missing
    return 'N/A';
  }
}
