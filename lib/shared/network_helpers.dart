import 'dart:convert';

import 'package:freedom/feature/auth/repository/repository_exceptions.dart';
import 'package:freedom/shared/exceptions.dart';

String parseApiErrorMessage(String message) {
  if (message.contains('{') && message.contains('}')) {
    try {
      final jsonStartIndex = message.indexOf('{');
      final jsonEndIndex = message.lastIndexOf('}') + 1;
      final jsonString = message.substring(jsonStartIndex, jsonEndIndex);

      final dynamic decoded = json.decode(jsonString);
      if (decoded is Map) {
        for (String key in ['msg', 'message', 'error']) {
          if (decoded.containsKey(key)) {
            if (decoded[key] is String) {
              return decoded[key].toString();
            }
          }
        }
      }
    } catch (e) {

    }
  }

  // If no JSON found or parsing failed, return the original message
  return message;
}

Failure handleException(dynamic exception) {
  // Get the user-friendly message
  final String userMessage = getUserFriendlyMessage(exception);

  // Map exception types to corresponding failure types
  if (exception is BadRequestException) {
    return BadRequestFailure(userMessage);
  } else if (exception is UnauthorizedException) {
    return UnauthorizedFailure(userMessage);
  } else if (exception is ForbiddenException) {
    return ForbiddenFailure(userMessage);
  } else if (exception is NotFoundException) {
    return NotFoundFailure(userMessage);
  } else if (exception is NetworkException) {
    return NetworkFailure(userMessage);
  } else if (exception is InternalServerErrorException) {
    return ServerFailure(userMessage);
  } else if (exception is CacheException) {
    return CacheFailure(userMessage);
  } else if (exception is ValidationException) {
    return ValidationFailure(userMessage);
  } else if (exception is AuthException) {
    return AuthFailure(userMessage);
  } else {
    return UnexpectedFailure(userMessage);
  }
}

// Convert error messages to user-friendly text
String getUserFriendlyMessage(dynamic exception) {
  // Get the raw message from the exception
  final String rawMessage =
      exception is ApiException ? exception.message : exception.toString();

  // Define common error message patterns and their user-friendly versions
  final Map<String, String> errorMessages = {
    'already exists with this phone number':
        'This phone number is already registered. Please use a different number or log in.',
    'Invalid phone number': 'Please enter a valid phone number.',
    'Network':
        'Connection error. Please check your internet connection and try again.',
    'timed out': 'Request timed out. Please try again later.',
    'Not Found':
        'The requested resource was not found. Please try again later.',
    'Unauthorized': 'Your session has expired. Please log in again.',
    'Invalid token': 'Your session has expired. Please log in again.',
  };

  // Check if the raw message contains any of the known patterns
  for (final entry in errorMessages.entries) {
    if (rawMessage.contains(entry.key)) {
      return entry.value;
    }
  }

  // If no match, return the original message with some formatting
  if (rawMessage.isNotEmpty) {
    String formattedMessage = rawMessage;

    // Capitalize first letter if it's not already
    if (formattedMessage.isNotEmpty &&
        formattedMessage[0].toLowerCase() == formattedMessage[0]) {
      formattedMessage =
          formattedMessage[0].toUpperCase() + formattedMessage.substring(1);
    }

    // Add period if needed
    if (formattedMessage.isNotEmpty &&
        !formattedMessage.endsWith('.') &&
        !formattedMessage.endsWith('!') &&
        !formattedMessage.endsWith('?')) {
      formattedMessage += '.';
    }

    return formattedMessage;
  }

  // Default message
  return 'An error occurred. Please try again.';
}
