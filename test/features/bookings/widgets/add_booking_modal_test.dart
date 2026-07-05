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
import 'package:ledger/features/bookings/modals/add_booking_modal.dart';
import 'package:ledger/shared/widgets/vendor_search_input.dart';
import 'package:ledger/shared/widgets/assignment_mode_toggle.dart';
import 'package:ledger/shared/widgets/inline_calendar.dart';

void main() {
  testWidgets('AddBookingModal renders successfully and shows new elements', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _providerOverrides(),
        child: const MaterialApp(
          home: Scaffold(
            body: AddBookingModal(onClose: _dummyClose, onSave: _dummySave),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify redesigned header labels
    expect(find.text('BOOKINGS'), findsOneWidget);
    expect(find.text('EXISTING BOOKINGS'), findsOneWidget);
    expect(
      find.text('Create Booking'),
      findsNWidgets(2),
    ); // Title and save button

    // Verify subcomponent labels
    expect(find.text('Vendor *'), findsOneWidget);
    expect(find.text('GENERATOR ASSIGNMENT'), findsOneWidget);
    expect(find.text('BOOKING DATES'), findsOneWidget);
    expect(find.text('Optional Notes'), findsOneWidget);

    // Verify presence of child widgets
    expect(find.byType(VendorSearchInput), findsOneWidget);
    expect(find.byType(AssignmentModeToggle), findsOneWidget);
    expect(find.byType(InlineCalendar), findsOneWidget);

    // Verify presence of "EXISTING BOOKINGS" info card fallback
    expect(
      find.text(
        'No vendor selected. Select a vendor to view existing bookings.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'AddBookingModal toggles generator assignment view conditional fields',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _providerOverrides(),
          child: const MaterialApp(
            home: Scaffold(
              body: AddBookingModal(onClose: _dummyClose, onSave: _dummySave),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially mode is 'id' -> shows 'GENERATOR' dropdown field
      expect(find.text('GENERATOR'), findsOneWidget);
      expect(find.text('Capacity (kVA)'), findsNothing);

      // Tap on the Capacity toggle button
      final capacityToggle = find.text('Assign by Capacity (Auto-assign)');
      expect(capacityToggle, findsOneWidget);
      await tester.tap(capacityToggle);
      await tester.pump();

      // Mode is now 'capacity' -> shows 'Capacity (kVA)' chips and hides 'GENERATOR' dropdown
      expect(find.text('Capacity (kVA)'), findsOneWidget);
      expect(find.text('GENERATOR'), findsNothing);
    },
  );
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
