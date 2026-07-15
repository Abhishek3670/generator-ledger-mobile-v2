import 'package:intl/intl.dart';

class BookingItem {
  final String generatorId;
  final int? capacityKva;
  final String startDt;  // "2026-04-19" — the per-item date
  final String? endDt;
  final String itemStatus;
  final bool isEmergency;
  final String remarks;

  BookingItem({
    required this.generatorId,
    this.capacityKva,
    required this.startDt,
    this.endDt,
    required this.itemStatus,
    required this.isEmergency,
    required this.remarks,
  });

  factory BookingItem.fromMap(Map<String, dynamic> map) {
    final startDtRaw = (map['start_dt'] ?? map['startDt'] ?? '').toString();
    final isEmergency = map['is_emergency'] == true || map['inventory_type'] == 'emergency';
    final capacityKva = map['capacity_kva'] is num ? (map['capacity_kva'] as num).toInt() : null;

    return BookingItem(
      generatorId: (map['generator_id'] ?? '').toString(),
      capacityKva: capacityKva,
      startDt: startDtRaw,
      endDt: (map['end_dt'] ?? map['endDt'] ?? '').toString(),
      itemStatus: (map['item_status'] ?? map['status'] ?? '').toString(),
      isEmergency: isEmergency,
      remarks: (map['remarks'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'generator_id': generatorId,
      'capacity_kva': capacityKva,
      'start_dt': startDt,
      'end_dt': endDt,
      'item_status': itemStatus,
      'is_emergency': isEmergency,
      'remarks': remarks,
    };
  }
}

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
  final List<BookingItem> items;

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
    this.items = const [],
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
    this.items = const [],
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
    List<BookingItem>? items,
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
      items: items ?? this.items,
    );
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    // Parse parent dates first to use as fallbacks for items
    final startDate = _parseDate(
      map['start_date'] ?? map['startDate'] ?? map['date'] ?? map['created_at'],
    );
    final endDate = _parseDate(
      map['end_date'] ?? map['endDate'] ?? map['date'] ?? map['created_at'],
      fallback: startDate,
    );

    List<String> generators = [];
    double totalCapacity = 0.0;
    List<BookingItem> itemsList = [];
    
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
          final parsedItem = BookingItem.fromMap(item);
          final finalStartDt = (parsedItem.startDt.isEmpty || parsedItem.startDt == 'null')
              ? DateFormat('yyyy-MM-dd').format(startDate)
              : parsedItem.startDt;
          
          itemsList.add(BookingItem(
            generatorId: parsedItem.generatorId,
            capacityKva: parsedItem.capacityKva,
            startDt: finalStartDt,
            endDt: parsedItem.endDt,
            itemStatus: parsedItem.itemStatus,
            isEmergency: parsedItem.isEmergency,
            remarks: parsedItem.remarks,
          ));
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
      items: itemsList,
    );
  }

  Map<String, dynamic> toMap() {
    // Build items array for the API.
    // When creating a booking (items is empty), construct from generators + date.
    List<Map<String, dynamic>> apiItems;
    if (items.isNotEmpty) {
      apiItems = items.map((i) => i.toMap()).toList();
    } else {
      // Construct items from generators list (used when creating bookings)
      final capacityNum = int.tryParse(capacity.replaceAll(RegExp(r'[^0-9]'), ''));
      apiItems = generators
          .where((g) => g.isNotEmpty && g != 'N/A')
          .map((genId) => {
                'generator_id': genId,
                if (capacityNum != null) 'capacity_kva': capacityNum,
                'date': startDate.toIso8601String().split('T')[0],
                'remarks': notes,
              })
          .toList();
    }

    return {
      'vendor_id': vendorId,
      'items': apiItems,
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

  List<Map<String, String>> parseGeneratorItems() {
    return generators.map((genId) {
      final match = RegExp(r'(\d+)kva', caseSensitive: false).firstMatch(genId);
      String capacityVal = match != null ? '${match.group(1)} kVA' : 'N/A';
      if (capacityVal == 'N/A' && generators.length == 1) {
        capacityVal = capacity;
      }
      return {'id': genId, 'capacity': capacityVal};
    }).toList();
  }

  String formatBookingDate() {
    return DateFormat('yyyy-MM-dd').format(startDate);
  }

  Map<String, List<BookingItem>> groupItemsByDate() {
    if (items.isEmpty) {
      final dateKey = DateFormat('yyyy-MM-dd').format(startDate);
      final List<BookingItem> syntheticItems = generators.map((genId) {
        final match = RegExp(r'(\d+)kva', caseSensitive: false).firstMatch(genId);
        int? cap;
        if (match != null) {
          cap = int.tryParse(match.group(1)!);
        }
        final isEmergency = genId.toUpperCase().contains('EMERGENCY') || genId.toUpperCase().contains('HA');
        return BookingItem(
          generatorId: genId,
          capacityKva: cap,
          startDt: dateKey,
          itemStatus: status,
          isEmergency: isEmergency,
          remarks: notes,
        );
      }).toList();
      return {dateKey: syntheticItems};
    }

    final grouped = <String, List<BookingItem>>{};
    for (final item in items) {
      if (item.startDt.isEmpty) continue;
      final dateKey = item.startDt.split(' ')[0];
      grouped.putIfAbsent(dateKey, () => []).add(item);
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
  }
}
