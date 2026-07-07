import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/mock/mock_generators.dart';
import '../../../shared/widgets/modal_scaffold.dart';
import '../../../shared/widgets/capacity_chip_selector.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../core/services/form_defaults_service.dart';
import '../../../core/services/draft_service.dart';

class AddGeneratorModal extends ConsumerStatefulWidget {
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
  ConsumerState<AddGeneratorModal> createState() => _AddGeneratorModalState();
}

class _AddGeneratorModalState extends ConsumerState<AddGeneratorModal> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _typeController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedCapacity;
  String? _capacityError;
  String? _selectedCategory;
  String _selectedStatus = 'active';
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
    final draft = await _draftService.loadDraft('add_generator');
    if (draft != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Resume Draft?'),
          content: const Text('We found a saved draft of this generator form. Would you like to resume editing?'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _draftService.clearDraft('add_generator');
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
    final defaults = ref.read(formDefaultsServiceProvider).getGeneratorDefaults();
    setState(() {
      _selectedCategory ??= defaults.category;
      _selectedStatus = defaults.status;
      _selectedCapacity = defaults.capacity;
      _typeController.text = defaults.type;
    });
    _addListeners();
  }

  void _restoreDraft(Map<String, dynamic> draft) {
    setState(() {
      _idController.text = draft['id'] ?? '';
      _typeController.text = draft['type'] ?? '';
      _notesController.text = draft['notes'] ?? '';
      _selectedCapacity = draft['capacity'];
      _selectedCategory = draft['category'] ?? 'retailer';
      _selectedStatus = draft['status'] ?? 'active';
    });
    _addListeners();
  }

  void _addListeners() {
    if (_listenersAdded) return;
    _idController.addListener(_onFormChanged);
    _typeController.addListener(_onFormChanged);
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
      'id': _idController.text,
      'type': _typeController.text,
      'notes': _notesController.text,
      'capacity': _selectedCapacity,
      'category': _selectedCategory,
      'status': _selectedStatus,
    };
    await _draftService.saveDraft('add_generator', draft);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
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
            AppTextField(
              labelText: 'GENERATOR ID',
              hintText: 'e.g. GEN-250KVA-XT',
              controller: _idController,
              validator: (value) => value == null || value.trim().isEmpty ? 'Please enter generator ID' : null,
            ),
            const SizedBox(height: 16),

            // Capacity Chips Selector
            _buildFieldLabel('CAPACITY (kVA)'),
            const SizedBox(height: 8),
            CapacityChipSelector(
              selectedCapacity: _selectedCapacity,
              onCapacitySelected: (cap) {
                setState(() {
                  _selectedCapacity = cap;
                  _capacityError = null;
                });
                _onFormChanged();
              },
            ),
            if (_capacityError != null)
              _buildValidationError(_capacityError!),
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
              onChanged: widget.initialCategory != null
                  ? null
                  : (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                      _onFormChanged();
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
                _onFormChanged();
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
              setState(() {
                _capacityError = _selectedCapacity == null ? 'Please select capacity' : null;
              });
              final isFormValid = _formKey.currentState?.validate() ?? false;
              if (isFormValid && _selectedCapacity != null) {
                final newGen = MockGenerator(
                  id: _idController.text.trim().toUpperCase(),
                  capacity: '$_selectedCapacity kVA',
                  type: _typeController.text.trim(),
                  status: _selectedStatus,
                  category: _selectedCategory!,
                );
                _autoSaveTimer?.cancel();
                await _draftService.clearDraft('add_generator');
                widget.onSave(newGen);
              }
            },
            variant: AppButtonVariant.accent,
          ),
        ],
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
