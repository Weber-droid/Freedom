part of 'ride_cubit.dart';

class RideState extends Equatable {
  const RideState({
    this.status = RideRequestStatus.initial,
    this.errorMessage,
    this.paymentMethod = 'cash',
    this.rideResponse,
    this.socketStatus,
    this.cancellationStatus = RideCancellationStatus.initial,
    this.currentRideId,
    this.message,
    this.requestRidesStatus = RequestRidesStatus.initial,
    this.rideHistory,
    this.showStackedBottomSheet = true,
    this.showRiderFound = false,
    this.isSearching = false,
    this.searchTimeElapsed = 0,
    this.rideStatus = RideStatus.pending,
    this.nearestDriverDistance = 0.0,
    this.riderAvailable = false,
    this.isMultiDestination = false,
    this.driverAccepted,
    this.driverRejected,
    this.driverCancelled,
    this.driverCompleted,
    this.driverStarted,
    this.driverArrived,
    this.routeDisplayed = false,
    this.routePolylines = const {},
    this.routeMarkers = const {},
    this.routeSegments,
    this.currentDriverPosition,
    this.driverMarkerIcon,
    this.userLocationMarkerIcon,
    this.driverHasArrived = false,
    this.rideInProgress = false,
    this.currentSegmentIndex = 0,
    this.rideStatusResponse,
    this.shouldUpdateCamera = false,
    this.cameraTarget,
    this.lastPositionUpdate,
    this.currentSpeed,
    this.estimatedDistance,
    this.estimatedTimeArrival,
    this.isRealTimeTrackingActive = false,
    this.trackingStatusMessage,
    this.routeRecalculated = false,
    this.routeProgress,
    this.driverOffRoute = false,
    this.lastRouteRecalculation,
  });
  final RideRequestStatus status;
  final RequestRideResponse? rideResponse;
  final RideCancellationStatus cancellationStatus;
  final SocketStatus? socketStatus;
  final String? errorMessage;
  final String? paymentMethod;
  final String? currentRideId;
  final String? message;
  final RequestRidesStatus requestRidesStatus;
  final List<RideData>? rideHistory;
  final bool showStackedBottomSheet;
  final bool showRiderFound;
  final bool isSearching;
  final int searchTimeElapsed;
  final RideStatus rideStatus;
  final double nearestDriverDistance;
  final bool riderAvailable;
  final bool isMultiDestination;
  final DriverAcceptedModel? driverAccepted;
  final DriverRejected? driverRejected;
  final DriverCancelled? driverCancelled;
  final DriverCompleted? driverCompleted;
  final DriverStarted? driverStarted;
  final DriverArrived? driverArrived;
  final bool routeDisplayed;
  final Set<Polyline> routePolylines;
  final Map<MarkerId, Marker> routeMarkers;
  final List<RouteSegment>? routeSegments;
  final LatLng? currentDriverPosition;
  final BitmapDescriptor? driverMarkerIcon;
  final bool driverHasArrived;
  final bool rideInProgress;
  final int currentSegmentIndex;
  final BitmapDescriptor? userLocationMarkerIcon;
  final RideStatusResponse? rideStatusResponse;
  final bool shouldUpdateCamera;
  final LatLng? cameraTarget;
  final DateTime? lastPositionUpdate;
  final double? currentSpeed;
  final int? estimatedTimeArrival;
  final double? estimatedDistance;
  final bool isRealTimeTrackingActive;
  final String? trackingStatusMessage;
  final bool routeRecalculated;
  final double? routeProgress;
  final bool driverOffRoute;
  final DateTime? lastRouteRecalculation;
  RideState copyWith({
    RideRequestStatus? status,
    String? errorMessage,
    String? paymentMethod,
    RequestRideResponse? rideResponse,
    SocketStatus? socketStatus,
    RideCancellationStatus? cancellationStatus,
    String? currentRideId,
    String? message,
    RequestRidesStatus? requestRidesStatus,
    List<RideData>? rideHistory,
    bool? showStackedBottomSheet,
    bool? showRiderFound,
    bool? isSearching,
    int? searchTimeElapsed,
    RideStatus? rideStatus,
    double? nearestDriverDistance,
    bool? riderAvailable,
    bool? isMultiDestination,
    DriverAcceptedModel? driverAccepted,
    DriverRejected? driverRejected,
    DriverCancelled? driverCancelled,
    DriverCompleted? driverCompleted,
    DriverStarted? driverStarted,
    DriverArrived? driverArrived,
    bool? routeDisplayed,
    Set<Polyline>? routePolylines,
    Map<MarkerId, Marker>? routeMarkers,
    List<RouteSegment>? routeSegments,
    LatLng? currentDriverPosition,
    final BitmapDescriptor? driverMarkerIcon,
    final BitmapDescriptor? userLocationMarkerIcon,
    bool? driverHasArrived,
    bool? rideInProgress,
    int? currentSegmentIndex,
    RideStatusResponse? rideStatusResponse,
    bool? shouldUpdateCamera,
    LatLng? cameraTarget,
    DateTime? lastPositionUpdate,
    double? currentSpeed,
    final int? estimatedTimeArrival,
    final double? estimatedDistance,
    bool? isRealTimeTrackingActive,
    String? trackingStatusMessage,
    bool? routeRecalculated,
    double? routeProgress,
    bool? driverOffRoute,
    DateTime? lastRouteRecalculation,
  }) {
    return RideState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      rideResponse: rideResponse ?? this.rideResponse,
      socketStatus: socketStatus ?? this.socketStatus,
      cancellationStatus: cancellationStatus ?? this.cancellationStatus,
      currentRideId: currentRideId ?? this.currentRideId,
      message: message ?? this.message,
      requestRidesStatus: requestRidesStatus ?? this.requestRidesStatus,
      rideHistory: rideHistory ?? this.rideHistory,
      showStackedBottomSheet:
          showStackedBottomSheet ?? this.showStackedBottomSheet,
      showRiderFound: showRiderFound ?? this.showRiderFound,
      isSearching: isSearching ?? this.isSearching,
      searchTimeElapsed: searchTimeElapsed ?? this.searchTimeElapsed,
      rideStatus: rideStatus ?? this.rideStatus,
      nearestDriverDistance:
          nearestDriverDistance ?? this.nearestDriverDistance,
      riderAvailable: riderAvailable ?? this.riderAvailable,
      isMultiDestination: isMultiDestination ?? this.isMultiDestination,
      driverAccepted: driverAccepted ?? this.driverAccepted,
      driverRejected: driverRejected ?? this.driverRejected,
      driverCancelled: driverCancelled ?? this.driverCancelled,
      driverCompleted: driverCompleted ?? this.driverCompleted,
      driverStarted: driverStarted ?? this.driverStarted,
      driverArrived: driverArrived ?? this.driverArrived,
      routeDisplayed: routeDisplayed ?? this.routeDisplayed,
      routePolylines: routePolylines ?? this.routePolylines,
      routeMarkers: routeMarkers ?? this.routeMarkers,
      routeSegments: routeSegments ?? this.routeSegments,
      currentDriverPosition:
          currentDriverPosition ?? this.currentDriverPosition,
      driverMarkerIcon: driverMarkerIcon ?? this.driverMarkerIcon,
      driverHasArrived: driverHasArrived ?? this.driverHasArrived,
      rideInProgress: rideInProgress ?? this.rideInProgress,
      userLocationMarkerIcon:
          userLocationMarkerIcon ?? this.userLocationMarkerIcon,
      currentSegmentIndex: currentSegmentIndex ?? this.currentSegmentIndex,
      rideStatusResponse: rideStatusResponse ?? this.rideStatusResponse,
      shouldUpdateCamera: shouldUpdateCamera ?? this.shouldUpdateCamera,
      cameraTarget: cameraTarget ?? this.cameraTarget,
      lastPositionUpdate: lastPositionUpdate ?? this.lastPositionUpdate,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
      estimatedTimeArrival: estimatedTimeArrival ?? this.estimatedTimeArrival,
      isRealTimeTrackingActive: isRealTimeTrackingActive ?? this.isRealTimeTrackingActive,
      trackingStatusMessage: trackingStatusMessage ?? this.trackingStatusMessage,
      routeRecalculated: routeRecalculated ?? this.routeRecalculated,
      routeProgress: routeProgress ?? this.routeProgress,
      driverOffRoute: driverOffRoute ?? this.driverOffRoute,
      lastRouteRecalculation: lastRouteRecalculation ?? this.lastRouteRecalculation,
    );
  }

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    paymentMethod,
    rideResponse,
    socketStatus,
    cancellationStatus,
    currentRideId,
    message,
    requestRidesStatus,
    rideHistory,
    showStackedBottomSheet,
    showRiderFound,
    isSearching,
    searchTimeElapsed,
    rideStatus,
    nearestDriverDistance,
    riderAvailable,
    isMultiDestination,
    driverAccepted,
    driverRejected,
    driverCancelled,
    driverCompleted,
    driverStarted,
    driverArrived,
    routeDisplayed,
    routePolylines,
    routeMarkers,
    routeSegments,
    currentDriverPosition,
    driverMarkerIcon,
    driverHasArrived,
    rideInProgress,
    currentSegmentIndex,
    userLocationMarkerIcon,
    rideStatusResponse,
    shouldUpdateCamera,
    cameraTarget,
    lastPositionUpdate,
    currentSpeed,
    estimatedDistance,
    estimatedTimeArrival,
    isRealTimeTrackingActive,
    trackingStatusMessage,
    routeRecalculated,
    routeProgress,
    driverOffRoute,
    lastRouteRecalculation,
  ];
}
