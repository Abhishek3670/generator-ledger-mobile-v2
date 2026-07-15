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
import 'package:ledger/core/services/user_preferences_service.dart';
import 'package:ledger/shared/widgets/autocomplete_field.dart';
import 'package:ledger/core/providers/vendor_provider.dart';
import 'package:ledger/data/mock/mock_vendors.dart';
import 'package:ledger/shared/models/vendor.dart';

import 'package:ledger/core/services/secure_screen_manager.dart';
import 'package:ledger/shared/widgets/app_toast.dart';

class BillingPreviewScreen extends ConsumerStatefulWidget {
  const BillingPreviewScreen({super.key});

  @override
  ConsumerState<BillingPreviewScreen> createState() =>
      _BillingPreviewScreenState();
}

class _BillingPreviewScreenState extends ConsumerState<BillingPreviewScreen> {
  final TextEditingController _dateRangeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final Map<String, TextEditingController> _rateControllers = {};

  // Keep track of paid amounts per vendor ID
  final Map<String, double> _paidAmounts = {};

  bool _includeGrandTotal = true;

  @override
  void initState() {
    super.initState();
    SecureScreenManager.enableSecureMode();
    SecureScreenManager.registerScreenshotCallback(() {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Screenshots are disabled on this screen for security.',
          type: ToastType.warning,
        );
      }
    });
  }

  @override
  void dispose() {
    SecureScreenManager.unregisterScreenshotCallback();
    SecureScreenManager.disableSecureMode();
    _dateRangeController.dispose();
    _searchController.dispose();
    for (var controller in _rateControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final dateRange = ref.read(billingDateRangeProvider);
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: dateRange != null
          ? DateTimeRange(start: dateRange.startDate, end: dateRange.endDate)
          : null,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final vendorFilter = _searchController.text.trim();
      ref.read(billingDateRangeProvider.notifier).state = BillingDateRange(
        startDate: picked.start,
        endDate: picked.end,
        vendorId: vendorFilter.isNotEmpty ? vendorFilter : null,
      );

      final prefs = ref.read(userPreferencesServiceProvider);
      prefs.saveLastBillingDateRange(picked.start, picked.end);
      prefs.saveLastBillingVendorFilter(vendorFilter);

      ref.invalidate(billingProvider);
    }
  }

  double _getRateForCapacity(String capacity) {
    // Normalize capacity key (extract numeric part, e.g. "125 kVA" -> 125 -> "125 kVA")
    final match = RegExp(r'(\d+)').firstMatch(capacity);
    if (match != null) {
      final numericPart = match.group(1);
      final key = '$numericPart kVA';
      final controller = _rateControllers[key];
      if (controller != null) {
        return double.tryParse(controller.text) ?? 0.0;
      }
    }
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
    final dateRange = ref.watch(billingDateRangeProvider);
    ref.listen<BillingDateRange?>(billingDateRangeProvider, (previous, next) {
      if (next != null) {
        final startStr = DateFormat('dd-MM-yyyy').format(next.startDate);
        final endStr = DateFormat('dd-MM-yyyy').format(next.endDate);
        _dateRangeController.text = '$startStr / $endStr';
        if (next.vendorId != null) {
          _searchController.text = next.vendorId!;
        }
      } else {
        _dateRangeController.clear();
        _searchController.clear();
      }
    });
    final List<MockVendor> vendors = ref.watch(vendorProvider).valueOrNull ?? [];
    final billingState = ref.watch(billingProvider);
    final connectivity = ref.watch(connectivityProvider);
    final isLoading = billingState.isLoading;

    final response = billingState.valueOrNull;
    final summaries = response?.summaries ?? <BillingSummary>[];
    final capacities = response?.capacities ?? <int>[];

    // Ensure all dynamic capacities have a controller in _rateControllers.
    // If a capacity doesn't have a controller, initialize it with '0'.
    for (final cap in capacities) {
      final key = '$cap kVA';
      _rateControllers.putIfAbsent(key, () => TextEditingController(text: '0'));
    }

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
        child: Stack(
          children: [
            Column(
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
                padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 100.0),
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
                           Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DATE RANGE',
                                style: AppTypography.labelCaps.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _dateRangeController,
                                readOnly: true,
                                onTap: () => _selectDateRange(context),
                                decoration: InputDecoration(
                                  hintText: 'Select date range',
                                  suffixIcon: const Icon(
                                    Icons.calendar_today,
                                    size: 20,
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
                            ],
                          ),
                          const SizedBox(height: 16),
                          AutocompleteField<Vendor>(
                            items: vendors,
                            initialValue: dateRange?.vendorId != null && vendors.any((v) => v.id == dateRange?.vendorId || v.name == dateRange?.vendorId)
                                ? vendors.firstWhere((v) => v.id == dateRange?.vendorId || v.name == dateRange?.vendorId)
                                : null,
                            displayStringForOption: (Vendor vendor) => vendor.name,
                            searchFields: (Vendor vendor) => [vendor.name, vendor.id],
                            onSelected: (Vendor? vendor) {
                              _searchController.text = vendor?.id ?? '';
                              if (_dateRangeController.text.isNotEmpty) {
                                final currentRange = ref.read(billingDateRangeProvider);
                                if (currentRange != null) {
                                  ref.read(billingDateRangeProvider.notifier).state = BillingDateRange(
                                    startDate: currentRange.startDate,
                                    endDate: currentRange.endDate,
                                    vendorId: _searchController.text.trim().isNotEmpty
                                        ? _searchController.text.trim()
                                        : null,
                                  );
                                  ref.invalidate(billingProvider);
                                }
                              } else {
                                setState(() {});
                              }
                            },
                            hintText: 'Search by vendor name or ID',
                            labelText: 'FILTER BY VENDOR',
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'INCLUDE GRAND TOTAL',
                                    style: AppTypography.labelCaps.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Checkbox(
                                    value: _includeGrandTotal,
                                    activeColor: AppColors.primary,
                                    onChanged: (val) {
                                      setState(() {
                                        _includeGrandTotal = val ?? true;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (dateRange == null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 64.0),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 48,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Select a date range to load billing data',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
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
                                  children: capacities.map((cap) {
                                    final key = '$cap kVA';
                                    final controller = _rateControllers[key]!;
                                    return SizedBox(
                                      width: isWide
                                          ? (constraints.maxWidth - 24) / 3
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
                                              key.toUpperCase(),
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
                                                controller: controller,
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
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              'Range: ${_dateRangeController.text} | '
                              '${sortedSummaries.fold<int>(0, (prev, s) => prev + s.lines.length)} Booking(s) across ${sortedSummaries.length} vendor(s).',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: sortedSummaries.map((summary) {
                              final vendorId = summary.vendorId;
                              final vendorName = summary.vendorName;

                              double vendorSubtotal = 0.0;
                              for (var line in summary.lines) {
                                vendorSubtotal += _getRateForCapacity(
                                  line.booking.capacity,
                                );
                              }

                              final paidAmount = _paidAmounts[vendorId] ?? 0.0;
                              final vendorFinalTotal = vendorSubtotal - paidAmount;
                              final lineCount = summary.lines.length;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Card Header
                                    Container(
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(16),
                                          topRight: Radius.circular(16),
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '$vendorName ($vendorId)',
                                              style: AppTypography.bodyMedium.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.15),
                                              borderRadius: const BorderRadius.all(Radius.circular(9999)),
                                            ),
                                            child: Text(
                                              '$lineCount Booking${lineCount == 1 ? "" : "s"}',
                                              style: AppTypography.bodySmall.copyWith(
                                                fontSize: 11,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Line Items
                                    ...summary.lines.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final line = entry.value;
                                      final booking = line.booking;
                                      final rate = _getRateForCapacity(booking.capacity);

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                // Line 1: Date and Gen ID
                                                Text(
                                                  '${DateFormat('MMM dd').format(booking.date)} · ${booking.generatorId}',
                                                  style: AppTypography.bodySmall.copyWith(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                // Line 2: Capacity, Rate, Line Amount
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: const BoxDecoration(
                                                        color: AppColors.surfaceContainer,
                                                        borderRadius: BorderRadius.all(Radius.circular(9999)),
                                                      ),
                                                      child: Text(
                                                        booking.capacity,
                                                        style: AppTypography.bodySmall.copyWith(
                                                          fontSize: 11,
                                                          color: AppColors.textSecondary,
                                                        ),
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Text(
                                                      currencyFormatter.format(rate),
                                                      style: AppTypography.bodySmall.copyWith(
                                                        color: AppColors.textSecondary,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 24),
                                                    Text(
                                                      currencyFormatter.format(rate),
                                                      style: AppTypography.bodySmall.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.primary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (index < summary.lines.length - 1)
                                            const Divider(
                                              height: 1,
                                              thickness: 1,
                                              color: AppColors.surfaceContainer,
                                            ),
                                        ],
                                      );
                                    }),

                                    // Card Footer
                                    Container(
                                      decoration: const BoxDecoration(
                                        color: AppColors.surfaceContainer,
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(16),
                                          bottomRight: Radius.circular(16),
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: Wrap(
                                        alignment: WrapAlignment.end,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 16,
                                        runSpacing: 8,
                                        children: [
                                          Text(
                                            'SUBTOTAL',
                                            style: AppTypography.labelCaps.copyWith(
                                              color: AppColors.textSecondary,
                                              fontSize: 10,
                                            ),
                                          ),
                                          Text(
                                            currencyFormatter.format(vendorSubtotal),
                                            style: AppTypography.bodySmall.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(color: AppColors.border),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'PAID',
                                                  style: AppTypography.labelCaps.copyWith(
                                                    color: AppColors.textSecondary,
                                                    fontSize: 9,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                SizedBox(
                                                  width: 90,
                                                  height: 28,
                                                  child: TextField(
                                                    keyboardType: TextInputType.number,
                                                    onChanged: (val) {
                                                      setState(() {
                                                        _paidAmounts[vendorId] = double.tryParse(val) ?? 0.0;
                                                      });
                                                    },
                                                    decoration: const InputDecoration(
                                                      border: InputBorder.none,
                                                      isDense: true,
                                                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                                                      hintText: '0',
                                                    ),
                                                    style: AppTypography.bodySmall.copyWith(
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '- ${currencyFormatter.format(paidAmount)}',
                                                  style: AppTypography.bodySmall.copyWith(
                                                    color: AppColors.danger,
                                                    fontWeight: FontWeight.w500,
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
                                                style: AppTypography.labelCaps.copyWith(
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                currencyFormatter.format(vendorFinalTotal),
                                                style: AppTypography.headlineSmall.copyWith(
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_includeGrandTotal && sortedSummaries.isNotEmpty)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                      spreadRadius: 0,
                    ),
                  ],
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
          ),
      ],
    ),
  ),
);
  }
}
