import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:ledger/features/bookings/modals/add_booking_modal.dart';
import 'package:ledger/shared/models/booking.dart';
import 'package:ledger/shared/models/vendor.dart';
import 'package:ledger/shared/widgets/autocomplete_field.dart';
import 'package:ledger/shared/models/calendar_event.dart';
import 'package:ledger/shared/widgets/confirmation_dialog.dart';

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

  testWidgets('EditBookingModal renders successfully with generator list and FAB', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _providerOverrides(testBooking),
        child: MaterialApp(
          home: Scaffold(
            body: EditBookingModal(
              booking: testBooking,
              onClose: _dummyClose,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Header Section
    expect(find.text('EDIT BOOKING'), findsOneWidget);
    expect(find.text('Mock Vendor 1'), findsOneWidget);
    expect(find.text('April 19, 2026'), findsOneWidget);

    // Verify Section Header and Search Input
    expect(find.text('Edit Assigned Generators'), findsOneWidget);
    final searchField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Search assigned assets...');
    expect(searchField, findsOneWidget);
    expect(find.text('Search assigned assets...'), findsOneWidget);

    // Verify Generator Card displays
    expect(find.text('G1'), findsOneWidget);
    expect(find.text('50 kVA'), findsOneWidget);
    expect(find.text('2026-04-19'), findsOneWidget);
    expect(find.text('Initial notes'), findsOneWidget);

    // Verify FAB is rendered
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('Search bar filters generator cards list by ID', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _providerOverrides(testBooking),
        child: MaterialApp(
          home: Scaffold(
            body: EditBookingModal(
              booking: testBooking,
              onClose: _dummyClose,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initially G1 is visible
    expect(find.text('G1'), findsOneWidget);

    final searchField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Search assigned assets...');

    // Type non-matching string into search field
    await tester.enterText(searchField, 'GEN-XYZ');
    await tester.pumpAndSettle();

    // G1 card should be filtered out
    expect(find.text('G1'), findsNothing);
    expect(find.text('No assigned assets found.'), findsOneWidget);

    // Type matching G1
    await tester.enterText(searchField, 'g1');
    await tester.pumpAndSettle();

    // G1 card should be visible again
    expect(find.text('G1'), findsOneWidget);
  });

  testWidgets('Swipe-to-delete shows confirmation dialog and cancels or deletes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _providerOverrides(testBooking),
        child: MaterialApp(
          home: Scaffold(
            body: EditBookingModal(
              booking: testBooking,
              onClose: _dummyClose,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Swipe the card left
    await tester.drag(find.text('G1'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    // Verify ConfirmationDialog is shown
    expect(find.byType(ConfirmationDialog), findsOneWidget);
    expect(find.text('Delete Assignment'), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();

    // Card should still be present
    expect(find.text('G1'), findsOneWidget);

    // Swipe card again and tap Delete
    await tester.drag(find.text('G1'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('DELETE'));
    await tester.pumpAndSettle();

    // Card should be deleted/removed
    expect(find.text('G1'), findsNothing);
  });

  testWidgets('FAB (+) opens AddBookingModal with locked vendor', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _providerOverrides(testBooking),
        child: MaterialApp(
          home: Scaffold(
            body: EditBookingModal(
              booking: testBooking,
              onClose: _dummyClose,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify AddBookingModal is not shown initially
    expect(find.byType(AddBookingModal), findsNothing);

    // Tap FAB
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Verify AddBookingModal is now visible overlaying the edit view
    expect(find.byType(AddBookingModal), findsOneWidget);

    // Verify AutocompleteField<Vendor> has enabled set to false
    final autocompleteFinder = find.byType(AutocompleteField<Vendor>);
    expect(autocompleteFinder, findsOneWidget);
    final autocomplete = tester.widget<AutocompleteField<Vendor>>(autocompleteFinder);
    expect(autocomplete.enabled, isFalse);
  });
}

void _dummyClose() {}

List<Override> _providerOverrides(Booking testBooking) {
  return [
    bookingRepositoryProvider.overrideWithValue(_FakeBookingRepository(testBooking)),
    vendorRepositoryProvider.overrideWithValue(_FakeVendorRepository()),
    generatorRepositoryProvider.overrideWithValue(_FakeGeneratorRepository()),
  ];
}

class _FakeBookingRepository extends BookingRepository {
  final Booking testBooking;

  _FakeBookingRepository(this.testBooking);

  @override
  Future<List<Booking>> getBookings({
    DateTime? startDate,
    DateTime? endDate,
    String? vendorId,
    String? status,
  }) async {
    return [testBooking, ...mockBookings];
  }

  @override
  Future<Map<String, List<Booking>>> getAllVendorBookings() async {
    final result = <String, List<Booking>>{};
    result.putIfAbsent(testBooking.vendorId, () => []).add(testBooking);
    for (final booking in mockBookings) {
      result.putIfAbsent(booking.vendorId, () => []).add(booking);
    }
    return result;
  }

  @override
  Future<List<CalendarEvent>> getCalendarEvents() async {
    return [
      CalendarEvent(date: '2026-04-19', count: 1, title: '1 booking(s)'),
    ];
  }

  @override
  Future<List<Booking>> getCalendarDayBookings(String date) async {
    final list = [testBooking, ...mockBookings];
    return list.where((b) {
      final bDate = b.startDate.toIso8601String().split('T')[0];
      return bDate == date;
    }).toList();
  }

  @override
  Future<void> deleteBooking(String id) async {
    // Stub
  }

  @override
  Future<Booking> updateBooking(String id, Booking booking) async {
    return booking;
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
