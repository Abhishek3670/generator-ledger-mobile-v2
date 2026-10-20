import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/connectivity_service.dart';
import '../../../shared/models/vendor.dart';
import '../../../shared/models/booking.dart';
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
  DateTime? _selectedMonth;
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
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
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

  bool _matchesMonth(Booking booking) {
    if (_selectedMonth == null) return true;

    final targetYear = _selectedMonth!.year;
    final targetMonth = _selectedMonth!.month;

    if (booking.items.isNotEmpty) {
      return booking.items.any((item) {
        final itemDate = DateTime.tryParse(item.date);
        if (itemDate != null) {
          return itemDate.year == targetYear && itemDate.month == targetMonth;
        }
        return false;
      });
    }

    final start = booking.startDate;
    final end = booking.endDate;
    final monthStart = DateTime(targetYear, targetMonth, 1);
    final monthEnd = DateTime(targetYear, targetMonth + 1, 0, 23, 59, 59, 999);

    return !start.isAfter(monthEnd) && !end.isBefore(monthStart);
  }

  Booking _filterBookingItemsToSelectedMonth(Booking booking) {
    if (_selectedMonth == null || booking.items.isEmpty) return booking;

    final targetYear = _selectedMonth!.year;
    final targetMonth = _selectedMonth!.month;

    final matchingItems = booking.items.where((item) {
      final itemDate = DateTime.tryParse(item.date);
      if (itemDate != null) {
        return itemDate.year == targetYear && itemDate.month == targetMonth;
      }
      return false;
    }).toList();

    if (matchingItems.isEmpty) return booking;
    return booking.copyWith(items: matchingItems);
  }

  Widget _buildMonthFilter() {
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth != null &&
        _selectedMonth!.year == now.year &&
        _selectedMonth!.month == now.month;
    final isAllSelected = _selectedMonth == null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.modalRadius),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                key: const ValueKey('btn_prev_month'),
                tooltip: 'Previous month',
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: () {
                  setState(() {
                    final base = _selectedMonth ?? DateTime.now();
                    _selectedMonth = DateTime(base.year, base.month - 1);
                  });
                },
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
                  shape: const CircleBorder(
                    side: BorderSide(color: AppColors.border, width: 1),
                  ),
                  padding: const EdgeInsets.all(4),
                  minimumSize: const Size(34, 34),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: InkWell(
                  key: const ValueKey('btn_pick_month'),
                  onTap: () async {
                    final initial = _selectedMonth ?? DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                      helpText: 'SELECT MONTH',
                      initialDatePickerMode: DatePickerMode.year,
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedMonth = DateTime(picked.year, picked.month);
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              isAllSelected
                                  ? 'ALL MONTHS'
                                  : DateFormat('MMMM yyyy')
                                      .format(_selectedMonth!)
                                      .toUpperCase(),
                              style: AppTypography.title.copyWith(
                                fontSize: 16,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_drop_down,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                key: const ValueKey('btn_next_month'),
                tooltip: 'Next month',
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: () {
                  setState(() {
                    final base = _selectedMonth ?? DateTime.now();
                    _selectedMonth = DateTime(base.year, base.month + 1);
                  });
                },
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
                  shape: const CircleBorder(
                    side: BorderSide(color: AppColors.border, width: 1),
                  ),
                  padding: const EdgeInsets.all(4),
                  minimumSize: const Size(34, 34),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                key: const ValueKey('btn_toggle_all_months'),
                onTap: () {
                  setState(() {
                    if (isAllSelected) {
                      _selectedMonth = DateTime(now.year, now.month);
                    } else {
                      _selectedMonth = null;
                    }
                  });
                },
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAllSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isAllSelected ? AppColors.primary : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'ALL',
                    style: AppTypography.labelCaps.copyWith(
                      fontSize: 11,
                      color: isAllSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isAllSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!isCurrentMonth && !isAllSelected)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GestureDetector(
                key: const ValueKey('btn_reset_current_month'),
                onTap: () {
                  setState(() {
                    _selectedMonth = DateTime(now.year, now.month);
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.replay, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'RESET TO CURRENT MONTH',
                      style: AppTypography.labelCaps.copyWith(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingContent(
    List<Vendor> vendors,
    Map<String, List<Booking>> allBookingsMap,
  ) {
    final vendorWidgets = <Widget>[];

    for (final vendor in vendors) {
      final bookings = allBookingsMap[vendor.id] ?? [];
      final filtered = <Booking>[];
      for (final booking in bookings) {
        if (!_matchesMonth(booking)) continue;
        final displayBooking = _filterBookingItemsToSelectedMonth(booking);
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery;
          final matchesVendorName =
              displayBooking.vendorName.toLowerCase().contains(query);
          final matchesVendorId =
              displayBooking.vendorId.toLowerCase().contains(query);
          final matchesGenId =
              displayBooking.generatorId.toLowerCase().contains(query);
          final matchesBookingId =
              displayBooking.bookingId.toLowerCase().contains(query);
          final matchesAnyGen = displayBooking.generators
              .any((g) => g.toLowerCase().contains(query));
          final matchesRemarks = displayBooking.notes
                  .toLowerCase()
                  .contains(query) ||
              displayBooking.items
                  .any((i) => i.remarks.toLowerCase().contains(query));

          if (!matchesVendorName &&
              !matchesVendorId &&
              !matchesGenId &&
              !matchesBookingId &&
              !matchesAnyGen &&
              !matchesRemarks) {
            continue;
          }
        }
        filtered.add(displayBooking);
      }

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
            _searchQuery.isNotEmpty
                ? 'No matching bookings found.'
                : (_selectedMonth != null
                    ? 'No bookings found for ${DateFormat('MMMM yyyy').format(_selectedMonth!)}.'
                    : 'No bookings found.'),
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
  }

  @override
  Widget build(BuildContext context) {
    final allVendorBookingsState = ref.watch(allVendorBookingsProvider);
    final connectivity = ref.watch(connectivityProvider);
    final vendors = List<Vendor>.from(ref.watch(vendorProvider).valueOrNull ?? [])
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

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
                    const SizedBox(height: 16),
                    _buildMonthFilter(),
                    const SizedBox(height: 20),

                    allVendorBookingsState.when(
                      data: (allBookingsMap) =>
                          _buildBookingContent(vendors, allBookingsMap),
                      loading: () => Column(
                        children: List.generate(4, (index) => const Padding(
                          padding: EdgeInsets.only(bottom: 16.0),
                          child: SkeletonCard(height: 120),
                        )),
                      ),
                      error: (error, stack) => ErrorScreen(
                        message: error.toString(),
                        onRetry: () =>
                            ref.read(allVendorBookingsProvider.notifier).loadBookings(),
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
