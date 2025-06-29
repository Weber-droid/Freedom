import 'package:freedom/feature/home/repository/location_repository.dart';

class ClearRecentLocations {
  ClearRecentLocations(this.repository);
  final LocationRepository repository;

  Future<void> call() {
    return repository.clearRecentLocations();
  }
}
