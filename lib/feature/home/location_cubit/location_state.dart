part of 'location_cubit.dart';

class LocationState extends Equatable {
  final LatLng? currentLocation;
  final LocationServiceStatus serviceStatus;
  final String? errorMessage;

  const LocationState({
    this.currentLocation,
    this.serviceStatus = LocationServiceStatus.initial,
    this.errorMessage,
  });

  // Standard e-hailing app initial camera position (Kumasi, Ghana)
  static final LatLng defaultInitialPosition = LatLng(6.6667, -1.6167);

  // Typical e-hailing app initial camera position
  static CameraPosition get initialCameraPosition => CameraPosition(
    target: defaultInitialPosition,
    zoom: 13.0,
    tilt: 0,
    bearing: 0,
  );

  LocationState copyWith({
    LatLng? currentLocation,
    LocationServiceStatus? serviceStatus,
    String? errorMessage,
  }) {
    return LocationState(
      currentLocation: currentLocation ?? this.currentLocation,
      serviceStatus: serviceStatus ?? this.serviceStatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [currentLocation, serviceStatus, errorMessage];
}