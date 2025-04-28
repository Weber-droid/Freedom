import 'package:freedom/feature/location_search/repository/location_repository.dart';
import 'package:freedom/feature/location_search/repository/models/PlacePrediction.dart';

class GetPlacePredictions {

  GetPlacePredictions(this.repository);
  final LocationRepository repository;


  Future<List<PlacePrediction>> call(String query) {
    return repository.getPlacePredictions(query);
  }
}