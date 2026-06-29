import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/mock/mock_bookings.dart';
import '../../../data/mock/mock_vendors.dart';
import '../../../shared/widgets/floating_search_fab.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/side_navigation_drawer.dart';
import '../widgets/vendor_booking_group.dart';
import '../widgets/add_booking_modal.dart';
import '../widgets/edit_booking_modal.dart';

/// Directory screen listing bookings grouped by vendor.
class BookingsDirectoryScreen extends StatefulWidget {
  const BookingsDirectoryScreen({super.key});

  @override
  State<BookingsDirectoryScreen> createState() => _BookingsDirectoryScreenState();
}

class _BookingsDirectoryScreenState extends State<BookingsDirectoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  late final List<MockBooking> _bookings;
  bool _showAddModal = false;
  MockBooking? _editingBooking;

  @override
  void initState() {
    super.initState();
    _bookings = List.from(mockBookings);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter bookings based on search query
    final filteredBookings = _bookings.where((booking) {
      if (_searchQuery.isEmpty) return true;
      return booking.vendorName.toLowerCase().contains(_searchQuery) ||
          booking.vendorId.toLowerCase().contains(_searchQuery) ||
          booking.generatorId.toLowerCase().contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'BOOKINGS',
          style: AppTypography.headlineSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: SideNavigationDrawer(
        currentRoute: '/bookings',
        onNavigate: (routePath) {
          context.go(routePath);
        },
        userName: 'Abhishek Sharma',
        userRole: 'Fleet Manager',
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.mobileGutter,
                AppDimensions.mobileGutter,
                AppDimensions.mobileGutter,
                100, // Bottom margin to avoid overlap with FloatingSearchFAB
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Page Header
                  const SectionHeader(
                    category: 'DIRECTORY',
                    title: 'Bookings by Vendor',
                    description: 'Review active reservations and manage vendor schedules.',
                  ),
                  const SizedBox(height: 24),

                  // Vendor Groups List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: mockVendors.length,
                    separatorBuilder: (context, index) {
                      final vendor = mockVendors[index];
                      final vendorBookings = filteredBookings
                          .where((b) => b.vendorId == vendor.id)
                          .toList();
                      return vendorBookings.isEmpty ? const SizedBox.shrink() : const SizedBox(height: 20);
                    },
                    itemBuilder: (context, index) {
                      final vendor = mockVendors[index];
                      final vendorBookings = filteredBookings
                          .where((b) => b.vendorId == vendor.id)
                          .toList();

                      if (vendorBookings.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return VendorBookingGroup(
                        vendor: vendor,
                        bookings: vendorBookings,
                        onBookingTap: (booking) {
                          setState(() {
                            _editingBooking = booking;
                          });
                        },
                      );
                    },
                  ),

                  // Empty State
                  if (filteredBookings.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppDimensions.functionalRadius),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Center(
                        child: Text(
                          'No matching bookings found.',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Floating Search Action Zone
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FloatingSearchFAB(
                searchHint: 'Search bookings...',
                controller: _searchController,
                fabIcon: Icons.add,
                onFABPressed: () {
                  setState(() {
                    _showAddModal = true;
                  });
                },
              ),
            ),

            // Add Booking Modal
            if (_showAddModal)
              AddBookingModal(
                onClose: () => setState(() => _showAddModal = false),
                onSave: (newBooking) {
                  setState(() {
                    _bookings.insert(0, newBooking);
                    _showAddModal = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking added successfully')),
                  );
                },
              ),

            // Edit Booking Modal
            if (_editingBooking != null)
              EditBookingModal(
                booking: _editingBooking!,
                onClose: () => setState(() => _editingBooking = null),
                onSave: (updatedBooking) {
                  setState(() {
                    final index = _bookings.indexWhere((b) => b.id == updatedBooking.id);
                    if (index != -1) {
                      _bookings[index] = updatedBooking;
                    }
                    _editingBooking = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking updated successfully')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
