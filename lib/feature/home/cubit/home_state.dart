part of 'home_cubit.dart';

class HomeState extends Equatable {
  const HomeState({
    this.locations = const [],
    this.fieldIndexSetter,
    this.searchText = '',
    this.predictions = const [],
    this.locationSearchErrorMessage = '',
    this.status = MapSearchStatus.initial,
    this.selectedPickUpLocation,
    this.selectedDestinationLocation,
    this.markers = const <Marker>{},
  });

  final List<String> locations;
  final int? fieldIndexSetter;
  final String searchText;
  final List<PlacePrediction> predictions;
  final String locationSearchErrorMessage;
  final MapSearchStatus status;
  final Location? selectedPickUpLocation;
  final Location? selectedDestinationLocation;
  final Set<Marker> markers;

  HomeState copyWith({
    List<String>? locations,
    int? fieldIndexSetter,
    String? searchText,
    List<PlacePrediction>? predictions,
    String? locationSearchErrorMessage,
    MapSearchStatus? status,
    Location? selectedPickUpLocation,
    Location? selectedDestinationLocation,
    Set<Marker>? markers,
  }) {
    return HomeState(
      locations: locations ?? this.locations,
      fieldIndexSetter: fieldIndexSetter ?? this.fieldIndexSetter,
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

  @override
  List<Object?> get props => [locations, fieldIndexSetter];
}
