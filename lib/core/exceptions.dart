/// Typed exceptions used across the app.
///
/// [message] is always a human-readable Indonesian sentence that can be shown
/// directly in a SnackBar / dialog — never a raw stack trace.
class AppException implements Exception {
  final String message;

  /// HTTP status code if the error came from an API response, otherwise null.
  final int? statusCode;

  AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// The tenant key (x-app-key) is missing/invalid, or the user is not
/// authenticated (401). Session should be cleared and the user sent to login.
class UnauthorizedException extends AppException {
  UnauthorizedException(super.message, {super.statusCode});
}

/// Credentials or request payload rejected by the API (400/403/404/409...).
class ApiException extends AppException {
  ApiException(super.message, {super.statusCode});
}

/// No internet / DNS failure / connection refused.
class NetworkException extends AppException {
  NetworkException(super.message);
}

/// Server took too long to answer.
class TimeoutException extends AppException {
  TimeoutException(super.message);
}

/// Response could not be parsed as the documented JSON envelope.
class FormatException extends AppException {
  FormatException(super.message);
}
