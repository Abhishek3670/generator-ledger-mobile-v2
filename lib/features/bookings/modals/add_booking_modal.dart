import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/models/vendor.dart';
import '../../../shared/models/generator.dart';
import '../../../shared/widgets/backdrop_blur_overlay.dart';
import '../../../shared/widgets/assignment_mode_toggle.dart';
import '../../../shared/widgets/capacity_chip_selector.dart';
import '../../../shared/widgets/inline_calendar.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/autocomplete_field.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../core/providers/generator_provider.dart';
import '../../../core/providers/vendor_provider.dart';

import '../../../core/services/user_preferences_service.dart';
import '../../../core/services/form_defaults_service.dart';
import '../../../core/services/draft_service.dart';

/// A modal window used to create a new booking.
///
/// Connected to Riverpod state management. Features left-aligned Space Grotesk headers,
/// vendor search autocomplete, assignment mode toggle, multi-capacity selection,
/// inline calendar range selector, and an existing bookings log view.
class AddBookingModal extends ConsumerStatefulWidget {
  /// Callback triggered when the modal is closed.
  final VoidCallback onClose;

  /// Callback triggered when the booking is successfully created and saved.
  final Function(List<Booking>) onSave;

  /// Controls the visibility of this overlay.
  final bool isVisible;

  /// Creates an [AddBookingModal].
  const AddBookingModal({
    super.key,
    required this.onClose,
    required this.onSave,
    this.isVisible = true,
  });

  @override
  ConsumerState<AddBookingModal> createState() => _AddBookingModalState();
}

class _AddBookingModalState extends ConsumerState<AddBookingModal> {
  String _assignmentMode = 'id'; // 'id' or 'capacity'
  List<String> _selectedCapacities = ['50'];
  DateTime? _startDate;
  DateTime? _endDate;
  List<DateTime> _selectedDates = [];
  String? _selectedVendorId;
  String? _selectedGeneratorId;
  final _notesController = TextEditingController();

  // Focus nodes for interactive field styling
  late final FocusNode _notesFocusNode;
  bool _notesHasFocus = false;

  // Custom validation error state variables
  String? _vendorError;
  String? _generatorError;
  String? _dateError;

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
          content: const Text('We found a saved draft of this booking form. Would you like to resume editing?'),
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
      _startDate = defaults.startDate;
      _endDate = defaults.endDate;
      _selectedDates = defaults.startDate != null ? [defaults.startDate!] : [DateTime.now()];
      if (defaults.lastVendorId != null) {
        _selectedVendorId = defaults.lastVendorId;
      }
      if (defaults.lastCapacities != null && defaults.lastCapacities!.isNotEmpty) {
        _selectedCapacities = defaults.lastCapacities!;
      }
    });
    _addListeners();
  }

  void _restoreDraft(Map<String, dynamic> draft) {
    setState(() {
      _assignmentMode = draft['assignmentMode'] ?? 'id';
      _selectedCapacities = List<String>.from(draft['selectedCapacities'] ?? ['50']);
      _startDate = draft['startDate'] != null ? DateTime.parse(draft['startDate']) : null;
      _endDate = draft['endDate'] != null ? DateTime.parse(draft['endDate']) : null;
      _selectedDates = (draft['selectedDates'] as List?)?.map((d) => DateTime.parse(d as String)).toList() ?? [];
      if (_selectedDates.isEmpty && _startDate != null) {
        _selectedDates = [_startDate!];
      }
      _selectedVendorId = draft['selectedVendorId'];
      _selectedGeneratorId = draft['selectedGeneratorId'];
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
    final draft = {
      'assignmentMode': _assignmentMode,
      'selectedCapacities': _selectedCapacities,
      'startDate': _startDate?.toIso8601String(),
      'endDate': _endDate?.toIso8601String(),
      'selectedDates': _selectedDates.map((d) => d.toIso8601String()).toList(),
      'selectedVendorId': _selectedVendorId,
      'selectedGeneratorId': _selectedGeneratorId,
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

  void _submitForm() {
    setState(() {
      _vendorError = _selectedVendorId == null
          ? 'Please search and select a vendor'
          : null;
      _generatorError =
          (_assignmentMode == 'id' && _selectedGeneratorId == null)
          ? 'Please select a generator ID'
          : null;
      _dateError = _selectedDates.isEmpty ? 'Please select booking dates' : null;
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

    String genId = _selectedGeneratorId ?? 'AUTO-ASSIGN';
    String capacityText = '';

    final generators = ref.read(generatorProvider).valueOrNull ?? [];
    if (generators.isEmpty) {
      setState(() {
        _generatorError =
            'Generators are still loading. Try again in a moment.';
      });
      return;
    }
    if (_assignmentMode == 'capacity') {
      capacityText = _selectedCapacities.map((c) => '$c kVA').join(', ');
      // Try to find a mock generator that matches the first selected capacity
      final match = generators.firstWhere(
        (g) => _selectedCapacities.any((c) => g.capacity.contains(c)),
        orElse: () => generators.first,
      );
      genId = match.id;
    } else {
      final match = generators.firstWhere((g) => g.id == _selectedGeneratorId);
      capacityText = match.capacity;
    }

    final List<Booking> newBookings = [];
    final baseTime = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < _selectedDates.length; i++) {
      final date = _selectedDates[i];
      newBookings.add(Booking(
        id: 'BK-$baseTime-$i',
        vendorId: _selectedVendorId!,
        vendorName: selectedVendor.name,
        generatorId: genId,
        capacity: capacityText,
        date: date,
        endDate: date,
        status: 'confirmed',
        notes: _notesController.text.trim(),
      ));
    }

    final prefs = ref.read(userPreferencesServiceProvider);
    prefs.saveLastVendor(_selectedVendorId!);
    if (_assignmentMode == 'capacity') {
      prefs.saveLastSelectedCapacities(_selectedCapacities);
    } else {
      final match = generators.firstWhere((g) => g.id == _selectedGeneratorId);
      final rawCap = match.capacity.replaceAll(RegExp(r'[^0-9]'), '');
      if (rawCap.isNotEmpty) {
        prefs.saveLastSelectedCapacities([rawCap]);
      }
    }

    _autoSaveTimer?.cancel();
    _draftService.clearDraft('add_booking');
    widget.onSave(newBookings);
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

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final List<Generator> availableGenerators = ref.watch(generatorProvider).valueOrNull ?? [];
    final bookings = ref.watch(bookingProvider).valueOrNull ?? [];
    final List<Vendor> vendors = ref.watch(vendorProvider).valueOrNull ?? [];

    return Stack(
      children: [
        // Backdrop Overlay
        BackdropBlurOverlay(isVisible: widget.isVisible, onTap: widget.onClose),

        // Centered Card Container
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.mobileGutter),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 500,
                  maxHeight: 750,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background, // bg-background (#fafafa)
                  borderRadius: BorderRadius.circular(
                    AppDimensions.modalRadius,
                  ),
                  border: Border.all(
                    color: AppColors.outlineVariant,
                    width: 1,
                  ), // border-outline-variant (#c6c6cd)
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 10),
                      blurRadius: 30,
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header (Left-aligned, space grotesk)
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BOOKINGS',
                                  style: AppTypography.labelCaps.copyWith(
                                    color: AppColors.textSecondary,
                                    letterSpacing: 2.2, // .2em letter spacing
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Create Booking',
                                  style: AppTypography.headlineMedium.copyWith(
                                    color: AppColors.primary,
                                    fontFamily: 'SpaceGrotesk',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: widget.onClose,
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.textSecondary,
                            ),
                            splashRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      color: AppColors.outlineVariant,
                      height: 1,
                      thickness: 1,
                    ),

                    // Scrollable content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                            ),
                            const SizedBox(height: 20),

                            // 2. Existing Bookings
                            _buildExistingBookingsSection(
                              bookings,
                              _selectedVendorId,
                            ),
                            const SizedBox(height: 20),

                            // 3. Generator Assignment Mode
                            _buildSectionHeader('GENERATOR ASSIGNMENT'),
                            const SizedBox(height: 8),
                            AssignmentModeToggle(
                              currentMode: _assignmentMode,
                              onModeChanged: (mode) {
                                setState(() {
                                  _assignmentMode = mode;
                                  _generatorError = null;
                                });
                                _onFormChanged();
                              },
                            ),
                            const SizedBox(height: 20),

                            // 4. Conditional Assignment Fields
                            if (_assignmentMode == 'id') ...[
                              AutocompleteField<Generator>(
                                items: availableGenerators,
                                initialValue: _selectedGeneratorId != null
                                    ? availableGenerators.firstWhere(
                                        (g) => g.id == _selectedGeneratorId,
                                        orElse: () => availableGenerators.first,
                                      )
                                    : null,
                                displayStringForOption: (Generator gen) =>
                                    '${gen.id} (${gen.capacity} - ${gen.category})',
                                searchFields: (Generator gen) => [gen.id, gen.capacity, gen.category],
                                onSelected: (Generator? gen) {
                                  setState(() {
                                    _selectedGeneratorId = gen?.id;
                                    _generatorError = null;
                                  });
                                  _onFormChanged();
                                },
                                hintText: 'Type generator ID or capacity...',
                                labelText: 'GENERATOR',
                                errorText: _generatorError,
                              ),
                            ]
 else ...[
                              _buildFieldLabel('Capacity (kVA)'),
                              const SizedBox(height: 8),
                              CapacityChipSelector(
                                capacities: const ['20', '30', '50', '100'],
                                selectedCapacities: _selectedCapacities,
                                isMultiSelect: true,
                                onCapacitiesChanged: (caps) {
                                  setState(() {
                                    _selectedCapacities = caps;
                                  });
                                  _onFormChanged();
                                },
                              ),
                            ],
                            const SizedBox(height: 20),

                            // 5. Booking Dates
                            _buildSectionHeader('BOOKING DATES'),
                            const SizedBox(height: 8),
                             InlineCalendar(
                              selectionMode: CalendarSelectionMode.multi,
                              selectedDates: _selectedDates,
                              onDatesChanged: (dates) {
                                setState(() {
                                  _selectedDates = dates;
                                  _dateError = null;
                                });
                                _onFormChanged();
                              },
                            ),
                            if (_dateError != null)
                              _buildValidationError(_dateError!),

                            // Date selection feedback display
                            if (_selectedDates.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.05,
                                  ),
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
                                        'Selected: ${_selectedDates.map((d) => DateFormat('MMM d').format(d)).join(', ')} (${_selectedDates.length} days)',
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
                            const SizedBox(height: 20),

                            // 6. Notes
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
                                decoration: _inputDecoration(
                                  hintText: 'Add any notes...',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(
                      color: AppColors.outlineVariant,
                      height: 1,
                      thickness: 1,
                    ),

                    // Footer actions
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      color: AppColors.surface,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: widget.onClose,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.outlineVariant,
                                width: 1,
                              ),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: AppTypography.labelCaps.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.primary,
                              elevation: 0,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              'Create Booking',
                              style: AppTypography.labelCaps.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.labelCaps.copyWith(
        color: AppColors.primary,
        letterSpacing: 2.2, // .2em letter spacing
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
        color: AppColors.surface, // Background surface (#f9f9f9)
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasFocus
              ? AppColors.primary
              : AppColors
                    .outlineVariant, // primary on focus, outlineVariant (#c6c6cd) otherwise
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
                                Row(
                                  children: [
                                    Text(
                                      b.generatorId,
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '(${b.capacity})',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${DateFormat('MMM dd').format(b.startDate)} - ${DateFormat('MMM dd, yyyy').format(b.endDate)}',
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
