import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/mock/mock_bookings.dart';
import '../../../data/mock/mock_vendors.dart';
import '../../../data/mock/mock_generators.dart';
import '../../../shared/widgets/modal_scaffold.dart';
import '../../../shared/widgets/assignment_mode_toggle.dart';
import '../../../shared/widgets/capacity_chip_selector.dart';
class AddBookingModal extends StatefulWidget {
  final VoidCallback onClose;
  final Function(MockBooking) onSave;
  final bool isVisible;

  const AddBookingModal({
    super.key,
    required this.onClose,
    required this.onSave,
    this.isVisible = true,
  });

  @override
  State<AddBookingModal> createState() => _AddBookingModalState();
}

class _AddBookingModalState extends State<AddBookingModal> {
  final _formKey = GlobalKey<FormState>();
  String _assignmentMode = 'id'; // 'id' or 'capacity'
  String _selectedCapacity = '50';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 4));
  String? _selectedVendorId;
  String? _selectedGeneratorId;
  final _capacityController = TextEditingController(text: '50 kVA');
  final _notesController = TextEditingController();

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
    return ModalScaffold(
      title: 'ADD BOOKING',
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
              initialValue: _selectedVendorId,
              hint: Text('Select Vendor', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              decoration: _inputDecoration(),
              items: mockVendors.map((vendor) {
                return DropdownMenuItem<String>(
                  value: vendor.id,
                  child: Text(vendor.name, style: AppTypography.bodyMedium),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedVendorId = value;
                });
              },
              validator: (value) => value == null ? 'Please select a vendor' : null,
            ),
            const SizedBox(height: 16),

            // Assignment Mode Segmented Toggle
            _buildFieldLabel('GENERATOR ASSIGNMENT'),
            const SizedBox(height: 8),
            AssignmentModeToggle(
              currentMode: _assignmentMode,
              onModeChanged: (mode) => setState(() => _assignmentMode = mode),
            ),
            const SizedBox(height: 16),

            if (_assignmentMode == 'id') ...[
              // Generator Dropdown
              _buildFieldLabel('GENERATOR'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedGeneratorId,
                hint: Text('Select Generator', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                decoration: _inputDecoration(),
                items: mockGenerators.map((gen) {
                  return DropdownMenuItem<String>(
                    value: gen.id,
                    child: Text(gen.id, style: AppTypography.bodyMedium),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGeneratorId = value;
                    final match = mockGenerators.firstWhere((g) => g.id == value);
                    _capacityController.text = match.capacity;
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
              CapacityChipSelector(
                selectedCapacity: _selectedCapacity,
                onCapacitySelected: (cap) {
                  setState(() {
                    _selectedCapacity = cap;
                    _capacityController.text = '$cap kVA';
                  });
                },
              ),
            ],
            const SizedBox(height: 16),

            // Date Range Selector
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
                final selectedVendor = mockVendors.firstWhere((v) => v.id == _selectedVendorId);
                String genId = _selectedGeneratorId ?? 'AUTO-ASSIGN';
                if (_assignmentMode == 'capacity') {
                  final match = mockGenerators.firstWhere(
                    (g) => g.capacity.contains(_selectedCapacity),
                    orElse: () => mockGenerators.first,
                  );
                  genId = match.id;
                }

                final newBooking = MockBooking(
                  id: 'BK-${DateTime.now().millisecondsSinceEpoch}',
                  vendorId: _selectedVendorId!,
                  vendorName: selectedVendor.name,
                  generatorId: genId,
                  capacity: _capacityController.text.trim(),
                  date: _startDate, // uses start date as main date representation
                  status: 'pending',
                );
                widget.onSave(newBooking);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.primary,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('CREATE', style: AppTypography.labelCaps.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
