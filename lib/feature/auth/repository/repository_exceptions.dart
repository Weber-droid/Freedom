
// Base Failure class for domain layer
abstract class Failure {
  Failure(this.message);
  final String message;
}

// HTTP status-related Failures
class BadRequestFailure extends Failure {
  BadRequestFailure(super.message);
}

class UnauthorizedFailure extends Failure {
  UnauthorizedFailure(super.message);
}

class ForbiddenFailure extends Failure {
  ForbiddenFailure(super.message);
}

class NotFoundFailure extends Failure {
  NotFoundFailure(super.message);
}

class ServerFailure extends Failure {
  ServerFailure(super.message);
}

// Network-related Failures
class NetworkFailure extends Failure {
  NetworkFailure(super.message);
}

// Local storage related Failures
class CacheFailure extends Failure {
  CacheFailure(super.message);
}

// Validation-related Failures
class ValidationFailure extends Failure {
  ValidationFailure(super.message);
}

// Authentication-related Failures
class AuthFailure extends Failure {
  AuthFailure(super.message);
}

// Generic Failure for unexpected situations
class UnexpectedFailure extends Failure {
  UnexpectedFailure([super.message = 'An unexpected error occurred.']);
}

