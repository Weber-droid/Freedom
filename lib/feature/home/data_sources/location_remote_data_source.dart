import 'dart:developer';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:freedom/feature/home/models/location_models.dart';
import 'package:freedom/feature/home/models/prediction_model.dart';

abstract class LocationRemoteDataSource {
  Future<List<PlacePredictionModel>> getPlacePredictions(String query);
  Future<LocationModel?> getPlaceDetails(String placeId);
}

class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  LocationRemoteDataSourceImpl({GoogleMapsPlaces? placesApi})
      : _placesApi = placesApi ??
            GoogleMapsPlaces(apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']);
  final GoogleMapsPlaces _placesApi;

  @override
  Future<List<PlacePredictionModel>> getPlacePredictions(String query) async {
    log('query: $query');
    if (query.isEmpty) {
      return [];
    }

    try {
      final response = await _placesApi.autocomplete(
        query,
        language: 'en',
      );
      log('response: ${response.predictions.length}');
      if (response.status == 'OK') {
        return response.predictions.map((prediction) {
          final mainText = prediction.structuredFormatting?.mainText ??
              prediction.description;
          final secondaryText =
              prediction.structuredFormatting?.secondaryText ?? '';

          return PlacePredictionModel(
            placeId: prediction.placeId!,
            description: prediction.description!,
            mainText: mainText!,
            secondaryText: secondaryText,
            types: prediction.types,
            iconType:
                PlacePredictionModel.getIconForPlaceType(prediction.types),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      log('Places API Error: $e');
      throw Exception('Failed to fetch place predictions');
    }
  }

  @override
  Future<LocationModel?> getPlaceDetails(String placeId) async {
    try {
      final response = await _placesApi.getDetailsByPlaceId(placeId);

      if (response.status == 'OK') {
        final place = response.result;
        return LocationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          placeId: place.placeId,
          name: place.name,
          address: place.formattedAddress ?? '',
          latitude: place.geometry!.location.lat,
          longitude: place.geometry!.location.lng,
          iconType: PlacePredictionModel.getIconForPlaceType(place.types),
        );
      }
      return null;
    } catch (e) {
      print('Places API Error: $e');
      throw Exception('Failed to fetch place details');
    }
  }
}
