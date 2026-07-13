class CalendarEvent {
  final String date;    // "2026-07-13"
  final int count;      // number of bookings
  final String title;   // "3 booking(s)"

  CalendarEvent({required this.date, required this.count, required this.title});

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    final title = map['title']?.toString() ?? '';
    final count = int.tryParse(title.split(' ').first) ?? 0;
    return CalendarEvent(
      date: map['start']?.toString() ?? map['extendedProps']?['date']?.toString() ?? '',
      count: count,
      title: title,
    );
  }
}
