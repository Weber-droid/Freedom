import 'dart:developer';

import 'package:freedom/feature/location_search/data_sources/local_location_data_source.dart';
import 'package:freedom/feature/location_search/data_sources/location_remote_data_source.dart';
import 'package:freedom/feature/location_search/models/location_models.dart';
import 'package:freedom/feature/location_search/repository/models/PlacePrediction.dart';
import 'package:freedom/feature/location_search/repository/models/location.dart';

class LocationRepositoryImpl implements LocationRepository {
  LocationRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });
  final LocationRemoteDataSource remoteDataSource;
  final LocationLocalDataSource localDataSource;

  @override
  Future<List<PlacePrediction>> getPlacePredictions(String query) async {
    try {
      final models = await remoteDataSource.getPlacePredictions(query);
      log('Place predictions: ${models.length}');
      return models
          .map(
            (model) => PlacePrediction(
              placeId: model.placeId,
              description: model.description,
              mainText: model.mainText,
              secondaryText: model.secondaryText,
              types: model.types,
              iconType: model.iconType,
            ),
          )
          .toList();
    } catch (e) {
      log('Repository error: $e');
      return [];
    }
  }

  @override
  Future<Location?> getPlaceDetails(String placeId) async {
    try {
      final model = await remoteDataSource.getPlaceDetails(placeId);
      if (model == null) return null;

      await localDataSource.addToRecent(model);

      return Location(
        id: model.id,
        placeId: model.placeId,
        name: model.name,
        address: model.address,
        latitude: model.latitude,
        longitude: model.longitude,
        iconType: model.iconType,
        isFavorite: model.isFavorite,
      );
    } catch (e) {
      log('Repository error: $e');
      return null;
    }
  }

  @override
  Future<List<Location>> getSavedLocations() async {
    try {
      final models = await localDataSource.getSavedLocations();
      return models
          .map((model) => Location(
                id: model.id,
                placeId: model.placeId,
                name: model.name,
                address: model.address,
                latitude: model.latitude,
                longitude: model.longitude,
                iconType: model.iconType,
                isFavorite: true,
              ))
          .toList();
    } catch (e) {
      log('Repository error: $e');
      return [];
    }
  }

  @override
  Future<List<Location>> getRecentLocations() async {
    try {
      final models = await localDataSource.getRecentLocations();
      return models
          .map(
            (model) => Location(
              id: model.id,
              placeId: model.placeId,
              name: model.name,
              address: model.address,
              latitude: model.latitude,
              longitude: model.longitude,
              iconType: model.iconType,
              isFavorite: false,
            ),
          )
          .toList();
    } catch (e) {
      log('Repository error: $e');
      return [];
    }
  }

  @override
  Future<void> saveLocation(Location location) async {
    try {
      final model = LocationModel(
        id: location.id,
        placeId: location.placeId,
        name: location.name,
        address: location.address,
        latitude: location.latitude,
        longitude: location.longitude,
        iconType: location.iconType,
        isFavorite: true,
      );
      await localDataSource.saveLocation(model);
    } catch (e) {
      log('Repository error: $e');
      throw Exception('Failed to save location');
    }
  }

  @override
  Future<void> removeLocation(String locationId) async {
    try {
      await localDataSource.removeLocation(locationId);
    } catch (e) {
      log('Repository error: $e');
      throw Exception('Failed to remove location');
    }
  }

  @override
  Future<void> clearRecentLocations() async {
    try {
      await localDataSource.clearRecentLocations();
    } catch (e) {
      log('Repository error: $e');
      throw Exception('Failed to clear recent locations');
    }
  }
}

abstract class LocationRepository {
  Future<List<PlacePrediction>> getPlacePredictions(String query);
  Future<Location?> getPlaceDetails(String placeId);
  Future<List<Location>> getSavedLocations();
  Future<List<Location>> getRecentLocations();
  Future<void> saveLocation(Location location);
  Future<void> removeLocation(String locationId);
  Future<void> clearRecentLocations();
}
