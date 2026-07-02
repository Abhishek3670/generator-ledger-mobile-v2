import '../../shared/models/user.dart';

final List<User> mockUsers = [
  User(
    username: 'manohar',
    role: 'operator',
    status: 'ACTIVE',
    lastLogin: DateTime.utc(2025, 3, 8),
    createdAt: DateTime.utc(2025, 2, 15),
  ),
  User(
    username: 'abhishek',
    role: 'admin',
    status: 'ACTIVE',
    lastLogin: DateTime.utc(2025, 4, 20),
    createdAt: DateTime.utc(2025, 2, 9),
  ),
  User(
    username: 'owner',
    role: 'admin',
    status: 'ACTIVE',
    lastLogin: DateTime.utc(2025, 4, 19),
    createdAt: DateTime.utc(2025, 2, 9),
  ),
];
