import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/mock/mock_generators.dart';
import '../../../shared/widgets/draggable_form_sheet.dart';
import '../../../shared/widgets/capacity_chip_selector.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class EditGeneratorModal extends StatefulWidget {
  final MockGenerator generator;
  final VoidCallback onClose;
  final Function(MockGenerator) onSave;
  final bool isVisible;

  const EditGeneratorModal({
    super.key,
    required this.generator,
    required this.onClose,
    required this.onSave,
    this.isVisible = true,
  });

  @override
  State<EditGeneratorModal> createState() => _EditGeneratorModalState();
}

class _EditGeneratorModalState extends State<EditGeneratorModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idController;
  late final TextEditingController _typeController;
  late final TextEditingController _notesController;
  late String _selectedCapacity;
  String? _selectedCategory;
  late String _selectedStatus;

  final List<String> _capacityOptions = const ['25', '50', '100', '250'];

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.generator.id);
    _typeController = TextEditingController(text: widget.generator.type);
    _notesController = TextEditingController(); // Notes are optional and start blank
    _selectedCategory = widget.generator.category;
    _selectedStatus = widget.generator.status;
    
    // Normalize capacity string (e.g., '250 kVA' or '250' -> select closest or extract number)
    final numMatch = RegExp(r'\d+').firstMatch(widget.generator.capacity);
    if (numMatch != null) {
      final capVal = numMatch.group(0)!;
      if (_capacityOptions.contains(capVal)) {
        _selectedCapacity = capVal;
      } else {
        _selectedCapacity = _capacityOptions.last; // Default fallback
      }
    } else {
      _selectedCapacity = '100';
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _typeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final formContent = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Generator ID
          AppTextField(
            labelText: 'GENERATOR ID',
            hintText: 'e.g. GEN-250KVA-XT',
            controller: _idController,
            validator: (value) => value == null || value.trim().isEmpty ? 'Please enter generator ID' : null,
          ),
          const SizedBox(height: 16),

          // Capacity Selector
          _buildFieldLabel('CAPACITY (kVA)'),
          const SizedBox(height: 8),
          CapacityChipSelector(
            selectedCapacity: _selectedCapacity,
            onCapacitySelected: (cap) {
              setState(() {
                _selectedCapacity = cap;
              });
            },
          ),
          const SizedBox(height: 16),

          // Type
          AppTextField(
            labelText: 'TYPE',
            hintText: 'e.g. 6R / SL90 / HA',
            controller: _typeController,
            validator: (value) => value == null || value.trim().isEmpty ? 'Please enter type' : null,
          ),
          const SizedBox(height: 16),

          // Category Selection
          _buildFieldLabel('CATEGORY'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            hint: Text('Select Category', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            decoration: _inputDecoration(),
            items: const [
              DropdownMenuItem<String>(
                value: 'retailer',
                child: Row(
                  children: [
                    Icon(Icons.storefront, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Retailer', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              DropdownMenuItem<String>(
                value: 'permanent',
                child: Row(
                  children: [
                    Icon(Icons.domain, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Permanent', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              DropdownMenuItem<String>(
                value: 'emergency',
                child: Row(
                  children: [
                    Icon(Icons.emergency_outlined, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Emergency', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
            validator: (value) => value == null ? 'Please select category' : null,
          ),
          const SizedBox(height: 16),

          // Status Selection
          _buildFieldLabel('STATUS'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedStatus,
            decoration: _inputDecoration(),
            items: const [
              DropdownMenuItem<String>(
                value: 'active',
                child: Text('Active', style: TextStyle(fontSize: 14)),
              ),
              DropdownMenuItem<String>(
                value: 'offline',
                child: Text('Offline', style: TextStyle(fontSize: 14)),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedStatus = value ?? 'active';
              });
            },
          ),
          const SizedBox(height: 16),

          // Notes
          AppTextField(
            labelText: 'NOTES (OPTIONAL)',
            hintText: 'Add any relevant details...',
            controller: _notesController,
          ),
        ],
      ),
    );

    return DraggableFormSheet(
      title: 'Edit Generator',
      category: 'generators',
      onClose: widget.onClose,
      footer: AppButton(
        label: 'SAVE',
        isFullWidth: true,
        onPressed: () {
          if (_formKey.currentState?.validate() ?? false) {
            final updatedGen = MockGenerator(
              id: _idController.text.trim().toUpperCase(),
              capacity: '$_selectedCapacity kVA',
              type: _typeController.text.trim(),
              status: _selectedStatus,
              category: _selectedCategory!,
            );
            widget.onSave(updatedGen);
          }
        },
        variant: AppButtonVariant.accent,
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
