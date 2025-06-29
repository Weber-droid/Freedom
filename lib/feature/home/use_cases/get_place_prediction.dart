import 'package:freedom/feature/home/repository/location_repository.dart';
import 'package:freedom/feature/home/repository/models/place_prediction.dart';

class GetPlacePredictions {
  GetPlacePredictions(this.repository);
  final LocationRepository repository;

  Future<List<PlacePrediction>> call(String query) {
    return repository.getPlacePredictions(query);
  }
}
