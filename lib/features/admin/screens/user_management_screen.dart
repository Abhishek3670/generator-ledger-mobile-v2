import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/side_navigation_drawer.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _selectedUser = 'manohar';

  final List<Map<String, String>> _users = [
    {
      'username': 'manohar',
      'role': 'operator',
      'status': 'ACTIVE',
      'lastLogin': '2025-03-08',
      'created': '2025-02-15',
    },
    {
      'username': 'abhishek',
      'role': 'admin',
      'status': 'ACTIVE',
      'lastLogin': '2025-04-20',
      'created': '2025-02-09',
    },
    {
      'username': 'owner',
      'role': 'admin',
      'status': 'ACTIVE',
      'lastLogin': '2025-04-19',
      'created': '2025-02-09',
    },
  ];

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'USER ACCESS',
          style: AppTypography.headlineSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: SideNavigationDrawer(
        currentRoute: '/admin/users',
        onNavigate: (routePath) {
          context.go(routePath);
        },
        userName: 'Abhishek Sharma',
        userRole: 'Fleet Manager',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Create user modal opening')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Text(
                      'CREATE USER',
                      style: AppTypography.labelCaps.copyWith(color: Colors.white, fontSize: 10),
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
                itemCount: _users.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final initial = user['username']!.substring(0, 1).toUpperCase();
                  final isOperator = user['role'] == 'operator';

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
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.check, size: 12, color: AppColors.success),
                                  const SizedBox(width: 4),
                                  Text(
                                    user['status']!,
                                    style: AppTypography.labelCaps.copyWith(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.bold),
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
                                onPressed: () {},
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
                                onPressed: () {},
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
                    value: _selectedUser,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.expand_more, color: AppColors.textSecondary),
                    items: _users.map((user) {
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
                    ..._buildTableRows(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  List<TableRow> _buildTableRows() {
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

      final isAdminActive = _selectedUser == 'abhishek' || _selectedUser == 'owner';
      final isOperActive = _selectedUser == 'manohar';

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
