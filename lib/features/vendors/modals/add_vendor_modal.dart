import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/vendor.dart';
import '../../../shared/widgets/modal_scaffold.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../core/services/form_defaults_service.dart';
import '../../../core/services/draft_service.dart';

class AddVendorModal extends ConsumerStatefulWidget {
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
  ConsumerState<AddVendorModal> createState() => _AddVendorModalState();
}

class _AddVendorModalState extends ConsumerState<AddVendorModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedCategory;
  final _draftService = DraftService();
  Timer? _autoSaveTimer;
  bool _listenersAdded = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkDraft();
      }
    });
  }

  Future<void> _checkDraft() async {
    final draft = await _draftService.loadDraft('add_vendor');
    if (draft != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Resume Draft?'),
          content: const Text('We found a saved draft of this vendor form. Would you like to resume editing?'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _draftService.clearDraft('add_vendor');
                _initFormDefaults();
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
      _initFormDefaults();
    }
  }

  void _initFormDefaults() {
    final defaults = ref.read(formDefaultsServiceProvider).getVendorDefaults();
    setState(() {
      _phoneController.text = '${defaults.countryCode} ';
      if (_selectedCategory == null) {
        _selectedCategory = 'retailer';
      }
    });
    _addListeners();
  }

  void _restoreDraft(Map<String, dynamic> draft) {
    setState(() {
      _nameController.text = draft['name'] ?? '';
      _locationController.text = draft['location'] ?? '';
      _phoneController.text = draft['phone'] ?? '';
      _notesController.text = draft['notes'] ?? '';
      _selectedCategory = draft['category'] ?? 'retailer';
    });
    _addListeners();
  }

  void _addListeners() {
    if (_listenersAdded) return;
    _nameController.addListener(_onFormChanged);
    _locationController.addListener(_onFormChanged);
    _phoneController.addListener(_onFormChanged);
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
      'name': _nameController.text,
      'location': _locationController.text,
      'phone': _phoneController.text,
      'notes': _notesController.text,
      'category': _selectedCategory,
    };
    await _draftService.saveDraft('add_vendor', draft);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
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
              onChanged: widget.initialCategory != null
                  ? null
                  : (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                      _onFormChanged();
                    },
              validator: (value) => value == null ? 'Please select a type' : null,
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
            label: 'CREATE',
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                final newVendor = Vendor(
                  id: 'VEN-${DateTime.now().millisecondsSinceEpoch}',
                  name: _nameController.text.trim(),
                  location: _locationController.text.trim(),
                  phone: _phoneController.text.trim(),
                  category: _selectedCategory!,
                );
                _autoSaveTimer?.cancel();
                await _draftService.clearDraft('add_vendor');
                widget.onSave(newVendor);
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
