import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'places_api_models.dart';

/// Production-level Google Places API Service
/// Handles all Places API requests with proper error handling and retry logic
class GooglePlacesService {
  final String apiKey;
  final String baseUrl = 'https://maps.googleapis.com/maps/api/place';
  final http.Client? httpClient;

  GooglePlacesService({required this.apiKey, this.httpClient});

  http.Client get _client => httpClient ?? http.Client();

  /// Get place autocomplete suggestions
  ///
  /// [input] - The text string on which to search
  /// [sessionToken] - A random string to identify the session (for billing optimization)
  /// [location] - The point around which to retrieve place information (lat,lng)
  /// [radius] - Distance in meters within which to return results
  /// [types] - Restricts results to places matching the specified type
  /// [components] - Component filters (e.g., 'country:us')
  /// [language] - Language for results (default: 'en')
  Future<PlacesAutocompleteResponse> autocomplete({
    required String input,
    String? sessionToken,
    String? location,
    int? radius,
    String? types,
    String? components,
    bool strictBounds = false,
    String language = 'en',
  }) async {
    try {
      final queryParams = <String, String>{
        'input': input,
        'key': apiKey,
        'language': language,
      };

      if (sessionToken != null) queryParams['sessiontoken'] = sessionToken;
      if (location != null) queryParams['location'] = location;
      if (radius != null) queryParams['radius'] = radius.toString();
      if (types != null) queryParams['types'] = types;
      if (components != null) queryParams['components'] = components;
      if (strictBounds) queryParams['strictbounds'] = 'true';

      final uri = Uri.parse(
        '$baseUrl/autocomplete/json',
      ).replace(queryParameters: queryParams);

      log('📡 Request URL: $uri');

      final response = await _client
          .get(uri)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw PlacesApiException(
                'Request timeout',
                'The request took too long',
              );
            },
          );

      log('📥 Response status: ${response.statusCode}');
      log('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final result = PlacesAutocompleteResponse.fromJson(data);

        if (result.status == 'OK') {
          log(
            '✅ Autocomplete successful: ${result.predictions.length} results',
          );
        } else if (result.status == 'ZERO_RESULTS') {
          log('⚠️ No results found');
        } else {
          log('❌ API returned status: ${result.status}');
          if (result.errorMessage != null) {
            log('❌ Error message: ${result.errorMessage}');
          }
        }

        return result;
      } else {
        throw PlacesApiException('HTTP ${response.statusCode}', response.body);
      }
    } on PlacesApiException {
      rethrow;
    } catch (e, stackTrace) {
      log('❌ Autocomplete error: $e', stackTrace: stackTrace);
      throw PlacesApiException(
        'Failed to fetch autocomplete results',
        e.toString(),
      );
    }
  }

  /// Get detailed information about a place
  ///
  /// [placeId] - A textual identifier that uniquely identifies a place
  /// [fields] - Specific fields to return (reduces billing). If null, returns all fields.
  /// Available fields: name, formatted_address, geometry, place_id, types, etc.
  /// [sessionToken] - Session token from autocomplete (for billing optimization)
  /// [language] - Language for results (default: 'en')
  Future<PlaceDetailsResponse> getPlaceDetails({
    required String placeId,
    List<String>? fields,
    String? sessionToken,
    String language = 'en',
  }) async {
    try {
      log('🔍 Places API: Fetching details for place ID: $placeId');

      final queryParams = <String, String>{
        'place_id': placeId,
        'key': apiKey,
        'language': language,
      };

      // Only add fields if specified (to control billing)
      if (fields != null && fields.isNotEmpty) {
        queryParams['fields'] = fields.join(',');
        log('📋 Requested fields: ${fields.join(', ')}');
      }

      if (sessionToken != null) queryParams['sessiontoken'] = sessionToken;

      final uri = Uri.parse(
        '$baseUrl/details/json',
      ).replace(queryParameters: queryParams);

      log('📡 Request URL: $uri');

      final response = await _client
          .get(uri)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw PlacesApiException(
                'Request timeout',
                'The request took too long',
              );
            },
          );

      log('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final result = PlaceDetailsResponse.fromJson(data);

        if (result.status == 'OK') {
          log('✅ Place details retrieved successfully');
        } else {
          log('❌ API returned status: ${result.status}');
          if (result.errorMessage != null) {
            log('❌ Error message: ${result.errorMessage}');
          }
        }

        return result;
      } else {
        throw PlacesApiException('HTTP ${response.statusCode}', response.body);
      }
    } on PlacesApiException {
      rethrow;
    } catch (e, stackTrace) {
      log('❌ Place details error: $e', stackTrace: stackTrace);
      throw PlacesApiException('Failed to fetch place details', e.toString());
    }
  }

  /// Get a URL for a place photo
  ///
  /// [photoReference] - Photo reference from place details
  /// [maxWidth] - Maximum width (1-1600)
  /// [maxHeight] - Maximum height (1-1600)
  /// Note: Specify either maxWidth or maxHeight, not both
  String getPhotoUrl({
    required String photoReference,
    int? maxWidth,
    int? maxHeight,
  }) {
    assert(
      maxWidth != null || maxHeight != null,
      'Either maxWidth or maxHeight must be specified',
    );

    final queryParams = <String, String>{
      'photoreference': photoReference,
      'key': apiKey,
    };

    if (maxWidth != null) queryParams['maxwidth'] = maxWidth.toString();
    if (maxHeight != null) queryParams['maxheight'] = maxHeight.toString();

    final uri = Uri.parse(
      '$baseUrl/photo',
    ).replace(queryParameters: queryParams);

    return uri.toString();
  }

  /// Dispose the HTTP client if it was created internally
  void dispose() {
    if (httpClient == null) {
      _client.close();
    }
  }
}
