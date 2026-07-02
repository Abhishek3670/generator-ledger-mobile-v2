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
  })  : bookingId = id,
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
}
