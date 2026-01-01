import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'places_api_models.dart';

extension GooglePlacesServiceHelper on http.Client {
  /// Alternative reverse geocoding using Places API Nearby Search
  /// This is a workaround when Geocoding API is not enabled
  static Future<PlaceDetailsResponse> getPlaceFromCoordinatesViaPlaces({
    required http.Client client,
    required String apiKey,
    required String baseUrl,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final queryParams = <String, String>{
        'location': '$latitude,$longitude',
        'radius': '200', // Increased to 200 meters for better coverage
        'rankby': 'distance', // Prioritize closest results
        'key': apiKey,
      };

      final uri = Uri.parse(
        '$baseUrl/nearbysearch/json',
      ).replace(queryParameters: queryParams);

      final response = await client.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final firstResult = data['results'][0];

          final placeData = {
            'place_id': firstResult['place_id'],
            'name': firstResult['name'],
            'formatted_address': firstResult['vicinity'] ?? firstResult['name'],
            'geometry': firstResult['geometry'],
            'types': firstResult['types'],
          };

          return PlaceDetailsResponse(
            status: 'OK',
            result: PlaceDetails.fromJson(placeData),
          );
        } else {
          return PlaceDetailsResponse(
            status: data['status'],
            errorMessage: data['error_message'],
          );
        }
      } else {
        throw PlacesApiException('HTTP ${response.statusCode}', response.body);
      }
    } catch (e, stackTrace) {
      log('Places nearby search error: $e', stackTrace: stackTrace);
      throw PlacesApiException(
        'Failed to reverse geocode via Places',
        e.toString(),
      );
    }
  }
}
