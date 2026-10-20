import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/exceptions/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/models/vendor.dart';
import '../../../shared/models/generator.dart';
import '../../../shared/widgets/draggable_form_sheet.dart';
import '../../../shared/widgets/assignment_mode_toggle.dart';
import '../../../shared/widgets/capacity_chip_selector.dart';
import '../../../shared/widgets/inline_calendar.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/autocomplete_field.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../core/providers/generator_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/vendor_provider.dart';
import '../../../core/services/user_preferences_service.dart';
import '../../../core/services/form_defaults_service.dart';
import '../../../core/services/draft_service.dart';

/// Single genset schedule requirement within a booking order.
class BookingRequirement {
  String id;
  String assignmentMode; // 'capacity' or 'id'
  List<String> selectedCapacities;
  String? selectedGeneratorId;
  int quantity;
  List<DateTime> selectedDates;
  bool isCalendarExpanded;

  BookingRequirement({
    required this.id,
    this.assignmentMode = 'capacity',
    List<String>? selectedCapacities,
    this.selectedGeneratorId,
    this.quantity = 1,
    List<DateTime>? selectedDates,
    this.isCalendarExpanded = false,
  }) : selectedCapacities = selectedCapacities ?? ['50'],
       selectedDates = selectedDates ?? [DateTime.now()];

  Map<String, dynamic> toJson() => {
    'id': id,
    'assignmentMode': assignmentMode,
    'selectedCapacities': selectedCapacities,
    'selectedGeneratorId': selectedGeneratorId,
    'quantity': quantity,
    'selectedDates': selectedDates.map((d) => d.toIso8601String()).toList(),
    'isCalendarExpanded': isCalendarExpanded,
  };

  factory BookingRequirement.fromJson(Map<String, dynamic> json) {
    return BookingRequirement(
      id: json['id'] ?? 'req_1',
      assignmentMode: json['assignmentMode'] ?? 'capacity',
      selectedCapacities: List<String>.from(
        json['selectedCapacities'] ?? ['50'],
      ),
      selectedGeneratorId: json['selectedGeneratorId'],
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      selectedDates:
          (json['selectedDates'] as List?)
              ?.map((d) => DateTime.parse(d as String))
              .toList() ??
          [DateTime.now()],
      isCalendarExpanded: json['isCalendarExpanded'] ?? false,
    );
  }
}

/// A modal window used to create single or multi-schedule bookings.
class AddBookingModal extends ConsumerStatefulWidget {
  /// Callback triggered when the modal is closed.
  final VoidCallback onClose;

  /// Callback triggered when the booking is successfully created and saved.
  final Function(List<Booking>) onSave;

  /// Controls the visibility of this overlay.
  final bool isVisible;

  /// Locks the booking to a specific vendor, disabling dropdown edits.
  final String? lockedVendorId;

  /// Creates an [AddBookingModal].
  const AddBookingModal({
    super.key,
    required this.onClose,
    required this.onSave,
    this.isVisible = true,
    this.lockedVendorId,
  });

  @override
  ConsumerState<AddBookingModal> createState() => _AddBookingModalState();
}

class _AddBookingModalState extends ConsumerState<AddBookingModal> {
  List<BookingRequirement> _requirements = [BookingRequirement(id: 'req_1')];

  String? _selectedVendorId;
  final _notesController = TextEditingController();

  // Focus nodes for interactive field styling
  late final FocusNode _notesFocusNode;
  bool _notesHasFocus = false;

  // Custom validation error state variables
  String? _vendorError;
  String? _generatorError;
  String? _dateError;
  String? _submissionError;
  bool _isSubmitting = false;

  final _draftService = DraftService();
  Timer? _autoSaveTimer;
  bool _listenersAdded = false;

  @override
  void initState() {
    super.initState();
    _notesFocusNode = FocusNode();

    _notesFocusNode.addListener(() {
      setState(() {
        _notesHasFocus = _notesFocusNode.hasFocus;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkDraft();
      }
    });
  }

  Future<void> _checkDraft() async {
    final draft = await _draftService.loadDraft('add_booking');
    if (draft != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Resume Draft?'),
          content: const Text(
            'We found a saved draft of this booking form. Would you like to resume editing?',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _draftService.clearDraft('add_booking');
                _applyDefaults();
              },
              child: const Text('Discard'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restoreDraft(draft);
              },
              child: const Text('Resume'),
            ),
          ],
        ),
      );
    } else {
      _applyDefaults();
    }
  }

  void _applyDefaults() {
    final defaults = ref.read(formDefaultsServiceProvider).getBookingDefaults();
    setState(() {
      _requirements = [
        BookingRequirement(
          id: 'req_1',
          selectedDates: [defaults.startDate],
          selectedCapacities: defaults.lastCapacities ?? ['50'],
        ),
      ];
      if (widget.lockedVendorId != null) {
        _selectedVendorId = widget.lockedVendorId;
      } else if (defaults.lastVendorId != null) {
        _selectedVendorId = defaults.lastVendorId;
      }
    });
    _addListeners();
  }

  void _restoreDraft(Map<String, dynamic> draft) {
    setState(() {
      if (draft['requirements'] != null) {
        final list = draft['requirements'] as List;
        _requirements = list
            .map(
              (item) =>
                  BookingRequirement.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else {
        _requirements = [
          BookingRequirement(
            id: 'req_1',
            assignmentMode: draft['assignmentMode'] ?? 'capacity',
            selectedCapacities: List<String>.from(
              draft['selectedCapacities'] ?? ['50'],
            ),
            selectedGeneratorId: draft['selectedGeneratorId'],
            selectedDates:
                (draft['selectedDates'] as List?)
                    ?.map((d) => DateTime.parse(d as String))
                    .toList() ??
                [DateTime.now()],
          ),
        ];
      }
      _selectedVendorId = widget.lockedVendorId ?? draft['selectedVendorId'];
      _notesController.text = draft['notes'] ?? '';
    });
    _addListeners();
  }

  void _addListeners() {
    if (_listenersAdded) return;
    _notesController.addListener(_onFormChanged);
    _listenersAdded = true;
  }

  void _onFormChanged() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      _saveDraft();
    });
  }

  Future<void> _saveDraft() async {
    final first = _requirements.first;
    final draft = {
      'requirements': _requirements.map((r) => r.toJson()).toList(),
      // Legacy keys for backward compatibility
      'assignmentMode': first.assignmentMode,
      'selectedCapacities': first.selectedCapacities,
      'selectedGeneratorId': first.selectedGeneratorId,
      'selectedDates': first.selectedDates
          .map((d) => d.toIso8601String())
          .toList(),
      'selectedVendorId': _selectedVendorId,
      'notes': _notesController.text,
    };
    await _draftService.saveDraft('add_booking', draft);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _notesFocusNode.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Calculates available units for a given requirement across all of its selected dates.
  int _calculateAvailableUnits(
    BookingRequirement req,
    List<Generator> availableGenerators,
    Map<String, List<Booking>> allBookingsMap,
  ) {
    if (req.selectedDates.isEmpty) return 999;

    if (req.assignmentMode == 'id') {
      if (req.selectedGeneratorId == null || req.selectedGeneratorId!.isEmpty) {
        return 0;
      }
      final genId = req.selectedGeneratorId!;
      for (final date in req.selectedDates) {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        for (final bookings in allBookingsMap.values) {
          for (final booking in bookings) {
            for (final item in booking.items) {
              if (item.startDt.split(' ')[0] == dateStr &&
                  item.generatorId == genId &&
                  item.itemStatus.toLowerCase() != 'cancelled') {
                return 0;
              }
            }
          }
        }
      }
      return 1;
    }

    final capNum = int.tryParse(
      req.selectedCapacities.isNotEmpty ? req.selectedCapacities.first : '50',
    );
    if (capNum == null) return 999;

    final matching = availableGenerators.where((g) {
      final gCap = int.tryParse(g.capacity.replaceAll(RegExp(r'[^0-9]'), ''));
      final s = g.status.toLowerCase();
      return gCap == capNum && (s == 'available' || s == 'active');
    }).toList();

    final totalUnits = matching.length;
    if (totalUnits == 0) return -1;

    int minAvailable = totalUnits;
    for (final date in req.selectedDates) {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      int bookedUnits = 0;
      for (final bookings in allBookingsMap.values) {
        for (final booking in bookings) {
          for (final item in booking.items) {
            if (item.startDt.split(' ')[0] == dateStr &&
                item.capacityKva == capNum &&
                item.itemStatus.toLowerCase() != 'cancelled') {
              bookedUnits++;
            }
          }
        }
      }
      final free = (totalUnits - bookedUnits).clamp(0, totalUnits);
      if (free < minAvailable) {
        minAvailable = free;
      }
    }
    return minAvailable;
  }

  Future<void> _submitForm() async {
    final firstReq = _requirements.first;
    setState(() {
      _submissionError = null;
      _vendorError = _selectedVendorId == null
          ? 'Please search and select a vendor'
          : null;
      _generatorError =
          (firstReq.assignmentMode == 'id' &&
              firstReq.selectedGeneratorId == null)
          ? 'Please select a generator ID'
          : null;
      _dateError = firstReq.selectedDates.isEmpty
          ? 'Please select booking dates'
          : null;
    });

    if (_vendorError != null || _generatorError != null || _dateError != null) {
      return;
    }

    final vendors = ref.read(vendorProvider).valueOrNull ?? [];
    if (vendors.isEmpty) {
      setState(() {
        _vendorError = 'Vendors are still loading. Try again in a moment.';
      });
      return;
    }
    final selectedVendor = vendors.firstWhere((v) => v.id == _selectedVendorId);

    final generators = ref.read(generatorProvider).valueOrNull ?? [];
    if (generators.isEmpty) {
      setState(() {
        _generatorError =
            'Generators are still loading. Try again in a moment.';
      });
      return;
    }

    final allBookingsMap =
        ref.read(allVendorBookingsProvider).valueOrNull ?? {};

    // Validate inventory availability for all requirements
    for (int i = 0; i < _requirements.length; i++) {
      final req = _requirements[i];
      if (req.selectedDates.isEmpty) {
        setState(() {
          _submissionError = 'Requirement #${i + 1} has no dates selected.';
        });
        return;
      }
      final available = _calculateAvailableUnits(
        req,
        generators,
        allBookingsMap,
      );
      if (available >= 0 && req.quantity > available) {
        final cap = req.selectedCapacities.isNotEmpty
            ? req.selectedCapacities.first
            : '50';
        setState(() {
          _submissionError =
              'Insufficient inventory for $cap kVA: requested ${req.quantity}, only $available unit(s) available on selected date(s).';
        });
        return;
      }
    }

    final List<BookingItem> allItems = [];
    final List<String> allGeneratorIds = [];

    for (final req in _requirements) {
      final capNum = int.tryParse(
        req.selectedCapacities.isNotEmpty ? req.selectedCapacities.first : '50',
      );

      final matchingGens = generators.where((g) {
        if (req.assignmentMode == 'id') {
          return g.id == req.selectedGeneratorId;
        }
        final gCap = int.tryParse(g.capacity.replaceAll(RegExp(r'[^0-9]'), ''));
        return gCap == capNum;
      }).toList();

      for (final date in req.selectedDates) {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        for (int q = 0; q < req.quantity; q++) {
          final genId = (q < matchingGens.length)
              ? matchingGens[q].id
              : (matchingGens.isNotEmpty
                    ? matchingGens.first.id
                    : 'AUTO-ASSIGN');
          allGeneratorIds.add(genId);
          allItems.add(
            BookingItem(
              generatorId: genId,
              capacityKva: capNum,
              startDt: dateStr,
              endDt: dateStr,
              itemStatus: 'confirmed',
              isEmergency: false,
              remarks: _notesController.text.trim(),
            ),
          );
        }
      }
    }

    // Determine representative capacity display string
    String capacityText;
    if (_requirements.length == 1 && _requirements.first.quantity == 1) {
      if (_requirements.first.assignmentMode == 'capacity') {
        capacityText = _requirements.first.selectedCapacities
            .map((c) => '$c kVA')
            .join(', ');
      } else {
        final match = generators.firstWhere(
          (g) => g.id == _requirements.first.selectedGeneratorId,
          orElse: () => generators.first,
        );
        capacityText = match.capacity;
      }
    } else {
      capacityText = '${allItems.length} Units';
    }

    final baseTime = DateTime.now().millisecondsSinceEpoch;
    final primaryGenId = allGeneratorIds.isNotEmpty
        ? allGeneratorIds.first
        : 'AUTO-ASSIGN';

    final newBooking = Booking.withGenerators(
      bookingId: 'BK-$baseTime-0',
      vendorId: _selectedVendorId!,
      vendorName: selectedVendor.name,
      generators: allGeneratorIds.isNotEmpty ? allGeneratorIds : [primaryGenId],
      startDate: _requirements.first.selectedDates.first,
      endDate: _requirements.last.selectedDates.last,
      status: 'confirmed',
      notes: _notesController.text.trim(),
      capacity: capacityText,
      items: allItems,
    );

    // Also schedule reminders
    final reminderService = ref.read(bookingReminderServiceProvider);
    await reminderService.scheduleRemindersForBooking(newBooking);

    // Save preferences
    final prefs = ref.read(userPreferencesServiceProvider);
    prefs.saveLastVendor(_selectedVendorId!);
    if (_requirements.first.assignmentMode == 'capacity') {
      prefs.saveLastSelectedCapacities(_requirements.first.selectedCapacities);
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onSave([newBooking]);
      _autoSaveTimer?.cancel();
      await _draftService.clearDraft('add_booking');
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _submissionError = e.message;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submissionError = e.toString().replaceFirst(
            RegExp(r'^Exception:\s*'),
            '',
          );
          _isSubmitting = false;
        });
      }
    }
  }

  StatusBadgeType _getStatusType(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return StatusBadgeType.confirmed;
      case 'pending':
        return StatusBadgeType.pending;
      case 'cancelled':
        return StatusBadgeType.cancelled;
      default:
        return StatusBadgeType.pending;
    }
  }

  Future<bool> _onDismissAttempt() async {
    final isFormDirty =
        _selectedVendorId != null ||
        _notesController.text.isNotEmpty ||
        _requirements.first.selectedGeneratorId != null ||
        _requirements.first.selectedDates.isNotEmpty ||
        _requirements.length > 1;

    if (!isFormDirty) {
      await _draftService.clearDraft('add_booking');
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Draft?'),
        content: const Text(
          'You have unsaved changes. Do you want to discard this draft or keep editing?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Editing'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
              await _draftService.clearDraft('add_booking');
              await ref.read(userPreferencesServiceProvider).clearLastVendor();
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildQuantitySection(BookingRequirement req, int availableStock) {
    final hasShortage = availableStock >= 0 && req.quantity > availableStock;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasShortage ? AppColors.danger : AppColors.outlineVariant,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'QUANTITY',
                style: AppTypography.labelCaps.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    availableStock < 0
                        ? Icons.info_outline
                        : (hasShortage
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline),
                    size: 12,
                    color: availableStock < 0
                        ? AppColors.textSecondary
                        : (hasShortage ? AppColors.danger : AppColors.success),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    availableStock < 0
                        ? 'Stock verified on submit'
                        : (hasShortage
                              ? 'Only $availableStock free on date(s)'
                              : '$availableStock available on date(s)'),
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11,
                      color: availableStock < 0
                          ? AppColors.textSecondary
                          : (hasShortage
                                ? AppColors.danger
                                : AppColors.success),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: AppColors.outlineVariant, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  splashRadius: 16,
                  onPressed: req.quantity > 1
                      ? () {
                          setState(() => req.quantity--);
                          _onFormChanged();
                        }
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    '${req.quantity}',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  splashRadius: 16,
                  onPressed: () {
                    setState(() => req.quantity++);
                    _onFormChanged();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    final Map<String, List<String>> breakdown = {};
    int totalUnits = 0;
    for (final req in _requirements) {
      final cap = req.selectedCapacities.isNotEmpty
          ? req.selectedCapacities.first
          : '50';
      final label = '${req.quantity}× $cap kVA';
      for (final d in req.selectedDates) {
        final dStr = DateFormat('dd MMM yyyy').format(d);
        breakdown.putIfAbsent(dStr, () => []).add(label);
        totalUnits += req.quantity;
      }
    }

    if (totalUnits <= 1 && breakdown.length <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'ORDER SCHEDULE BREAKDOWN',
                style: AppTypography.labelCaps.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...breakdown.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ${e.key}: ',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value.join(', '),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 16),
          Text(
            'Total: $totalUnits genset reservation(s) across ${breakdown.length} date(s)',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalRequirementCard(
    int index,
    BookingRequirement req,
    List<Generator> availableGenerators,
    int availableStock,
  ) {
    final hasShortage = req.quantity > availableStock;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasShortage ? AppColors.danger : AppColors.outlineVariant,
          width: hasShortage ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 1),
            blurRadius: 2,
            color: AppColors.shadowSoft,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ITEM #${index + 1}',
                      style: AppTypography.labelCaps.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (hasShortage) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Over-capacity',
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.danger,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: AppColors.danger,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  setState(() {
                    _requirements.removeAt(index);
                  });
                  _onFormChanged();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFieldLabel('Capacity (kVA)'),
          const SizedBox(height: 8),
          CapacityChipSelector(
            capacities: const [
              '15',
              '20',
              '30',
              '45',
              '50',
              '82',
              '100',
              '125',
              '160',
            ],
            selectedCapacities: req.selectedCapacities,
            isMultiSelect: false,
            onCapacitiesChanged: (caps) {
              setState(() {
                req.selectedCapacities = caps;
              });
              _onFormChanged();
            },
          ),
          _buildQuantitySection(req, availableStock),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BOOKING DATES',
                style: AppTypography.labelCaps.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    req.isCalendarExpanded = !req.isCalendarExpanded;
                  });
                },
                icon: Icon(
                  req.isCalendarExpanded
                      ? Icons.expand_less
                      : Icons.expand_more,
                  size: 16,
                  color: AppColors.primary,
                ),
                label: Text(
                  req.isCalendarExpanded ? 'Collapse' : 'Change Dates',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    req.selectedDates.isEmpty
                        ? 'No dates selected'
                        : 'Selected: ${req.selectedDates.map((d) => DateFormat('MMM d').format(d)).join(', ')} (${req.selectedDates.length} day${req.selectedDates.length > 1 ? 's' : ''})',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (req.isCalendarExpanded) ...[
            const SizedBox(height: 8),
            InlineCalendar(
              selectionMode: CalendarSelectionMode.multi,
              selectedDates: req.selectedDates,
              onDatesChanged: (dates) {
                setState(() {
                  req.selectedDates = dates;
                });
                _onFormChanged();
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final List<Generator> availableGenerators =
        ref.watch(generatorProvider).valueOrNull ?? [];
    final bookings = ref.watch(bookingProvider).valueOrNull ?? [];
    final List<Vendor> vendors = ref.watch(vendorProvider).valueOrNull ?? [];
    final allBookingsMap =
        ref.watch(allVendorBookingsProvider).valueOrNull ?? {};

    final firstReq = _requirements.first;
    final firstAvailableStock = _calculateAvailableUnits(
      firstReq,
      availableGenerators,
      allBookingsMap,
    );

    return DraggableFormSheet(
      title: 'Create Booking',
      category: 'bookings',
      onClose: widget.onClose,
      onDismissAttempt: _onDismissAttempt,
      footer: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.primary,
            elevation: 0,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : Text(
                  'Create Booking',
                  style: AppTypography.labelCaps.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Submission Error Alert Box
          if (_submissionError != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: const Border(
                  left: BorderSide(color: AppColors.danger, width: 4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.danger,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _submissionError!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.danger,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    onPressed: () => setState(() => _submissionError = null),
                  ),
                ],
              ),
            ),
          ],

          // 1. Vendor Selection
          AutocompleteField<Vendor>(
            items: vendors,
            initialValue: _selectedVendorId != null
                ? vendors.firstWhere(
                    (v) => v.id == _selectedVendorId,
                    orElse: () => vendors.first,
                  )
                : null,
            displayStringForOption: (Vendor vendor) => vendor.name,
            searchFields: (Vendor vendor) => [vendor.name, vendor.id],
            onSelected: (Vendor? vendor) {
              setState(() {
                _selectedVendorId = vendor?.id;
                _vendorError = null;
              });
              _onFormChanged();
            },
            hintText: 'Search by vendor name or ID',
            labelText: 'Vendor *',
            errorText: _vendorError,
            enabled: widget.lockedVendorId == null,
          ),
          const SizedBox(height: 20),

          // 2. Existing Bookings
          _buildExistingBookingsSection(bookings, _selectedVendorId),
          const SizedBox(height: 20),

          // 3. Generator Assignment Mode (Primary Item)
          _buildSectionHeader('GENERATOR ASSIGNMENT'),
          const SizedBox(height: 8),
          AssignmentModeToggle(
            currentMode: firstReq.assignmentMode,
            onModeChanged: (mode) {
              setState(() {
                firstReq.assignmentMode = mode;
                _generatorError = null;
              });
              _onFormChanged();
            },
          ),
          const SizedBox(height: 20),

          // 4. Conditional Assignment Fields (Primary Item)
          if (firstReq.assignmentMode == 'id') ...[
            AutocompleteField<Generator>(
              items: availableGenerators,
              initialValue: firstReq.selectedGeneratorId != null
                  ? availableGenerators.firstWhere(
                      (g) => g.id == firstReq.selectedGeneratorId,
                      orElse: () => availableGenerators.first,
                    )
                  : null,
              displayStringForOption: (Generator gen) =>
                  '${gen.id} (${gen.capacity} - ${gen.category})',
              searchFields: (Generator gen) => [
                gen.id,
                gen.capacity,
                gen.category,
              ],
              onSelected: (Generator? gen) {
                setState(() {
                  firstReq.selectedGeneratorId = gen?.id;
                  _generatorError = null;
                });
                _onFormChanged();
              },
              hintText: 'Type generator ID or capacity...',
              labelText: 'GENERATOR',
              errorText: _generatorError,
            ),
          ] else ...[
            _buildFieldLabel('Capacity (kVA)'),
            const SizedBox(height: 8),
            CapacityChipSelector(
              capacities: const [
                '15',
                '20',
                '30',
                '45',
                '50',
                '82',
                '100',
                '125',
                '160',
              ],
              selectedCapacities: firstReq.selectedCapacities,
              isMultiSelect: true,
              onCapacitiesChanged: (caps) {
                setState(() {
                  firstReq.selectedCapacities = caps;
                });
                _onFormChanged();
              },
            ),
          ],

          // Quantity Stepper (Primary Item)
          _buildQuantitySection(firstReq, firstAvailableStock),
          const SizedBox(height: 20),

          // 5. Booking Dates (Primary Item)
          _buildSectionHeader('BOOKING DATES'),
          const SizedBox(height: 8),
          InlineCalendar(
            selectionMode: CalendarSelectionMode.multi,
            selectedDates: firstReq.selectedDates,
            onDatesChanged: (dates) {
              setState(() {
                firstReq.selectedDates = dates;
                _dateError = null;
              });
              _onFormChanged();
            },
          ),
          if (_dateError != null) _buildValidationError(_dateError!),

          // Date selection feedback display
          if (firstReq.selectedDates.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selected: ${firstReq.selectedDates.map((d) => DateFormat('MMM d').format(d)).join(', ')} (${firstReq.selectedDates.length} days)',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 6. Additional Requirements List
          if (_requirements.length > 1) ...[
            for (int i = 1; i < _requirements.length; i++)
              _buildAdditionalRequirementCard(
                i,
                _requirements[i],
                availableGenerators,
                _calculateAvailableUnits(
                  _requirements[i],
                  availableGenerators,
                  allBookingsMap,
                ),
              ),
          ],

          const SizedBox(height: 16),

          // Add Requirement Action Button
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _requirements.add(
                  BookingRequirement(
                    id: 'req_${DateTime.now().millisecondsSinceEpoch}',
                    selectedCapacities: ['20'],
                    quantity: 1,
                    selectedDates: _requirements.isNotEmpty
                        ? List.of(_requirements.last.selectedDates)
                        : [DateTime.now()],
                  ),
                );
              });
              _onFormChanged();
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Another Genset / Schedule'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.outlineVariant),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),

          // 7. Order Schedule Breakdown Summary
          _buildOrderSummary(),

          const SizedBox(height: 12),

          // 8. Notes
          _buildFieldLabel('Optional Notes'),
          const SizedBox(height: 8),
          _buildFieldWrapper(
            focusNode: _notesFocusNode,
            hasFocus: _notesHasFocus,
            child: TextFormField(
              focusNode: _notesFocusNode,
              controller: _notesController,
              maxLines: 3,
              style: AppTypography.bodyMedium,
              decoration: _inputDecoration(hintText: 'Add any notes...'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.labelCaps.copyWith(
        color: AppColors.primary,
        letterSpacing: 2.2,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppTypography.bodySmall.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildValidationError(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 14, color: AppColors.danger),
          const SizedBox(width: 4),
          Text(
            error,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.danger,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldWrapper({
    required FocusNode focusNode,
    required bool hasFocus,
    required Widget child,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasFocus ? AppColors.primary : AppColors.outlineVariant,
          width: 1,
        ),
        boxShadow: [
          if (hasFocus)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 4,
              spreadRadius: 0,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTypography.bodySmall.copyWith(
        color: AppColors.textSecondary,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: InputBorder.none,
      focusedBorder: InputBorder.none,
      enabledBorder: InputBorder.none,
    );
  }

  Widget _buildExistingBookingsSection(
    List<Booking> bookings,
    String? vendorId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('EXISTING BOOKINGS'),
        const SizedBox(height: 8),
        if (vendorId == null)
          _buildInfoCard(
            'No vendor selected. Select a vendor to view existing bookings.',
          )
        else ...[
          Builder(
            builder: (context) {
              final vendorBookings = bookings
                  .where((b) => b.vendorId == vendorId)
                  .toList();
              if (vendorBookings.isEmpty) {
                return _buildInfoCard('No existing bookings for this vendor.');
              }
              return Column(
                children: vendorBookings.map((b) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...b.parseGeneratorItems().map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 2.0),
                                    child: RichText(
                                      text: TextSpan(
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                        children: [
                                          TextSpan(text: item['id'] ?? ''),
                                          const TextSpan(text: ' '),
                                          TextSpan(
                                            text: '(${item['capacity'] ?? ''})',
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  b.formatBookingDate(),
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(
                            label: b.status.toUpperCase(),
                            type: _getStatusType(b.status),
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
      ],
    );
  }

  Widget _buildInfoCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
