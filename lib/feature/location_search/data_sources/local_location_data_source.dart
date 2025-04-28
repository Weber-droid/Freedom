import 'dart:convert';

import 'package:freedom/feature/location_search/models/location_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LocationLocalDataSource {
  Future<List<LocationModel>> getSavedLocations();
  Future<List<LocationModel>> getRecentLocations();
  Future<void> saveLocation(LocationModel location);
  Future<void> addToRecent(LocationModel location);
  Future<void> removeLocation(String locationId);
  Future<void> clearRecentLocations();
}

class LocationLocalDataSourceImpl implements LocationLocalDataSource {
  LocationLocalDataSourceImpl({required SharedPreferences prefs})
      : _prefs = prefs;
  final SharedPreferences _prefs;
  static const String _savedLocationsKey = 'saved_locations';
  static const String _recentLocationsKey = 'recent_locations';
  static const int _maxRecentLocations = 10;

  @override
  Future<List<LocationModel>> getSavedLocations() async {
    final locationStrings = _prefs.getStringList(_savedLocationsKey);

    if (locationStrings == null || locationStrings.isEmpty) {
      return [];
    }

    return locationStrings.map((string) {
      final json = jsonDecode(string) as Map<String, dynamic>;
      return LocationModel.fromJson(json);
    }).toList();
  }

  @override
  Future<List<LocationModel>> getRecentLocations() async {
    final locationStrings = _prefs.getStringList(_recentLocationsKey);

    if (locationStrings == null || locationStrings.isEmpty) {
      return [];
    }

    return locationStrings.map((string) {
      final json = jsonDecode(string) as Map<String, dynamic>;
      return LocationModel.fromJson(json);
    }).toList();
  }

  @override
  Future<void> saveLocation(LocationModel location) async {
    final savedLocations = await getSavedLocations();

    final existingIndex =
        savedLocations.indexWhere((loc) => loc.placeId == location.placeId);
    if (existingIndex >= 0) {
      savedLocations[existingIndex] = location;
    } else {
      savedLocations.add(location);
    }

    final encodedLocations =
        savedLocations.map((loc) => jsonEncode(loc.toJson())).toList();

    await _prefs.setStringList(_savedLocationsKey, encodedLocations);
  }

  @override
  Future<void> addToRecent(LocationModel location) async {
    var recentLocations = await getRecentLocations();

    recentLocations
      ..removeWhere((loc) => loc.placeId == location.placeId)

      ..insert(0, location);

    if (recentLocations.length > _maxRecentLocations) {
      recentLocations = recentLocations.sublist(0, _maxRecentLocations);
    }

    final encodedLocations =
        recentLocations.map((loc) => jsonEncode(loc.toJson())).toList();

    await _prefs.setStringList(_recentLocationsKey, encodedLocations);
  }

  @override
  Future<void> removeLocation(String locationId) async {
    final savedLocations = await getSavedLocations();

    savedLocations.removeWhere((loc) => loc.id == locationId);

    final encodedLocations =
        savedLocations.map((loc) => jsonEncode(loc.toJson())).toList();

    await _prefs.setStringList(_savedLocationsKey, encodedLocations);
  }

  @override
  Future<void> clearRecentLocations() async {
    await _prefs.setStringList(_recentLocationsKey, []);
  }
}
