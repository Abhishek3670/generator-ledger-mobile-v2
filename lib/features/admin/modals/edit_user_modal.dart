import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/modal_scaffold.dart';

class EditUserModal extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onClose;
  final Function(Map<String, dynamic>) onSave;
  final bool isVisible;

  const EditUserModal({
    super.key,
    required this.user,
    required this.onClose,
    required this.onSave,
    this.isVisible = true,
  });

  @override
  State<EditUserModal> createState() => _EditUserModalState();
}

class _EditUserModalState extends State<EditUserModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late String _selectedRole;
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user['username']);
    _selectedRole = widget.user['role'] ?? 'operator';
    _selectedStatus = widget.user['status'] ?? 'ACTIVE';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalScaffold(
      title: 'EDIT USER',
      isVisible: widget.isVisible,
      onClose: widget.onClose,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Username Field (disabled or read-only if username is identifier)
            _buildFieldLabel('USERNAME'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _usernameController,
              readOnly: true,
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
                }
              },
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
                widget.onSave({
                  ...widget.user,
                  'username': _usernameController.text.trim().toLowerCase(),
                  'role': _selectedRole,
                  'status': _selectedStatus,
                });
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
