import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:freedom/core/services/places_service/google_places_api_service.dart';
import 'package:freedom/core/services/places_service/places_api_models.dart';
import 'package:freedom/feature/home/models/location_models.dart';
import 'package:freedom/feature/home/models/prediction_model.dart';

abstract class LocationRemoteDataSource {
  Future<List<PlacePredictionModel>> getPlacePredictions(String query);
  Future<LocationModel?> getPlaceDetails(String placeId);
  Future<LocationModel?> getPlaceFromCoordinates(double lat, double lng);
}

class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  LocationRemoteDataSourceImpl({GooglePlacesService? placesService})
    : _placesService =
          placesService ??
          GooglePlacesService(apiKey: dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '');

  final GooglePlacesService _placesService;

  @override
  Future<LocationModel?> getPlaceFromCoordinates(double lat, double lng) async {
    try {
      final response = await _placesService.getPlaceFromCoordinates(
        latitude: lat,
        longitude: lng,
      );

      if (response.isOk && response.result != null) {
        final place = response.result!;

        final model = LocationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          placeId: place.placeId,
          name: place.name,
          address: place.formattedAddress ?? '',
          latitude: place.geometry?.location.lat ?? lat,
          longitude: place.geometry?.location.lng ?? lng,
          iconType: PlacePredictionModel.getIconForPlaceType(place.types),
        );
        return model;
      }
      if (response.errorMessage != null) {
        print('RemoteDataSource: Error message: ${response.errorMessage}');
      }
      return null;
    } catch (e) {
      log('Reverse Geocode Error: $e');
      return null;
    }
  }

  @override
  Future<List<PlacePredictionModel>> getPlacePredictions(String query) async {
    log('query: $query');

    if (query.isEmpty) {
      return [];
    }

    try {
      final response = await _placesService.autocomplete(
        input: query,
        language: 'en',
      );

      log('response: ${response.predictions.length}');

      if (response.isOk) {
        return response.predictions.map((prediction) {
          final mainText =
              prediction.structuredFormatting?.mainText ??
              prediction.description;
          final secondaryText =
              prediction.structuredFormatting?.secondaryText ?? '';

          return PlacePredictionModel(
            placeId: prediction.placeId,
            description: prediction.description,
            mainText: mainText,
            secondaryText: secondaryText,
            types: prediction.types,
            iconType: PlacePredictionModel.getIconForPlaceType(
              prediction.types,
            ),
          );
        }).toList();
      }

      // Handle specific error cases
      if (response.status == 'REQUEST_DENIED') {
        log('REQUEST_DENIED: ${response.errorMessage}');
        throw Exception(
          'Places API access denied. Please check your API key and billing settings.',
        );
      }

      if (response.status == 'INVALID_REQUEST') {
        log('INVALID_REQUEST: ${response.errorMessage}');
        throw Exception('Invalid request parameters.');
      }

      return [];
    } on PlacesApiException catch (e) {
      log('Places API Exception: ${e.message}');
      if (e.details != null) {
        log('Details: ${e.details}');
      }
      throw Exception('Failed to fetch place predictions: ${e.message}');
    } catch (e) {
      log('Places API Error: $e');
      throw Exception('Failed to fetch place predictions');
    }
  }

  @override
  Future<LocationModel?> getPlaceDetails(String placeId) async {
    try {
      // Request only the fields we need to reduce billing costs
      final response = await _placesService.getPlaceDetails(
        placeId: placeId,
        fields: ['place_id', 'name', 'formatted_address', 'geometry', 'types'],
      );

      if (response.isOk && response.result != null) {
        final place = response.result!;

        return LocationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          placeId: place.placeId,
          name: place.name,
          address: place.formattedAddress ?? '',
          latitude: place.geometry?.location.lat ?? 0.0,
          longitude: place.geometry?.location.lng ?? 0.0,
          iconType: PlacePredictionModel.getIconForPlaceType(place.types),
        );
      }

      // Handle specific error cases
      if (response.status == 'REQUEST_DENIED') {
        log('REQUEST_DENIED: ${response.errorMessage}');
        throw Exception(
          'Places API access denied. Please check your API key and billing settings.',
        );
      }

      if (response.status == 'INVALID_REQUEST') {
        log('INVALID_REQUEST: ${response.errorMessage}');
        throw Exception('Invalid place ID.');
      }

      if (response.status == 'NOT_FOUND') {
        log('Place not found for ID: $placeId');
        return null;
      }

      return null;
    } on PlacesApiException catch (e) {
      log('Places API Exception: ${e.message}');
      if (e.details != null) {
        log('Details: ${e.details}');
      }
      throw Exception('Failed to fetch place details: ${e.message}');
    } catch (e) {
      log('Places API Error: $e');
      throw Exception('Failed to fetch place details');
    }
  }

  /// Dispose resources
  void dispose() {
    _placesService.dispose();
  }
}
