import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math' as math;
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freedom/core/services/life_cycle_manager.dart';
import 'package:freedom/core/services/push_notification_service/socket_ride_models.dart';
import 'package:freedom/core/services/ride_persistence_service.dart';
import 'package:freedom/core/services/socket_service.dart';
import 'package:freedom/core/services/real_time_driver_tracking.dart';
import 'package:freedom/core/services/route_animation_services.dart';
import 'package:freedom/core/services/route_services.dart';
import 'package:freedom/feature/History/model/history_model.dart' as hm;
import 'package:freedom/feature/home/models/request_ride_model.dart';
import 'package:freedom/feature/home/models/request_ride_response.dart';
import 'package:freedom/feature/home/models/ride_status_response.dart';
import 'package:freedom/feature/home/repository/models/location.dart';
import 'package:freedom/feature/home/repository/ride_request_repository.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';
import 'package:freedom/shared/enums/enums.dart';
import 'package:freedom/di/locator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'ride_state.dart';

class RideCubit extends Cubit<RideState> {
  RideCubit({
    required this.rideRequestRepository,
    RouteService? routeService,
    RouteAnimationService? animationService,
    RealTimeDriverTrackingService? trackingService,
    RidePersistenceService? persistenceService,
  }) : _routeService = routeService ?? getIt<RouteService>(),
       _animationService = animationService ?? getIt<RouteAnimationService>(),
       _realTimeTrackingService =
           trackingService ?? getIt<RealTimeDriverTrackingService>(),
       _persistenceService =
           persistenceService ??
           RidePersistenceService(getIt<SharedPreferences>()),
       super(const RideState()) {
    _initSocketListener();
    _initializePersistence();
  }

  final RideRequestRepository rideRequestRepository;
  final RouteService _routeService;
  final RouteAnimationService _animationService;
  final RealTimeDriverTrackingService _realTimeTrackingService;
  final RidePersistenceService _persistenceService;

  DateTime? _lastStatusUpdate;
  DateTime? _lastPersistenceTime;
  RideRequestModel? _currentRideRequest;
  bool _isDisposed = false;

  // Socket subscriptions
  StreamSubscription<dynamic>? _driverStatusSubscription;
  StreamSubscription<dynamic>? _driverCancelledSubscription;
  StreamSubscription<dynamic>? _driverAcceptedSubscription;
  StreamSubscription<dynamic>? _driverArrivedSubscription;
  StreamSubscription<dynamic>? _driverCompletedSubscription;
  StreamSubscription<dynamic>? _driverStartedSubscription;
  StreamSubscription<dynamic>? _driverRejectedSubscription;
  StreamSubscription<dynamic>? _driverPositionSubscription;

  // Timers
  Timer? _timer;
  Timer? _persistenceTimer;
  Timer? _statusUpdateThrottle;

  static const Duration _statusUpdateInterval = Duration(milliseconds: 500);
  static const Duration _persistenceInterval = Duration(seconds: 10);
  static const int maxSearchTime = 60;

  String? _pendingStatusMessage;

  set currentRideRequest(RideRequestModel? request) =>
      _currentRideRequest = request;
  // Getters
  RideRequestModel? get currentRideRequest => _currentRideRequest;
  int get searchTimeElapsed => state.searchTimeElapsed;

  set searchTimeElapsed(int searchTimeElapsed) =>
      emit(state.copyWith(searchTimeElapsed: searchTimeElapsed));

  // ============================================================================
  // CENTRALIZED MARKER MANAGEMENT
  // ============================================================================

  void listenToDriverStatus() {
    _listenToDriverStatus();
  }

  void enableDriverCameraFollow() {
    emit(
      state.copyWith(
        followDriverCamera: true,
        cameraFollowingMode: CameraFollowingMode.followDriver,
      ),
    );
  }

  void disableDriverCameraFollow() {
    emit(
      state.copyWith(
        followDriverCamera: false,
        cameraFollowingMode: CameraFollowingMode.none,
      ),
    );
  }

  void toggleCameraFollowingMode() {
    if (state.followDriverCamera) {
      disableDriverCameraFollow();
    } else {
      enableDriverCameraFollow();
    }
  }

  void setCameraToFollowWithRoute() {
    emit(
      state.copyWith(
        followDriverCamera: true,
        cameraFollowingMode: CameraFollowingMode.followWithRoute,
      ),
    );
  }

  /// Central method for creating all markers consistently
  Map<MarkerId, Marker> _createMarkers({
    required RideRequestModel rideRequest,
    LatLng? driverPosition,
    double driverRotation = 0.0,
  }) {
    final markers = <MarkerId, Marker>{};

    // Pickup marker
    const pickupMarkerId = MarkerId('pickup_location');
    markers[pickupMarkerId] = Marker(
      markerId: pickupMarkerId,
      position: LatLng(
        rideRequest.pickupLocation.latitude,
        rideRequest.pickupLocation.longitude,
      ),
      icon:
          state.userLocationMarkerIcon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(
        title: 'Pickup Location',
        snippet: rideRequest.pickupLocation.address,
      ),
    );

    // Destination marker
    const destinationMarkerId = MarkerId('destination_location');
    markers[destinationMarkerId] = Marker(
      markerId: destinationMarkerId,
      position: LatLng(
        rideRequest.dropoffLocation.latitude,
        rideRequest.dropoffLocation.longitude,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: 'Destination',
        snippet: rideRequest.dropoffLocation.address,
      ),
    );

    // Additional destinations for multi-destination rides
    if (rideRequest.isMultiDestination &&
        rideRequest.additionalDestinations != null) {
      for (int i = 0; i < rideRequest.additionalDestinations!.length; i++) {
        final stop = rideRequest.additionalDestinations![i];
        final stopMarkerId = MarkerId('stop_$i');

        markers[stopMarkerId] = Marker(
          markerId: stopMarkerId,
          position: LatLng(stop.latitude, stop.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(title: 'Stop ${i + 1}', snippet: stop.address),
        );
      }
    }

    // Driver marker (only if position is available)
    if (driverPosition != null) {
      const driverMarkerId = MarkerId('driver_location');
      markers[driverMarkerId] = Marker(
        markerId: driverMarkerId,
        position: driverPosition,
        icon:
            state.driverMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Driver Location'),
        rotation: driverRotation,
      );
    }

    return markers;
  }

  /// Update only the driver marker position and rotation
  void _updateDriverMarker(LatLng position, double rotation) {
    if (_isDisposed) return;

    final updatedMarkers = Map<MarkerId, Marker>.from(state.routeMarkers);
    const driverMarkerId = MarkerId('driver_location');

    if (updatedMarkers.containsKey(driverMarkerId)) {
      final currentMarker = updatedMarkers[driverMarkerId]!;
      updatedMarkers[driverMarkerId] = currentMarker.copyWith(
        positionParam: position,
        rotationParam: rotation,
      );
    } else {
      // Create new driver marker if it doesn't exist
      updatedMarkers[driverMarkerId] = Marker(
        markerId: driverMarkerId,
        position: position,
        icon:
            state.driverMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Driver Location'),
        rotation: rotation,
      );
    }

    emit(
      state.copyWith(
        routeMarkers: updatedMarkers,
        currentDriverPosition: position,
      ),
    );
  }

  /// Ensure marker icons are loaded
  Future<void> _ensureMarkerIcons() async {
    if (state.driverMarkerIcon == null) {
      await _createDriverMarkerIcon();
    }
    if (state.userLocationMarkerIcon == null) {
      await _createUserLocationMarkerIcon();
    }
  }

  Future<void> _createDriverMarkerIcon() async {
    try {
      final driverIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(25, 25)),
        'assets/images/bike_marker.png',
      );
      emit(state.copyWith(driverMarkerIcon: driverIcon));
    } catch (e) {
      final defaultDriverIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueBlue,
      );
      emit(state.copyWith(driverMarkerIcon: defaultDriverIcon));
    }
  }

  Future<void> _createUserLocationMarkerIcon() async {
    try {
      final userIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(25, 25)),
        'assets/images/user_pin.png',
      );
      emit(state.copyWith(userLocationMarkerIcon: userIcon));
    } catch (e) {
      final defaultUserIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueGreen,
      );
      emit(state.copyWith(userLocationMarkerIcon: defaultUserIcon));
    }
  }

  // ============================================================================
  // PERSISTENCE MANAGEMENT
  // ============================================================================

  void _initializePersistence() {
    _startPeriodicPersistence();
  }

  void _startPeriodicPersistence() {
    _persistenceTimer?.cancel();

    _persistenceTimer = Timer.periodic(_persistenceInterval, (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      if (state.hasActiveRide) {
        _persistCurrentStateAsync();
      }
    });
  }

  @override
  void emit(RideState state) {
    super.emit(state);

    if (state.currentRideId != null && state.hasActiveRide) {
      _persistCurrentStateAsync();
    }
  }

  void _persistCurrentStateAsync() {
    if (_isDisposed) return;

    Future.microtask(() async {
      try {
        await _persistenceService.persistCompleteRideState(state);

        if (state.routeMarkers.isNotEmpty) {
          await _persistenceService.persistMarkers(state.routeMarkers);
        }

        if (state.routePolylines.isNotEmpty) {
          await _persistenceService.persistPolylines(state.routePolylines);
        }

        if (state.currentDriverPosition != null) {
          await _persistenceService.persistDriverLocation(
            state.currentDriverPosition!,
            speed: state.currentSpeed,
            timestamp: state.lastPositionUpdate,
          );
        }

        if (state.isRealTimeTrackingActive && state.driverAccepted != null) {
          await _persistenceService.persistTrackingState(
            isActive: true,
            rideId: state.currentRideId ?? '',
            driverId: state.driverAccepted!.driverId ?? '',
            destination:
                _currentRideRequest != null
                    ? LatLng(
                      _currentRideRequest!.dropoffLocation.latitude,
                      _currentRideRequest!.dropoffLocation.longitude,
                    )
                    : null,
            trackingMetrics: _realTimeTrackingService.getTrackingMetrics(),
          );
        }

        _lastPersistenceTime = DateTime.now();
      } catch (e) {
        dev.log('Persistence error: $e');
      }
    });
  }

  Future<void> forcePersistence({String reason = 'manual'}) async {
    if (_isDisposed) return;

    try {
      if (state.hasActiveRide) {
        await _persistenceService.persistCompleteRideState(state);

        if (state.currentDriverPosition != null) {
          await _persistenceService.persistDriverLocation(
            state.currentDriverPosition!,
            speed: state.currentSpeed,
            timestamp: state.lastPositionUpdate,
          );
        }

        if (state.routeDisplayed && state.routePolylines.isNotEmpty) {
          final routePoints = state.routePolylines.first.points;
          await _persistenceService.persistRouteData(
            routePoints,
            segments: state.routeSegments,
            totalDistance: _routeService.calculateRouteDistance(routePoints),
          );
        }
      }
    } catch (e) {
      dev.log('Force persistence error: $e');
    }
  }

  // ============================================================================
  // RIDE STATE RESTORATION
  // ============================================================================

  Future<void> restoreFromPersistedData(PersistedRideData persistedData) async {
    if (_isDisposed) return;

    try {
      if (persistedData.rideRequest != null) {
        _currentRideRequest = persistedData.rideRequest;
      }

      // Load persisted polylines
      final restoredPolylines =
          await _persistenceService.loadPersistedPolylines();
      Set<Polyline> finalPolylines = {};
      if (restoredPolylines != null && restoredPolylines.isNotEmpty) {
        finalPolylines = restoredPolylines;
      }

      // Create markers using centralized method
      Map<MarkerId, Marker> finalMarkers = {};
      if (_currentRideRequest != null) {
        await _ensureMarkerIcons();
        finalMarkers = _createMarkers(
          rideRequest: _currentRideRequest!,
          driverPosition: persistedData.currentDriverPosition,
        );
      }

      final restoredState = RideState(
        status: persistedData.status,
        currentRideId: persistedData.rideId,
        rideResponse: persistedData.rideResponse,
        showRiderFound: persistedData.showRiderFound,
        riderAvailable: persistedData.riderAvailable,
        isSearching: persistedData.isSearching,
        searchTimeElapsed: persistedData.searchTimeElapsed,
        rideInProgress: persistedData.rideInProgress,
        driverHasArrived: persistedData.driverHasArrived,
        isRealTimeTrackingActive: false,
        isMultiDestination: persistedData.isMultiDestination,
        paymentMethod: persistedData.paymentMethod ?? 'cash',
        currentSpeed: persistedData.currentSpeed,
        lastPositionUpdate: persistedData.lastPositionUpdate,
        trackingStatusMessage: 'Restoring ride state...',
        routeRecalculated: persistedData.routeRecalculated,
        routeProgress: persistedData.routeProgress,
        driverOffRoute: persistedData.driverOffRoute,
        driverAnimationComplete: persistedData.driverAnimationComplete,
        currentSegmentIndex: persistedData.currentSegmentIndex,
        estimatedDistance: persistedData.estimatedDistance,
        estimatedTimeArrival: persistedData.estimatedTimeArrival,
        nearestDriverDistance: persistedData.nearestDriverDistance,
        lastRouteRecalculation: persistedData.lastRouteRecalculation,
        currentDriverPosition: persistedData.currentDriverPosition,
        cameraTarget: persistedData.cameraTarget,
        rideRequestModel: persistedData.rideRequest,
        driverAccepted: persistedData.driverAccepted,
        driverStarted: persistedData.driverStarted,
        driverArrived: persistedData.driverArrived,
        driverCompleted: persistedData.driverCompleted,
        driverCancelled: persistedData.driverCancelled,
        driverRejected: persistedData.driverRejected,
        routePolylines: finalPolylines,
        routeMarkers: finalMarkers,
        routeDisplayed: finalMarkers.isNotEmpty || finalPolylines.isNotEmpty,
        routeSegments: persistedData.routeSegments,
        showStackedBottomSheet: false,
        driverMarkerIcon: state.driverMarkerIcon,
        userLocationMarkerIcon: state.userLocationMarkerIcon,
      );

      emit(restoredState);
      _listenToDriverStatus();

      dev.log('✅ Ride state restored with ${finalMarkers.length} markers');
    } catch (e, stack) {
      dev.log('❌ Failed to restore ride state: $e');
      resetRideState();
    }
  }

  // ============================================================================
  // RIDE REQUEST FLOW
  // ============================================================================

  Future<void> requestRide(RideRequestModel request) async {
    if (_isDisposed) return;

    dev.log('🚗 Requesting ride: ${request.toJson()}');
    _currentRideRequest = request;

    await forcePersistence(reason: 'ride_request_initiated');

    emit(state.copyWith(status: RideRequestStatus.loading, errorMessage: null));

    try {
      await _processSingleDestinationRide(request);
    } catch (e) {
      emit(
        state.copyWith(
          status: RideRequestStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _processSingleDestinationRide(RideRequestModel request) async {
    emit(state.copyWith(rideRequestModel: request));
    final response = await rideRequestRepository.requestRide(request);

    response.fold(
      (failure) {
        emit(
          state.copyWith(
            status: RideRequestStatus.error,
            errorMessage: failure.message,
          ),
        );
      },
      (rideResponse) {
        emit(
          state.copyWith(
            status: RideRequestStatus.searching,
            rideResponse: rideResponse,
            currentRideId: rideResponse.data.rideId,
            showStackedBottomSheet: false,
            showRiderFound: false,
            isSearching: true,
            riderAvailable: false,
          ),
        );

        _persistCurrentStateAsync();
        _startTimer();
        _listenToDriverStatus();
      },
    );
  }

  RideRequestModel createRideRequestFromHomeState({
    required FreedomLocation pickupLocation,
    required FreedomLocation mainDestination,
    required List<FreedomLocation> additionalDestinations,
    required String paymentMethod,
    String promoCode = '',
  }) {
    final validAdditionalDestinations =
        additionalDestinations
            .where(
              (loc) =>
                  loc.latitude != 0 &&
                  loc.longitude != 0 &&
                  (loc.latitude != mainDestination.latitude ||
                      loc.longitude != mainDestination.longitude),
            )
            .toList();

    return RideRequestModel(
      pickupLocation: pickupLocation,
      dropoffLocation: mainDestination,
      additionalDestinations:
          validAdditionalDestinations.isEmpty
              ? null
              : validAdditionalDestinations,
      paymentMethod: paymentMethod,
      isMultiDestination: validAdditionalDestinations.isNotEmpty,
      promoCode: promoCode,
    );
  }

  // ============================================================================
  // TIMER MANAGEMENT
  // ============================================================================

  void _startTimer() {
    _timer?.cancel();
    emit(state.copyWith(searchTimeElapsed: 0));

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (searchTimeElapsed < maxSearchTime) {
        searchTimeElapsed++;
        emit(state.copyWith(searchTimeElapsed: searchTimeElapsed));
      } else {
        emit(
          state.copyWith(
            isSearching: false,
            searchTimeElapsed: 0,
            requestRidesStatus: RequestRidesStatus.initial,
            status: RideRequestStatus.noDriverFound,
            showStackedBottomSheet: true,
            showRiderFound: false,
            riderAvailable: false,
          ),
        );
        _timer?.cancel();
        _timer = null;
      }
    });
  }

  void _stopSearchTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void resumeSearchTimer() {
    _startTimer();
  }

  // ============================================================================
  // SOCKET LISTENERS
  // ============================================================================

  void _initSocketListener() {
    _driverStatusSubscription?.cancel();
    _driverStatusSubscription = null;
    _driverCancelledSubscription?.cancel();
    _driverCancelledSubscription = null;
  }

  void _listenToDriverStatus() {
    final socketService = getIt<SocketService>();
    _cancelAllSubscriptions();

    _driverStatusSubscription = socketService.onDriverAcceptRide.listen((
      data,
    ) async {
      _stopSearchTimer();

      emit(
        state.copyWith(
          status: RideRequestStatus.success,
          showRiderFound: true,
          riderAvailable: true,
          showStackedBottomSheet: false,
          driverAccepted: data,
          isRealTimeTrackingActive: false,
          rideInProgress: false,
        ),
      );

      try {
        await displayStaticRoute();
        await forcePersistence(reason: 'driver_accepted');
      } catch (e) {
        emit(state.copyWith(errorMessage: 'Failed to display route: $e'));
      }
    });

    _driverStartedSubscription = socketService.onDriverStarted.listen((
      data,
    ) async {
      emit(
        state.copyWith(
          driverStarted: data,
          rideInProgress: true,
          isRealTimeTrackingActive: false,
        ),
      );

      await _startRealTimeTracking();
      await forcePersistence(reason: 'ride_started');
    });

    _driverArrivedSubscription = socketService.onDriverArrived.listen((data) {
      emit(state.copyWith(driverArrived: data, driverHasArrived: true));
      forcePersistence(reason: 'driver_arrived');
    });

    _driverPositionSubscription = socketService.onDriverLocation.listen((
      locationData,
    ) {
      if (state.isRealTimeTrackingActive && state.rideInProgress) {
        _realTimeTrackingService.processDriverLocation(locationData);
      }
    });

    _driverCancelledSubscription = socketService.onDriverCancelled.listen((
      data,
    ) {
      _stopAllTrackingAndReset();
      emit(
        state.copyWith(
          driverCancelled: data,
          rideInProgress: false,
          showRiderFound: false,
          riderAvailable: false,
          showStackedBottomSheet: true,
          isSearching: false,
        ),
      );
      _persistenceService.clearRideData();
    });

    _driverCompletedSubscription = socketService.onDriverCompleted.listen((
      data,
    ) {
      _stopAllTrackingAndReset();
      resetRideState();
      _persistenceService.clearRideData();
    });

    _driverRejectedSubscription = socketService.onDriverRejected.listen((data) {
     
      emit(state.copyWith(driverRejected: data));
    });
  }

  void _cancelAllSubscriptions() {
    _driverStatusSubscription?.cancel();
    _driverCancelledSubscription?.cancel();
    _driverAcceptedSubscription?.cancel();
    _driverArrivedSubscription?.cancel();
    _driverCompletedSubscription?.cancel();
    _driverStartedSubscription?.cancel();
    _driverRejectedSubscription?.cancel();
    _driverPositionSubscription?.cancel();
  }

  // ============================================================================
  // ROUTE DISPLAY AND TRACKING
  // ============================================================================

  Future<void> displayStaticRoute() async {
    if (_currentRideRequest == null) return;

    try {
      await _ensureMarkerIcons();

      final request = _currentRideRequest!;
      final pickup = LatLng(
        request.pickupLocation.latitude,
        request.pickupLocation.longitude,
      );

      if (request.isMultiDestination &&
          request.additionalDestinations != null &&
          request.additionalDestinations!.isNotEmpty) {
        await _displayMultiDestinationRoute(request, pickup);
      } else {
        await _displaySingleDestinationRoute(request, pickup);
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Route display failed: $e'));
    }
  }

  Future<void> _displaySingleDestinationRoute(
    RideRequestModel request,
    LatLng pickup,
  ) async {
    final destination = LatLng(
      request.dropoffLocation.latitude,
      request.dropoffLocation.longitude,
    );

    final routeResult = await _routeService.getRoute(pickup, destination);

    if (routeResult.isSuccess && routeResult.polyline != null) {
      await _persistenceService.persistRouteData(
        routeResult.routePoints!,
        totalDistance: _routeService.calculateRouteDistance(
          routeResult.routePoints!,
        ),
      );

      // Use centralized marker creation
      final markers = _createMarkers(
        rideRequest: request,
        driverPosition: pickup,
      );

      emit(
        state.copyWith(
          routePolylines: {routeResult.polyline!},
          routeMarkers: markers,
          routeDisplayed: true,
          currentDriverPosition: pickup,
          isRealTimeTrackingActive: false,
        ),
      );

      focusCameraOnRoute();
      dev.log('✅ Static route displayed with ${markers.length} markers');
    } else {
      emit(state.copyWith(errorMessage: 'Failed to load route'));
    }
  }

  Future<void> _displayMultiDestinationRoute(
    RideRequestModel request,
    LatLng pickup,
  ) async {
    final destinations = <LatLng>[
      LatLng(
        request.dropoffLocation.latitude,
        request.dropoffLocation.longitude,
      ),
    ];

    for (final dest in request.additionalDestinations!) {
      destinations.add(LatLng(dest.latitude, dest.longitude));
    }

    final routesResult = await _routeService.getRoutesForMultipleDestinations(
      pickup,
      destinations,
    );

    if (routesResult.isSuccess && routesResult.polylines != null) {
      // Use centralized marker creation
      final markers = _createMarkers(
        rideRequest: request,
        driverPosition: pickup,
      );

      emit(
        state.copyWith(
          routePolylines: routesResult.polylines!,
          routeMarkers: markers,
          routeDisplayed: true,
          routeSegments: routesResult.routeSegments,
          currentDriverPosition: pickup,
          isRealTimeTrackingActive: false,
        ),
      );

      focusCameraOnRoute();
    } else {
      emit(
        state.copyWith(errorMessage: 'Failed to load multi-destination route'),
      );
    }
  }

  Future<void> _startRealTimeTracking() async {
    if (_currentRideRequest == null || _isDisposed) return;

    try {
      final destination = LatLng(
        _currentRideRequest!.dropoffLocation.latitude,
        _currentRideRequest!.dropoffLocation.longitude,
      );

      final rideId = state.driverAccepted?.rideId ?? state.currentRideId ?? '';
      final driverId = state.driverAccepted?.driverId ?? '';

      if (rideId.isEmpty || driverId.isEmpty) {
        dev.log(
          '❌ Missing IDs for tracking: rideId($rideId) driverId($driverId)',
        );
        return;
      }

      _animationService.transitionToRealTimeTracking(
        onPositionUpdate: (position, rotation) {
          _updateDriverMarker(position, rotation);
        },
      );

      _realTimeTrackingService.startTracking(
        rideId: rideId,
        driverId: driverId,
        destination: destination,
        onPositionUpdate: handleRealTimePositionUpdate,
        onRouteUpdated: _updateRouteOnMap,
        onStatusUpdate: _updateTrackingStatusThrottled,
        onMarkerUpdate: _handlePreciseMarkerUpdate,
      );

      emit(
        state.copyWith(
          isRealTimeTrackingActive: true,
          trackingStatusMessage: 'Live tracking started',
          followDriverCamera: true,
          cameraFollowingMode: CameraFollowingMode.followDriver,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Failed to start live tracking: $e',
          trackingStatusMessage: 'Live tracking failed to start',
        ),
      );
    }
  }

  void handleRealTimePositionUpdate(
    LatLng position,
    double bearing,
    DriverLocationData locationData,
  ) {
    if (!state.isRealTimeTrackingActive ||
        !state.rideInProgress ||
        _isDisposed) {
      return;
    }

    _animationService.updateRealTimePosition(
      position,
      bearing,
      locationData: {
        'speed': locationData.speed,
        'accuracy': locationData.accuracy,
        'timestamp': locationData.lastUpdate.toIso8601String(),
      },
    );

    _updateDriverMarker(position, bearing);

    emit(
      state.copyWith(
        currentDriverPosition: position,
        lastPositionUpdate: locationData.lastUpdate,
        currentSpeed: locationData.speed,
        trackingStatusMessage: _getEnhancedTrackingMessage(locationData),
        // Trigger camera update when following driver
        shouldUpdateCamera: state.followDriverCamera,
        cameraTarget: state.followDriverCamera ? position : state.cameraTarget,
      ),
    );

    // Auto-follow camera if enabled
    if (state.followDriverCamera) {
      _updateCameraToFollowDriver(position);
    }

    // Periodic persistence
    if (DateTime.now().millisecondsSinceEpoch % 5000 < 100) {
      _persistenceService.persistDriverLocation(
        position,
        speed: locationData.speed,
        bearing: bearing,
        timestamp: locationData.lastUpdate,
      );
    }

    if (_realTimeTrackingService.hasReachedDestination(position)) {
      _handleDriverReachedDestination();
    }
  }

  void _updateCameraToFollowDriver(LatLng driverPosition) {
    if (!state.followDriverCamera || _isDisposed) return;

    switch (state.cameraFollowingMode) {
      case CameraFollowingMode.followDriver:
        // Simple follow - just center on driver
        _centerCameraOnPosition(driverPosition);
        break;

      case CameraFollowingMode.followWithRoute:
        // Follow driver but keep route visible
        _centerCameraOnDriverWithRoute(driverPosition);
        break;

      case CameraFollowingMode.showRoute:
        // Show full route
        focusCameraOnRoute();
        break;

      case CameraFollowingMode.none:
        // No automatic camera updates
        break;
    }
  }

  void _centerCameraOnDriverWithRoute(LatLng driverPosition) {
    if (state.routePolylines.isEmpty) {
      _centerCameraOnPosition(driverPosition);
      return;
    }

    // Calculate bounds that include driver and route
    final routePoints = state.routePolylines.first.points;
    final allPoints = [driverPosition, ...routePoints];

    emit(
      state.copyWith(shouldUpdateCamera: true, cameraTarget: driverPosition),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!isClosed) {
        emit(state.copyWith(shouldUpdateCamera: false));
      }
    });
  }

  /// Center camera on specific position
  void _centerCameraOnPosition(LatLng position) {
    emit(state.copyWith(shouldUpdateCamera: true, cameraTarget: position));

    // Reset camera update flag after short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!isClosed) {
        emit(state.copyWith(shouldUpdateCamera: false));
      }
    });
  }

  String _getEnhancedTrackingMessage(DriverLocationData locationData) {
    if (locationData.speed > 15.0) {
      return 'Driver moving fast (${locationData.speed.toStringAsFixed(0)} km/h)';
    } else if (locationData.speed > 5.0) {
      return 'Driver moving (${locationData.speed.toStringAsFixed(0)} km/h)';
    } else if (locationData.speed > 1.0) {
      return 'Driver moving slowly';
    } else {
      return 'Driver stationary';
    }
  }

  void _updateRouteOnMap(List<LatLng> newRoutePoints) {
    if (_isDisposed) return;

    try {
      if (state.routePolylines.isEmpty) return;

      final currentPolyline = state.routePolylines.first;
      final updatedPolyline = currentPolyline.copyWith(
        pointsParam: newRoutePoints,
      );

      emit(
        state.copyWith(
          routePolylines: {updatedPolyline},
          routeRecalculated: true,
          trackingStatusMessage: 'Route updated',
        ),
      );

      Future.delayed(const Duration(seconds: 3), () {
        if (!isClosed) {
          emit(state.copyWith(routeRecalculated: false));
        }
      });
    } catch (e) {
      dev.log('Route update error: $e');
    }
  }

  void _updateTrackingStatusThrottled(String status) {
    _pendingStatusMessage = status;

    if (_statusUpdateThrottle?.isActive != true) {
      _statusUpdateThrottle = Timer(_statusUpdateInterval, () {
        _performThrottledStatusUpdate();
      });
    }
  }

  void _performThrottledStatusUpdate() {
    if (_pendingStatusMessage == null || _isDisposed) return;

    final status = _pendingStatusMessage!;
    final currentTime = DateTime.now();

    if (_lastStatusUpdate != null &&
        currentTime.difference(_lastStatusUpdate!).inSeconds < 2 &&
        status.contains('position updated')) {
      _pendingStatusMessage = null;
      return;
    }

    _lastStatusUpdate = currentTime;

    emit(state.copyWith(trackingStatusMessage: status));

    final duration =
        status.contains('error') || status.contains('failed')
            ? const Duration(seconds: 8)
            : const Duration(seconds: 4);

    Future.delayed(duration, () {
      if (!isClosed) {
        emit(state.copyWith(trackingStatusMessage: null));
      }
    });

    _pendingStatusMessage = null;
  }

  void _handlePreciseMarkerUpdate(LatLng position) {
    if (_isDisposed) return;

    if (_animationService.isRealTimeTracking) {
      _animationService.updateRealTimePosition(
        position,
        _animationService.currentBearing,
      );
    }
  }

  void _handleDriverReachedDestination() {
    if (_isDisposed) return;

    _stopAllTrackingAndReset();
    emit(
      state.copyWith(
        isRealTimeTrackingActive: false,
        trackingStatusMessage: 'Driver arrived at destination',
      ),
    );
  }

  void _stopAllTrackingAndReset() {
    _realTimeTrackingService.stopTracking();
    _animationService.stopAll();
    _animationService.stopRealTimeTracking();

    emit(
      state.copyWith(
        routePolylines: const {},
        routeMarkers: const {},
        routeDisplayed: false,
        routeSegments: null,
        currentDriverPosition: null,
        isRealTimeTrackingActive: false,
        rideInProgress: false,
        trackingStatusMessage: null,
        // Reset camera following
        followDriverCamera: false,
        cameraFollowingMode: CameraFollowingMode.none,
        shouldUpdateCamera: false,
        cameraTarget: null,
      ),
    );
  }
  // ============================================================================
  // RIDE STATUS AND RESTORATION
  // ============================================================================

  Future<void> checkRideStatus(String rideId) async {
    if (_isDisposed) return;

    try {
      emit(state.copyWith(status: RideRequestStatus.loading));

      final response = await rideRequestRepository.checkRideStatus(rideId);

      await response.fold(
        (failure) {
          emit(
            state.copyWith(
              status: RideRequestStatus.error,
              errorMessage: failure.message,
            ),
          );
        },
        (statusResponse) async {
          final currentStatus = statusResponse.data.status;
          switch (currentStatus) {
            case 'accepted':
              emit(
                state.copyWith(
                  status: RideRequestStatus.success,
                  showRiderFound: true,
                  riderAvailable: true,
                  showStackedBottomSheet: false,
                  isRealTimeTrackingActive: false,
                  rideInProgress: false,
                ),
              );
              await restoreStaticRoute();
              break;

            case 'in_progress':
              emit(
                state.copyWith(
                  status: RideRequestStatus.success,
                  showRiderFound: true,
                  riderAvailable: true,
                  showStackedBottomSheet: false,
                  rideInProgress: true,
                ),
              );
              await restoreRealTimeTracking();
              break;

            case 'arrived':
              emit(
                state.copyWith(
                  status: RideRequestStatus.success,
                  showRiderFound: true,
                  riderAvailable: true,
                  driverHasArrived: true,
                  showStackedBottomSheet: false,
                ),
              );
              await restoreStaticRoute();
              break;

            case 'completed':
              _stopAllTrackingAndReset();
              emit(
                state.copyWith(
                  status: RideRequestStatus.completed,
                  showStackedBottomSheet: true,
                  showRiderFound: false,
                ),
              );
              await _persistenceService.clearRideData();
              break;

            case 'cancelled':
              _stopAllTrackingAndReset();
              emit(
                state.copyWith(
                  status: RideRequestStatus.cancelled,
                  showStackedBottomSheet: true,
                  showRiderFound: false,
                ),
              );
              await _persistenceService.clearRideData();
              break;

            default:
              emit(
                state.copyWith(
                  status: RideRequestStatus.searching,
                  isSearching: true,
                ),
              );
              resumeSearchTimer();
          }
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: RideRequestStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> restoreStaticRoute() async {
    if (_isDisposed) return;

    try {
      await _ensureMarkerIcons();

      final routeData = await _persistenceService.loadRouteData();

      if (routeData != null && routeData.routePoints.isNotEmpty) {
        await _restoreRouteFromPersistedData(routeData);
      } else if (_currentRideRequest != null) {
        await displayStaticRoute();
      } else {
        emit(state.copyWith(trackingStatusMessage: 'No route data available'));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to restore route: $e'));
    }
  }

  Future<void> _restoreRouteFromPersistedData(
    PersistedRouteData routeData,
  ) async {
    if (_isDisposed || routeData.routePoints.isEmpty) return;

    try {
      final polyline = Polyline(
        polylineId: const PolylineId('restored_route'),
        color: Colors.orange,
        points: routeData.routePoints,
        width: 5,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      );

      // Create markers using centralized method
      Map<MarkerId, Marker> markers = {};

      if (_currentRideRequest != null) {
        markers = _createMarkers(
          rideRequest: _currentRideRequest!,
          driverPosition: state.currentDriverPosition,
        );
      } else {
        // Fallback: create basic markers from route points
        const pickupMarkerId = MarkerId('pickup_location');
        markers[pickupMarkerId] = Marker(
          markerId: pickupMarkerId,
          position: routeData.routePoints.first,
          icon:
              state.userLocationMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Pickup'),
        );

        const destinationMarkerId = MarkerId('destination_location');
        markers[destinationMarkerId] = Marker(
          markerId: destinationMarkerId,
          position: routeData.routePoints.last,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Destination'),
        );

        if (state.currentDriverPosition != null) {
          const driverMarkerId = MarkerId('driver_location');
          markers[driverMarkerId] = Marker(
            markerId: driverMarkerId,
            position: state.currentDriverPosition!,
            icon:
                state.driverMarkerIcon ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(title: 'Driver Location'),
          );
        }
      }

      emit(
        state.copyWith(
          routePolylines: {polyline},
          routeMarkers: markers,
          routeDisplayed: true,
          trackingStatusMessage: 'Route restored from cache',
        ),
      );

      dev.log('✅ Route restored with ${markers.length} markers');
    } catch (e) {
      throw e;
    }
  }

  Future<void> restoreRealTimeTracking() async {
    if (_isDisposed) return;

    try {
      await restoreStaticRoute();
      await Future.delayed(const Duration(milliseconds: 1000));

      final trackingState = await _persistenceService.loadTrackingState();
      final lastLocation = await _persistenceService.loadLastDriverLocation();

      if (trackingState != null && trackingState.isActive) {
        await _startRealTimeTracking();

        if (lastLocation != null) {
          handleRealTimePositionUpdate(
            lastLocation.latLng,
            lastLocation.bearing ?? 0.0,
            DriverLocationData(
              position: lastLocation.latLng,
              isMultiStop: false,
              isSignificantMovement: false,
              speed: lastLocation.speed ?? 0.0,
              accuracy: 10.0,
              lastUpdate: lastLocation.timestamp,
            ),
          );
        }

        emit(state.copyWith(trackingStatusMessage: 'Live tracking restored'));
      } else {
        emit(
          state.copyWith(
            trackingStatusMessage: 'Unable to restore live tracking',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Failed to restore tracking: $e',
          trackingStatusMessage: 'Tracking restoration failed',
        ),
      );
    }
  }

  // ============================================================================
  // RIDE OPERATIONS
  // ============================================================================

  Future<void> cancelRide({required String reason}) async {
    if (_isDisposed) return;

    try {
      emit(
        state.copyWith(cancellationStatus: RideCancellationStatus.canceling),
      );
      _stopSearchTimer();
      _stopAllTrackingAndReset();

      if (state.currentRideId == null) {
        throw Exception('No active ride to cancel');
      }

      final response = await rideRequestRepository.cancelRide(
        state.currentRideId!,
        reason,
      );

      response.fold(
        (failure) {
          emit(
            state.copyWith(
              cancellationStatus: RideCancellationStatus.error,
              errorMessage: failure.message,
            ),
          );
        },
        (success) {
          emit(
            state.copyWith(
              cancellationStatus: RideCancellationStatus.cancelled,
              message: success.message,
              showStackedBottomSheet: true,
              showRiderFound: false,
            ),
          );

          _persistenceService.clearRideData();
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          cancellationStatus: RideCancellationStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> getRides(String status, int page, int limit) async {
    emit(state.copyWith(requestRidesStatus: RequestRidesStatus.loading));

    final response = await rideRequestRepository.getRideHistory(
      status,
      page,
      limit,
    );

    response.fold(
      (failure) {
        emit(
          state.copyWith(
            requestRidesStatus: RequestRidesStatus.error,
            errorMessage: failure.message,
          ),
        );
      },
      (success) {
        emit(
          state.copyWith(
            requestRidesStatus: RequestRidesStatus.success,
            rideHistory: success.data,
          ),
        );
      },
    );
  }

  // ============================================================================
  // CAMERA AND UI CONTROLS
  // ============================================================================

  void focusCameraOnRoute() {
    if (state.routePolylines.isEmpty) return;

    emit(
      state.copyWith(
        shouldUpdateCamera: true,
        cameraFollowingMode: CameraFollowingMode.showRoute,
        followDriverCamera: false,
      ),
    );

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!isClosed) {
        emit(state.copyWith(shouldUpdateCamera: false));
      }
    });
  }

  void centerCameraOnDriver() {
    if (state.currentDriverPosition != null) {
      emit(
        state.copyWith(
          shouldUpdateCamera: true,
          cameraTarget: state.currentDriverPosition,
          followDriverCamera: true,
          cameraFollowingMode: CameraFollowingMode.followDriver,
        ),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (!isClosed) {
          emit(state.copyWith(shouldUpdateCamera: false));
        }
      });
    }
  }

  void setPayMentMethod(String paymentMethod) {
    emit(state.copyWith(paymentMethod: paymentMethod));
  }

  // ============================================================================
  // ROUTE PROGRESS AND TRACKING METRICS
  // ============================================================================

  TrackingStatus getTrackingStatus() {
    return _realTimeTrackingService.getTrackingStatus();
  }

  RouteProgress? getCurrentRouteProgress() {
    if (!_realTimeTrackingService.isTracking) return null;

    final trackingStatus = _realTimeTrackingService.getTrackingStatus();

    if (!trackingStatus.isReceivingRegularUpdates ||
        trackingStatus.lastKnownPosition == null) {
      return null;
    }

    try {
      final driverPosition = trackingStatus.lastKnownPosition!;
      final destination = trackingStatus.destination;

      if (destination != null) {
        final distanceToDestination = _calculateDistanceInMeters(
          LatLng(driverPosition.latitude, driverPosition.longitude),
          LatLng(destination.latitude, destination.longitude),
        );

        final routePoints = _realTimeTrackingService.currentRoutePoints;
        final totalDistance =
            routePoints.isNotEmpty
                ? _calculateTotalRouteDistance(routePoints)
                : distanceToDestination + 1000;

        final progress =
            routePoints.isNotEmpty
                ? _calculateActualProgress(driverPosition, routePoints)
                : (1.0 - (distanceToDestination / totalDistance)).clamp(
                  0.0,
                  1.0,
                );

        return RouteProgress(
          progress: progress,
          distanceCovered: totalDistance * progress,
          remainingDistance: distanceToDestination,
          totalDistance: totalDistance,
          estimatedTimeRemaining: _calculateEnhancedETA(
            distanceToDestination,
            trackingStatus,
          ),
        );
      }
    } catch (e) {
      dev.log('Route progress calculation error: $e');
    }

    return null;
  }

  double _calculateTotalRouteDistance(List<LatLng> routePoints) {
    double totalDistance = 0.0;

    for (int i = 0; i < routePoints.length - 1; i++) {
      final point1 = routePoints[i];
      final point2 = routePoints[i + 1];
      totalDistance += _calculateDistanceInMeters(point1, point2);
    }

    return totalDistance;
  }

  double _calculateActualProgress(
    LatLng driverPosition,
    List<LatLng> routePoints,
  ) {
    if (routePoints.length < 2) return 0.0;

    double minDistance = double.infinity;
    int closestSegmentIndex = 0;

    for (int i = 0; i < routePoints.length - 1; i++) {
      final point1 = routePoints[i];
      final point2 = routePoints[i + 1];

      final distance = _calculateDistanceToLineSegment(
        driverPosition,
        point1,
        point2,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestSegmentIndex = i;
      }
    }

    final totalSegments = routePoints.length - 1;
    return totalSegments > 0 ? closestSegmentIndex / totalSegments : 0.0;
  }

  double _calculateDistanceToLineSegment(
    LatLng point,
    LatLng lineStart,
    LatLng lineEnd,
  ) {
    final startDistance = _calculateDistanceInMeters(point, lineStart);
    final endDistance = _calculateDistanceInMeters(point, lineEnd);
    return math.min(startDistance, endDistance);
  }

  Duration _calculateEnhancedETA(
    double distanceMeters,
    TrackingStatus trackingStatus,
  ) {
    final recentHistory = _realTimeTrackingService.locationHistory;
    double averageSpeedMps = 8.33;

    if (recentHistory.isNotEmpty) {
      final recentSpeeds =
          recentHistory
              .where(
                (h) => DateTime.now().difference(h.timestamp).inMinutes < 5,
              )
              .map((h) => h.speed * 1000 / 3600)
              .where((speed) => speed > 1.0)
              .toList();

      if (recentSpeeds.isNotEmpty) {
        averageSpeedMps =
            recentSpeeds.reduce((a, b) => a + b) / recentSpeeds.length;
      }
    }

    final etaSeconds = distanceMeters / averageSpeedMps;
    return Duration(seconds: etaSeconds.round());
  }

  double _calculateDistanceInMeters(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000;

    final lat1Rad = point1.latitude * math.pi / 180;
    final lat2Rad = point2.latitude * math.pi / 180;
    final dLat = (point2.latitude - point1.latitude) * math.pi / 180;
    final dLng = (point2.longitude - point1.longitude) * math.pi / 180;

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  Future<void> forceRouteRecalculation() async {
    if (!_realTimeTrackingService.isTracking || _isDisposed) return;

    final driverPosition = _realTimeTrackingService.lastKnownDriverPosition;
    final destination = _realTimeTrackingService.currentDestination;

    if (driverPosition != null && destination != null) {
      try {
        emit(state.copyWith(trackingStatusMessage: 'Recalculating route...'));

        final routeResult = await _routeService.getRoute(
          driverPosition,
          destination,
        );

        if (routeResult.isSuccess && routeResult.polyline != null) {
          _updateRouteOnMap(routeResult.polyline!.points);
          _updateTrackingStatusThrottled('Route recalculated');
        } else {
          _updateTrackingStatusThrottled('Route recalculation failed');
        }
      } catch (e) {
        _updateTrackingStatusThrottled('Route recalculation error');
      }
    }
  }

  // ============================================================================
  // LIFECYCLE AND STATE MANAGEMENT
  // ============================================================================

  Future<void> handleAppLifecycleChange(
    AppLifecycleState lifecycleState,
  ) async {
    if (_isDisposed) return;

    switch (lifecycleState) {
      case AppLifecycleState.paused:
        await forcePersistence(reason: 'app_paused');
        break;

      case AppLifecycleState.resumed:
        if (state.currentRideId != null) {
          await checkRideStatus(state.currentRideId!);
        }
        break;

      case AppLifecycleState.detached:
        await forcePersistence(reason: 'app_detached');
        break;

      default:
        break;
    }
  }

  void resetRideState() {
    _stopAllTrackingAndReset();
    _persistenceService.clearRideData();

    emit(
      const RideState(
        status: RideRequestStatus.initial,
        showStackedBottomSheet: true,
        showRiderFound: false,
        isSearching: false,
        searchTimeElapsed: 0,
        riderAvailable: false,
        isMultiDestination: false,
        paymentMethod: 'cash',
        currentRideId: null,
        rideResponse: null,
        errorMessage: null,
        requestRidesStatus: RequestRidesStatus.initial,
        routeDisplayed: false,
        routePolylines: {},
        routeMarkers: {},
        routeSegments: null,
        currentDriverPosition: null,
        driverHasArrived: false,
        rideInProgress: false,
        isRealTimeTrackingActive: false,
        trackingStatusMessage: null,
        routeRecalculated: false,
        currentSpeed: 0.0,
      ),
    );
  }

  // ============================================================================
  // DEBUG AND METRICS
  // ============================================================================

  Map<String, dynamic> getEnhancedTrackingMetrics() {
    final baseMetrics = _realTimeTrackingService.getTrackingMetrics();
    final performanceMetrics = _realTimeTrackingService.getPerformanceMetrics();
    final issues = _realTimeTrackingService.validateTrackingState();

    return {
      ...baseMetrics,
      'performance': performanceMetrics,
      'issues': issues,
      'uiTrackingActive': state.isRealTimeTrackingActive,
      'rideInProgress': state.rideInProgress,
      'socketConnected': getIt<SocketService>().isConnected,
      'currentRideId': state.currentRideId,
      'driverAcceptedId': state.driverAccepted?.driverId,
      'lastPersistenceTime': _lastPersistenceTime?.toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> getRidePersistenceStats() async {
    try {
      final stats = await _persistenceService.getPersistenceStats();
      return {
        ...stats,
        'cubitInitialized': true,
        'hasActiveRide': state.hasActiveRide,
        'lastPersistenceTime': _lastPersistenceTime?.toIso8601String(),
        'isDisposed': _isDisposed,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ============================================================================
  // DISPOSAL
  // ============================================================================

  @override
  Future<void> close() async {
    _isDisposed = true;

    _statusUpdateThrottle?.cancel();
    _cancelAllSubscriptions();
    _timer?.cancel();
    _persistenceTimer?.cancel();

    _animationService.dispose();
    _realTimeTrackingService.stopTracking();

    if (state.hasActiveRide) {
      await forcePersistence(reason: 'cubit_disposed');
    }

    return super.close();
  }
}

// ============================================================================
// ROUTE PROGRESS MODEL
// ============================================================================

class RouteProgress {
  final double progress;
  final double distanceCovered;
  final double remainingDistance;
  final double totalDistance;
  final Duration estimatedTimeRemaining;

  const RouteProgress({
    required this.progress,
    required this.distanceCovered,
    required this.remainingDistance,
    required this.totalDistance,
    required this.estimatedTimeRemaining,
  });

  String get formattedRemainingDistance {
    if (remainingDistance < 1000) {
      return '${remainingDistance.round()} m';
    } else {
      return '${(remainingDistance / 1000).toStringAsFixed(1)} km';
    }
  }

  String get formattedETA {
    final hours = estimatedTimeRemaining.inHours;
    final minutes = estimatedTimeRemaining.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  String toString() {
    return 'RouteProgress(progress: $progress, remainingDistance: $formattedRemainingDistance, ETA: $formattedETA)';
  }
}
