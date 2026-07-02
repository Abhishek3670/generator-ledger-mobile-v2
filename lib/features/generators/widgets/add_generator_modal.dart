import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/mock/mock_generators.dart';
import '../../../shared/widgets/modal_scaffold.dart';

class AddGeneratorModal extends StatefulWidget {
  final VoidCallback onClose;
  final Function(MockGenerator) onSave;
  final bool isVisible;
  final String? initialCategory; // Optional: 'retailer', 'permanent', 'emergency'

  const AddGeneratorModal({
    super.key,
    required this.onClose,
    required this.onSave,
    this.isVisible = true,
    this.initialCategory,
  });

  @override
  State<AddGeneratorModal> createState() => _AddGeneratorModalState();
}

class _AddGeneratorModalState extends State<AddGeneratorModal> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _typeController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedCapacity = '100';
  String? _selectedCategory;
  String _selectedStatus = 'active';

  final List<String> _capacityOptions = const ['25', '50', '100', '250'];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
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
    return ModalScaffold(
      title: 'ADD GENERATOR',
      isVisible: widget.isVisible,
      onClose: widget.onClose,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Generator ID
            _buildFieldLabel('GENERATOR ID'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _idController,
              style: AppTypography.bodyMedium,
              decoration: _inputDecoration(hintText: 'e.g. GEN-250KVA-XT'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Please enter generator ID' : null,
            ),
            const SizedBox(height: 16),

            // Capacity Chips Selector
            _buildFieldLabel('CAPACITY (kVA)'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _capacityOptions.map((cap) {
                final isSelected = _selectedCapacity == cap;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCapacity = cap;
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
            const SizedBox(height: 16),

            // Type
            _buildFieldLabel('TYPE'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _typeController,
              style: AppTypography.bodyMedium,
              decoration: _inputDecoration(hintText: 'e.g. 6R / SL90 / HA'),
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
            _buildFieldLabel('NOTES (OPTIONAL)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              style: AppTypography.bodyMedium,
              decoration: _inputDecoration(hintText: 'Add any relevant details...'),
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
                final newGen = MockGenerator(
                  id: _idController.text.trim().toUpperCase(),
                  capacity: '$_selectedCapacity kVA',
                  type: _typeController.text.trim(),
                  status: _selectedStatus,
                  category: _selectedCategory!,
                );
                widget.onSave(newGen);
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
