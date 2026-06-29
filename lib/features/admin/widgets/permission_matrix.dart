import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class PermissionMatrix extends StatefulWidget {
  final Map<String, bool> permissions;
  final Function(String, bool)? onChanged;

  const PermissionMatrix({
    super.key,
    required this.permissions,
    this.onChanged,
  });

  @override
  State<PermissionMatrix> createState() => _PermissionMatrixState();
}

class _PermissionMatrixState extends State<PermissionMatrix> {
  late Map<String, bool> _localPermissions;

  @override
  void initState() {
    super.initState();
    _localPermissions = Map.from(widget.permissions);
  }

  @override
  void didUpdateWidget(covariant PermissionMatrix oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.permissions != widget.permissions) {
      setState(() {
        _localPermissions = Map.from(widget.permissions);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _localPermissions.entries.map((entry) {
          final isLast = entry.key == _localPermissions.keys.last;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key.toUpperCase().replaceAll('_', ' '),
                            style: AppTypography.labelCaps.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getPermissionDescription(entry.key),
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: entry.value,
                      activeThumbColor: AppColors.success,
                      activeTrackColor: AppColors.successBg,
                      onChanged: (newValue) {
                        setState(() {
                          _localPermissions[entry.key] = newValue;
                        });
                        if (widget.onChanged != null) {
                          widget.onChanged!(entry.key, newValue);
                        }
                      },
                    ),
                  ],
                ),
              ),
              if (!isLast) const Divider(color: AppColors.border, height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _getPermissionDescription(String key) {
    switch (key.toLowerCase()) {
      case 'manage_generators':
        return 'Create, update, and retire genset fleet items.';
      case 'manage_bookings':
        return 'Approve, modify, or cancel vendor bookings.';
      case 'view_billing':
        return 'Access and export financial ledger statements.';
      case 'manage_users':
        return 'Edit administrative permissions and add managers.';
      case 'system_monitoring':
        return 'View runtime performance and health indicators.';
      default:
        return 'Grant permission privilege to user account.';
    }
  }
}
