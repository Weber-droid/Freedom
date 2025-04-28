import 'package:freedom/feature/location_search/repository/location_repository.dart';
import 'package:freedom/feature/location_search/repository/models/location.dart';

class SaveLocation {
  SaveLocation(this.repository);
  final LocationRepository repository;

  Future<void> call(Location location) {
    return repository.saveLocation(location);
  }
}