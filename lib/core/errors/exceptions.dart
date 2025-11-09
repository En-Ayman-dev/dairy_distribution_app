class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}

class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
}

class AuthenticationException implements Exception {
  final String message;
  AuthenticationException(this.message);
}