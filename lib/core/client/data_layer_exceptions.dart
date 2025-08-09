// Exception classes
import 'package:freedom/feature/auth/repository/repository_exceptions.dart';

class ServerException implements Failure {
  ServerException(this.message);
  @override
  final String message;

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  NetworkException(this.message);
  final String message;
}

class CacheException implements Exception {
  CacheException(this.message);
  final String message;
}
