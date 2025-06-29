import 'package:freedom/feature/home/repository/location_repository.dart';
import 'package:freedom/feature/home/repository/models/location.dart';

class GetPlaceDetails {
  GetPlaceDetails(this.repository);
  final LocationRepository repository;

  Future<Location?> call(String placeId) {
    return repository.getPlaceDetails(placeId);
  }
}
