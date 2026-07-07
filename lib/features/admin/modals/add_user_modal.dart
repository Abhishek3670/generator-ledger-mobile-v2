import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/draggable_form_sheet.dart';
import '../../../core/services/form_defaults_service.dart';
import '../../../core/services/draft_service.dart';

class AddUserModal extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final Function(Map<String, String>) onSave;
  final bool isVisible;

  const AddUserModal({
    super.key,
    required this.onClose,
    required this.onSave,
    this.isVisible = true,
  });

  @override
  ConsumerState<AddUserModal> createState() => _AddUserModalState();
}

class _AddUserModalState extends ConsumerState<AddUserModal> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'operator';
  String _selectedStatus = 'ACTIVE';
  final _draftService = DraftService();
  Timer? _autoSaveTimer;
  bool _listenersAdded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkDraft();
      }
    });
  }

  Future<void> _checkDraft() async {
    final draft = await _draftService.loadDraft('add_user');
    if (draft != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Resume Draft?'),
          content: const Text('We found a saved draft of this user form. Would you like to resume editing?'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _draftService.clearDraft('add_user');
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
    final defaults = ref.read(formDefaultsServiceProvider).getUserDefaults();
    setState(() {
      _selectedRole = defaults.role;
      _selectedStatus = defaults.status;
    });
    _addListeners();
  }

  void _restoreDraft(Map<String, dynamic> draft) {
    setState(() {
      _usernameController.text = draft['username'] ?? '';
      _passwordController.text = draft['password'] ?? '';
      _selectedRole = draft['role'] ?? 'operator';
      _selectedStatus = draft['status'] ?? 'ACTIVE';
    });
    _addListeners();
  }

  void _addListeners() {
    if (_listenersAdded) return;
    _usernameController.addListener(_onFormChanged);
    _passwordController.addListener(_onFormChanged);
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
      'username': _usernameController.text,
      'password': _passwordController.text,
      'role': _selectedRole,
      'status': _selectedStatus,
    };
    await _draftService.saveDraft('add_user', draft);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<bool> _onDismissAttempt() async {
    final isFormDirty = _usernameController.text.isNotEmpty ||
        _passwordController.text.isNotEmpty;

    if (!isFormDirty) {
      await _draftService.clearDraft('add_user');
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Draft?'),
        content: const Text('You have unsaved changes. Do you want to discard this draft or keep editing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Editing'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
              await _draftService.clearDraft('add_user');
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final formContent = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Username Field
          _buildFieldLabel('USERNAME'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _usernameController,
            style: AppTypography.bodyMedium,
            decoration: _inputDecoration(hintText: 'Enter username'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a username';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password Field
          _buildFieldLabel('PASSWORD'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            style: AppTypography.bodyMedium,
            decoration: _inputDecoration(hintText: 'Enter password'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a password';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Role Field
          _buildFieldLabel('ROLE'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedRole,
            decoration: _inputDecoration(),
            items: const [
              DropdownMenuItem(value: 'operator', child: Text('Operator')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedRole = val;
                });
                _onFormChanged();
              }
            },
          ),
          const SizedBox(height: 16),

          // Status Field
          _buildFieldLabel('STATUS'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedStatus,
            decoration: _inputDecoration(),
            items: const [
              DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
              DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedStatus = val;
                });
                _onFormChanged();
              }
            },
          ),
        ],
      ),
    );

    return DraggableFormSheet(
      title: 'Create User',
      category: 'users',
      onClose: widget.onClose,
      onDismissAttempt: _onDismissAttempt,
      footer: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              final dateStr = DateTime.now().toString().substring(0, 10);
              _autoSaveTimer?.cancel();
              await _draftService.clearDraft('add_user');
              widget.onSave({
                'username': _usernameController.text.trim().toLowerCase(),
                'role': _selectedRole,
                'status': _selectedStatus,
                'lastLogin': 'NEVER',
                'created': dateStr,
              });
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
