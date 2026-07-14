import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ledger/core/providers/booking_provider.dart';
import 'package:ledger/core/providers/generator_provider.dart';
import 'package:ledger/core/providers/vendor_provider.dart';
import 'package:ledger/data/mock/mock_bookings.dart';
import 'package:ledger/data/mock/mock_generators.dart';
import 'package:ledger/data/mock/mock_vendors.dart';
import 'package:ledger/data/repositories/booking_repository.dart';
import 'package:ledger/data/repositories/generator_repository.dart';
import 'package:ledger/data/repositories/vendor_repository.dart';
import 'package:ledger/features/bookings/widgets/edit_booking_modal.dart';
import 'package:ledger/shared/models/booking.dart';
import 'package:ledger/shared/models/calendar_event.dart';
import 'package:ledger/shared/widgets/assignment_mode_toggle.dart';
import 'package:ledger/shared/widgets/inline_calendar.dart';

void main() {
  final testBooking = Booking(
    id: 'BK-test',
    vendorId: 'vendor_1',
    vendorName: 'Mock Vendor 1',
    generatorId: 'G1',
    capacity: '50 kVA',
    date: DateTime(2026, 4, 19),
    status: 'confirmed',
    notes: 'Initial notes',
  );

  testWidgets('EditBookingModal renders successfully with prefilled values', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _providerOverrides(),
        child: MaterialApp(
          home: Scaffold(
            body: EditBookingModal(
              booking: testBooking,
              onClose: _dummyClose,
              onSave: _dummySave,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Redesigned header labels
    expect(find.text('Edit Booking'), findsOneWidget);
    expect(find.text('VENDOR'), findsOneWidget);
    expect(find.text('GENERATOR ASSIGNMENT'), findsOneWidget);
    expect(find.text('BOOKING DATES'), findsOneWidget);
    expect(find.text('OPTIONAL NOTES'), findsOneWidget);

    // Verify vendor selection dropdown is present and disabled
    final dropdowns = find.byType(DropdownButtonFormField<String>);
    expect(dropdowns, findsNWidgets(2)); // VENDOR and GENERATOR dropdowns

    // Verify AssignmentModeToggle and InlineCalendar presence
    expect(find.byType(AssignmentModeToggle), findsOneWidget);
    expect(find.byType(InlineCalendar), findsOneWidget);

    // Verify date chip showing pre-filled date
    expect(find.byType(Chip), findsOneWidget);
    expect(find.text(DateFormat('MMM dd, yyyy').format(testBooking.date)), findsOneWidget);
  });

  testWidgets('EditBookingModal toggles generator assignment mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _providerOverrides(),
        child: MaterialApp(
          home: Scaffold(
            body: EditBookingModal(
              booking: testBooking,
              onClose: _dummyClose,
              onSave: _dummySave,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Mode is initially 'id' (from widget state _assignmentMode initialization)
    expect(find.text('GENERATOR'), findsOneWidget);

    // Toggle mode using AssignmentModeToggle switch
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // Mode is now 'capacity' -> shows 'CAPACITY (kVA)' chips and hides 'GENERATOR' dropdown
    expect(find.text('GENERATOR'), findsNothing);
    expect(find.text('CAPACITY (kVA)'), findsOneWidget);
  });

  testWidgets('EditBookingModal allows removing and adding dates', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _providerOverrides(),
        child: MaterialApp(
          home: Scaffold(
            body: EditBookingModal(
              booking: testBooking,
              onClose: _dummyClose,
              onSave: _dummySave,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final initialChipText = DateFormat('MMM dd, yyyy').format(testBooking.date);
    expect(find.text(initialChipText), findsOneWidget);

    // Tap on delete icon of the date chip
    final deleteFinder = find.descendant(
      of: find.byType(Chip),
      matching: find.byIcon(Icons.close),
    );
    expect(deleteFinder, findsOneWidget);
    await tester.ensureVisible(deleteFinder);
    await tester.tap(deleteFinder);
    await tester.pumpAndSettle();

    // Chip should be removed
    expect(find.text(initialChipText), findsNothing);

    // Save button should trigger validation error for empty dates
    final saveButton = find.text('SAVE');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(find.text('Please select at least one date'), findsOneWidget);
  });
}

void _dummyClose() {}
void _dummySave(_) {}

List<Override> _providerOverrides() {
  return [
    bookingRepositoryProvider.overrideWithValue(_FakeBookingRepository()),
    vendorRepositoryProvider.overrideWithValue(_FakeVendorRepository()),
    generatorRepositoryProvider.overrideWithValue(_FakeGeneratorRepository()),
  ];
}

class _FakeBookingRepository extends BookingRepository {
  @override
  Future<List<MockBooking>> getBookings({
    DateTime? startDate,
    DateTime? endDate,
    String? vendorId,
    String? status,
  }) async {
    return List.of(mockBookings);
  }

  @override
  Future<Map<String, List<Booking>>> getAllVendorBookings() async {
    final result = <String, List<Booking>>{};
    for (final booking in mockBookings) {
      result.putIfAbsent(booking.vendorId, () => []).add(booking);
    }
    return result;
  }

  @override
  Future<List<CalendarEvent>> getCalendarEvents() async {
    return [
      CalendarEvent(date: '2026-04-19', count: 1, title: '1 booking(s)'),
      CalendarEvent(date: '2026-04-20', count: 1, title: '1 booking(s)'),
      CalendarEvent(date: '2026-04-21', count: 1, title: '1 booking(s)'),
      CalendarEvent(date: '2026-05-01', count: 1, title: '1 booking(s)'),
    ];
  }

  @override
  Future<List<Booking>> getCalendarDayBookings(String date) async {
    return mockBookings.where((b) {
      final bDate = b.startDate.toIso8601String().split('T')[0];
      return bDate == date;
    }).toList();
  }
}

class _FakeVendorRepository extends VendorRepository {
  @override
  Future<List<MockVendor>> getVendors() async => List.of(mockVendors);
}

class _FakeGeneratorRepository extends GeneratorRepository {
  @override
  Future<List<MockGenerator>> getGenerators({String? inventoryGroup}) async {
    return List.of(mockGenerators);
  }
}
