// Exception classes
class ServerException implements Exception {
  ServerException(this.message);
  final String message;
}

class NetworkException implements Exception {
  NetworkException(this.message);
  final String message;
}

class CacheException implements Exception {
  CacheException(this.message);
  final String message;
}