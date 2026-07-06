import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ledger/core/theme/app_colors.dart';
import 'package:ledger/core/theme/app_typography.dart';
import 'package:ledger/core/utils/connectivity_service.dart';
import 'package:ledger/shared/models/billing.dart';
import 'package:ledger/features/billing/providers/billing_provider.dart';
import 'package:ledger/shared/widgets/skeleton_loading.dart';

class BillingPreviewScreen extends ConsumerStatefulWidget {
  const BillingPreviewScreen({super.key});

  @override
  ConsumerState<BillingPreviewScreen> createState() =>
      _BillingPreviewScreenState();
}

class _BillingPreviewScreenState extends ConsumerState<BillingPreviewScreen> {
  final TextEditingController _dateFromController = TextEditingController(
    text: '01-04-2026',
  );
  final TextEditingController _dateToController = TextEditingController(
    text: '30-04-2026',
  );
  final TextEditingController _searchController = TextEditingController();

  final Map<String, TextEditingController> _rateControllers = {
    '20 kVA': TextEditingController(text: '0'),
    '30 kVA': TextEditingController(text: '0'),
    '45 kVA': TextEditingController(text: '0'),
    '82 kVA': TextEditingController(text: '0'),
    '100 kVA': TextEditingController(text: '0'),
  };

  // Keep track of paid amounts per vendor ID
  final Map<String, double> _paidAmounts = {};

  bool _includeGrandTotal = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final dateRange = ref.read(billingDateRangeProvider);
        _dateFromController.text = _formatDateForInput(dateRange.startDate);
        _dateToController.text = _formatDateForInput(dateRange.endDate);
      }
    });
  }

  String _formatDateForInput(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day-$month-$year';
  }

  @override
  void dispose() {
    _dateFromController.dispose();
    _dateToController.dispose();
    _searchController.dispose();
    for (var controller in _rateControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onLoadButtonPressed() {
    final dateFrom = _parseDate(_dateFromController.text);
    final dateTo = _parseDate(_dateToController.text);

    if (dateFrom == null || dateTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid dates (DD-MM-YYYY)')),
      );
      return;
    }

    ref.read(billingDateRangeProvider.notifier).state = BillingDateRange(
      startDate: dateFrom,
      endDate: dateTo,
    );
    ref.invalidate(billingProvider);
  }

  Future<void> _selectDateFrom(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _parseDate(_dateFromController.text) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _dateFromController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  Future<void> _selectDateTo(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _parseDate(_dateToController.text) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _dateToController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  DateTime? _parseDate(String input) {
    try {
      final parts = input.split('-');
      if (parts.length != 3) return null;
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      return DateTime.utc(year, month, day);
    } catch (_) {
      return null;
    }
  }

  double _getRateForCapacity(String capacity) {
    // Normalize capacity key
    final cleanCapacity = capacity.trim();
    final controller = _rateControllers[cleanCapacity];
    if (controller == null) return 0.0;
    return double.tryParse(controller.text) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 2,
    );
    final billingState = ref.watch(billingProvider);
    final connectivity = ref.watch(connectivityProvider);
    final isLoading = billingState.isLoading;

    final summaries = billingState.valueOrNull ?? <BillingSummary>[];

    // Apply search filter to the summaries (vendors) loaded in date range
    final searchQuery = _searchController.text.toLowerCase().trim();
    final summariesToDisplay = summaries.where((summary) {
      if (searchQuery.isEmpty) return true;
      return summary.vendorName.toLowerCase().contains(searchQuery) ||
          summary.vendorId.toLowerCase().contains(searchQuery);
    }).toList();

    // Sort vendor summaries by name
    final sortedSummaries = List<BillingSummary>.of(summariesToDisplay)
      ..sort((a, b) => a.vendorName.compareTo(b.vendorName));

    double grandTotal = 0.0;
    if (_includeGrandTotal && sortedSummaries.isNotEmpty) {
      for (var summary in sortedSummaries) {
        double vendorSubtotal = 0.0;
        for (var line in summary.lines) {
          final rate = _getRateForCapacity(line.booking.capacity);
          vendorSubtotal += rate;
        }
        final paidAmount = _paidAmounts[summary.vendorId] ?? 0.0;
        grandTotal += (vendorSubtotal - paidAmount);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fixed Top Header
            Container(
              color: AppColors.background,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => context.go('/dashboard'),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'BACK TO DASHBOARD',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 2.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (connectivity.value == ConnectivityResult.none) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 8, bottom: 8),
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
                    const SizedBox(height: 8),
                    Text(
                      'BILLING',
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Billing Preview',
                      style: AppTypography.displayLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Calculate vendor totals from confirmed bookings using session-only pricing.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Date Range Filter Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DATE FROM',
                                      style: AppTypography.labelCaps.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: _dateFromController,
                                      readOnly: true,
                                      onTap: () => _selectDateFrom(context),
                                      decoration: InputDecoration(
                                        suffixIcon: const Icon(
                                          Icons.calendar_today,
                                          size: 20,
                                          color: AppColors.textSecondary,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.border,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                      ),
                                      style: AppTypography.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DATE TO',
                                      style: AppTypography.labelCaps.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: _dateToController,
                                      readOnly: true,
                                      onTap: () => _selectDateTo(context),
                                      decoration: InputDecoration(
                                        suffixIcon: const Icon(
                                          Icons.calendar_today,
                                          size: 20,
                                          color: AppColors.textSecondary,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.border,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                      ),
                                      style: AppTypography.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: _includeGrandTotal,
                                    activeColor: AppColors.primary,
                                    onChanged: (val) {
                                      setState(() {
                                        _includeGrandTotal = val ?? true;
                                      });
                                    },
                                  ),
                                  Text(
                                    'INCLUDE GRAND TOTAL',
                                    style: AppTypography.labelCaps.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  OutlinedButton(
                                    onPressed: () {
                                      // Mock print action
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Print initiated'),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: AppColors.border,
                                      ),
                                      shape: const StadiumBorder(),
                                    ),
                                    child: Text(
                                      'PRINT',
                                      style: AppTypography.labelCaps.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _onLoadButtonPressed,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: const StadiumBorder(),
                                    ),
                                    child: Text(
                                      'LOAD',
                                      style: AppTypography.labelCaps.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Price Per Capacity Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PRICE PER CAPACITY',
                            style: AppTypography.labelCaps.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Rates are temporary and reset on refresh or navigation.',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 600;
                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: _rateControllers.entries.map((entry) {
                                  return SizedBox(
                                    width: isWide
                                        ? (constraints.maxWidth - 48) / 5
                                        : (constraints.maxWidth - 12) / 2,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry.key.toUpperCase(),
                                            style: AppTypography.labelCaps
                                                .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 10,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            height: 36,
                                            child: TextField(
                                              controller: entry.value,
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (val) {
                                                setState(
                                                  () {},
                                                ); // trigger rebuild to recalculate totals
                                              },
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                              ),
                                              style: AppTypography.bodySmall,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Billing Data Section Title & Stats
                    if (billingState.hasValue || billingState.isLoading || billingState.hasError) ...[
                      if (billingState.hasValue && !billingState.hasError) ...[
                        // Success banner
                        Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          border: const Border(
                            left: BorderSide(
                              color: AppColors.success,
                              width: 4,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Billing lines loaded. Update rates to recalculate totals instantly.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Search Box
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'SEARCH VENDOR',
                              style: AppTypography.labelCaps.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _searchController,
                              onChanged: (val) {
                                setState(() {});
                              },
                              decoration: InputDecoration(
                                hintText: 'Type vendor name or vendor ID',
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: AppColors.textSecondary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              style: AppTypography.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Range: ${_dateFromController.text} to ${_dateToController.text} | '
                              '${sortedSummaries.fold<int>(0, (prev, s) => prev + s.lines.length)} line(s) across ${sortedSummaries.length} vendor(s).',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ],

                      // Grouped Billing List
                      if (isLoading)
                        Column(
                          children: List.generate(4, (index) => const Padding(
                            padding: EdgeInsets.only(bottom: 16.0),
                            child: SkeletonCard(height: 80),
                          )),
                        )
                      else if (billingState.hasError)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32.0),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                                const SizedBox(height: 16),
                                Text(
                                  'Failed to load billing data',
                                  style: AppTypography.bodyMedium.copyWith(color: AppColors.danger),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  billingState.error.toString(),
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => ref.invalidate(billingProvider),
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
                        )
                      else if (sortedSummaries.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          child: Center(
                            child: Text('No matching billing lines found.'),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Desktop Table Header
                              Container(
                                color: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'VENDOR',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'BOOKED DATE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'GENERATOR (CAPACITY)',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'PRICE / CAPACITY',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'LINE AMOUNT',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Loop through vendor groups
                              ...sortedSummaries.map((summary) {
                                final vendorId = summary.vendorId;
                                final vendorName = summary.vendorName;

                                double vendorSubtotal = 0.0;
                                for (var line in summary.lines) {
                                  vendorSubtotal += _getRateForCapacity(
                                    line.booking.capacity,
                                  );
                                }

                                final paidAmount =
                                    _paidAmounts[vendorId] ?? 0.0;
                                final vendorFinalTotal =
                                    vendorSubtotal - paidAmount;

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Group Rows
                                    ...summary.lines.map((line) {
                                      final booking = line.booking;
                                      final rate = _getRateForCapacity(
                                        booking.capacity,
                                      );
                                      return Container(
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: AppColors.surfaceContainer,
                                            ),
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '$vendorName ($vendorId)',
                                                    style: AppTypography
                                                        .bodySmall
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                  Text(
                                                    booking.id,
                                                    style: AppTypography
                                                        .bodySmall
                                                        .copyWith(
                                                          fontSize: 11,
                                                          color: AppColors
                                                              .textSecondary,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                DateFormat(
                                                  'yyyy-MM-dd',
                                                ).format(booking.date),
                                                style: AppTypography.bodySmall,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                '${booking.generatorId} (${booking.capacity})',
                                                style: AppTypography.bodySmall
                                                    .copyWith(
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                currencyFormatter.format(rate),
                                                style: AppTypography.bodySmall
                                                    .copyWith(
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                currencyFormatter.format(rate),
                                                style: AppTypography.bodySmall
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),

                                    // Subtotal Row for Vendor
                                    Container(
                                      color: AppColors.surfaceContainer,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      child: Wrap(
                                        alignment: WrapAlignment.end,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 16,
                                        runSpacing: 8,
                                        children: [
                                          Text(
                                            '${vendorName.toUpperCase()} ($vendorId) SUBTOTAL',
                                            style: AppTypography.labelCaps
                                                .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 10,
                                                ),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color: AppColors.border,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'PAID',
                                                  style: AppTypography.labelCaps
                                                      .copyWith(
                                                        color: AppColors
                                                            .textSecondary,
                                                        fontSize: 9,
                                                      ),
                                                ),
                                                const SizedBox(width: 8),
                                                SizedBox(
                                                  width: 80,
                                                  height: 24,
                                                  child: TextField(
                                                    keyboardType:
                                                        TextInputType.number,
                                                    onChanged: (val) {
                                                      setState(() {
                                                        _paidAmounts[vendorId] =
                                                            double.tryParse(
                                                              val,
                                                            ) ??
                                                            0.0;
                                                      });
                                                    },
                                                    decoration:
                                                        const InputDecoration(
                                                          border:
                                                              InputBorder.none,
                                                          contentPadding:
                                                              EdgeInsets.zero,
                                                          hintText: '0',
                                                        ),
                                                    style: AppTypography
                                                        .bodySmall
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '- ${currencyFormatter.format(paidAmount)}',
                                                  style: AppTypography.bodySmall
                                                      .copyWith(
                                                        color: AppColors.danger,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'FINAL TOTAL',
                                                style: AppTypography.labelCaps
                                                    .copyWith(
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                currencyFormatter.format(
                                                  vendorFinalTotal,
                                                ),
                                                style: AppTypography
                                                    .headlineSmall
                                                    .copyWith(
                                                      color: AppColors.primary,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),

            // Fixed Bottom Footer
            if (_includeGrandTotal && sortedSummaries.isNotEmpty)
              Container(
                color: AppColors.background,
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'GRAND TOTAL',
                        style: AppTypography.headlineSmall.copyWith(
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        currencyFormatter.format(grandTotal),
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.accent,
                          fontSize: 26,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
