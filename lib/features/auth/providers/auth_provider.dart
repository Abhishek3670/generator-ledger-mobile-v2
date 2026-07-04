import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user.dart';

/// Provider to track the currently authenticated user.
final authProvider = StateProvider<User?>((ref) {
  // Return the default user "abhishek" (admin) for initial mock state.
  return User(
    username: 'abhishek',
    role: 'admin',
    status: 'ACTIVE',
    lastLogin: DateTime.utc(2025, 4, 20),
    createdAt: DateTime.utc(2025, 2, 9),
  );
});
