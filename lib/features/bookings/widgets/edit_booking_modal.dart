import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ledger/core/providers/generator_provider.dart';
import 'package:ledger/core/providers/vendor_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/widgets/draggable_form_sheet.dart';
import '../../../shared/widgets/assignment_mode_toggle.dart';
import '../../../shared/widgets/inline_calendar.dart';

class EditBookingModal extends ConsumerStatefulWidget {
  final Booking booking;
  final VoidCallback onClose;
  final Function(Booking) onSave;
  final bool isVisible;

  const EditBookingModal({
    super.key,
    required this.booking,
    required this.onClose,
    required this.onSave,
    this.isVisible = true,
  });

  @override
  ConsumerState<EditBookingModal> createState() => _EditBookingModalState();
}

class _EditBookingModalState extends ConsumerState<EditBookingModal> {
  final _formKey = GlobalKey<FormState>();
  String _assignmentMode = 'id';
  late String _selectedCapacity;
  String? _selectedVendorId;
  String? _selectedGeneratorId;
  late final TextEditingController _capacityController;
  final _notesController = TextEditingController();
  List<DateTime> _selectedDates = [];
  String? _dateError;

  @override
  void initState() {
    super.initState();
    _selectedVendorId = widget.booking.vendorId;
    _selectedGeneratorId = widget.booking.generatorId;
    _capacityController = TextEditingController(text: widget.booking.capacity);
    _notesController.text = widget.booking.notes;

    if (widget.booking.items.isNotEmpty) {
      _selectedDates = widget.booking.items
          .map((item) => DateTime.parse(item.startDt))
          .toList();
    } else {
      _selectedDates = [widget.booking.date];
    }
    _selectedDates.sort((a, b) => a.compareTo(b));

    final numMatch = RegExp(r'\d+').firstMatch(widget.booking.capacity);
    _selectedCapacity = numMatch != null ? numMatch.group(0)! : '50';
  }

  @override
  void dispose() {
    _capacityController.dispose();
    _notesController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final vendors = ref.watch(vendorProvider).valueOrNull ?? [];
    final generators = ref.watch(generatorProvider).valueOrNull ?? [];

    // Ensure initial/selected values are in the options list to avoid DropdownButton assertion crashes
    final vendorIds = vendors.map((v) => v.id).toSet();
    if (_selectedVendorId != null) {
      vendorIds.add(_selectedVendorId!);
    }

    final generatorIds = generators.map((g) => g.id).toSet();
    if (_selectedGeneratorId != null) {
      generatorIds.add(_selectedGeneratorId!);
    }

    final vendorDropdownItems = vendorIds.map((id) {
      final match = vendors.where((v) => v.id == id);
      final name = match.isNotEmpty ? match.first.name : id;
      return DropdownMenuItem<String>(
        value: id,
        child: Text(name, style: AppTypography.bodyMedium.copyWith(color: const Color(0xFF475569))),
      );
    }).toList();

    final generatorDropdownItems = generatorIds.map((id) {
      return DropdownMenuItem<String>(
        value: id,
        child: Text(id, style: AppTypography.bodyMedium),
      );
    }).toList();

    if (!widget.isVisible) return const SizedBox.shrink();

    final formContent = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vendor Dropdown (Disabled / Read-only)
          _buildFieldLabel('VENDOR'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _selectedVendorId,
            hint: Text('Select Vendor', style: AppTypography.bodySmall.copyWith(color: const Color(0xFF475569))),
            decoration: _inputDecoration(
              enabled: false,
              fillColor: const Color(0xFFF3F3F3),
              filled: true,
            ),
            icon: const SizedBox.shrink(),
            items: vendorDropdownItems,
            onChanged: null,
            style: AppTypography.bodyMedium.copyWith(color: const Color(0xFF475569)),
          ),
          const SizedBox(height: 16),

          // Assignment Mode Toggle
          _buildFieldLabel('GENERATOR ASSIGNMENT'),
          const SizedBox(height: 8),
          AssignmentModeToggle(
            currentMode: _assignmentMode,
            onModeChanged: (mode) {
              setState(() {
                _assignmentMode = mode;
              });
            },
          ),
          const SizedBox(height: 16),

          if (_assignmentMode == 'id') ...[
            // Generator Dropdown
            _buildFieldLabel('GENERATOR'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedGeneratorId,
              hint: Text('Select Generator', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              decoration: _inputDecoration(),
              items: generatorDropdownItems,
              onChanged: (value) {
                setState(() {
                  _selectedGeneratorId = value;
                  final match = generators.where((g) => g.id == value);
                  if (match.isNotEmpty) {
                    _capacityController.text = match.first.capacity;
                  }
                });
              },
              validator: (value) => _assignmentMode == 'id' && value == null ? 'Please select a generator' : null,
            ),
            const SizedBox(height: 16),

            // Capacity Field
            _buildFieldLabel('CAPACITY'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _capacityController,
              readOnly: true,
              style: AppTypography.bodyMedium,
              decoration: _inputDecoration(),
            ),
          ] else ...[
            // Capacity Radio Chips
            _buildFieldLabel('CAPACITY (kVA)'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const ['25', '50', '100', '250'].map((cap) {
                final isSelected = _selectedCapacity == cap;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCapacity = cap;
                      _capacityController.text = '$cap kVA';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: 1),
                      borderRadius: BorderRadius.circular(AppDimensions.pillRadius),
                    ),
                    child: Text(
                      cap,
                      style: AppTypography.bodySmall.copyWith(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),

          // Date Picker (InlineCalendar)
          _buildFieldLabel('BOOKING DATES'),
          const SizedBox(height: 8),
          InlineCalendar(
            selectionMode: CalendarSelectionMode.multi,
            selectedDates: _selectedDates,
            onDatesChanged: (dates) {
              setState(() {
                _selectedDates = dates;
                _dateError = null;
              });
            },
          ),
          if (_dateError != null)
            _buildValidationError(_dateError!),
          const SizedBox(height: 12),

          // Individual date chips
          if (_selectedDates.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedDates.map((date) {
                return Chip(
                  label: Text(
                    DateFormat('MMM dd, yyyy').format(date),
                    style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                  ),
                  onDeleted: () {
                    setState(() {
                      _selectedDates.remove(date);
                    });
                  },
                  deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.primary),
                  shape: const StadiumBorder(
                    side: BorderSide(color: AppColors.border, width: 1),
                  ),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Notes
          _buildFieldLabel('OPTIONAL NOTES'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            style: AppTypography.bodyMedium,
            decoration: _inputDecoration(hintText: 'Add any notes...'),
          ),
        ],
      ),
    );

    return DraggableFormSheet(
      title: 'Edit Booking',
      category: 'bookings',
      onClose: widget.onClose,
      footer: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              if (_selectedDates.isEmpty) {
                setState(() {
                  _dateError = 'Please select at least one date';
                });
                return;
              }

              final matchVendor = vendors.where((v) => v.id == _selectedVendorId);
              final vendorName = matchVendor.isNotEmpty ? matchVendor.first.name : (_selectedVendorId ?? '');

              String genId = _selectedGeneratorId ?? 'AUTO-ASSIGN';
              if (_assignmentMode == 'capacity') {
                final matchGen = generators.where((g) => g.capacity.contains(_selectedCapacity));
                if (matchGen.isNotEmpty) {
                  genId = matchGen.first.id;
                } else if (generators.isNotEmpty) {
                  genId = generators.first.id;
                }
              }

              final capacityNum = int.tryParse(_capacityController.text.replaceAll(RegExp(r'[^0-9]'), ''));

              final List<BookingItem> updatedItems = _selectedDates.map((date) {
                final dateStr = DateFormat('yyyy-MM-dd').format(date);
                return BookingItem(
                  generatorId: genId,
                  capacityKva: capacityNum,
                  startDt: dateStr,
                  itemStatus: widget.booking.status,
                  isEmergency: false,
                  remarks: _notesController.text.trim(),
                );
              }).toList();

              _selectedDates.sort((a, b) => a.compareTo(b));
              final newStartDate = _selectedDates.first;
              final newEndDate = _selectedDates.last;

              final updatedBooking = Booking.withGenerators(
                bookingId: widget.booking.id,
                vendorId: _selectedVendorId!,
                vendorName: vendorName,
                generators: [genId],
                startDate: newStartDate,
                endDate: newEndDate,
                status: widget.booking.status,
                notes: _notesController.text.trim(),
                capacity: _capacityController.text.trim(),
                items: updatedItems,
              );
              widget.onSave(updatedBooking);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.primary,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text('SAVE', style: AppTypography.labelCaps.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
      ),
      child: formContent,
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppTypography.labelCaps.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
    );
  }

  InputDecoration _inputDecoration({String? hintText, bool enabled = true, Color? fillColor, bool filled = false}) {
    return InputDecoration(
      hintText: hintText,
      fillColor: fillColor,
      filled: filled,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.functionalRadius),
        borderSide: BorderSide(color: enabled ? AppColors.border : const Color(0xFFCBD5E1), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.functionalRadius),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.functionalRadius),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.functionalRadius),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
