import 'package:freedom/feature/home/repository/location_repository.dart';
import 'package:freedom/feature/home/repository/models/location.dart';

class SaveLocation {
  SaveLocation(this.repository);
  final LocationRepository repository;

  Future<void> call(Location location) {
    return repository.saveLocation(location);
  }
}
