part of 'delivery_cubit.dart';

enum DeliveryStatus { initial, loading, success, failure }

enum DeliveryCancellationStatus { initial, canceling, cancelled, error }

@immutable
class DeliveryState extends Equatable {
  const DeliveryState({
    this.status = DeliveryStatus.initial,
    this.deliveryData,
    this.errorMessage,
    this.message,
    this.searchTimeElapsed = 0,
    this.showDeliverySearchSheet = false,
    this.isSearching = false,
    this.riderFound = false,
    this.deliveryControllers = const [],
    this.isMultipleDestination = false,
    this.activeDestinationIndex = 0,
    this.pickupPredictions = const [],
    this.destinationPredictions = const [],
    this.showPickupPredictions = false,
    this.showDestinationPredictions = false,
    this.showRecentPickUpLocations = false,
    this.showRecentDestinationLocations = false,
    this.isLoadingPredictions = false,
    this.islocationSelected = false,
    this.isPickUpLocation = false,
    this.isDestinationLocation = false,
    this.recentLocations = const [],

    this.currentDeliveryId,
    this.deliveryCancellationStatus = DeliveryCancellationStatus.initial,

    // Driver status tracking
    this.deliveryDriverAccepted,
    this.deliveryDriverStarted,
    this.deliveryDriverArrived,
    this.deliveryDriverCompleted,
    this.deliveryDriverCancelled,
    this.deliveryDriverHasArrived = false,
    this.deliveryInProgress = false,

    // Real-time tracking
    this.isRealTimeDeliveryTrackingActive = false,
    this.deliveryTrackingStatusMessage,
    this.lastDeliveryPositionUpdate,
    this.currentDeliverySpeed = 0.0,

    // Route and map display
    this.deliveryRouteDisplayed = false,
    this.deliveryRoutePolylines = const {},
    this.deliveryRouteMarkers = const {},
    this.deliveryRouteSegments,
    this.currentDeliveryDriverPosition,
    this.deliveryRouteRecalculated = false,
    this.shouldUpdateCamera = false,
    this.cameraTarget,

    // Animation state
    this.deliveryDriverAnimationComplete = false,

    // Marker icons
    this.deliveryDriverMarkerIcon,
    this.streetLevelZoom,
    this.statusData,
  });

  // Basic delivery state
  final DeliveryStatus status;
  final DeliveryData? deliveryData;
  final String? errorMessage;
  final String? message;
  final int searchTimeElapsed;
  final bool showDeliverySearchSheet;
  final bool isSearching;
  final bool riderFound;

  // Delivery destinations management
  final List<TextEditingController> deliveryControllers;
  final bool isMultipleDestination;
  final int activeDestinationIndex;

  // Location search and predictions
  final List<PlacePrediction> pickupPredictions;
  final List<PlacePrediction> destinationPredictions;
  final bool showPickupPredictions;
  final bool showDestinationPredictions;
  final bool showRecentPickUpLocations;
  final bool showRecentDestinationLocations;
  final bool isLoadingPredictions;
  final bool islocationSelected;
  final bool isPickUpLocation;
  final bool isDestinationLocation;
  final List<FreedomLocation> recentLocations;

  // Enhanced delivery tracking
  final String? currentDeliveryId;
  final DeliveryCancellationStatus deliveryCancellationStatus;

  // Driver status tracking
  final DeliveryManAcceptedModel? deliveryDriverAccepted;
  final DeliveryManStarted? deliveryDriverStarted;
  final DeliveryArrived? deliveryDriverArrived;
  final DeliveryManCompleted? deliveryDriverCompleted;
  final DeliveryManCancelled? deliveryDriverCancelled;
  final bool deliveryDriverHasArrived;
  final bool deliveryInProgress;

  // Real-time tracking state
  final bool isRealTimeDeliveryTrackingActive;
  final String? deliveryTrackingStatusMessage;
  final DateTime? lastDeliveryPositionUpdate;
  final double currentDeliverySpeed;

  // Route and map display
  final bool deliveryRouteDisplayed;
  final Set<Polyline> deliveryRoutePolylines;
  final Map<MarkerId, Marker> deliveryRouteMarkers;
  final List<RouteSegment>? deliveryRouteSegments;
  final LatLng? currentDeliveryDriverPosition;
  final bool deliveryRouteRecalculated;
  final bool shouldUpdateCamera;
  final LatLng? cameraTarget;

  // Animation state
  final bool deliveryDriverAnimationComplete;

  // Marker icons
  final BitmapDescriptor? deliveryDriverMarkerIcon;
  final double? streetLevelZoom;
  final DeliveryStatusResponse? statusData;

  @override
  List<Object?> get props => [
    status,
    deliveryData,
    errorMessage,
    message,
    searchTimeElapsed,
    showDeliverySearchSheet,
    isSearching,
    riderFound,
    deliveryControllers,
    isMultipleDestination,
    activeDestinationIndex,
    pickupPredictions,
    destinationPredictions,
    showPickupPredictions,
    showDestinationPredictions,
    showRecentPickUpLocations,
    showRecentDestinationLocations,
    isLoadingPredictions,
    islocationSelected,
    isPickUpLocation,
    isDestinationLocation,
    recentLocations,
    currentDeliveryId,
    deliveryCancellationStatus,
    deliveryDriverAccepted,
    deliveryDriverStarted,
    deliveryDriverArrived,
    deliveryDriverCompleted,
    deliveryDriverCancelled,
    deliveryDriverHasArrived,
    deliveryInProgress,
    isRealTimeDeliveryTrackingActive,
    deliveryTrackingStatusMessage,
    lastDeliveryPositionUpdate,
    currentDeliverySpeed,
    deliveryRouteDisplayed,
    deliveryRoutePolylines,
    deliveryRouteMarkers,
    deliveryRouteSegments,
    currentDeliveryDriverPosition,
    deliveryRouteRecalculated,
    shouldUpdateCamera,
    cameraTarget,
    deliveryDriverAnimationComplete,
    deliveryDriverMarkerIcon,
    streetLevelZoom,
    statusData,
  ];

  DeliveryState copyWith({
    DeliveryStatus? status,
    DeliveryData? deliveryData,
    String? errorMessage,
    String? message,
    int? searchTimeElapsed,
    bool? showDeliverySearchSheet,
    bool? isSearching,
    bool? riderFound,
    List<TextEditingController>? deliveryControllers,
    bool? isMultipleDestination,
    int? activeDestinationIndex,
    List<PlacePrediction>? pickupPredictions,
    List<PlacePrediction>? destinationPredictions,
    bool? showPickupPredictions,
    bool? showDestinationPredictions,
    bool? showRecentPickUpLocations,
    bool? showRecentDestinationLocations,
    bool? isLoadingPredictions,
    bool? islocationSelected,
    bool? isPickUpLocation,
    bool? isDestinationLocation,
    List<FreedomLocation>? recentLocations,
    String? currentDeliveryId,
    DeliveryCancellationStatus? deliveryCancellationStatus,
    DeliveryManAcceptedModel? deliveryDriverAccepted,
    DeliveryManStarted? deliveryDriverStarted,
    DeliveryArrived? deliveryDriverArrived,
    DeliveryManCompleted? deliveryDriverCompleted,
    DeliveryManCancelled? deliveryDriverCancelled,
    bool? deliveryDriverHasArrived,
    bool? deliveryInProgress,
    bool? isRealTimeDeliveryTrackingActive,
    String? deliveryTrackingStatusMessage,
    DateTime? lastDeliveryPositionUpdate,
    double? currentDeliverySpeed,
    bool? deliveryRouteDisplayed,
    Set<Polyline>? deliveryRoutePolylines,
    Map<MarkerId, Marker>? deliveryRouteMarkers,
    List<RouteSegment>? deliveryRouteSegments,
    LatLng? currentDeliveryDriverPosition,
    bool? deliveryRouteRecalculated,
    bool? shouldUpdateCamera,
    LatLng? cameraTarget,
    bool? deliveryDriverAnimationComplete,
    BitmapDescriptor? deliveryDriverMarkerIcon,
    double? streetLevelZoom,
    DeliveryStatusResponse? statusData,
  }) {
    return DeliveryState(
      status: status ?? this.status,
      deliveryData: deliveryData ?? this.deliveryData,
      errorMessage: errorMessage ?? this.errorMessage,
      message: message ?? this.message,
      searchTimeElapsed: searchTimeElapsed ?? this.searchTimeElapsed,
      showDeliverySearchSheet:
          showDeliverySearchSheet ?? this.showDeliverySearchSheet,
      isSearching: isSearching ?? this.isSearching,
      riderFound: riderFound ?? this.riderFound,
      deliveryControllers: deliveryControllers ?? this.deliveryControllers,
      isMultipleDestination:
          isMultipleDestination ?? this.isMultipleDestination,
      activeDestinationIndex:
          activeDestinationIndex ?? this.activeDestinationIndex,
      pickupPredictions: pickupPredictions ?? this.pickupPredictions,
      destinationPredictions:
          destinationPredictions ?? this.destinationPredictions,
      showPickupPredictions:
          showPickupPredictions ?? this.showPickupPredictions,
      showDestinationPredictions:
          showDestinationPredictions ?? this.showDestinationPredictions,
      showRecentPickUpLocations:
          showRecentPickUpLocations ?? this.showRecentPickUpLocations,
      showRecentDestinationLocations:
          showRecentDestinationLocations ?? this.showRecentDestinationLocations,
      isLoadingPredictions: isLoadingPredictions ?? this.isLoadingPredictions,
      islocationSelected: islocationSelected ?? this.islocationSelected,
      isPickUpLocation: isPickUpLocation ?? this.isPickUpLocation,
      isDestinationLocation:
          isDestinationLocation ?? this.isDestinationLocation,
      recentLocations: recentLocations ?? this.recentLocations,
      currentDeliveryId: currentDeliveryId ?? this.currentDeliveryId,
      deliveryCancellationStatus:
          deliveryCancellationStatus ?? this.deliveryCancellationStatus,
      deliveryDriverAccepted:
          deliveryDriverAccepted ?? this.deliveryDriverAccepted,
      deliveryDriverStarted:
          deliveryDriverStarted ?? this.deliveryDriverStarted,
      deliveryDriverArrived:
          deliveryDriverArrived ?? this.deliveryDriverArrived,
      deliveryDriverCompleted:
          deliveryDriverCompleted ?? this.deliveryDriverCompleted,
      deliveryDriverCancelled:
          deliveryDriverCancelled ?? this.deliveryDriverCancelled,
      deliveryDriverHasArrived:
          deliveryDriverHasArrived ?? this.deliveryDriverHasArrived,
      deliveryInProgress: deliveryInProgress ?? this.deliveryInProgress,
      isRealTimeDeliveryTrackingActive:
          isRealTimeDeliveryTrackingActive ??
          this.isRealTimeDeliveryTrackingActive,
      deliveryTrackingStatusMessage:
          deliveryTrackingStatusMessage ?? this.deliveryTrackingStatusMessage,
      lastDeliveryPositionUpdate:
          lastDeliveryPositionUpdate ?? this.lastDeliveryPositionUpdate,
      currentDeliverySpeed: currentDeliverySpeed ?? this.currentDeliverySpeed,
      deliveryRouteDisplayed:
          deliveryRouteDisplayed ?? this.deliveryRouteDisplayed,
      deliveryRoutePolylines:
          deliveryRoutePolylines ?? this.deliveryRoutePolylines,
      deliveryRouteMarkers: deliveryRouteMarkers ?? this.deliveryRouteMarkers,
      deliveryRouteSegments:
          deliveryRouteSegments ?? this.deliveryRouteSegments,
      currentDeliveryDriverPosition:
          currentDeliveryDriverPosition ?? this.currentDeliveryDriverPosition,
      deliveryRouteRecalculated:
          deliveryRouteRecalculated ?? this.deliveryRouteRecalculated,
      shouldUpdateCamera: shouldUpdateCamera ?? this.shouldUpdateCamera,
      cameraTarget: cameraTarget ?? this.cameraTarget,
      deliveryDriverAnimationComplete:
          deliveryDriverAnimationComplete ??
          this.deliveryDriverAnimationComplete,
      deliveryDriverMarkerIcon:
          deliveryDriverMarkerIcon ?? this.deliveryDriverMarkerIcon,
      streetLevelZoom: streetLevelZoom ?? this.streetLevelZoom,
      statusData: statusData ?? this.statusData,
    );
  }

  // Helper getters for delivery tracking status
  bool get hasActiveDelivery => currentDeliveryId != null && riderFound;

  bool get isDeliveryTrackingHealthy =>
      isRealTimeDeliveryTrackingActive &&
      (lastDeliveryPositionUpdate != null &&
          DateTime.now().difference(lastDeliveryPositionUpdate!).inSeconds <
              15);

  String get deliveryStatusSummary {
    if (!hasActiveDelivery) return 'No active delivery';
    if (!riderFound) return 'Searching for delivery driver';
    if (!deliveryInProgress) return 'Delivery driver assigned';
    if (!isRealTimeDeliveryTrackingActive) return 'Delivery in progress';
    if (!isDeliveryTrackingHealthy) return 'Connection issues';
    return 'Live tracking active';
  }

  Duration? get timeSinceLastDeliveryUpdate {
    if (lastDeliveryPositionUpdate == null) return null;
    return DateTime.now().difference(lastDeliveryPositionUpdate!);
  }

  bool get isDeliveryStale {
    if (timeSinceLastDeliveryUpdate == null) return false;
    return timeSinceLastDeliveryUpdate!.inSeconds > 10;
  }

  @override
  String toString() {
    return 'DeliveryState('
        'status: $status, '
        'hasActiveDelivery: $hasActiveDelivery, '
        'riderFound: $riderFound, '
        'deliveryInProgress: $deliveryInProgress, '
        'isRealTimeDeliveryTrackingActive: $isRealTimeDeliveryTrackingActive, '
        'currentDeliverySpeed: ${currentDeliverySpeed.toStringAsFixed(1)} km/h, '
        'statusSummary: $deliveryStatusSummary'
        ')';
  }
}

class DeliveryRouteInfo {
  final double totalDistance;
  final bool isMultipleDestination;
  final int destinationCount;
  final Duration estimatedDuration;

  const DeliveryRouteInfo({
    required this.totalDistance,
    required this.isMultipleDestination,
    required this.destinationCount,
    required this.estimatedDuration,
  });

  String get formattedDistance {
    if (totalDistance < 1000) {
      return '${totalDistance.toStringAsFixed(0)}m';
    } else {
      return '${(totalDistance / 1000).toStringAsFixed(1)}km';
    }
  }

  String get formattedDuration {
    final hours = estimatedDuration.inHours;
    final minutes = estimatedDuration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  String toString() {
    return 'DeliveryRouteInfo('
        'distance: $formattedDistance, '
        'multipleDestinations: $isMultipleDestination, '
        'destinations: $destinationCount, '
        'duration: $formattedDuration'
        ')';
  }
}

class DeliveryTrackingMetrics {
  final bool isTrackingActive;
  final bool isReceivingUpdates;
  final double averageAccuracy;
  final int locationHistoryCount;
  final Duration? timeSinceLastUpdate;
  final double currentSpeed;
  final String statusSummary;

  const DeliveryTrackingMetrics({
    required this.isTrackingActive,
    required this.isReceivingUpdates,
    required this.averageAccuracy,
    required this.locationHistoryCount,
    this.timeSinceLastUpdate,
    required this.currentSpeed,
    required this.statusSummary,
  });

  bool get isHealthy =>
      isTrackingActive && isReceivingUpdates && averageAccuracy < 50.0;

  @override
  String toString() {
    return 'DeliveryTrackingMetrics('
        'active: $isTrackingActive, '
        'receiving: $isReceivingUpdates, '
        'accuracy: ${averageAccuracy.toStringAsFixed(1)}m, '
        'history: $locationHistoryCount, '
        'lastUpdate: ${timeSinceLastUpdate?.inSeconds}s ago, '
        'speed: ${currentSpeed.toStringAsFixed(1)} km/h, '
        'status: $statusSummary'
        ')';
  }
}
