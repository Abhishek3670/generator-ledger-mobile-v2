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
    final rawGenerators = map['generator_ids'] ?? map['generators'];
    final generators = switch (rawGenerators) {
      List<dynamic> values => values.map((value) => value.toString()).toList(),
      String value when value.isNotEmpty => [value],
      _ => [
        (map['generator_id'] ?? map['generatorId'] ?? map['generator'] ?? '')
            .toString(),
      ],
    }..removeWhere((value) => value.isEmpty);

    final startDate = _parseDate(
      map['start_date'] ?? map['startDate'] ?? map['date'],
    );
    final endDate = _parseDate(
      map['end_date'] ?? map['endDate'] ?? map['date'],
      fallback: startDate,
    );

    return Booking.withGenerators(
      bookingId: (map['booking_id'] ?? map['bookingId'] ?? map['id'] ?? '')
          .toString(),
      vendorId: (map['vendor_id'] ?? map['vendorId'] ?? '').toString(),
      vendorName: (map['vendor_name'] ?? map['vendorName'] ?? '').toString(),
      generators: generators,
      startDate: startDate,
      endDate: endDate,
      status: (map['status'] ?? 'pending').toString(),
      notes: (map['notes'] ?? '').toString(),
      capacity: _capacityFromMap(map),
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
    return (value ?? '').toString();
  }
}
