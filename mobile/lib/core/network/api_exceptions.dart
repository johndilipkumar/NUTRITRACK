/// Typed API exceptions for consistent error handling across the app.
library;

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException([
    super.message = 'No internet connection. Please check your network.',
  ]);
}

class AuthException extends ApiException {
  AuthException([super.message = 'Authentication failed. Please login again.'])
    : super(statusCode: 401);
}

class ServerException extends ApiException {
  ServerException([
    super.message = 'Something went wrong. Please try again later.',
  ]) : super(statusCode: 500);
}

class ValidationException extends ApiException {
  final Map<String, dynamic>? errors;

  ValidationException([
    super.message = 'Please check your input and try again.',
    this.errors,
  ]) : super(statusCode: 400);
}

class TimeoutException extends ApiException {
  TimeoutException([super.message = 'Request timed out. Please try again.']);
}

class NotFoundException extends ApiException {
  NotFoundException([super.message = 'The requested resource was not found.'])
    : super(statusCode: 404);
}
