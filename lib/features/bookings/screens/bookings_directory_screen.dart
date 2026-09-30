import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../../../shared/widgets/skeleton_loading.dart';
import '../widgets/vendor_booking_group.dart';
import '../modals/add_booking_modal.dart';
import '../widgets/edit_booking_modal.dart';
import '../modals/booking_detail_modal.dart';
import '../providers/bookings_provider.dart';
import '../../vendors/providers/vendors_provider.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/routing/app_router.dart';

/// Directory screen listing bookings grouped by vendor.
class BookingsDirectoryScreen extends ConsumerStatefulWidget {
  const BookingsDirectoryScreen({super.key});

  @override
  ConsumerState<BookingsDirectoryScreen> createState() =>
      _BookingsDirectoryScreenState();
}

class _BookingsDirectoryScreenState
    extends ConsumerState<BookingsDirectoryScreen> with RouteAware {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showAddModal = false;
  bool _showCancelModal = false;
  MockBooking? _editingBooking;
  MockBooking? _viewingBooking;
  MockBooking? _selectedBookingForCancel;

  int _slidableResetCounter = 0;
  int? _lastIndex;

  void _closeAllSwipeRows() {
    if (mounted) {
      setState(() {
        _slidableResetCounter++;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppRouter.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didPushNext() {
    _closeAllSwipeRows();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  Widget _buildBookingContent(List<Vendor> vendors, List<MockBooking> filteredBookings) {
    final allVendorBookingsState = ref.watch(allVendorBookingsProvider);

    return allVendorBookingsState.when(
      data: (allBookingsMap) {
        final vendorWidgets = <Widget>[];

        for (final vendor in vendors) {
          final bookings = allBookingsMap[vendor.id] ?? [];
          final filtered = bookings.where((booking) {
            if (_searchQuery.isEmpty) return true;
            return booking.vendorName.toLowerCase().contains(_searchQuery) ||
                booking.vendorId.toLowerCase().contains(_searchQuery) ||
                booking.generatorId.toLowerCase().contains(_searchQuery);
          }).toList();

          if (filtered.isEmpty) continue;

          vendorWidgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: VendorBookingGroup(
                vendor: vendor,
                bookings: filtered,
                slidableResetCounter: _slidableResetCounter,
                onBookingTap: (booking) {
                  setState(() {
                    _viewingBooking = booking;
                  });
                },
                onModify: (booking) {
                  setState(() {
                    _editingBooking = booking;
                  });
                },
                onDelete: (booking) {
                  setState(() {
                    _selectedBookingForCancel = booking;
                    _showCancelModal = true;
                  });
                },
              ),
            ),
          );
        }

        if (vendorWidgets.isEmpty) {
          return Container(
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
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: vendorWidgets,
        );
      },
      loading: () => Column(
        children: List.generate(4, (index) => const Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: SkeletonCard(height: 120),
        )),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
              const SizedBox(height: 16),
              Text(
                'Failed to load bookings',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.danger),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(allVendorBookingsProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);
    final connectivity = ref.watch(connectivityProvider);
    final bookings = bookingState.valueOrNull ?? [];
    final vendors = List<Vendor>.from(ref.watch(vendorProvider).valueOrNull ?? [])
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final filteredBookings = bookings.where((booking) {
      if (_searchQuery.isEmpty) return true;
      return booking.vendorName.toLowerCase().contains(_searchQuery) ||
          booking.vendorId.toLowerCase().contains(_searchQuery) ||
          booking.generatorId.toLowerCase().contains(_searchQuery);
    }).toList();

    // Detect tab changes to close swipe actions
    try {
      final shell = StatefulNavigationShell.of(context);
      final currentIndex = shell.currentIndex;
      if (_lastIndex != null && _lastIndex != currentIndex) {
        _closeAllSwipeRows();
      }
      _lastIndex = currentIndex;
    } catch (_) {}

    return Container(
      color: AppColors.background,
      child: SlidableAutoCloseBehavior(
        child: SafeArea(
          child: Stack(
            children: [
            RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(allVendorBookingsProvider);
                await ref.read(allVendorBookingsProvider.notifier).loadBookings();
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
                      loading: () => Column(
                        children: List.generate(4, (index) => const Padding(
                          padding: EdgeInsets.only(bottom: 16.0),
                          child: SkeletonCard(height: 80),
                        )),
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
                onSave: (newBookings) async {
                  for (final booking in newBookings) {
                    await ref
                        .read(bookingProvider.notifier)
                        .addBooking(booking);
                  }
                  if (!context.mounted) return;
                  setState(() => _showAddModal = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${newBookings.length} booking(s) added successfully')),
                  );
                },
              ),

            // Detail Booking Modal
            if (_viewingBooking != null)
              BookingDetailModal(
                booking: _viewingBooking!,
                onClose: () => setState(() => _viewingBooking = null),
                onEdit: () {
                  final b = _viewingBooking;
                  setState(() {
                    _viewingBooking = null;
                    _editingBooking = b;
                  });
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

            // Cancel Booking Dialog
            if (_showCancelModal && _selectedBookingForCancel != null)
              ConfirmationDialog(
                title: 'CANCEL BOOKING',
                message:
                    'Cancel this booking for "${_selectedBookingForCancel!.vendorName}"? The vendor will be notified.',
                confirmText: 'CANCEL BOOKING',
                isDestructive: true,
                onCancel: () => setState(() {
                  _showCancelModal = false;
                  _selectedBookingForCancel = null;
                }),
                onConfirm: () {
                  final bookingId = _selectedBookingForCancel!.id;
                  ref.read(bookingProvider.notifier).deleteBooking(bookingId);
                  setState(() {
                    _showCancelModal = false;
                    _selectedBookingForCancel = null;
                  });
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Booking cancelled'),
                      action: SnackBarAction(
                        label: 'UNDO',
                        onPressed: () {
                          ref.read(bookingProvider.notifier).undoDeleteBooking();
                        },
                      ),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      ),
    );
  }
}
