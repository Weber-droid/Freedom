import 'package:freedom/feature/home/repository/location_repository.dart';
import 'package:freedom/feature/home/repository/models/location.dart';

class GetSavedLocations {
  GetSavedLocations(this.repository);
  final LocationRepository repository;

  Future<List<FreedomLocation>> call() {
    return repository.getSavedLocations();
  }
}
