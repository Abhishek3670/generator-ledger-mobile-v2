import '../../data/mock/mock_bookings.dart';
import '../../data/mock/mock_generators.dart';
import '../../data/mock/mock_system_health.dart';
import '../../data/mock/mock_users.dart';
import '../../data/mock/mock_vendors.dart';
import '../../shared/models/system_health.dart';
import '../../shared/models/user.dart';

class MockDataService {
  List<MockVendor> getVendors() => List.of(mockVendors);
  List<MockGenerator> getGenerators() => List.of(mockGenerators);
  List<MockBooking> getBookings() => List.of(mockBookings);
  List<User> getUsers() => List.of(mockUsers);
  SystemHealth getSystemHealth() => mockSystemHealth;
}
