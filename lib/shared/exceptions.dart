import 'dart:convert';

// Base Exception class
abstract class ApiException implements Exception {
  ApiException(this._rawMessage);
  final String _rawMessage;

  String get message => parseErrorMessage(_rawMessage);
}

// HTTP status-related Exceptions
class BadRequestException extends ApiException {
  BadRequestException(super.message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message);
}

class ForbiddenException extends ApiException {
  ForbiddenException(super.message);
}

class NotFoundException extends ApiException {
  NotFoundException(super.message);
}

class InternalServerErrorException extends ApiException {
  InternalServerErrorException(super.message);
}

// Network-related Exceptions
class NetworkException extends ApiException {
  NetworkException(super.message);
}

// Local storage related Exceptions
class CacheException extends ApiException {
  CacheException(super.message);
}

// Validation-related Exceptions
class ValidationException extends ApiException {
  ValidationException(super.message);
}

// Authentication-related Exceptions
class AuthException extends ApiException {
  AuthException(super.message);
}

String parseErrorMessage(String jsonString) {
  try {
    // Try to decode the JSON string and cast the result
    final dynamic decoded = json.decode(jsonString);

    // Check if the decoded value is a Map
    if (decoded is Map<String, dynamic>) {
      final Map<String, dynamic> errorMap = decoded;

      // Look for common error message fields
      if (errorMap.containsKey('msg')) {
        return errorMap['msg'].toString();
      } else if (errorMap.containsKey('message')) {
        return errorMap['message'].toString();
      } else if (errorMap.containsKey('error')) {
        if (errorMap['error'] is String) {
          return errorMap['error'].toString();
        } else if (errorMap['error'] is Map &&
            (errorMap['error'] as Map).containsKey('message')) {
          return (errorMap['error'] as Map)['message'].toString();
        }
      }
    }

    // If no specific message field found, return the whole JSON as string
    return jsonString;
  } catch (e) {
    // If it's not valid JSON, just return the original string
    return jsonString;
  }
}