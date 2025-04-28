part of 'map_search_cubit.dart';

enum MapSearchStatus {
  initial,
  loading,
  success,
  error,
}

class MapSearchState {
  const MapSearchState({
    this.searchText = '',
    this.predictions = const [],
    this.locationSearchErrorMessage = '',
    this.status = MapSearchStatus.initial,
    this.selectedPickUpLocation,
    this.selectedDestinationLocation,
    this.markers = const <Marker>{},
  });

  final String searchText;
  final List<PlacePrediction> predictions;
  final String locationSearchErrorMessage;
  final MapSearchStatus status;
  final Location? selectedPickUpLocation;
  final Location? selectedDestinationLocation;
  final Set<Marker> markers;

  MapSearchState copyWith({
    String? searchText,
    List<PlacePrediction>? predictions,
    String? locationSearchErrorMessage,
    MapSearchStatus? status,
    Location? selectedPickUpLocation,
    Location? selectedDestinationLocation,
    Set<Marker>? markers,
  }) {
    return MapSearchState(
      searchText: searchText ?? this.searchText,
      predictions: predictions ?? this.predictions,
      locationSearchErrorMessage:
          locationSearchErrorMessage ?? this.locationSearchErrorMessage,
      status: status ?? this.status,
      selectedPickUpLocation:
          selectedPickUpLocation ?? this.selectedPickUpLocation,
      selectedDestinationLocation:
          selectedDestinationLocation ?? this.selectedDestinationLocation,
      markers: markers ?? this.markers,
    );
  }
}
