class ApiException implements Exception {
  const ApiException({
    this.statusCode,
    required this.message,
    this.originalError,
  });

  final int? statusCode;
  final String message;
  final Object? originalError;

  factory ApiException.network([Object? originalError]) {
    return ApiException(
      message: 'Network error. Please check your connection.',
      originalError: originalError,
    );
  }

  factory ApiException.unauthorized([Object? originalError]) {
    return ApiException(
      statusCode: 401,
      message: 'Unauthorized. Please log in again.',
      originalError: originalError,
    );
  }

  factory ApiException.serverError({
    int statusCode = 500,
    Object? originalError,
  }) {
    return ApiException(
      statusCode: statusCode,
      message: 'Server error. Please try again later.',
      originalError: originalError,
    );
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
