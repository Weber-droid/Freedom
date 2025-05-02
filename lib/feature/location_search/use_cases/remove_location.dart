import 'package:freedom/feature/location_search/repository/location_repository.dart';

class RemoveLocation {


  RemoveLocation(this.repository);
  final LocationRepository repository;
  Future<void> call(String locationId) {
    return repository.removeLocation(locationId);
  }
}