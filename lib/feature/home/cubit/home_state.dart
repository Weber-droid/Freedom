part of 'home_cubit.dart';

class HomeState extends Equatable {
  const HomeState({
    this.locations = const [],
    this.fieldIndexSetter,
    this.searchText = '',
    this.pickUpPredictions = const [],
    this.destinationPredictions = const [],
    this.locationSearchErrorMessage = '',
    this.status = MapSearchStatus.initial,
    this.markers = const <Marker>{},
    this.polylines = const {},
    this.currentLocation,
    this.serviceStatus = LocationServiceStatus.initial,
    this.errorMessage,
    this.userAddress,
    this.isPickUpLocation = false,
    this.isDestinationLocation = false,
    this.recentLocations = const [],
    this.showRecentPickUpLocations = false,
    this.showDestinationRecentLocations = false,
    this.destinationFocusNode,
    this.pickUpFocusNode,
  });

  final List<String> locations;
  final int? fieldIndexSetter;
  final String searchText;
  final List<PlacePrediction> pickUpPredictions;
  final List<PlacePrediction> destinationPredictions;
  final String locationSearchErrorMessage;
  final MapSearchStatus status;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final LatLng? currentLocation;
  final LocationServiceStatus serviceStatus;
  final String? userAddress;
  final String? errorMessage;
  final bool isPickUpLocation;
  final bool isDestinationLocation;
  final List<loc.Location> recentLocations;
  final bool showRecentPickUpLocations;
  final bool showDestinationRecentLocations;
  final FocusNode? pickUpFocusNode;
  final FocusNode? destinationFocusNode;

  static const LatLng defaultInitialPosition = LatLng(6.6667, -1.6167);

  static CameraPosition get initialCameraPosition => const CameraPosition(
        target: defaultInitialPosition,
        zoom: 15,
      );

  HomeState copyWith({
    List<String>? locations,
    int? fieldIndexSetter,
    String? searchText,
    List<PlacePrediction>? pickUpPredictions,
    List<PlacePrediction>? destinationPredictions,
    String? locationSearchErrorMessage,
    MapSearchStatus? status,
    Set<Marker>? markers,
    Set<Polyline>? polylines,
    LatLng? currentLocation,
    LocationServiceStatus? serviceStatus,
    String? userAddress,
    String? errorMessage,
    bool? isPickUpLocation,
    bool? isDestinationLocation,
    List<loc.Location>? recentLocations,
    bool? showRecentPickUpLocations,
    bool? showDestinationRecentLocations,
  }) {
    return HomeState(
      locations: locations ?? this.locations,
      fieldIndexSetter: fieldIndexSetter ?? this.fieldIndexSetter,
      searchText: searchText ?? this.searchText,
      pickUpPredictions: pickUpPredictions ?? this.pickUpPredictions,
      destinationPredictions:
          destinationPredictions ?? this.destinationPredictions,
      locationSearchErrorMessage:
          locationSearchErrorMessage ?? this.locationSearchErrorMessage,
      status: status ?? this.status,
      markers: markers ?? this.markers,
      currentLocation: currentLocation ?? this.currentLocation,
      serviceStatus: serviceStatus ?? this.serviceStatus,
      userAddress: userAddress ?? this.userAddress,
      errorMessage: errorMessage ?? this.errorMessage,
      polylines: polylines ?? this.polylines,
      isPickUpLocation: isPickUpLocation ?? this.isPickUpLocation,
      recentLocations: recentLocations ?? this.recentLocations,
      isDestinationLocation:
          isDestinationLocation ?? this.isDestinationLocation,
      showRecentPickUpLocations:
          showRecentPickUpLocations ?? this.showRecentPickUpLocations,
    );
  }

  @override
  List<Object?> get props => [
        locations,
        fieldIndexSetter,
        searchText,
        pickUpPredictions,
        destinationPredictions,
        locationSearchErrorMessage,
        status,
        markers,
        polylines,
        currentLocation,
        serviceStatus,
        userAddress,
        errorMessage,
        isPickUpLocation,
        isDestinationLocation,
        recentLocations,
        showRecentPickUpLocations,
        showDestinationRecentLocations,
        pickUpFocusNode,
        destinationFocusNode,
      ];
}
