import 'package:freedom/feature/location_search/repository/location_repository.dart';
import 'package:freedom/feature/location_search/repository/models/location.dart';

class GetPlaceDetails {

  GetPlaceDetails(this.repository);
  final LocationRepository repository;

  Future<Location?> call(String placeId) {
    return repository.getPlaceDetails(placeId);
  }
}