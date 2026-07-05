import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/vendor.dart';
import '../../../shared/widgets/modal_scaffold.dart';

class AddVendorModal extends StatefulWidget {
  final VoidCallback onClose;
  final Function(Vendor) onSave;
  final bool isVisible;
  final String? initialCategory; // Optional: 'retailer' or 'rental'

  const AddVendorModal({
    super.key,
    required this.onClose,
    required this.onSave,
    this.isVisible = true,
    this.initialCategory,
  });

  @override
  State<AddVendorModal> createState() => _AddVendorModalState();
}

class _AddVendorModalState extends State<AddVendorModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalScaffold(
      title: 'ADD VENDOR',
      isVisible: widget.isVisible,
      onClose: widget.onClose,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vendor Name
            _buildFieldLabel('NAME'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              style: AppTypography.bodyMedium,
              decoration: _inputDecoration(hintText: 'Enter Vendor Name'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 16),

            // Location
            _buildFieldLabel('LOCATION'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationController,
              style: AppTypography.bodyMedium,
              decoration: _inputDecoration(hintText: 'Enter Location'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a location' : null,
            ),
            const SizedBox(height: 16),

            // Phone
            _buildFieldLabel('PHONE'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              style: AppTypography.bodyMedium,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration(hintText: 'Enter Phone Number'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a phone number' : null,
            ),
            const SizedBox(height: 16),

            // Category Selection
            _buildFieldLabel('TYPE'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              hint: Text('Select Category', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              decoration: _inputDecoration(),
              items: const [
                DropdownMenuItem<String>(
                  value: 'retailer',
                  child: Text('Retailer', style: TextStyle(fontSize: 14)),
                ),
                DropdownMenuItem<String>(
                  value: 'rental',
                  child: Text('Rental', style: TextStyle(fontSize: 14)),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              validator: (value) => value == null ? 'Please select a type' : null,
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
                final newVendor = Vendor(
                  id: 'VEN-${DateTime.now().millisecondsSinceEpoch}',
                  name: _nameController.text.trim(),
                  location: _locationController.text.trim(),
                  phone: _phoneController.text.trim(),
                  category: _selectedCategory!,
                );
                widget.onSave(newVendor);
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
