import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ledger/core/providers/generator_provider.dart';
import 'package:ledger/core/providers/vendor_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/widgets/modal_scaffold.dart';

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
  late DateTime _startDate;
  late DateTime _endDate;
  String? _selectedVendorId;
  String? _selectedGeneratorId;
  late final TextEditingController _capacityController;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedVendorId = widget.booking.vendorId;
    _selectedGeneratorId = widget.booking.generatorId;
    _capacityController = TextEditingController(text: widget.booking.capacity);
    _startDate = widget.booking.date;
    _endDate = widget.booking.date.add(const Duration(days: 2)); // Default fallback range

    final numMatch = RegExp(r'\d+').firstMatch(widget.booking.capacity);
    _selectedCapacity = numMatch != null ? numMatch.group(0)! : '50';
  }

  @override
  void dispose() {
    _capacityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
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
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
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
        child: Text(name, style: AppTypography.bodyMedium),
      );
    }).toList();

    final generatorDropdownItems = generatorIds.map((id) {
      return DropdownMenuItem<String>(
        value: id,
        child: Text(id, style: AppTypography.bodyMedium),
      );
    }).toList();

    return ModalScaffold(
      title: 'EDIT BOOKING',
      isVisible: widget.isVisible,
      onClose: widget.onClose,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vendor Dropdown
            _buildFieldLabel('VENDOR'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedVendorId,
              hint: Text('Select Vendor', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              decoration: _inputDecoration(),
              items: vendorDropdownItems,
              onChanged: (value) {
                setState(() {
                  _selectedVendorId = value;
                });
              },
              validator: (value) => value == null ? 'Please select a vendor' : null,
            ),
            const SizedBox(height: 16),

            // Assignment Mode Toggle
            _buildFieldLabel('GENERATOR ASSIGNMENT'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _assignmentMode = 'id'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _assignmentMode == 'id' ? AppColors.primary : AppColors.surfaceContainer,
                      foregroundColor: _assignmentMode == 'id' ? Colors.white : AppColors.textSecondary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text('Generator ID', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _assignmentMode = 'capacity'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _assignmentMode == 'capacity' ? AppColors.primary : AppColors.surfaceContainer,
                      foregroundColor: _assignmentMode == 'capacity' ? Colors.white : AppColors.textSecondary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text('Capacity', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
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

            // Date Range Picker
            _buildFieldLabel('BOOKING DATES'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectDateRange(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppDimensions.functionalRadius),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${DateFormat('MMM dd').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}',
                            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_endDate.difference(_startDate).inDays + 1} days',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

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
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: widget.onClose,
            child: Text('CANCEL', style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
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

                final updatedBooking = Booking(
                  id: widget.booking.id,
                  vendorId: _selectedVendorId!,
                  vendorName: vendorName,
                  generatorId: genId,
                  capacity: _capacityController.text.trim(),
                  date: _startDate,
                  status: widget.booking.status,
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
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppTypography.labelCaps.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.functionalRadius),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.functionalRadius),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.functionalRadius),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
