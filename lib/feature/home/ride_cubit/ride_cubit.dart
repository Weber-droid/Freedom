import 'dart:math' as math;
import 'dart:developer' as dev;
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:freedom/core/services/real_time_driver_tracking.dart';
import 'package:freedom/core/services/push_notification_service/socket_ride_models.dart';
import 'package:freedom/core/services/route_animation_services.dart';
import 'package:freedom/core/services/route_services.dart';
import 'package:freedom/core/services/socket_service.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/History/model/history_model.dart';
import 'package:freedom/feature/home/models/multiple_stop_ride_model.dart';
import 'package:freedom/feature/home/models/request_ride_model.dart';
import 'package:freedom/feature/home/models/request_ride_response.dart';
import 'package:freedom/feature/home/models/ride_status_response.dart';
import 'package:freedom/feature/home/repository/models/location.dart' as loc;
import 'package:freedom/feature/home/repository/ride_request_repository.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

part 'ride_state.dart';

class RideCubit extends Cubit<RideState> {
  RideCubit({
    required this.rideRequestRepository,
    RouteService? routeService,
    RouteAnimationService? animationService,
    RealTimeDriverTrackingService? trackingService,
  }) : _routeService = routeService ?? getIt<RouteService>(),
       _animationService = animationService ?? getIt<RouteAnimationService>(),
       _realTimeTrackingService =
           trackingService ?? getIt<RealTimeDriverTrackingService>(),
       super(const RideState()) {
    _initSocketListener();
  }

  final RideRequestRepository rideRequestRepository;
  final RouteService _routeService;
  final RouteAnimationService _animationService;
  final RealTimeDriverTrackingService _realTimeTrackingService;
  DateTime? _lastStatusUpdate;

  // Socket subscriptions
  StreamSubscription<dynamic>? _driverStatusSubscription;
  StreamSubscription<dynamic>? _driverCancelledSubscription;
  StreamSubscription<dynamic>? _driverAcceptedSubscription;
  StreamSubscription<dynamic>? _driverArrivedSubscription;
  StreamSubscription<dynamic>? _driverCompletedSubscription;
  StreamSubscription<dynamic>? _driverStartedSubscription;
  StreamSubscription<dynamic>? _driverRejecetedSubscription;
  StreamSubscription<dynamic>? _driverPositionSubscription;

  Timer? _timer;
  static const int maxSearchTime = 60;

  RideRequestModel? _currentRideRequest;

  RideRequestModel? get currentRideRequest => _currentRideRequest;

  set searchTimeElapsed(int searchTimeElapsed) =>
      emit(state.copyWith(searchTimeElapsed: searchTimeElapsed));

  int get searchTimeElapsed => state.searchTimeElapsed;

  void _initSocketListener() {
    _driverStatusSubscription?.cancel();
    _driverStatusSubscription = null;
    _driverCancelledSubscription?.cancel();
    _driverCancelledSubscription = null;
  }

  void setPayMentMethod(String paymentMethod) {
    emit(state.copyWith(paymentMethod: paymentMethod));
  }

  Future<void> requestRide(RideRequestModel request) async {
    dev.log('requestRide from ride cubit: ${request.toJson()}');

    _currentRideRequest = request;

    dev.log('_currentRideRequest set: ${_currentRideRequest?.toJson()}');

    emit(state.copyWith(status: RideRequestStatus.loading, errorMessage: null));

    try {
      final hasMultipleDestinations =
          request.isMultiDestination &&
          request.additionalDestinations != null &&
          request.additionalDestinations!.isNotEmpty;

      dev.log(
        'Requesting ride with ${hasMultipleDestinations ? "multiple destinations" : "single destination"}',
      );

      if (hasMultipleDestinations) {
        dev.log(
          'Number of additional destinations: ${request.additionalDestinations!.length}',
        );
        await _processMultiDestinationRide(request);
      } else {
        await _processSingleDestinationRide(request);
      }
    } catch (e) {
      dev.log('Exception in requestRide: $e');
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
        dev.log('Ride request failed: ${failure.message}');
        emit(
          state.copyWith(
            status: RideRequestStatus.error,
            errorMessage: failure.message,
          ),
        );
      },
      (rideResponse) {
        dev.log(
          'Ride request successful. Ride ID: ${rideResponse.data.rideId}',
        );

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

        _startTimer();
        _listenToDriverStatus();
      },
    );
  }

  Future<void> _processMultiDestinationRide(RideRequestModel request) async {
    try {
      final multiStopModel = _convertToMultiStopModel(request);

      dev.log('converted to multi stop model: ${multiStopModel.toJson()}');

      final response = await rideRequestRepository.requestMultipleStopRide(
        multiStopModel,
      );

      response.fold(
        (failure) {
          dev.log('Multiple stop ride request failed: ${failure.message}');
          emit(
            state.copyWith(
              status: RideRequestStatus.error,
              errorMessage: failure.message,
            ),
          );
        },
        (multiStopResponse) {
          dev.log('Multiple stop ride request successful');

          final rideId = state.currentRideId;

          final requestData = RequestData(
            rideId: rideId,
            fare: '0.0',
            currency: 'NGN',
            rideStatus: RideStatus.searching,
            paymentMethod: request.paymentMethod,
            notifiedDriverCount: 0,
          );

          final standardResponse = RequestRideResponse(
            success: true,
            message: 'Multiple destination ride requested successfully',
            data: requestData,
          );

          emit(
            state.copyWith(
              status: RideRequestStatus.searching,
              rideResponse: standardResponse,
              currentRideId: rideId,
              showStackedBottomSheet: false,
              showRiderFound: false,
              isSearching: true,
              riderAvailable: false,
              isMultiDestination: true,
            ),
          );

          _startTimer();
          _listenToDriverStatus();
        },
      );
    } catch (e) {
      dev.log('Error processing multi-destination ride: $e');
      emit(
        state.copyWith(
          status: RideRequestStatus.error,
          errorMessage: 'Failed to process multiple destination ride: $e',
        ),
      );
    }
  }

  MultipleStopRideModel _convertToMultiStopModel(RideRequestModel request) {
    final pickupLocation = request.pickupLocation.address;

    dev.log('pickupLocation: $pickupLocation');

    final dropoffLocations = <String>[request.dropoffLocation.address];

    if (request.additionalDestinations != null) {
      for (final destination in request.additionalDestinations!) {
        dropoffLocations.add(destination.address);
      }
      dev.log('dropoffLocations: $dropoffLocations');
    }

    return MultipleStopRideModel(
      pickupLocation: pickupLocation,
      dropoffLocations: dropoffLocations,
      paymentMethod: request.paymentMethod,
      promoCode: request.promoCode,
    );
  }

  RideRequestModel createRideRequestFromHomeState({
    required loc.Location pickupLocation,
    required loc.Location mainDestination,
    required List<loc.Location> additionalDestinations,
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
    resetRideState();
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

  Future<void> cancelRide({required String reason}) async {
    try {
      emit(
        state.copyWith(cancellationStatus: RideCancellationStatus.canceling),
      );
      _stopSearchTimer();
      _stopRealTimeTracking(); // Stop tracking when canceling

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

  Future<void> _displayRideRoute() async {
    dev.log(
      '🎬 _displayRideRoute(): Displaying animated route for accepted ride',
    );
    dev.log(
      '🎬 _displayRideRoute(): CURRENT RIDE ${_currentRideRequest?.toJson()}',
    );

    if (_currentRideRequest == null) {
      dev.log('❌ No current ride request to display route for');
      return;
    }

    try {
      dev.log('🎬 Displaying animated route for accepted ride');
      await _ensureMarkerIcons();

      final request = _currentRideRequest!;
      final pickup = LatLng(
        request.pickupLocation.latitude,
        request.pickupLocation.longitude,
      );

      if (request.isMultiDestination &&
          request.additionalDestinations != null &&
          request.additionalDestinations!.isNotEmpty) {
        await _displayMultiDestinationRouteWithAnimation(request, pickup);
      } else {
        await _displaySingleDestinationRouteWithAnimation(request, pickup);
      }
    } catch (e) {
      dev.log('❌ Error displaying animated route: $e');
      emit(state.copyWith(errorMessage: 'Failed to display route: $e'));
    }
  }

  Future<void> _displayStaticRideRoute() async {
    dev.log(
      '_displayStaticRideRoute(): Displaying static route for accepted ride',
    );
    dev.log(
      '_displayStaticRideRoute(): CURRENT RIDE ${_currentRideRequest?.toJson()}',
    );

    if (_currentRideRequest == null) {
      dev.log('No current ride request to display route for');
      return;
    }

    try {
      dev.log('Displaying static route for accepted ride');

      await _ensureMarkerIcons();

      final request = _currentRideRequest!;
      final pickup = LatLng(
        request.pickupLocation.latitude,
        request.pickupLocation.longitude,
      );

      if (request.isMultiDestination &&
          request.additionalDestinations != null &&
          request.additionalDestinations!.isNotEmpty) {
        await _displayMultiDestinationRouteWithAnimation(request, pickup);
      } else {
        await _displaySingleDestinationRouteWithAnimation(request, pickup);
      }

      await _createStaticDriverMarker(pickup);
      focusCameraOnRoute();
    } catch (e) {
      dev.log('Error displaying static ride route: $e');
      emit(state.copyWith(errorMessage: 'Failed to display route: $e'));
    }
  }

  Future<void> _createStaticDriverMarker(LatLng pickupPosition) async {
    try {
      const driverMarkerId = MarkerId('driver');

      final updatedMarkers = Map<MarkerId, Marker>.from(state.routeMarkers);

      updatedMarkers.removeWhere(
        (markerId, marker) =>
            markerId.value == 'driver' ||
            markerId.value.toLowerCase().contains('driver') ||
            marker.infoWindow.title?.toLowerCase().contains('driver') == true,
      );

      final driverMarker = Marker(
        markerId: driverMarkerId,
        position: pickupPosition,
        icon:
            state.driverMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Driver'),
        rotation: 0.0,
      );

      updatedMarkers[driverMarkerId] = driverMarker;

      emit(
        state.copyWith(
          routeMarkers: updatedMarkers,
          currentDriverPosition: pickupPosition,
          routeDisplayed: true,
        ),
      );

      dev.log('✅ Static driver marker created at pickup: $pickupPosition');
    } catch (e) {
      dev.log('❌ Error creating static driver marker: $e');
    }
  }

  Future<void> _ensureUniqueDriverMarker(LatLng initialPosition) async {
    try {
      const driverMarkerId = MarkerId('driver');

      final updatedMarkers = Map<MarkerId, Marker>.from(state.routeMarkers);

      updatedMarkers.removeWhere(
        (markerId, marker) =>
            markerId.value == 'driver' ||
            markerId.value.toLowerCase().contains('driver') ||
            marker.infoWindow.title?.toLowerCase().contains('driver') == true,
      );

      final driverMarker = Marker(
        markerId: driverMarkerId,
        position: initialPosition,
        icon:
            state.driverMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Driver'),
        rotation: 0.0,
      );

      updatedMarkers[driverMarkerId] = driverMarker;

      emit(
        state.copyWith(
          routeMarkers: updatedMarkers,
          currentDriverPosition: initialPosition,
        ),
      );

      dev.log('✅ Unique driver marker created at position: $initialPosition');
    } catch (e) {
      dev.log('❌ Error creating unique driver marker: $e');
    }
  }

  Future<void> _ensureMarkerIcons() async {
    try {
      if (state.driverMarkerIcon == null) {
        await _createDriverMarkerIcon();
      }

      if (state.userLocationMarkerIcon == null) {
        await _createUserLocationMarkerIcon();
      }
    } catch (e) {
      dev.log('Error creating marker icons: $e');
    }
  }

  Future<void> _createDriverMarkerIcon() async {
    try {
      final driverIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/bike_marker.png',
      );

      emit(state.copyWith(driverMarkerIcon: driverIcon));
      dev.log('Driver marker icon created successfully');
    } catch (e) {
      dev.log('Failed to create driver marker icon, using default: $e');

      final defaultDriverIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueBlue,
      );
      emit(state.copyWith(driverMarkerIcon: defaultDriverIcon));
    }
  }

  Future<void> _createUserLocationMarkerIcon() async {
    try {
      final userIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(40, 40)),
        'assets/images/user_pin.png',
      );

      emit(state.copyWith(userLocationMarkerIcon: userIcon));
      dev.log('User location marker icon created successfully');
    } catch (e) {
      dev.log('Failed to create user location marker icon, using default: $e');

      final defaultUserIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueGreen,
      );
      emit(state.copyWith(userLocationMarkerIcon: defaultUserIcon));
    }
  }

  Future<void> _displaySingleDestinationRouteWithAnimation(
    RideRequestModel request,
    LatLng pickup,
  ) async {
    dev.log('🎬 Displaying single destination route with animation');

    final destination = LatLng(
      request.dropoffLocation.latitude,
      request.dropoffLocation.longitude,
    );

    final routeResult = await _routeService.getRoute(pickup, destination);

    if (routeResult.isSuccess && routeResult.polyline != null) {
      // Create markers (without driver marker initially)
      final routeMarkers = _routeService.createMarkers(
        request.pickupLocation,
        request.dropoffLocation,
        state.driverMarkerIcon,
      );

      // Remove driver marker from route markers (we'll animate it)
      final filteredMarkers = <MarkerId, Marker>{};
      routeMarkers.forEach((markerId, marker) {
        if (!_isDriverMarker(markerId, marker)) {
          filteredMarkers[markerId] = marker;
        }
      });

      // Get route points for animation
      final routePoints = routeResult.polyline!.points;

      emit(
        state.copyWith(
          routePolylines: {routeResult.polyline!},
          routeMarkers: filteredMarkers,
          routeDisplayed: true,
        ),
      );

      dev.log(
        '✅ Route displayed, starting driver animation along ${routePoints.length} points',
      );

      // Start animating driver marker along the route
      _animationService.animateMarkerAlongRoute(
        routePoints,
        onPositionUpdate: (position, rotation) {
          _updateDriverMarkerPositionRealTime(position, rotation);
        },
        speedMetersPerSecond: AnimationConfig.normal.speedMetersPerSecond,
        onAnimationComplete: () {
          dev.log('🎬 Initial route animation completed');
          // Animation is complete, driver is now at destination
          _onInitialAnimationComplete();
        },
      );
    } else {
      dev.log(
        '❌ Failed to get single destination route: ${routeResult.errorMessage}',
      );
    }
  }

  Future<void> _displayMultiDestinationRouteWithAnimation(
    RideRequestModel request,
    LatLng pickup,
  ) async {
    dev.log('🎬 Displaying multi-destination route with animation');

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
      final allLocations = <loc.Location>[
        request.pickupLocation,
        request.dropoffLocation,
        ...request.additionalDestinations!,
      ];

      final routeMarkers = _routeService.createMarkersForMultipleLocations(
        allLocations,
        state.driverMarkerIcon,
      );

      // Remove driver marker from route markers
      final filteredMarkers = <MarkerId, Marker>{};
      routeMarkers.forEach((markerId, marker) {
        if (!_isDriverMarker(markerId, marker)) {
          filteredMarkers[markerId] = marker;
        }
      });

      emit(
        state.copyWith(
          routePolylines: routesResult.polylines!,
          routeMarkers: filteredMarkers,
          routeDisplayed: true,
          routeSegments: routesResult.routeSegments,
        ),
      );

      // Combine all route points for animation
      final allRoutePoints = <LatLng>[];
      for (final polyline in routesResult.polylines!) {
        allRoutePoints.addAll(polyline.points);
      }

      dev.log(
        '✅ Multi-destination route displayed, animating along ${allRoutePoints.length} points',
      );

      // Animate driver along combined route
      _animationService.animateMarkerAlongRoute(
        allRoutePoints,
        onPositionUpdate: (position, rotation) {
          _updateDriverMarkerPositionRealTime(position, rotation);
        },
        speedMetersPerSecond: AnimationConfig.normal.speedMetersPerSecond,
        onAnimationComplete: () {
          dev.log('🎬 Multi-destination animation completed');
          _onInitialAnimationComplete();
        },
      );
    } else {
      dev.log(
        '❌ Failed to get multi-destination routes: ${routesResult.errorMessage}',
      );
    }
  }

  void _onInitialAnimationComplete() {
    dev.log('🎬 Initial animation complete - driver ready for real tracking');
    emit(state.copyWith(driverAnimationComplete: true));
  }

  bool _isDriverMarker(MarkerId markerId, Marker marker) {
    final id = markerId.value.toLowerCase();
    final title = marker.infoWindow.title?.toLowerCase() ?? '';

    final driverKeywords = [
      'driver',
      'bike',
      'car',
      'vehicle',
      'pickup',
      'origin',
    ];

    for (final keyword in driverKeywords) {
      if (id.contains(keyword) || title.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  void _updateDriverMarkerPositionRealTime(LatLng position, double rotation) {
    try {
      final updatedMarkers = Map<MarkerId, Marker>.from(state.routeMarkers);
      const driverMarkerId = MarkerId('driver');

      // Ensure driver marker exists
      if (!updatedMarkers.containsKey(driverMarkerId)) {
        dev.log('🚗 Creating driver marker for real-time tracking');
        final driverMarker = Marker(
          markerId: driverMarkerId,
          position: position,
          icon:
              state.driverMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Driver'),
          rotation: rotation,
        );
        updatedMarkers[driverMarkerId] = driverMarker;
      } else {
        // Update existing marker with smooth animation
        final currentMarker = updatedMarkers[driverMarkerId]!;
        final updatedMarker = currentMarker.copyWith(
          positionParam: position,
          rotationParam: rotation,
        );
        updatedMarkers[driverMarkerId] = updatedMarker;
      }

      emit(
        state.copyWith(routeMarkers: updatedMarkers, shouldUpdateCamera: true),
      );

      // Throttled logging
      if (DateTime.now().millisecondsSinceEpoch % 5000 < 100) {
        dev.log(
          '🎬 Smooth marker update: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)} (${rotation.toStringAsFixed(1)}°)',
        );
      }
    } catch (e) {
      dev.log('❌ Error in smooth marker update: $e');
    }
  }

  void focusCameraOnRoute() {
    if (state.routePolylines.isEmpty) return;

    emit(state.copyWith(shouldUpdateCamera: true));

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
        ),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (!isClosed) {
          emit(state.copyWith(shouldUpdateCamera: false));
        }
      });
    }
  }

  bool get isRealTimeTrackingActiveGetter => state.isRealTimeTrackingActive;
  String? get trackingStatusMessage => state.trackingStatusMessage;
  bool get isRouteRecalculated => state.routeRecalculated;

  void _clearRouteDisplay() {
    _animationService.stopAnimation();
    _stopRealTimeTracking();

    emit(
      state.copyWith(
        routePolylines: const {},
        routeMarkers: const {},
        routeDisplayed: false,
        routeSegments: null,
        currentDriverPosition: null,
      ),
    );
  }

  void _cancelAllSubscriptions() {
    _driverStatusSubscription?.cancel();
    _driverCancelledSubscription?.cancel();
    _driverAcceptedSubscription?.cancel();
    _driverArrivedSubscription?.cancel();
    _driverCompletedSubscription?.cancel();
    _driverStartedSubscription?.cancel();
    _driverRejecetedSubscription?.cancel();
    _driverPositionSubscription?.cancel();
    _stopRealTimeTracking();
  }

  void _listenToDriverStatus() {
    dev.log('Setting up driver status listeners');

    final socketService = getIt<SocketService>();
    dev.log('Socket connected: ${socketService.isConnected}');

    _cancelAllSubscriptions();

    _driverStatusSubscription = socketService.onDriverAcceptRide.listen((
      data,
    ) async {
      dev.log('🚗 Driver accepted ride - showing static route');
      _stopSearchTimer();

      emit(
        state.copyWith(
          status: RideRequestStatus.success,
          showRiderFound: true,
          riderAvailable: true,
          showStackedBottomSheet: false,
          driverAccepted: data,
        ),
      );

      try {
        await _displayStaticRideRoute();
        dev.log('✅ Static route displayed successfully');
      } catch (e) {
        dev.log('❌ Error displaying route: $e');
        emit(state.copyWith(errorMessage: 'Failed to display route: $e'));
      }
    });

    _driverStartedSubscription = socketService.onDriverStarted.listen((
      data,
    ) async {
      dev.log('🚗 Driver started the ride - enabling real-time tracking');

      emit(
        state.copyWith(
          driverStarted: data,
          rideInProgress: data.status == 'in_progress',
        ),
      );
      // Start real-time tracking
      await _startRealTimeTracking();
    });

    _driverArrivedSubscription = socketService.onDriverArrived.listen((data) {
      dev.log('🚗 Driver arrived at pickup location');
      // Don't stop tracking here - driver will start the ride next
      emit(state.copyWith(driverArrived: data, driverHasArrived: true));
    });

    // CRITICAL: Listen for real-time driver position updates from socket
    _driverPositionSubscription = socketService.onDriverLocation.listen((
      locationData,
    ) {
      log('🚗 Driver location updated: ${locationData.entries}');
      // Process location updates through the tracking service
      _realTimeTrackingService.processDriverLocation(locationData);
    });

    _driverCancelledSubscription = socketService.onDriverCancelled.listen((
      data,
    ) {
      _stopRealTimeTracking();
      _clearRouteDisplay();
      resetRideState();
      emit(state.copyWith(driverCancelled: data));
    });

    _driverCompletedSubscription = socketService.onDriverCompleted.listen((
      data,
    ) {
      _stopRealTimeTracking();
      _clearRouteDisplay();
      resetRideState();
      emit(state.copyWith(driverCompleted: data));
    });

    _driverRejecetedSubscription = socketService.onDriverRejected.listen((
      data,
    ) {
      resetRideState();
      emit(state.copyWith(driverRejected: data));
    });
  }

  Future<void> _startRealTimeTracking() async {
    try {
      if (_currentRideRequest == null) {
        dev.log('❌ Cannot start tracking: no current ride request');
        return;
      }

      final destination = LatLng(
        _currentRideRequest!.dropoffLocation.latitude,
        _currentRideRequest!.dropoffLocation.longitude,
      );

      final rideId = state.driverAccepted?.rideId ?? state.currentRideId ?? '';
      final driverId = state.driverAccepted?.driverId ?? '';

      if (rideId.isEmpty || driverId.isEmpty) {
        dev.log(
          '❌ Cannot start tracking: missing rideId($rideId) or driverId($driverId)',
        );
        return;
      }

      dev.log('🔴 Starting enhanced real-time tracking with animation');

      // Convert to gmaps.LatLng for tracking service
      final gmapsDestination = gmaps.LatLng(
        destination.latitude,
        destination.longitude,
      );

      // Transition animation service to real-time mode
      _animationService.transitionToRealTimeTracking(
        onPositionUpdate: (position, rotation) {
          _updateDriverMarkerPositionRealTime(position, rotation);
        },
      );

      // Start the tracking service
      _realTimeTrackingService.startTracking(
        rideId: rideId,
        driverId: driverId,
        destination: gmapsDestination,
        onPositionUpdate: _handleRealTimePositionUpdate,
        onRouteUpdated: _updateRouteOnMap,
        onStatusUpdate: _updateTrackingStatus,
        onMarkerUpdate: _handlePreciseMarkerUpdate,
      );

      emit(
        state.copyWith(
          shouldUpdateCamera: false,
          isRealTimeTrackingActive: true,
          trackingStatusMessage: 'Real-time tracking with animation started',
        ),
      );

      dev.log('✅ Real-time tracking with animation started successfully');
    } catch (e) {
      dev.log('❌ Error starting real-time tracking: $e');
      emit(
        state.copyWith(
          errorMessage: 'Failed to start tracking: $e',
          trackingStatusMessage: 'Tracking startup failed',
        ),
      );
    }
  }

  void _handleRealTimePositionUpdate(
    gmaps.LatLng position,
    double bearing,
    DriverLocationData locationData,
  ) {
    // Convert to UI coordinates
    final uiPosition = LatLng(position.latitude, position.longitude);

    dev.log(
      '📍 Real-time update: ${uiPosition.latitude.toStringAsFixed(6)}, ${uiPosition.longitude.toStringAsFixed(6)} (${bearing.toStringAsFixed(1)}°)',
    );

    // Update animation service with new real-time position
    _animationService.updateRealTimePosition(
      uiPosition,
      bearing,
      locationData: {
        'speed': locationData.speed,
        'accuracy': locationData.accuracy,
        'timestamp': locationData.lastUpdate.toIso8601String(),
      },
    );

    // Update state for UI
    emit(
      state.copyWith(
        currentDriverPosition: uiPosition,
        lastPositionUpdate: locationData.lastUpdate,
        currentSpeed: locationData.speed,
        trackingStatusMessage: _getEnhancedTrackingMessage(locationData),
      ),
    );

    // Check destination arrival
    if (_realTimeTrackingService.hasReachedDestination(position)) {
      dev.log('🏁 Driver has reached destination');
      _handleDriverReachedDestination();
    }
  }

  void _handlePreciseMarkerUpdate(gmaps.LatLng position) {
    final uiPosition = LatLng(position.latitude, position.longitude);

    // Update animation service target position for smoother movement
    if (_animationService.isRealTimeTracking) {
      _animationService.updateRealTimePosition(
        uiPosition,
        _animationService.currentBearing,
      );
    }

    // Throttled logging for precision updates
    if (DateTime.now().millisecondsSinceEpoch % 15000 < 200) {
      dev.log('🎯 Precise position: ${position.toDisplayFormat()}');
    }
  }

  // New method to get enhanced tracking message
  String _getEnhancedTrackingMessage(DriverLocationData locationData) {
    if (locationData.speed > 15.0) {
      return 'Driver is moving fast (${locationData.speed.toStringAsFixed(0)} km/h)';
    } else if (locationData.speed > 5.0) {
      return 'Driver is moving (${locationData.speed.toStringAsFixed(0)} km/h)';
    } else if (locationData.speed > 1.0) {
      return 'Driver is moving slowly';
    } else {
      return 'Driver is stationary';
    }
  }

  // UPDATED: Update route on map when driver changes path
  void _updateRouteOnMap(List<gmaps.LatLng> newRoutePoints) {
    try {
      if (state.routePolylines.isEmpty) {
        dev.log('❌ No existing route to update');
        return;
      }

      dev.log('🛣️ Updating route with ${newRoutePoints.length} new points');

      // Convert to UI coordinates
      final uiRoutePoints =
          newRoutePoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

      // Update polyline
      final currentPolyline = state.routePolylines.first;
      final updatedPolyline = currentPolyline.copyWith(
        pointsParam: uiRoutePoints,
      );

      emit(
        state.copyWith(
          routePolylines: {updatedPolyline},
          routeRecalculated: true,
          trackingStatusMessage: 'Route updated - driver changed path',
        ),
      );

      dev.log('✅ Route updated on map');

      // Update animation service with new route if needed
      if (_animationService.isRealTimeTracking) {
        dev.log('🎬 Animation service will continue with new route points');
      }

      // Reset flag after delay
      Future.delayed(const Duration(seconds: 3), () {
        if (!isClosed) {
          emit(state.copyWith(routeRecalculated: false));
        }
      });
    } catch (e) {
      dev.log('❌ Error updating route on map: $e');
      emit(state.copyWith(trackingStatusMessage: 'Route update failed: $e'));
    }
  }

  // NEW: Show notification when route changes
  void _showEnhancedRouteChangeNotification() {
    emit(
      state.copyWith(
        trackingStatusMessage:
            'Driver took a different route. ETA updated automatically.',
      ),
    );

    // Clear notification after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (!isClosed) {
        emit(state.copyWith(trackingStatusMessage: null));
      }
    });
  }

  // UPDATED: Update tracking status with better user feedback
  void _updateTrackingStatus(String status) {
    dev.log('📊 Enhanced tracking status: $status');

    // Filter out frequent status updates to avoid UI spam
    final currentTime = DateTime.now();
    if (_lastStatusUpdate != null &&
        currentTime.difference(_lastStatusUpdate!).inSeconds < 2 &&
        status.contains('position updated')) {
      return; // Skip frequent position updates
    }
    _lastStatusUpdate = currentTime;

    emit(state.copyWith(trackingStatusMessage: status));

    // Clear status message after appropriate duration
    final duration =
        status.contains('error') || status.contains('failed')
            ? const Duration(seconds: 8)
            : const Duration(seconds: 4);

    Future.delayed(duration, () {
      if (!isClosed) {
        emit(state.copyWith(trackingStatusMessage: null));
      }
    });
  }

  double _calculateTotalRouteDistance(List<gmaps.LatLng> routePoints) {
    double totalDistance = 0.0;

    for (int i = 0; i < routePoints.length - 1; i++) {
      final point1 = LatLng(routePoints[i].latitude, routePoints[i].longitude);
      final point2 = LatLng(
        routePoints[i + 1].latitude,
        routePoints[i + 1].longitude,
      );
      totalDistance += _calculateDistanceInMeters(point1, point2);
    }

    return totalDistance;
  }

  // UPDATED: Handle when driver reaches destination
  void _handleDriverReachedDestination() {
    dev.log('🏁 Driver reached destination - stopping all animations');

    _stopRealTimeTracking();
    _animationService.stopAll();

    emit(
      state.copyWith(
        isRealTimeTrackingActive: false,
        trackingStatusMessage: 'Driver has arrived at destination',
      ),
    );
  }

  // Stop tracking with animation cleanup
  void _stopRealTimeTracking() {
    dev.log('🛑 Stopping real-time tracking and animation');

    _realTimeTrackingService.stopTracking();
    _animationService.stopRealTimeTracking();

    emit(
      state.copyWith(
        isRealTimeTrackingActive: false,
        trackingStatusMessage: null,
        currentSpeed: 0.0,
      ),
    );
  }

  // UPDATED: Get current route progress information
  RouteProgress? getCurrentRouteProgress() {
    if (!_realTimeTrackingService.isTracking) {
      return null;
    }

    // Get enhanced tracking status
    final trackingStatus = _realTimeTrackingService.getTrackingStatus();

    if (!trackingStatus.isReceivingRegularUpdates ||
        trackingStatus.lastKnownPosition == null) {
      return null;
    }

    // Try to get route progress from tracking service
    // You might need to add this method to your tracking service
    try {
      // This is a placeholder - you'd implement actual route progress calculation
      // in the tracking service based on the current route points
      final driverPosition = trackingStatus.lastKnownPosition!;
      final destination = trackingStatus.destination;

      if (destination != null) {
        final distanceToDestination = _calculateDistanceInMeters(
          LatLng(driverPosition.latitude, driverPosition.longitude),
          LatLng(destination.latitude, destination.longitude),
        );

        // Use tracking service route points for more accurate progress
        final routePoints = _realTimeTrackingService.currentRoutePoints;
        final totalDistance =
            routePoints.isNotEmpty
                ? _calculateTotalRouteDistance(routePoints)
                : distanceToDestination + 1000; // Fallback estimate

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
      dev.log('❌ Error calculating route progress: $e');
    }

    return null;
  }

  // Helper method to calculate total route distance

  // Helper method to calculate actual progress along route
  double _calculateActualProgress(
    gmaps.LatLng driverPosition,
    List<gmaps.LatLng> routePoints,
  ) {
    if (routePoints.length < 2) return 0.0;

    // Find closest point on route and calculate progress
    double minDistance = double.infinity;
    int closestSegmentIndex = 0;

    for (int i = 0; i < routePoints.length - 1; i++) {
      final point1 = LatLng(routePoints[i].latitude, routePoints[i].longitude);
      final point2 = LatLng(
        routePoints[i + 1].latitude,
        routePoints[i + 1].longitude,
      );
      final driverLatLng = LatLng(
        driverPosition.latitude,
        driverPosition.longitude,
      );

      // Simple distance calculation - you might want to use the geodesy library for accuracy
      final distance = _calculateDistanceToLineSegment(
        driverLatLng,
        point1,
        point2,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestSegmentIndex = i;
      }
    }

    // Calculate progress based on closest segment
    final totalSegments = routePoints.length - 1;
    return totalSegments > 0 ? closestSegmentIndex / totalSegments : 0.0;
  }

  // Simple distance to line segment calculation
  double _calculateDistanceToLineSegment(
    LatLng point,
    LatLng lineStart,
    LatLng lineEnd,
  ) {
    // Simplified calculation - in production you'd use proper geodesy
    final startDistance = _calculateDistanceInMeters(point, lineStart);
    final endDistance = _calculateDistanceInMeters(point, lineEnd);
    return math.min(startDistance, endDistance);
  }

  // Enhanced ETA calculation using tracking data
  Duration _calculateEnhancedETA(
    double distanceMeters,
    TrackingStatus trackingStatus,
  ) {
    // Use recent speed data if available
    final recentHistory = _realTimeTrackingService.locationHistory;

    double averageSpeedMps = 8.33; // Default 30 km/h in m/s

    if (recentHistory.isNotEmpty) {
      final recentSpeeds =
          recentHistory
              .where(
                (h) => DateTime.now().difference(h.timestamp).inMinutes < 5,
              )
              .map((h) => h.speed * 1000 / 3600) // Convert km/h to m/s
              .where((speed) => speed > 1.0) // Filter out stationary periods
              .toList();

      if (recentSpeeds.isNotEmpty) {
        averageSpeedMps =
            recentSpeeds.reduce((a, b) => a + b) / recentSpeeds.length;
      }
    }

    final etaSeconds = distanceMeters / averageSpeedMps;
    return Duration(seconds: etaSeconds.round());
  }

  // Updated getTrackingStatus method with enhanced information
  TrackingStatus getTrackingStatus() {
    return _realTimeTrackingService.getTrackingStatus();
  }

  // Enhanced real-time tracking active check
  bool get isRealTimeTrackingActive {
    final serviceActive = _realTimeTrackingService.isTracking;
    final stateActive = state.rideInProgress && state.isRealTimeTrackingActive;

    // Log mismatch for debugging
    if (serviceActive != stateActive) {
      dev.log(
        '🚨 Tracking state mismatch - Service: $serviceActive, State: $stateActive',
      );
    }

    return serviceActive && stateActive;
  }

  // Enhanced tracking metrics for debugging
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
    };
  }

  // Helper method for distance calculation
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

  // UPDATED: Manual route recalculation (for user-triggered updates)
  Future<void> forceRouteRecalculation() async {
    if (!_realTimeTrackingService.isTracking) {
      dev.log('❌ Cannot recalculate route - tracking not active');
      return;
    }

    final driverPosition = _realTimeTrackingService.lastKnownDriverPosition;
    final destination = _realTimeTrackingService.currentDestination;

    if (driverPosition != null && destination != null) {
      dev.log('🔄 Force recalculating route');

      try {
        emit(state.copyWith(trackingStatusMessage: 'Recalculating route...'));

        final routeResult = await _routeService.getRoute(
          driverPosition,
          destination,
        );

        if (routeResult.isSuccess && routeResult.polyline != null) {
          _updateRouteOnMap(routeResult.polyline!.points);
          _updateTrackingStatus('Route recalculated successfully');
        } else {
          _updateTrackingStatus('Route recalculation failed');
        }
      } catch (e) {
        dev.log('❌ Error force recalculating route: $e');
        _updateTrackingStatus('Route recalculation error');
      }
    }
  }

  // UPDATED: Better real-time tracking setup
  void _setupRealTimeDriverTracking() {
    dev.log('🔴 Setting up real-time driver tracking');
    emit(
      state.copyWith(
        shouldUpdateCamera: false,
        trackingStatusMessage: 'Preparing real-time tracking...',
      ),
    );
    dev.log('📍 Ready to receive real-time driver positions');
  }

  Duration? get timeSinceLastUpdate {
    final lastUpdate = state.lastPositionUpdate;
    if (lastUpdate == null) return null;
    return DateTime.now().difference(lastUpdate);
  }

  // UPDATED: Get current ETA based on real tracking data
  Duration? get estimatedTimeToDestination {
    final progress = getCurrentRouteProgress();
    return progress?.estimatedTimeRemaining;
  }

  // UPDATED: Get current distance to destination
  double? get distanceToDestination {
    final progress = getCurrentRouteProgress();
    return progress?.remainingDistance;
  }

  Future<void> checkRideStatus(String rideId) async {
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
          final currentStatus = statusResponse.data?.status;

          log('Current status: $currentStatus');

          if (currentStatus == 'accepted') {
            emit(
              state.copyWith(
                status: RideRequestStatus.success,
                showRiderFound: true,
                riderAvailable: true,
                showStackedBottomSheet: true,
              ),
            );

            await _displayStaticRideRoute();
          } else if (currentStatus == 'in_progress') {
            emit(
              state.copyWith(
                status: RideRequestStatus.success,
                showRiderFound: true,
                riderAvailable: true,
                showStackedBottomSheet: true,
                rideInProgress: true,
              ),
            );

            await _displayRideRoute();
            await _ensureUniqueDriverMarker(
              LatLng(
                _currentRideRequest!.pickupLocation.latitude,
                _currentRideRequest!.pickupLocation.longitude,
              ),
            );
            _setupRealTimeDriverTracking();
            await _startRealTimeTracking();
          } else if (currentStatus == 'completed') {
            _clearRouteDisplay();
            emit(
              state.copyWith(
                status: RideRequestStatus.completed,
                showStackedBottomSheet: true,
                showRiderFound: false,
              ),
            );
          } else if (currentStatus == 'cancelled') {
            _clearRouteDisplay();
            emit(
              state.copyWith(
                status: RideRequestStatus.cancelled,
                showStackedBottomSheet: true,
                showRiderFound: false,
              ),
            );
          } else {
            emit(
              state.copyWith(
                status: RideRequestStatus.searching,
                isSearching: true,
              ),
            );
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

  RouteInfo? get currentRouteInfo {
    if (!state.routeDisplayed) return null;

    var totalDistance = 0.0;
    Duration? estimatedDuration;

    if (state.routeSegments != null) {
      for (final segment in state.routeSegments!) {
        totalDistance += _routeService.calculateRouteDistance(
          segment.routePoints,
        );
      }
    } else if (state.routePolylines.isNotEmpty) {
      totalDistance = _routeService.calculateRouteDistance(
        state.routePolylines.first.points,
      );
    }

    // Use real-time ETA if available, otherwise calculate estimate
    if (isRealTimeTrackingActive) {
      estimatedDuration = estimatedTimeToDestination;
    }

    estimatedDuration ??= Duration(
      minutes: (totalDistance / 1000 / 30 * 60).round(),
    );

    return RouteInfo(
      totalDistance: totalDistance,
      isMultiDestination: state.isMultiDestination,
      segmentCount: state.routeSegments?.length ?? 1,
      estimatedDuration: estimatedDuration,
    );
  }

  void resetRideState() {
    _clearRouteDisplay();
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

  @override
  Future<void> close() {
    _driverStatusSubscription?.cancel();
    _driverCancelledSubscription?.cancel();
    _driverAcceptedSubscription?.cancel();
    _driverArrivedSubscription?.cancel();
    _driverCompletedSubscription?.cancel();
    _driverStartedSubscription?.cancel();
    _driverRejecetedSubscription?.cancel();
    _driverPositionSubscription?.cancel();

    _timer?.cancel();
    _animationService.dispose();
    _stopRealTimeTracking(); // Clean up tracking service
    return super.close();
  }
}

class RouteInfo {
  const RouteInfo({
    required this.totalDistance,
    required this.isMultiDestination,
    required this.segmentCount,
    required this.estimatedDuration,
  });
  final double totalDistance;
  final bool isMultiDestination;
  final int segmentCount;
  final Duration estimatedDuration;

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
}
