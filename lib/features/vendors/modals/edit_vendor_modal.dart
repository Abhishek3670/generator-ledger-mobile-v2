import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/vendor.dart';
import '../../../shared/widgets/modal_scaffold.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class EditVendorModal extends StatefulWidget {
  final Vendor vendor;
  final VoidCallback onClose;
  final Function(Vendor) onSave;
  final bool isVisible;

  const EditVendorModal({
    super.key,
    required this.vendor,
    required this.onClose,
    required this.onSave,
    this.isVisible = true,
  });

  @override
  State<EditVendorModal> createState() => _EditVendorModalState();
}

class _EditVendorModalState extends State<EditVendorModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _phoneController;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.vendor.name);
    _locationController = TextEditingController(text: widget.vendor.location);
    _phoneController = TextEditingController(text: widget.vendor.phone);
    _selectedCategory = widget.vendor.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalScaffold(
      title: 'EDIT VENDOR',
      isVisible: widget.isVisible,
      onClose: widget.onClose,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vendor Name
            AppTextField(
              labelText: 'NAME',
              hintText: 'Enter Vendor Name',
              controller: _nameController,
              validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 16),

            // Location
            AppTextField(
              labelText: 'LOCATION',
              hintText: 'Enter Location',
              controller: _locationController,
              validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a location' : null,
            ),
            const SizedBox(height: 16),

            // Phone
            AppTextField(
              labelText: 'PHONE',
              hintText: 'Enter Phone Number',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
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
          ],
        ),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppButton(
            label: 'CANCEL',
            onPressed: widget.onClose,
            variant: AppButtonVariant.ghost,
          ),
          const SizedBox(width: 12),
          AppButton(
            label: 'SAVE',
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                final updatedVendor = Vendor(
                  id: widget.vendor.id,
                  name: _nameController.text.trim(),
                  location: _locationController.text.trim(),
                  phone: _phoneController.text.trim(),
                  category: _selectedCategory!,
                );
                widget.onSave(updatedVendor);
              }
            },
            variant: AppButtonVariant.accent,
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
