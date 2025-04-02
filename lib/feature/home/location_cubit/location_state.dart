part of 'location_cubit.dart';

class LocationState extends Equatable {
  const LocationState({
    this.currentLocation,
    this.serviceStatus = LocationServiceStatus.initial,
    this.errorMessage,
    this.userAddress = '',
  });
  final LatLng? currentLocation;
  final LocationServiceStatus serviceStatus;
  final String userAddress;
  final String? errorMessage;

  static const LatLng defaultInitialPosition = LatLng(6.6667, -1.6167);

  static CameraPosition get initialCameraPosition => const CameraPosition(
        target: defaultInitialPosition,
        zoom: 13,
      );

  LocationState copyWith({
    LatLng? currentLocation,
    LocationServiceStatus? serviceStatus,
    String? userAddress,
    String? errorMessage,
  }) {
    return LocationState(
      currentLocation: currentLocation ?? this.currentLocation,
      serviceStatus: serviceStatus ?? this.serviceStatus,
      userAddress: userAddress ?? this.userAddress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [currentLocation, serviceStatus, userAddress, errorMessage];
}
