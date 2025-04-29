part of 'home_cubit.dart';

class HomeState extends Equatable {
  const HomeState({
    this.locations = const [],
    this.fieldIndexSetter,
    this.searchText = '',
    this.predictions = const [],
    this.locationSearchErrorMessage = '',
    this.status = MapSearchStatus.initial,
    this.markers = const <Marker>{},
    this.currentLocation,
    this.serviceStatus = LocationServiceStatus.initial,
    this.errorMessage,
    this.userAddress,
  });

  final List<String> locations;
  final int? fieldIndexSetter;
  final String searchText;
  final List<PlacePrediction> predictions;
  final String locationSearchErrorMessage;
  final MapSearchStatus status;
  final Set<Marker> markers;
  final LatLng? currentLocation;
  final LocationServiceStatus serviceStatus;
  final String? userAddress;
  final String? errorMessage;

  static const LatLng defaultInitialPosition = LatLng(6.6667, -1.6167);

  static CameraPosition get initialCameraPosition => const CameraPosition(
        target: defaultInitialPosition,
        zoom: 15,
      );

  HomeState copyWith({
    List<String>? locations,
    int? fieldIndexSetter,
    String? searchText,
    List<PlacePrediction>? predictions,
    String? locationSearchErrorMessage,
    MapSearchStatus? status,
    Set<Marker>? markers,
    LatLng? currentLocation,
    LocationServiceStatus? serviceStatus,
    String? userAddress,
    String? errorMessage,
  }) {
    return HomeState(
      locations: locations ?? this.locations,
      fieldIndexSetter: fieldIndexSetter ?? this.fieldIndexSetter,
      searchText: searchText ?? this.searchText,
      predictions: predictions ?? this.predictions,
      locationSearchErrorMessage:
          locationSearchErrorMessage ?? this.locationSearchErrorMessage,
      status: status ?? this.status,
      markers: markers ?? this.markers,
      currentLocation: currentLocation ?? this.currentLocation,
      serviceStatus: serviceStatus ?? this.serviceStatus,
      userAddress: userAddress ?? this.userAddress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        locations,
        fieldIndexSetter,
        searchText,
        predictions,
        locationSearchErrorMessage,
        status,
        markers,
        currentLocation,
        serviceStatus,
        userAddress,
        errorMessage
      ];
}
