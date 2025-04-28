import 'package:freedom/feature/location_search/repository/location_repository.dart';
import 'package:freedom/feature/location_search/repository/models/location.dart';

class GetRecentLocations {

  GetRecentLocations(this.repository);
  final LocationRepository repository;

  Future<List<Location>> call() {
    return repository.getRecentLocations();
  }
}
