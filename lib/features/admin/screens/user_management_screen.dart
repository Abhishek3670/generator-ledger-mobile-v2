import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/user.dart';
import '../providers/user_management_provider.dart';
import '../modals/add_user_modal.dart';
import '../modals/edit_user_modal.dart';
import '../../../shared/widgets/confirmation_dialog.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  String _selectedUser = 'manohar';
  bool _showCreateModal = false;
  bool _showEditModal = false;
  bool _showDeleteModal = false;
  Map<String, String>? _selectedUserForEdit;
  Map<String, String>? _selectedUserForDelete;

  final List<Map<String, dynamic>> _capabilities = [
    // System & Admin group
    {'group': 'System & Admin', 'name': 'Settings & User Admin', 'desc': 'Manage accounts', 'admin': true, 'oper': false},
    {'group': 'System & Admin', 'name': 'Monitor', 'desc': 'Live metrics', 'admin': true, 'oper': false},
    // Operations group
    {'group': 'Operations', 'name': 'Vendor Management', 'desc': 'Retailer/Rental', 'admin': true, 'oper': false},
    {'group': 'Operations', 'name': 'Generator Management', 'desc': 'Records', 'admin': true, 'oper': false},
    // Bookings & Billing group
    {'group': 'Bookings & Billing', 'name': 'Booking Create/Update', 'desc': 'Manage items', 'admin': true, 'oper': true},
    {'group': 'Bookings & Billing', 'name': 'Booking Delete', 'desc': 'Remove entries', 'admin': true, 'oper': false},
    {'group': 'Bookings & Billing', 'name': 'Billing Access', 'desc': 'APIs & Pages', 'admin': true, 'oper': false},
    // Data group
    {'group': 'Data & Views', 'name': 'Export', 'desc': 'API Export', 'admin': true, 'oper': false},
    {'group': 'Data & Views', 'name': 'Read-only Views', 'desc': 'Operational pages', 'admin': true, 'oper': true},
  ];

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(userProvider).map((user) => user.toMap()).toList();

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title and Header Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User Management',
                              style: AppTypography.displayLarge.copyWith(color: AppColors.primary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create users and control access roles.',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Existing Users Header
                  Text(
                    'EXISTING USERS',
                    style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),

                  // List of Users
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final initial = user['username']!.substring(0, 1).toUpperCase();
                      final isOperator = user['role'] == 'operator';
                      final isActive = user['status'] == 'ACTIVE';

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: isOperator
                                          ? AppColors.surfaceContainer
                                          : AppColors.primary,
                                      child: Text(
                                        initial,
                                        style: TextStyle(
                                          color: isOperator ? AppColors.primary : Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user['username']!,
                                          style: AppTypography.headlineSmall.copyWith(color: AppColors.primary, fontSize: 16),
                                        ),
                                        Text(
                                          user['role']!,
                                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isActive ? Icons.check : Icons.close,
                                        size: 12,
                                        color: isActive ? AppColors.success : AppColors.danger,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        user['status']!,
                                        style: AppTypography.labelCaps.copyWith(
                                          color: isActive ? AppColors.success : AppColors.danger,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: AppColors.surfaceContainer, height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'LAST LOGIN',
                                      style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary, fontSize: 9),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      user['lastLogin']!,
                                      style: AppTypography.bodySmall,
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'CREATED',
                                      style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary, fontSize: 9),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      user['created']!,
                                      style: AppTypography.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedUserForEdit = user;
                                        _showEditModal = true;
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.border),
                                      shape: const StadiumBorder(),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    child: Text(
                                      'EDIT',
                                      style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary, fontSize: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedUserForDelete = user;
                                        _showDeleteModal = true;
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                                      shape: const StadiumBorder(),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    child: Text(
                                      'DELETE',
                                      style: AppTypography.labelCaps.copyWith(color: AppColors.danger, fontSize: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Access Control Header
                  Text(
                    'ACCESS CONTROL',
                    style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Permission Matrix',
                        style: AppTypography.headlineMedium.copyWith(color: AppColors.primary),
                      ),
                      DropdownButton<String>(
                        value: users.any((u) => u['username'] == _selectedUser) ? _selectedUser : users.first['username'],
                        underline: const SizedBox(),
                        icon: const Icon(Icons.expand_more, color: AppColors.textSecondary),
                        items: users.map((user) {
                          return DropdownMenuItem<String>(
                            value: user['username'],
                            child: Text(
                              user['username']!,
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedUser = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Matrix Table Container
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(4),
                        1: FlexColumnWidth(2),
                        2: FlexColumnWidth(2),
                      },
                      border: const TableBorder(
                        horizontalInside: BorderSide(color: AppColors.surfaceContainer),
                      ),
                      children: [
                        // Header Row
                        TableRow(
                          decoration: const BoxDecoration(color: AppColors.surfaceContainer),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text('CAPABILITY', style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary, fontSize: 9)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text('ADMIN', style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary, fontSize: 9), textAlign: TextAlign.center),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text('OPER', style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary, fontSize: 9), textAlign: TextAlign.center),
                            ),
                          ],
                        ),

                        // Body Rows with Groups
                        ..._buildTableRows(users),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Modal Overlays
            if (_showCreateModal)
              AddUserModal(
                onClose: () => setState(() => _showCreateModal = false),
                onSave: (newUser) {
                  ref.read(userProvider.notifier).addUser(User.fromMap(newUser));
                  setState(() => _showCreateModal = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('User "${newUser['username']}" created successfully')),
                  );
                },
              ),

            if (_showEditModal && _selectedUserForEdit != null)
              EditUserModal(
                user: _selectedUserForEdit!,
                onClose: () => setState(() {
                  _showEditModal = false;
                  _selectedUserForEdit = null;
                }),
                onSave: (updatedUser) {
                  ref.read(userProvider.notifier).updateUser(
                        User.fromMap(updatedUser),
                        _selectedUserForEdit!['username']!,
                      );
                  setState(() {
                    _showEditModal = false;
                    _selectedUserForEdit = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('User "${updatedUser['username']}" updated successfully')),
                  );
                },
              ),

            if (_showDeleteModal && _selectedUserForDelete != null)
              ConfirmationDialog(
                title: 'DELETE USER',
                message: 'Are you sure you want to delete user "${_selectedUserForDelete!['username']}"? This action cannot be undone.',
                confirmText: 'DELETE',
                isDestructive: true,
                onCancel: () => setState(() {
                  _showDeleteModal = false;
                  _selectedUserForDelete = null;
                }),
                onConfirm: () {
                  ref
                      .read(userProvider.notifier)
                      .deleteUser(_selectedUserForDelete!['username']!);
                  setState(() {
                    _showDeleteModal = false;
                    _selectedUserForDelete = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User deleted successfully')),
                  );
                },
              ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _showCreateModal = true;
                  });
                },
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.primary,
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TableRow> _buildTableRows(List<Map<String, String>> users) {
    final List<TableRow> rows = [];
    String currentGroup = '';

    for (var capability in _capabilities) {
      if (capability['group'] != currentGroup) {
        currentGroup = capability['group'];
        rows.add(
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                child: Text(
                  currentGroup.toUpperCase(),
                  style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary, fontSize: 8),
                ),
              ),
              const SizedBox(),
              const SizedBox(),
            ],
          ),
        );
      }

      final activeUserMap =
          users.firstWhere((u) => u['username'] == _selectedUser, orElse: () => users.first);
      final isAdminActive = activeUserMap['role'] == 'admin';
      final isOperActive = activeUserMap['role'] == 'operator';

      final highlightAdmin = capability['admin'] == true && isAdminActive;
      final highlightOper = capability['oper'] == true && isOperActive;

      rows.add(
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    capability['name'],
                    style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    capability['desc'],
                    style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Center(
                child: Icon(
                  capability['admin'] == true ? Icons.check_circle : Icons.cancel,
                  color: capability['admin'] == true
                      ? (highlightAdmin ? AppColors.success : AppColors.success.withValues(alpha: 0.4))
                      : AppColors.danger.withValues(alpha: 0.3),
                  size: 20,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Center(
                child: Icon(
                  capability['oper'] == true ? Icons.check_circle : Icons.cancel,
                  color: capability['oper'] == true
                      ? (highlightOper ? AppColors.success : AppColors.success.withValues(alpha: 0.4))
                      : AppColors.danger.withValues(alpha: 0.3),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return rows;
  }
}
