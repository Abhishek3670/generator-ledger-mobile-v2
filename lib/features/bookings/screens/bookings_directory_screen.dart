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
  DateTime? _rangeStartMonth;
  DateTime? _rangeEndMonth;

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
    _rangeStartMonth = DateTime(now.year, now.month);
    _rangeEndMonth = DateTime(now.year, now.month);
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

  String _formatRangeLabel(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
      return DateFormat('MMMM yyyy').format(start).toUpperCase();
    }
    if (start.year == end.year) {
      final startStr = DateFormat('MMM').format(start);
      final endStr = DateFormat('MMM yyyy').format(end);
      return '$startStr – $endStr'.toUpperCase();
    }
    final startStr = DateFormat('MMM yyyy').format(start);
    final endStr = DateFormat('MMM yyyy').format(end);
    return '$startStr – $endStr'.toUpperCase();
  }

  bool _matchesMonth(Booking booking) {
    if (_rangeStartMonth == null || _rangeEndMonth == null) return true;

    final rangeStart =
        DateTime(_rangeStartMonth!.year, _rangeStartMonth!.month, 1, 0, 0, 0);
    final rangeEnd = DateTime(
        _rangeEndMonth!.year, _rangeEndMonth!.month + 1, 0, 23, 59, 59, 999);

    if (booking.items.isNotEmpty) {
      return booking.items.any((item) {
        final itemDate = DateTime.tryParse(item.date);
        if (itemDate != null) {
          return !itemDate.isBefore(rangeStart) && !itemDate.isAfter(rangeEnd);
        }
        return false;
      });
    }

    final start = booking.startDate;
    final end = booking.endDate;
    return !start.isAfter(rangeEnd) && !end.isBefore(rangeStart);
  }

  Booking _filterBookingItemsToSelectedMonth(Booking booking) {
    if (_rangeStartMonth == null ||
        _rangeEndMonth == null ||
        booking.items.isEmpty) {
      return booking;
    }

    final rangeStart =
        DateTime(_rangeStartMonth!.year, _rangeStartMonth!.month, 1, 0, 0, 0);
    final rangeEnd = DateTime(
        _rangeEndMonth!.year, _rangeEndMonth!.month + 1, 0, 23, 59, 59, 999);

    final matchingItems = booking.items.where((item) {
      final itemDate = DateTime.tryParse(item.date);
      if (itemDate != null) {
        return !itemDate.isBefore(rangeStart) && !itemDate.isAfter(rangeEnd);
      }
      return false;
    }).toList();

    if (matchingItems.isEmpty) return booking;
    return booking.copyWith(items: matchingItems);
  }

  Widget _buildMonthFilter() {
    final now = DateTime.now();
    final isAllSelected = _rangeStartMonth == null || _rangeEndMonth == null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.modalRadius),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('btn_prev_month'),
            tooltip: 'Previous month',
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: () {
              setState(() {
                final start = _rangeStartMonth ?? now;
                final end = _rangeEndMonth ?? now;
                _rangeStartMonth = DateTime(start.year, start.month - 1);
                _rangeEndMonth = DateTime(end.year, end.month - 1);
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
                final currentStart =
                    _rangeStartMonth ?? DateTime(now.year, now.month);
                final currentEnd =
                    _rangeEndMonth ?? DateTime(now.year, now.month);
                final picked = await showDialog<DateTimeRange>(
                  context: context,
                  builder: (context) => _MonthYearRangePickerDialog(
                    initialRange:
                        DateTimeRange(start: currentStart, end: currentEnd),
                  ),
                );
                if (picked != null) {
                  setState(() {
                    _rangeStartMonth =
                        DateTime(picked.start.year, picked.start.month);
                    _rangeEndMonth =
                        DateTime(picked.end.year, picked.end.month);
                  });
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
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
                              : _formatRangeLabel(
                                  _rangeStartMonth!,
                                  _rangeEndMonth!,
                                ),
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
                final start = _rangeStartMonth ?? now;
                final end = _rangeEndMonth ?? now;
                _rangeStartMonth = DateTime(start.year, start.month + 1);
                _rangeEndMonth = DateTime(end.year, end.month + 1);
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
                  _rangeStartMonth = DateTime(now.year, now.month);
                  _rangeEndMonth = DateTime(now.year, now.month);
                } else {
                  _rangeStartMonth = null;
                  _rangeEndMonth = null;
                }
              });
            },
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isAllSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color:
                      isAllSelected ? AppColors.primary : AppColors.border,
                  width: 1,
                ),
              ),
              child: Text(
                'ALL',
                style: AppTypography.labelCaps.copyWith(
                  fontSize: 11,
                  color:
                      isAllSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight:
                      isAllSelected ? FontWeight.bold : FontWeight.w600,
                ),
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
                : (_rangeStartMonth != null && _rangeEndMonth != null
                    ? 'No bookings found for ${_formatRangeLabel(_rangeStartMonth!, _rangeEndMonth!)}.'
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
                    SectionHeader(
                      category: 'DIRECTORY',
                      title: 'Bookings by Vendor',
                      description:
                          'Review active reservations and manage vendor schedules.',
                      action: IconButton(
                        key: const ValueKey('btn_reset_current_month'),
                        tooltip: 'Reset to current month',
                        icon: const Icon(Icons.refresh, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          shape: const CircleBorder(
                            side: BorderSide(color: AppColors.border, width: 1),
                          ),
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(36, 36),
                        ),
                        onPressed: () async {
                          final now = DateTime.now();
                          setState(() {
                            _rangeStartMonth = DateTime(now.year, now.month);
                            _rangeEndMonth = DateTime(now.year, now.month);
                          });
                          ref.invalidate(allVendorBookingsProvider);
                          await ref
                              .read(allVendorBookingsProvider.notifier)
                              .loadBookings();
                        },
                      ),
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

enum _RangeTab { from, to }

/// Modal dialog allowing the user to select a month range without date picking.
class _MonthYearRangePickerDialog extends StatefulWidget {
  final DateTimeRange initialRange;

  const _MonthYearRangePickerDialog({required this.initialRange});

  @override
  State<_MonthYearRangePickerDialog> createState() =>
      _MonthYearRangePickerDialogState();
}

class _MonthYearRangePickerDialogState
    extends State<_MonthYearRangePickerDialog> {
  late DateTime _startMonth;
  late DateTime _endMonth;
  late int _displayedYear;
  _RangeTab _activeTab = _RangeTab.from;

  static const _months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  @override
  void initState() {
    super.initState();
    _startMonth = DateTime(
      widget.initialRange.start.year,
      widget.initialRange.start.month,
    );
    _endMonth = DateTime(
      widget.initialRange.end.year,
      widget.initialRange.end.month,
    );
    _displayedYear = _startMonth.year;
  }

  void _onMonthTapped(int monthNum) {
    final tappedDate = DateTime(_displayedYear, monthNum);
    setState(() {
      if (_activeTab == _RangeTab.from) {
        _startMonth = tappedDate;
        if (_startMonth.isAfter(_endMonth)) {
          _endMonth = _startMonth;
        }
        _activeTab = _RangeTab.to;
      } else {
        _endMonth = tappedDate;
        if (_endMonth.isBefore(_startMonth)) {
          _startMonth = _endMonth;
        }
      }
    });
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Text(
          label,
          style: AppTypography.labelCaps.copyWith(
            fontSize: 10,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.structuralRadius),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Title & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SELECT MONTH RANGE',
                    style: AppTypography.labelCaps.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('btn_picker_close'),
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Presets Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPresetChip('THIS MONTH', () {
                      setState(() {
                        _startMonth = DateTime(now.year, now.month);
                        _endMonth = DateTime(now.year, now.month);
                        _displayedYear = now.year;
                        _activeTab = _RangeTab.from;
                      });
                    }),
                    const SizedBox(width: 6),
                    _buildPresetChip('NEXT 3 MONTHS', () {
                      setState(() {
                        _startMonth = DateTime(now.year, now.month);
                        _endMonth = DateTime(now.year, now.month + 2);
                        _displayedYear = now.year;
                        _activeTab = _RangeTab.to;
                      });
                    }),
                    const SizedBox(width: 6),
                    _buildPresetChip('NEXT 6 MONTHS', () {
                      setState(() {
                        _startMonth = DateTime(now.year, now.month);
                        _endMonth = DateTime(now.year, now.month + 5);
                        _displayedYear = now.year;
                        _activeTab = _RangeTab.to;
                      });
                    }),
                    const SizedBox(width: 6),
                    _buildPresetChip('FULL YEAR', () {
                      setState(() {
                        _startMonth = DateTime(_displayedYear, 1);
                        _endMonth = DateTime(_displayedYear, 12);
                        _activeTab = _RangeTab.to;
                      });
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // FROM & TO Selection Cards
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      key: const ValueKey('tab_range_from'),
                      onTap: () {
                        setState(() {
                          _activeTab = _RangeTab.from;
                          _displayedYear = _startMonth.year;
                        });
                      },
                      borderRadius:
                          BorderRadius.circular(AppDimensions.functionalRadius),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 10),
                        decoration: BoxDecoration(
                          color: _activeTab == _RangeTab.from
                              ? AppColors.surface
                              : Colors.white,
                          borderRadius: BorderRadius.circular(
                              AppDimensions.functionalRadius),
                          border: Border.all(
                            color: _activeTab == _RangeTab.from
                                ? AppColors.primary
                                : AppColors.border,
                            width: _activeTab == _RangeTab.from ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FROM',
                              style: AppTypography.labelCaps.copyWith(
                                fontSize: 10,
                                color: _activeTab == _RangeTab.from
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('MMM yyyy')
                                  .format(_startMonth)
                                  .toUpperCase(),
                              style: AppTypography.title.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      key: const ValueKey('tab_range_to'),
                      onTap: () {
                        setState(() {
                          _activeTab = _RangeTab.to;
                          _displayedYear = _endMonth.year;
                        });
                      },
                      borderRadius:
                          BorderRadius.circular(AppDimensions.functionalRadius),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 10),
                        decoration: BoxDecoration(
                          color: _activeTab == _RangeTab.to
                              ? AppColors.surface
                              : Colors.white,
                          borderRadius: BorderRadius.circular(
                              AppDimensions.functionalRadius),
                          border: Border.all(
                            color: _activeTab == _RangeTab.to
                                ? AppColors.primary
                                : AppColors.border,
                            width: _activeTab == _RangeTab.to ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TO',
                              style: AppTypography.labelCaps.copyWith(
                                fontSize: 10,
                                color: _activeTab == _RangeTab.to
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('MMM yyyy')
                                  .format(_endMonth)
                                  .toUpperCase(),
                              style: AppTypography.title.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Year Navigator: [<] 2026 [>]
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.functionalRadius),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      key: const ValueKey('btn_picker_prev_year'),
                      icon: const Icon(
                        Icons.chevron_left,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          _displayedYear--;
                        });
                      },
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                    Text(
                      '$_displayedYear',
                      style: AppTypography.title.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('btn_picker_next_year'),
                      icon: const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          _displayedYear++;
                        });
                      },
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Month Grid: 4 columns x 3 rows
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.8,
                ),
                itemBuilder: (context, index) {
                  final monthNum = index + 1;
                  final monthDate = DateTime(_displayedYear, monthNum);

                  final isStart = _startMonth.year == monthDate.year &&
                      _startMonth.month == monthDate.month;
                  final isEnd = _endMonth.year == monthDate.year &&
                      _endMonth.month == monthDate.month;
                  final isInRange = monthDate.isAfter(_startMonth) &&
                      monthDate.isBefore(_endMonth);
                  final isSelected = isStart || isEnd;
                  final isCurrentCalMonth =
                      monthDate.year == now.year && monthDate.month == now.month;

                  Color bgColor;
                  Color textColor;
                  Border? border;

                  if (isSelected) {
                    bgColor = AppColors.primary;
                    textColor = Colors.white;
                    border = Border.all(color: AppColors.primary, width: 1);
                  } else if (isInRange) {
                    bgColor = AppColors.surfaceContainer;
                    textColor = AppColors.primary;
                    border = Border.all(color: AppColors.border, width: 1);
                  } else {
                    bgColor = Colors.white;
                    textColor = isCurrentCalMonth
                        ? AppColors.primary
                        : AppColors.textPrimary;
                    border = Border.all(
                      color: isCurrentCalMonth
                          ? AppColors.primary
                          : AppColors.border,
                      width: isCurrentCalMonth ? 1.5 : 1,
                    );
                  }

                  return InkWell(
                    key: ValueKey('btn_picker_month_$monthNum'),
                    onTap: () => _onMonthTapped(monthNum),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.functionalRadius),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(
                            AppDimensions.functionalRadius),
                        border: border,
                      ),
                      child: Text(
                        _months[index],
                        style: AppTypography.labelCaps.copyWith(
                          fontSize: 11,
                          color: textColor,
                          fontWeight: isSelected || isCurrentCalMonth
                              ? FontWeight.bold
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // Action Buttons: CANCEL and APPLY RANGE
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: const ValueKey('btn_picker_cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                    child: Text(
                      'CANCEL',
                      style: AppTypography.labelCaps.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    key: const ValueKey('btn_apply_range'),
                    onPressed: () {
                      Navigator.of(context).pop(
                        DateTimeRange(start: _startMonth, end: _endMonth),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.primaryDark,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      elevation: 0,
                    ),
                    child: Text(
                      'APPLY RANGE',
                      style: AppTypography.labelCaps.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
