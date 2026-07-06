import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/connectivity_service.dart';
import '../../../shared/models/vendor.dart';
import '../../../data/mock/mock_bookings.dart';
import '../../../shared/widgets/floating_search_fab.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/error_screen.dart';
import '../widgets/vendor_booking_group.dart';
import '../modals/add_booking_modal.dart';
import '../widgets/edit_booking_modal.dart';
import '../providers/bookings_provider.dart';
import '../../vendors/providers/vendors_provider.dart';

/// Directory screen listing bookings grouped by vendor.
class BookingsDirectoryScreen extends ConsumerStatefulWidget {
  const BookingsDirectoryScreen({super.key});

  @override
  ConsumerState<BookingsDirectoryScreen> createState() =>
      _BookingsDirectoryScreenState();
}

class _BookingsDirectoryScreenState
    extends ConsumerState<BookingsDirectoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showAddModal = false;
  MockBooking? _editingBooking;

  @override
  void initState() {
    super.initState();
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

  Widget _buildBookingContent(List<Vendor> vendors, List<MockBooking> filteredBookings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Vendor Groups List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: vendors.length,
          separatorBuilder: (context, index) {
            final vendor = vendors[index];
            final vendorBookings = filteredBookings
                .where((b) => b.vendorId == vendor.id)
                .toList();
            return vendorBookings.isEmpty
                ? const SizedBox.shrink()
                : const SizedBox(height: 20);
          },
          itemBuilder: (context, index) {
            final vendor = vendors[index];
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
            padding: const EdgeInsets.symmetric(
              vertical: 32,
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                AppDimensions.functionalRadius,
              ),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Center(
              child: Text(
                'No matching bookings found.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);
    final connectivity = ref.watch(connectivityProvider);
    final bookings = bookingState.valueOrNull ?? [];
    final vendors = ref.watch(vendorProvider).valueOrNull ?? [];
    final filteredBookings = bookings.where((booking) {
      if (_searchQuery.isEmpty) return true;
      return booking.vendorName.toLowerCase().contains(_searchQuery) ||
          booking.vendorId.toLowerCase().contains(_searchQuery) ||
          booking.generatorId.toLowerCase().contains(_searchQuery);
    }).toList();

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                await ref.read(bookingProvider.notifier).loadBookings();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.mobileGutter,
                  AppDimensions.mobileGutter,
                  AppDimensions.mobileGutter,
                  100, // Bottom margin to avoid overlap with FloatingSearchFAB
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (connectivity.value == ConnectivityResult.none) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.warningBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.wifi_off, color: AppColors.warningText, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Offline Mode - Viewing Cached Data',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.warningText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Page Header
                    const SectionHeader(
                      category: 'DIRECTORY',
                      title: 'Bookings by Vendor',
                      description:
                          'Review active reservations and manage vendor schedules.',
                    ),
                    const SizedBox(height: 24),

                    bookingState.when(
                      data: (_) => _buildBookingContent(vendors, filteredBookings),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, stack) => ErrorScreen(
                        message: error.toString(),
                        onRetry: () => ref.read(bookingProvider.notifier).loadBookings(),
                      ),
                    ),
                  ],
                ),
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
                onSave: (newBooking) async {
                  await ref
                      .read(bookingProvider.notifier)
                      .addBooking(newBooking);
                  if (!context.mounted) return;
                  setState(() => _showAddModal = false);
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
                onSave: (updatedBooking) async {
                  await ref
                      .read(bookingProvider.notifier)
                      .updateBooking(updatedBooking);
                  if (!context.mounted) return;
                  setState(() => _editingBooking = null);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Booking updated successfully'),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
