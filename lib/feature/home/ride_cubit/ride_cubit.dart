import 'dart:developer' as dev;
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:freedom/core/services/real_time_driver_tracking.dart';
import 'package:freedom/core/services/push_notification_service/socket_models.dart';
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
    log('requestRide from ride cubit: ${request.toJson()}');

    _currentRideRequest = request;

    log('_currentRideRequest set: ${_currentRideRequest?.toJson()}');

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
    log('_displayRideRoute(): Displaying route for accepted ride');
    log('_displayRideRoute(): CURRENT RIDE ${_currentRideRequest?.toJson()}');

    if (_currentRideRequest == null) {
      dev.log('No current ride request to display route for');
      return;
    }

    try {
      dev.log('Displaying route for accepted ride');

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

      await _ensureUniqueDriverMarker(pickup);
    } catch (e) {
      dev.log('Error displaying ride route: $e');
      emit(state.copyWith(errorMessage: 'Failed to display route: $e'));
    }
  }

  Future<void> _displayStaticRideRoute() async {
    log('_displayStaticRideRoute(): Displaying static route for accepted ride');
    log(
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
        await _displayMultiDestinationRoute(request, pickup);
      } else {
        await _displaySingleDestinationRoute(request, pickup);
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

  Future<void> _displaySingleDestinationRoute(
    RideRequestModel request,
    LatLng pickup,
  ) async {
    log('_displaySingleDestinationRoute(): Displaying route for accepted ride');
    final destination = LatLng(
      request.dropoffLocation.latitude,
      request.dropoffLocation.longitude,
    );

    final routeResult = await _routeService.getRoute(pickup, destination);
    log('routeResult: ${routeResult.interpolatedPoints?.length}');

    if (routeResult.isSuccess) {
      final routeMarkers = _routeService.createMarkers(
        request.pickupLocation,
        request.dropoffLocation,
        state.driverMarkerIcon,
      );

      final filteredMarkers = <MarkerId, Marker>{};
      routeMarkers.forEach((markerId, marker) {
        if (!_isDriverMarker(markerId, marker)) {
          filteredMarkers[markerId] = marker;
        }
      });

      emit(
        state.copyWith(
          routePolylines: {routeResult.polyline!},
          routeMarkers: filteredMarkers,
          routeDisplayed: true,
        ),
      );

      dev.log('✅ Single destination route displayed successfully');
    } else {
      dev.log(
        '❌ Failed to get single destination route: ${routeResult.errorMessage}',
      );
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

    if (routesResult.isSuccess) {
      final allLocations = <loc.Location>[
        request.pickupLocation,
        request.dropoffLocation,
        ...request.additionalDestinations!,
      ];

      final routeMarkers = _routeService.createMarkersForMultipleLocations(
        allLocations,
        state.driverMarkerIcon,
      );

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

      dev.log('✅ Multi-destination route displayed successfully');
    } else {
      dev.log(
        '❌ Failed to get multi-destination routes: ${routesResult.errorMessage}',
      );
    }
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

  void _updateDriverMarkerPosition(LatLng position, double rotation) {
    try {
      final updatedMarkers = Map<MarkerId, Marker>.from(state.routeMarkers);
      const driverMarkerId = MarkerId('driver');

      if (!updatedMarkers.containsKey(driverMarkerId)) {
        dev.log('❌ ERROR: Driver marker not found during position update');
        return;
      }

      final currentMarker = updatedMarkers[driverMarkerId]!;
      final updatedMarker = currentMarker.copyWith(
        positionParam: position,
        rotationParam: rotation,
      );

      updatedMarkers[driverMarkerId] = updatedMarker;

      emit(
        state.copyWith(
          routeMarkers: updatedMarkers,
          currentDriverPosition: position,
          shouldUpdateCamera: false,
        ),
      );

      // Reduced logging for real-time updates
      if (DateTime.now().millisecondsSinceEpoch % 5000 < 200) {
        dev.log('📍 Driver position updated: $position');
      }
    } catch (e) {
      dev.log('❌ Error updating driver marker position: $e');
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

  bool get isRealTimeTrackingActiveGetter =>
      state.isRealTimeTrackingActive;
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

      // Start real-time tracking instead of simulation
      await _startRealTimeTracking();
    });

    _driverArrivedSubscription = socketService.onDriverArrived.listen((data) {
      dev.log('🚗 Driver arrived at pickup location');
      _stopRealTimeTracking();
      emit(state.copyWith(driverArrived: data, driverHasArrived: true));
    });

    // UPDATED: Listen for real-time driver position updates from socket
    _driverPositionSubscription = socketService.onDriverLocation.listen((
      locationData,
    ) {
      _handleRealTimeDriverPosition(locationData);
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
    if (_currentRideRequest == null) {
      dev.log('❌ No ride request available for tracking');
      return;
    }

    try {
      final destination = LatLng(
        _currentRideRequest!.dropoffLocation.latitude,
        _currentRideRequest!.dropoffLocation.longitude,
      );

      dev.log('🔴 Starting real-time tracking to destination: $destination');

      _realTimeTrackingService.startTracking(
        destination: destination,
        onPositionUpdate: (position, bearing) {
          _updateDriverMarkerPositionRealTime(position, bearing);
        },
        onRouteUpdated: (newRoute) {
          _updateRouteOnMap(newRoute);
        },
        onStatusUpdate: (status) {
          dev.log('📊 Tracking status: $status');
          _updateTrackingStatus(status);
        },
      );

      emit(
        state.copyWith(
          shouldUpdateCamera: false,
          isRealTimeTrackingActive: true,
        ),
      );
    } catch (e) {
      dev.log('❌ Error starting real-time tracking: $e');
      emit(state.copyWith(errorMessage: 'Failed to start tracking: $e'));
    }
  }

  void _handleRealTimeDriverPosition(Map<String, dynamic> locationData) {
    if (!state.rideInProgress) {
      dev.log('⚠️ Ignoring location update - ride not in progress');
      return;
    }

    try {
      dev.log('📍 Processing real-time driver location: $locationData');

      _realTimeTrackingService.processDriverLocation(locationData);

      // Update state with raw location data for debugging/info
      final latitude = locationData['latitude'] as double?;
      final longitude = locationData['longitude'] as double?;
      final timestamp = locationData['timestamp'] as String?;
      final speed = locationData['speed'] as double? ?? 0.0;

      if (latitude != null && longitude != null) {
        final position = LatLng(latitude, longitude);

        emit(
          state.copyWith(
            currentDriverPosition: position,
            lastPositionUpdate:
                timestamp != null
                    ? DateTime.tryParse(timestamp)
                    : DateTime.now(),
            currentSpeed: speed,
          ),
        );

        // Check if driver has reached destination
        if (_realTimeTrackingService.hasReachedDestination(position)) {
          dev.log('🏁 Driver has reached destination');
          _handleDriverReachedDestination();
        }
      }
    } catch (e) {
      dev.log('❌ Error handling real-time driver position: $e');
    }
  }

  // NEW: Update driver marker position from real-time tracking
  void _updateDriverMarkerPositionRealTime(LatLng position, double bearing) {
    try {
      final updatedMarkers = Map<MarkerId, Marker>.from(state.routeMarkers);
      const driverMarkerId = MarkerId('driver');

      if (!updatedMarkers.containsKey(driverMarkerId)) {
        dev.log('❌ Driver marker not found during real-time update');
        return;
      }

      final currentMarker = updatedMarkers[driverMarkerId]!;
      final updatedMarker = currentMarker.copyWith(
        positionParam: position,
        rotationParam: bearing,
      );

      updatedMarkers[driverMarkerId] = updatedMarker;

      emit(
        state.copyWith(
          routeMarkers: updatedMarkers,
          currentDriverPosition: position,
          shouldUpdateCamera: false, // Keep camera static during tracking
        ),
      );

      // Log periodically to avoid spam
      if (DateTime.now().millisecondsSinceEpoch % 10000 < 200) {
        dev.log(
          '📍 Real-time marker update: $position (${bearing.toStringAsFixed(1)}°)',
        );
      }
    } catch (e) {
      dev.log('❌ Error updating driver marker: $e');
    }
  }

  // NEW: Update route on map when driver changes path
  void _updateRouteOnMap(List<LatLng> newRoutePoints) {
    try {
      if (state.routePolylines.isEmpty) {
        dev.log('❌ No existing route to update');
        return;
      }

      dev.log('🛣️ Updating route with ${newRoutePoints.length} new points');

      // Get the current polyline and update it with new points
      final currentPolyline = state.routePolylines.first;
      final updatedPolyline = currentPolyline.copyWith(
        pointsParam: newRoutePoints,
      );

      emit(
        state.copyWith(
          routePolylines: {updatedPolyline},
          routeRecalculated: true,
        ),
      );

      dev.log('✅ Route updated on map');

      // Reset the flag after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (!isClosed) {
          emit(state.copyWith(routeRecalculated: false));
        }
      });
    } catch (e) {
      dev.log('❌ Error updating route on map: $e');
    }
  }

  // NEW: Update tracking status
  void _updateTrackingStatus(String status) {
    emit(state.copyWith(trackingStatusMessage: status));

    // Clear status message after a few seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (!isClosed) {
        emit(state.copyWith(trackingStatusMessage: null));
      }
    });
  }

  // NEW: Handle when driver reaches destination
  void _handleDriverReachedDestination() {
    dev.log('🏁 Driver reached destination - ride completing');

    _stopRealTimeTracking();

    emit(
      state.copyWith(
        isRealTimeTrackingActive: false,
        trackingStatusMessage: 'Driver has arrived at destination',
      ),
    );

    // The ride completion will be handled by the socket event
  }

  // NEW: Stop real-time tracking
  void _stopRealTimeTracking() {
    dev.log('🛑 Stopping real-time tracking');

    _realTimeTrackingService.stopTracking();

    emit(
      state.copyWith(
        isRealTimeTrackingActive: false,
        trackingStatusMessage: null,
      ),
    );
  }

  // NEW: Get current route progress information
  RouteProgress? getCurrentRouteProgress() {
    if (!_realTimeTrackingService.isTracking ||
        _realTimeTrackingService.lastKnownDriverPosition == null) {
      return null;
    }

    // This would require adding a getRouteProgress method to the tracking service
    return null; // Placeholder
  }

  // NEW: Get tracking status
  TrackingStatus getTrackingStatus() {
    return _realTimeTrackingService.getTrackingStatus();
  }

  // NEW: Manual route recalculation (for user-triggered updates)
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
        final routeResult = await _routeService.getRoute(
          driverPosition,
          destination,
        );

        if (routeResult.isSuccess && routeResult.polyline != null) {
          _updateRouteOnMap(routeResult.polyline!.points);
          _updateTrackingStatus('Route recalculated');
        } else {
          _updateTrackingStatus('Route recalculation failed');
        }
      } catch (e) {
        dev.log('❌ Error force recalculating route: $e');
        _updateTrackingStatus('Route recalculation error');
      }
    }
  }

  void _setupRealTimeDriverTracking() {
    dev.log('🔴 Setting up real-time driver tracking');
    emit(state.copyWith(shouldUpdateCamera: false));
    dev.log('📍 Ready to receive real-time driver positions');
  }

  bool get isRealTimeTrackingActive =>
      state.rideInProgress && state.currentDriverPosition != null;

  Duration? get timeSinceLastUpdate {
    final lastUpdate = state.lastPositionUpdate;
    if (lastUpdate == null) return null;
    return DateTime.now().difference(lastUpdate);
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

    return RouteInfo(
      totalDistance: totalDistance,
      isMultiDestination: state.isMultiDestination,
      segmentCount: state.routeSegments?.length ?? 1,
      estimatedDuration: Duration(
        minutes: (totalDistance / 1000 / 30 * 60).round(),
      ),
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
