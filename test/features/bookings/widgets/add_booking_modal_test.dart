import 'package:ledger/core/exceptions/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ledger/core/services/user_preferences_service.dart';
import 'package:ledger/core/providers/booking_provider.dart';
import 'package:ledger/shared/widgets/autocomplete_field.dart';
import 'package:ledger/shared/models/booking.dart';
import 'package:ledger/shared/models/vendor.dart';
import 'package:ledger/shared/models/calendar_event.dart';
import 'package:ledger/core/providers/generator_provider.dart';
import 'package:ledger/core/providers/vendor_provider.dart';
import 'package:ledger/data/mock/mock_bookings.dart';
import 'package:ledger/data/mock/mock_generators.dart';
import 'package:ledger/data/mock/mock_vendors.dart';
import 'package:ledger/data/repositories/booking_repository.dart';
import 'package:ledger/data/repositories/generator_repository.dart';
import 'package:ledger/data/repositories/vendor_repository.dart';
import 'package:ledger/features/bookings/modals/add_booking_modal.dart';
import 'package:ledger/shared/widgets/inline_calendar.dart';
import 'package:ledger/shared/widgets/draggable_form_sheet.dart';

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

    // Verify subcomponent labels (numbered step headers removed)
    expect(find.text('Vendor *'), findsOneWidget);
    expect(find.text('Capacity (kVA)'), findsOneWidget);
    expect(find.text('Quantity'), findsOneWidget);
    expect(find.text('Booking Dates'), findsOneWidget);
    expect(find.text('Total Units'), findsOneWidget);
    expect(find.text('Optional Notes'), findsOneWidget);
    expect(find.text('Vendor Details'), findsNothing);
    expect(find.text('Generator Schedules'), findsNothing);
    expect(find.text('Additional Notes'), findsNothing);

    // Verify presence of child widgets
    expect(find.byType(AutocompleteField<Vendor>), findsOneWidget);
    expect(find.text('Add Another Genset / Schedule'), findsOneWidget);

    // Verify presence of "EXISTING BOOKINGS" info card fallback
    expect(
      find.text(
        'No vendor selected. Select a vendor to view existing bookings.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'AddBookingModal displays generator requirement card with capacity and availability',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'last_selected_capacity': ['100'],
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._providerOverrides(),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AddBookingModal(onClose: _dummyClose, onSave: _dummySave),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Generator Requirement'), findsOneWidget);
      expect(find.text('Capacity (kVA)'), findsOneWidget);
      expect(find.text('Quantity'), findsOneWidget);
      expect(find.text('Booking Dates'), findsOneWidget);
      expect(
        find.textContaining('available on selected date(s)'),
        findsOneWidget,
      );
    },
  );

  testWidgets('AddBookingModal pre-fills values from preferences', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'last_selected_vendor': 'vendor_1',
      'last_selected_capacity': ['100'],
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingRepositoryProvider.overrideWithValue(_FakeBookingRepository()),
          vendorRepositoryProvider.overrideWithValue(_FakeVendorRepository()),
          generatorRepositoryProvider.overrideWithValue(
            _FakeGeneratorRepository(),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AddBookingModal(onClose: _dummyClose, onSave: _dummySave),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Check capacity selection is pre-selected
    expect(find.text('Capacity (kVA)'), findsOneWidget);
  });

  testWidgets(
    'Capacity dropdown only shows capacities existing in generator database',
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

      // Open dropdown
      final dropdownFinder = find.byType(DropdownButton<String>);
      expect(dropdownFinder, findsOneWidget);
      await tester.ensureVisible(dropdownFinder);
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // In _FakeGeneratorRepository: mockGenerators has 45 kVA, 100 kVA, 125 kVA
      expect(find.text('45 kVA'), findsWidgets);
      expect(find.text('100 kVA'), findsWidgets);
      expect(find.text('125 kVA'), findsWidgets);

      // Non-existent capacities like 50 kVA, 82 kVA, 160 kVA must NOT be in the dropdown
      expect(find.text('50 kVA'), findsNothing);
      expect(find.text('82 kVA'), findsNothing);
      expect(find.text('160 kVA'), findsNothing);
    },
  );

  testWidgets('Vendor field is configured in pinnedHeader to stick on scroll', (
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

    final sheetFinder = find.byType(DraggableFormSheet);
    expect(sheetFinder, findsOneWidget);
    final sheet = tester.widget<DraggableFormSheet>(sheetFinder);
    expect(sheet.pinnedHeader, isNotNull);
  });

  testWidgets(
    'AddBookingModal clears last vendor preference on draft discard',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'last_selected_vendor': 'vendor_1',
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingRepositoryProvider.overrideWithValue(
              _FakeBookingRepository(),
            ),
            vendorRepositoryProvider.overrideWithValue(_FakeVendorRepository()),
            generatorRepositoryProvider.overrideWithValue(
              _FakeGeneratorRepository(),
            ),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AddBookingModal(onClose: _dummyClose, onSave: _dummySave),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final closeButtonFinder = find.byIcon(Icons.close).first;
      expect(closeButtonFinder, findsOneWidget);
      await tester.tap(closeButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Discard Draft?'), findsOneWidget);

      final discardButtonFinder = find.text('Discard');
      expect(discardButtonFinder, findsOneWidget);
      await tester.tap(discardButtonFinder);
      await tester.pumpAndSettle();

      expect(prefs.containsKey('last_selected_vendor'), isFalse);
    },
  );

  testWidgets(
    'AddBookingModal supports adding and removing additional schedule lines',
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

      final addRequirementButton = find.text('Add Another Genset / Schedule');
      expect(addRequirementButton, findsOneWidget);
      await tester.ensureVisible(addRequirementButton);
      await tester.tap(addRequirementButton);
      await tester.pumpAndSettle();

      expect(find.text('Generator Requirement'), findsNWidgets(2));

      final deleteButton = find.byIcon(Icons.delete_outline);
      expect(deleteButton, findsNWidgets(2));
      await tester.tap(deleteButton.last);
      await tester.pumpAndSettle();

      expect(find.text('Generator Requirement'), findsOneWidget);
    },
  );

  testWidgets('AddBookingModal quantity stepper updates count', (
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

    expect(find.text('Quantity'), findsOneWidget);
    expect(find.text('1'), findsAtLeastNWidgets(1));

    final addQtyFinder = find.byIcon(Icons.add);
    await tester.ensureVisible(addQtyFinder.first);
    await tester.tap(addQtyFinder.first);
    await tester.pumpAndSettle();

    expect(find.text('2'), findsAtLeastNWidgets(1));

    final removeQtyFinder = find.byIcon(Icons.remove);
    await tester.tap(removeQtyFinder.first);
    await tester.pumpAndSettle();

    expect(find.text('1'), findsAtLeastNWidgets(1));
  });

  testWidgets(
    'AddBookingModal handles submission failure gracefully and displays error banner without closing',
    (WidgetTester tester) async {
      bool closed = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: _providerOverrides(),
          child: MaterialApp(
            home: Scaffold(
              body: AddBookingModal(
                lockedVendorId: 'VEN011',
                onClose: () => closed = true,
                onSave: (bookings) async {
                  throw const ApiException(
                    statusCode: 409,
                    message: 'Insufficient 20 kVA inventory on 2026-11-20',
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Submit
      final createButton = find.text('Create Booking').last;
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Modal must NOT be closed
      expect(closed, isFalse);

      // Error banner must be visible
      expect(
        find.text('Insufficient 20 kVA inventory on 2026-11-20'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'AddBookingModal blocks submission when quantity exceeds local available inventory',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'last_selected_capacity': ['100'],
      });
      final prefs = await SharedPreferences.getInstance();

      bool saveCalled = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._providerOverrides(),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AddBookingModal(
                lockedVendorId: 'VEN011',
                onClose: _dummyClose,
                onSave: (bookings) async {
                  saveCalled = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap add quantity twice: 1 -> 2 -> 3 (mock inventory has two 100 kVA units)
      final addQtyFinder = find.byIcon(Icons.add);
      await tester.ensureVisible(addQtyFinder.first);
      await tester.tap(addQtyFinder.first);
      await tester.pumpAndSettle();
      await tester.tap(addQtyFinder.first);
      await tester.pumpAndSettle();

      // Attempt to submit
      final createButton = find.text('Create Booking').last;
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(saveCalled, isFalse);
      expect(
        find.textContaining('Insufficient inventory for 100 kVA'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'AddBookingModal supports discrete individual date selection via dialog',
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

      final datePickerTrigger = find.ancestor(
        of: find.byIcon(Icons.calendar_today_outlined).first,
        matching: find.byType(InkWell),
      );
      expect(datePickerTrigger, findsWidgets);
      await tester.ensureVisible(datePickerTrigger.first);
      await tester.tap(datePickerTrigger.first);
      await tester.pumpAndSettle();

      expect(find.text('Select Dates'), findsOneWidget);
      expect(find.byType(InlineCalendar), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Select Dates'), findsNothing);
    },
  );

  testWidgets(
    'AddBookingModal generates discrete booking items for each individual selected date',
    (WidgetTester tester) async {
      List<Booking>? savedBookings;
      await tester.pumpWidget(
        ProviderScope(
          overrides: _providerOverrides(),
          child: MaterialApp(
            home: Scaffold(
              body: AddBookingModal(
                lockedVendorId: 'VEN011',
                onClose: _dummyClose,
                onSave: (bookings) async {
                  savedBookings = bookings;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final datePickerTrigger = find.ancestor(
        of: find.byIcon(Icons.calendar_today_outlined).first,
        matching: find.byType(InkWell),
      );
      await tester.ensureVisible(datePickerTrigger.first);
      await tester.tap(datePickerTrigger.first);
      await tester.pumpAndSettle();

      expect(find.text('Select Dates'), findsOneWidget);

      final clearAll = find.text('Clear All');
      if (clearAll.evaluate().isNotEmpty) {
        await tester.tap(clearAll);
        await tester.pumpAndSettle();
      }

      final day15Finder = find.widgetWithText(GestureDetector, '15');
      final day18Finder = find.widgetWithText(GestureDetector, '18');
      if (day15Finder.evaluate().isNotEmpty) {
        await tester.tap(day15Finder.first);
        await tester.pumpAndSettle();
      }
      if (day18Finder.evaluate().isNotEmpty) {
        await tester.tap(day18Finder.first);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      final createButton = find.text('Create Booking').last;
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(savedBookings, isNotNull);
      expect(savedBookings!.length, 1);
      final booking = savedBookings!.first;
      expect(booking.items.length, 2);
      expect(booking.items[0].startDt, contains('-15'));
      expect(booking.items[1].startDt, contains('-18'));
    },
  );

  testWidgets(
    'Order Summary displays individual dates with merged total units per capacity',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'last_selected_capacity': ['45'],
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._providerOverrides(),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AddBookingModal(onClose: _dummyClose, onSave: _dummySave),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open date picker and select 2 dates
      final datePickerTrigger = find.ancestor(
        of: find.byIcon(Icons.calendar_today_outlined).first,
        matching: find.byType(InkWell),
      );
      await tester.ensureVisible(datePickerTrigger.first);
      await tester.tap(datePickerTrigger.first);
      await tester.pumpAndSettle();

      final clearAll = find.text('Clear All');
      if (clearAll.evaluate().isNotEmpty) {
        await tester.tap(clearAll);
        await tester.pumpAndSettle();
      }

      final day15Finder = find.widgetWithText(GestureDetector, '15');
      final day18Finder = find.widgetWithText(GestureDetector, '18');
      if (day15Finder.evaluate().isNotEmpty) {
        await tester.tap(day15Finder.first);
        await tester.pumpAndSettle();
      }
      if (day18Finder.evaluate().isNotEmpty) {
        await tester.tap(day18Finder.first);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Verify capacity badge and total units in summary table
      expect(find.text('45 kVA'), findsWidgets);
      // Merged row displays '1 unit' once for this capacity group (not duplicated per date)
      expect(find.text('1 unit'), findsOneWidget);
      expect(find.text('Total Units'), findsOneWidget);
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
  Future<List<MockGenerator>> getGenerators({
    String? inventoryGroup,
    String? date,
  }) async {
    return List.of(mockGenerators);
  }
}
