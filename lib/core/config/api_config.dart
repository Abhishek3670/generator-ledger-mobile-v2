/// API Configuration for Backend Integration
///
/// Environment-specific configuration for connecting to the FastAPI backend.
/// The backend runs on PROD (192.162.29.71) and DEV (192.162.29.60) servers.

class ApiConfig {
  /// Current environment (dev, prod, or local)
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );

  /// Base URL for API requests (without trailing slash)
  static String get baseUrl {
    switch (environment) {
      case 'prod':
        return 'http://192.162.29.71:8000/api';
      case 'dev':
        return 'http://192.162.29.60:8000/api';
      case 'local':
        return 'http://localhost:8000/api';
      default:
        return 'http://192.162.29.60:8000/api'; // Default to DEV
    }
  }

  /// Connection timeout for HTTP requests
  static const Duration connectTimeout = Duration(seconds: 30);

  /// Receive timeout for HTTP responses
  static const Duration receiveTimeout = Duration(seconds: 60);

  /// Default headers for all requests
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Backend API version
  static const String backendVersion = '4.0.4';

  /// PostgreSQL connection (for reference only - not used by mobile app)
  /// Database is accessed via API, not direct connection
  static const String databaseInfo = 'PostgreSQL on 192.162.29.71:7865 (Docker)';
}
