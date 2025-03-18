import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:freedom/core/client/data_layer_exceptions.dart';
import 'package:http/http.dart' as http;

class BaseApiClients {
  BaseApiClients({required this.baseUrl, Map<String, String>? headers})
      : _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    ...?headers,
  };
  final String baseUrl;
  final Map<String, String> _headers;

  Future<http.Response> get(
      String endPoint, {
        Map<String, dynamic>? queryParameters,
        Map<String, String>? headers,
      }) async {
    try {
      final uri = _buildUri(endPoint, queryParameters: queryParameters);
      final response = await http
          .get(
        uri,
        headers: headers ?? _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Request timed out'),
      );

      return _handleResponse(response);
    } on TimeoutException {
      throw TimeoutException('Request timed out');
    } on NetworkException {
      throw NetworkException('No internet connection');
    }
  }

  Future<http.Response> post(
      String endPoint, {
        required Map<String, dynamic> body,
        Map<String, dynamic>? queryParameters,
        Map<String, String>? headers,
      }) async {
    try {
      final uri = _buildUri(endPoint, queryParameters: queryParameters);
      final encodedBody = json.encode(body);

      // Create default headers with content-type if not provided
      final Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ..._headers, // Merge with existing headers
        ...?headers, // Merge with provided headers (will override if same key)
      };

      // Log request details for debugging
      log('POST Request: $uri');
      log('Headers: $requestHeaders');
      log('Body: $encodedBody');

      final response = await http
          .post(
        uri,
        headers: requestHeaders,
        body: encodedBody,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Request timed out'),
      );

      // Log response for debugging
      log('Response Status: ${response.statusCode}');
      log('Response Body: ${response.body}');

      return _handleResponse(response);
    } on TimeoutException {
      throw TimeoutException('Request timed out');
    } on NetworkException {
      throw NetworkException('No internet connection');
    } catch (e) {
      // Log any other exceptions
      log('Unexpected error in POST request: $e');
      rethrow;
    }
  }

  Future<http.Response> put(
      String endPoint, {
        required Map<String, dynamic> body,
        Map<String, dynamic>? queryParameters,
        Map<String, String>? headers,
      }) async {
    try {
      final uri = _buildUri(endPoint, queryParameters: queryParameters);
      final encodedBody = json.encode(body);

      final response = await http
          .put(
        uri,
        headers: headers ?? _headers,
        body: encodedBody,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Request timed out'),
      );

      return _handleResponse(response);
    } on TimeoutException {
      throw TimeoutException('Request timed out');
    } on NetworkException {
      throw NetworkException('No internet connection');
    }
  }

  Future<http.Response> patch(
      String endPoint, {
        required Map<String, dynamic> body,
        Map<String, dynamic>? queryParameters,
        Map<String, String>? headers,
      }) async {
    try {
      final encodedBody = json.encode(body);
      final uri = _buildUri(endPoint, queryParameters: queryParameters);
      final response = await http
          .patch(
        uri,
        headers: headers ?? _headers,
        body: encodedBody,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Request timed out'),
      );
      return _handleResponse(response);
    } on TimeoutException {
      throw TimeoutException('Request timed out');
    } on NetworkException {
      throw NetworkException('No internet connection');
    }
  }

  Future<http.Response> delete(
      String endPoint, {
        Map<String, dynamic>? queryParameters,
        Map<String, String>? headers,
      }) async {
    try {
      final uri = _buildUri(endPoint, queryParameters: queryParameters);
      final response = await http
          .delete(
        uri,
        headers: headers ?? _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Request timed out'),
      );
      return _handleResponse(response);
    } on TimeoutException {
      throw TimeoutException('Request timed out');
    } on NetworkException {
      throw NetworkException('No internet connection');
    }
  }

  Uri _buildUri(String endPoint, {Map<String, dynamic>? queryParameters}) {
    log('logging: ${Uri.parse('$baseUrl$endPoint').replace(queryParameters: queryParameters)}');
    final parsedValue = Uri.parse('$baseUrl$endPoint').replace(
      queryParameters: queryParameters,
    );
    return parsedValue;
  }

  http.Response _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return response;
      case 400:
        throw BadRequestException(response.body);
      case 401:
        throw UnauthorizedException(response.body);
      case 403:
        throw ForbiddenException(response.body);
      case 404:
        throw NotFoundException(response.body);
      case 500:
        throw InternalServerErrorException(response.body);
      default:
        throw NetworkException(
          'Error occurred with status code: ${response.statusCode}',
        );
    }
  }
}
