// ignore_for_file: avoid_bool_literals_in_conditional_expressions

import 'dart:developer' as dev;
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:freedom/core/services/push_notification_service/socket_delivery_model.dart';
import 'package:freedom/core/services/real_time_driver_tracking.dart'
    as tracking;

import 'package:freedom/core/services/delivery_animation_service.dart';
import 'package:freedom/core/services/real_time_driver_tracking.dart';
import 'package:freedom/core/services/route_animation_services.dart';
import 'package:freedom/core/services/delivery_persistence_service.dart';
import 'package:freedom/feature/home/delivery_cubit/helpers.dart';
import 'package:freedom/feature/home/repository/models/delivery_status_response.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:freedom/feature/home/models/delivery_model.dart';
import 'package:freedom/feature/home/models/delivery_request_response.dart';
import 'package:freedom/feature/home/repository/delivery_repository.dart';
import 'package:freedom/feature/home/repository/location_repository.dart';
import 'package:freedom/feature/home/repository/models/location.dart';
import 'package:freedom/feature/home/repository/models/place_prediction.dart';
import 'package:freedom/core/services/route_services.dart';
import 'package:freedom/core/services/socket_service.dart';
import 'package:freedom/di/locator.dart';

part 'delivery_state.dart';

class DeliveryCubit extends Cubit<DeliveryState> {
  DeliveryCubit(
    this.deliveryRepository,
    this.locationRepository, {
    RouteService? routeService,
    RouteAnimationService? animationService,
    RealTimeDriverTrackingService? trackingService,
    DeliveryAnimationService? deliveryAnimationService,
    DeliveryPersistenceService? persistenceService,
  }) : _routeService = routeService ?? getIt<RouteService>(),
       _animationService = animationService ?? getIt<RouteAnimationService>(),
       _realTimeTrackingService =
           trackingService ?? getIt<RealTimeDriverTrackingService>(),
       _deliveryAnimationService =
           deliveryAnimationService ?? DeliveryAnimationService(),
       _persistenceService =
           persistenceService ?? DeliveryPersistenceService(deliveryRepository),
       super(const DeliveryState()) {
    _initSocketListener();
    _loadPersistedStateOnInit();
  }

  final DeliveryRepositoryImpl deliveryRepository;
  final LocationRepository locationRepository;
  final RouteService _routeService;
  final RouteAnimationService _animationService;
  final RealTimeDriverTrackingService _realTimeTrackingService;
  final DeliveryAnimationService _deliveryAnimationService;
  final DeliveryPersistenceService _persistenceService;

  Timer? _debounceTimer;
  Timer? _timer;
  static const int maxSearchTime = 60;

  StreamSubscription<dynamic>? _deliveryDriverStatusSubscription;
  StreamSubscription<dynamic>? _deliveryManCancelledSubscription;
  StreamSubscription<dynamic>? _deliveryDriverAcceptedSubscription;
  StreamSubscription<dynamic>? _deliveryDriverArrivedSubscription;
  StreamSubscription<dynamic>? _deliveryDriverCompletedSubscription;
  StreamSubscription<dynamic>? _deliveryDriverStartedSubscription;
  StreamSubscription<dynamic>? _deliveryDriverPositionSubscription;

  DateTime? _lastStatusUpdate;
  DeliveryModel? _currentDeliveryRequest;

  DeliveryModel? get currentDeliveryRequest => _currentDeliveryRequest;

  Future<void> checkDeliveryStatus(String id) async {
    try {
      final response = await deliveryRepository.checkDeliveryStatus(id);
      response.fold(
        (l) => emit(state.copyWith(errorMessage: l.message)),
        (r) => emit(state.copyWith(statusData: r)),
      );
    } catch (e) {}
  }

  Future<void> _loadPersistedStateOnInit() async {
    try {
      final persistedData =
          await _persistenceService.loadPersistedDeliveryState();
      if (persistedData == null) {
        return;
      }

      dev.log(
        '✅ Loading persisted delivery state: ${persistedData.deliveryId}',
      );

      dev.log(
        '  - driverAccepted: ${persistedData.deliveryDriverAccepted?.status}',
      );
      dev.log(
        '  - driverStarted: ${persistedData.deliveryDriverStarted?.status}',
      );
      dev.log(
        '  - wasTrackingActive: ${persistedData.isRealTimeDeliveryTrackingActive}',
      );

      _currentDeliveryRequest = persistedData.deliveryRequest;

      // Ensure custom marker is loaded first
      await _ensureDeliveryMarkerIcons();

      emit(
        state.copyWith(
          status: persistedData.status,
          currentDeliveryId: persistedData.deliveryId,
          riderFound: persistedData.riderFound,
          deliveryInProgress: persistedData.deliveryInProgress,
          deliveryDriverHasArrived: persistedData.deliveryDriverHasArrived,
          isRealTimeDeliveryTrackingActive:
              persistedData.isRealTimeDeliveryTrackingActive,
          deliveryRouteDisplayed: persistedData.deliveryRouteDisplayed,
          currentDeliverySpeed: persistedData.currentDeliverySpeed,
          lastDeliveryPositionUpdate: persistedData.lastDeliveryPositionUpdate,
          deliveryTrackingStatusMessage:
              persistedData.deliveryTrackingStatusMessage,
          currentDeliveryDriverPosition:
              persistedData.currentDeliveryDriverPosition,
          deliveryData: persistedData.deliveryData,
          deliveryDriverAccepted: persistedData.deliveryDriverAccepted,
          deliveryDriverStarted: persistedData.deliveryDriverStarted,
          deliveryRoutePolylines: persistedData.polylines ?? const {},
          deliveryRouteMarkers: persistedData.markers ?? const {},
        ),
      );

      // Always set up socket listeners if there's an active delivery
      if (persistedData.riderFound || persistedData.deliveryInProgress) {
        _listenToDeliveryDriverStatus();
      }

      final shouldResumeTracking = shouldResumeRealTimeTracking(persistedData);

      if (shouldResumeTracking) {
        // Longer delay to ensure everything is properly initialized
        await Future.delayed(const Duration(milliseconds: 1000));
        await _resumeRealTimeDeliveryTracking(persistedData);
      } else {}
    } catch (e, stackTrace) {
      await _persistenceService.clearPersistedState();
    }
  }

  Future<void> _resumeRealTimeDeliveryTracking(
    PersistedDeliveryData persistedData,
  ) async {
    try {
      if (_currentDeliveryRequest == null) {
        return;
      }

      // Get destination coordinates
      final destinationCoordinates = await _getCoordinatesFromAddress(
        _currentDeliveryRequest!.destinationLocation,
      );

      if (destinationCoordinates == null) {
        dev.log(
          '❌ Cannot resume tracking: failed to get destination coordinates',
        );
        return;
      }

      final destination = LatLng(
        destinationCoordinates.latitude,
        destinationCoordinates.longitude,
      );

      // Get delivery and driver IDs with multiple fallback options
      final deliveryId = persistedData.deliveryId;
      final driverId = getDriverId(persistedData);

      dev.log(
        '  - destination: ${destination.latitude}, ${destination.longitude}',
      );

      if (driverId.isEmpty) {
        // Try to get driver info from server as fallback
        await _fetchLatestDeliveryStatus(deliveryId);
        return;
      }

      final gmapsDestination = gmaps.LatLng(
        destination.latitude,
        destination.longitude,
      );

      // Start the real-time tracking service

      _realTimeTrackingService.startTracking(
        rideId: deliveryId,
        driverId: driverId,
        destination: gmapsDestination,
        onPositionUpdate: _handleRealTimeDeliveryPositionUpdate,
        onRouteUpdated: _updateDeliveryRouteOnMap,
        onStatusUpdate: _updateDeliveryTrackingStatus,
        onMarkerUpdate: _handlePreciseDeliveryMarkerUpdate,
      );

      // Resume animation service if we have a position
      final lastKnownPosition = persistedData.currentDeliveryDriverPosition;
      if (lastKnownPosition != null) {
        dev.log(
          '🎬 Resuming animation from last known position: $lastKnownPosition',
        );

        _deliveryAnimationService.startRealTimeTracking(
          onMarkerUpdate: (position, rotation) {
            _updateDeliveryDriverMarkerPositionRealTime(position, rotation);
          },
          initialPosition: lastKnownPosition,
        );
      } else {
        dev.log(
          '⚠️ No last known position, using pickup location for animation',
        );

        final pickupCoordinates = await _getCoordinatesFromAddress(
          _currentDeliveryRequest!.pickupLocation,
        );

        if (pickupCoordinates != null) {
          final pickup = LatLng(
            pickupCoordinates.latitude,
            pickupCoordinates.longitude,
          );
          _deliveryAnimationService.startRealTimeTracking(
            onMarkerUpdate: (position, rotation) {
              _updateDeliveryDriverMarkerPositionRealTime(position, rotation);
            },
            initialPosition: pickup,
          );
        }
      }

      emit(
        state.copyWith(
          isRealTimeDeliveryTrackingActive: true,
          deliveryTrackingStatusMessage: 'Real-time tracking resumed',
        ),
      );

      // Additional verification
      Future.delayed(const Duration(seconds: 3), () {
        final isServiceActive = _realTimeTrackingService.isTracking;
        final isAnimationActive = _deliveryAnimationService.isRealTimeTracking;

        dev.log(
          '  - State tracking active: ${state.isRealTimeDeliveryTrackingActive}',
        );

        if (!isServiceActive || !isAnimationActive) {}
      });
    } catch (e, stackTrace) {
      emit(
        state.copyWith(
          isRealTimeDeliveryTrackingActive: false,
          deliveryTrackingStatusMessage: 'Failed to resume tracking',
        ),
      );
    }
  }

  Future<void> _fetchLatestDeliveryStatus(String deliveryId) async {
    try {
      final response = await deliveryRepository.checkDeliveryStatus(deliveryId);
      response.fold((failure) {}, (statusData) {
        emit(state.copyWith(statusData: statusData));

        // If we now have driver info, try to resume tracking
        if (statusData.driverId?.isNotEmpty == true) {
          final persistedData = PersistedDeliveryData(
            deliveryId: deliveryId,
            status: state.status,
            riderFound: state.riderFound,
            deliveryInProgress: state.deliveryInProgress,
            deliveryDriverHasArrived: state.deliveryDriverHasArrived,
            isRealTimeDeliveryTrackingActive:
                state.isRealTimeDeliveryTrackingActive,
            deliveryRouteDisplayed: state.deliveryRouteDisplayed,
            currentDeliverySpeed: state.currentDeliverySpeed,
            lastDeliveryPositionUpdate: state.lastDeliveryPositionUpdate,
            deliveryTrackingStatusMessage: state.deliveryTrackingStatusMessage,
            currentDeliveryDriverPosition: state.currentDeliveryDriverPosition,
            deliveryData: state.deliveryData,
            deliveryDriverAccepted: state.deliveryDriverAccepted,
            deliveryDriverStarted: state.deliveryDriverStarted,
            polylines: state.deliveryRoutePolylines,
            markers: state.deliveryRouteMarkers,
            deliveryRequest: _currentDeliveryRequest,
            deliveryStatusResponse: statusData,
          );

          _resumeRealTimeDeliveryTracking(persistedData);
        }
      });
    } catch (e) {}
  }

  @override
  void emit(DeliveryState state) {
    super.emit(state);

    if (state.hasActiveDelivery) {
      _persistenceService.persistDeliveryState(state).catchError((e) {});
    }
  }

  void _initSocketListener() {
    _deliveryDriverStatusSubscription?.cancel();
    _deliveryDriverStatusSubscription = null;
    _deliveryManCancelledSubscription?.cancel();
    _deliveryManCancelledSubscription = null;
  }

  set searchTimeElapsed(int searchTimeElapsed) =>
      emit(state.copyWith(searchTimeElapsed: searchTimeElapsed));

  int get searchTimeElapsed => state.searchTimeElapsed;

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
            status: DeliveryStatus.initial,
            riderFound: false,
            showDeliverySearchSheet: false,
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
    _resetDeliveryState();
  }

  void _listenToDeliveryDriverStatus() {
    final socketService = getIt<SocketService>();

    _cancelAllSubscriptions();

    _deliveryDriverAcceptedSubscription = socketService.onDeliveryManAccepted
        .listen((data) async {
          _stopSearchTimer();

          emit(
            state.copyWith(
              status: DeliveryStatus.success,
              riderFound: true,
              showDeliverySearchSheet: false,
              deliveryDriverAccepted: data,
            ),
          );

          try {
            await _displayStaticDeliveryRoute();
          } catch (e) {
            emit(state.copyWith(errorMessage: 'Failed to display route: $e'));
          }
        });

    _deliveryDriverStartedSubscription = socketService.onDeliveryManStarted
        .listen((data) async {
          dev.log(
            '🚚 Delivery driver started - starting marker animation and tracking',
          );

          emit(
            state.copyWith(
              deliveryDriverStarted: data,
              deliveryInProgress: data.status == 'in_progress',
            ),
          );

          // Start both animation and real-time tracking
          await _startDeliveryMarkerAnimation();
          await _startRealTimeDeliveryTracking();
        });

    _deliveryDriverArrivedSubscription = socketService.onDeliveryManArrived
        .listen((data) {
          emit(
            state.copyWith(
              deliveryDriverArrived: data,
              deliveryDriverHasArrived: true,
            ),
          );
        });

    _deliveryDriverPositionSubscription = socketService.onDeliveryManLocation
        .listen((locationData) {
          dev.log(
            '🚚 Delivery driver location updated via socket: ${locationData.entries}',
          );
          _processRealTimeLocationUpdate(locationData);
        });

    _deliveryManCancelledSubscription = socketService.onDeliveryManCancelled
        .listen((data) {
          _stopDeliveryAnimation();
          _stopRealTimeDeliveryTracking();
          _clearDeliveryRouteDisplay();
          _resetDeliveryState();
          emit(state.copyWith(deliveryDriverCancelled: data));
        });

    _deliveryDriverCompletedSubscription = socketService.onDeliveryManCompleted
        .listen((data) {
          _stopDeliveryAnimation();
          _stopRealTimeDeliveryTracking();
          _clearDeliveryRouteDisplay();
          _resetDeliveryState();
          _persistenceService.clearPersistedState();
          emit(state.copyWith(deliveryDriverCompleted: data));
        });
  }

  Future<void> _startDeliveryMarkerAnimation() async {
    if (_currentDeliveryRequest == null) {
      return;
    }

    try {
      final pickupCoordinates = await _getCoordinatesFromAddress(
        _currentDeliveryRequest!.pickupLocation,
      );
      final destinationCoordinates = await _getCoordinatesFromAddress(
        _currentDeliveryRequest!.destinationLocation,
      );

      if (pickupCoordinates == null || destinationCoordinates == null) {
        return;
      }

      final pickup = LatLng(
        pickupCoordinates.latitude,
        pickupCoordinates.longitude,
      );
      final destination = LatLng(
        destinationCoordinates.latitude,
        destinationCoordinates.longitude,
      );

      _deliveryAnimationService.startRealTimeTracking(
        onMarkerUpdate: (position, rotation) {
          _updateDeliveryDriverMarkerPositionRealTime(position, rotation);
        },
        initialPosition: pickup,
      );

      _deliveryAnimationService.updateRealTimePosition(
        destination,
        _calculateBearing(pickup, destination),
      );

      _zoomToStreetLevel(pickup);

      emit(state.copyWith(deliveryDriverAnimationComplete: false));

      dev.log(
        '✅ Delivery marker animation started with existing driver marker',
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to start animation: $e'));
    }
  }

  void _processRealTimeLocationUpdate(Map<String, dynamic> locationData) {
    try {
      final latitude = locationData['latitude']?.toDouble();
      final longitude = locationData['longitude']?.toDouble();
      final bearing = locationData['bearing']?.toDouble() ?? 0.0;

      if (latitude == null || longitude == null) {
        return;
      }

      final newPosition = LatLng(latitude, longitude);

      _deliveryAnimationService.updateRealTimePosition(
        newPosition,
        bearing,
        locationData: locationData,
      );

      emit(
        state.copyWith(
          lastDeliveryPositionUpdate: DateTime.now(),
          currentDeliverySpeed: locationData['speed']?.toDouble() ?? 0.0,
          deliveryTrackingStatusMessage: _getDeliveryTrackingMessage(
            locationData['speed']?.toDouble() ?? 0.0,
          ),
        ),
      );

      if (_currentDeliveryRequest != null) {
        _checkIfDriverReachedDestination(newPosition);
      }
    } catch (e) {}
  }

  Future<void> _checkIfDriverReachedDestination(LatLng currentPosition) async {
    if (_currentDeliveryRequest == null) return;

    try {
      final destinationCoordinates = await _getCoordinatesFromAddress(
        _currentDeliveryRequest!.destinationLocation,
      );

      if (destinationCoordinates == null) return;

      final destination = LatLng(
        destinationCoordinates.latitude,
        destinationCoordinates.longitude,
      );

      final distance = _calculateDistanceInMeters(currentPosition, destination);

      if (distance <= 50.0) {
        _handleDeliveryDriverReachedDestination();
      }
    } catch (e) {}
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * math.pi / 180;
    final lat2 = end.latitude * math.pi / 180;
    final dLng = (end.longitude - start.longitude) * math.pi / 180;

    final y = math.sin(dLng) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  String _getDeliveryTrackingMessage(double speed) {
    if (speed > 15.0) {
      return 'Delivery driver moving fast (${speed.toStringAsFixed(0)} km/h)';
    } else if (speed > 5.0) {
      return 'Delivery driver is moving (${speed.toStringAsFixed(0)} km/h)';
    } else if (speed > 1.0) {
      return 'Delivery driver moving slowly';
    } else {
      return 'Delivery driver is stationary';
    }
  }

  void _stopDeliveryAnimation() {
    _deliveryAnimationService.stopRealTimeTracking();
  }

  void _updateDeliveryDriverMarkerPositionRealTime(
    LatLng position,
    double rotation,
  ) {
    try {
      final updatedMarkers = Map<MarkerId, Marker>.from(
        state.deliveryRouteMarkers,
      );
      const driverMarkerId = MarkerId('delivery_driver');

      if (updatedMarkers.containsKey(driverMarkerId)) {
        final currentMarker = updatedMarkers[driverMarkerId]!;
        final updatedMarker = currentMarker.copyWith(
          positionParam: position,
          rotationParam: rotation,
        );
        updatedMarkers[driverMarkerId] = updatedMarker;

        emit(
          state.copyWith(
            deliveryRouteMarkers: updatedMarkers,
            currentDeliveryDriverPosition: position,
            shouldUpdateCamera: false,
          ),
        );

        _persistenceService.updateDeliveryDriverPosition(position, rotation);
      } else {
        // Use consistent custom marker for fallback too
        final driverMarker = Marker(
          markerId: driverMarkerId,
          position: position,
          icon:
              state.deliveryDriverMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Delivery Driver'),
          rotation: rotation,
        );
        updatedMarkers[driverMarkerId] = driverMarker;

        emit(
          state.copyWith(
            deliveryRouteMarkers: updatedMarkers,
            currentDeliveryDriverPosition: position,
            shouldUpdateCamera: false,
          ),
        );
      }

      // Less frequent logging to reduce noise
      if (DateTime.now().millisecondsSinceEpoch % 5000 < 100) {
        dev.log(
          '🎬 Driver marker updated: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)} (${rotation.toStringAsFixed(1)}°)',
        );
      }
    } catch (e) {}
  }

  Future<void> _displayStaticDeliveryRoute() async {
    if (_currentDeliveryRequest == null) {
      return;
    }

    try {
      await _ensureDeliveryMarkerIcons();

      final pickupCoordinates = await _getCoordinatesFromAddress(
        _currentDeliveryRequest!.pickupLocation,
      );
      final destinationCoordinates = await _getCoordinatesFromAddress(
        _currentDeliveryRequest!.destinationLocation,
      );

      if (pickupCoordinates == null || destinationCoordinates == null) {
        emit(
          state.copyWith(errorMessage: 'Failed to locate delivery addresses'),
        );
        return;
      }

      final pickup = LatLng(
        pickupCoordinates.latitude,
        pickupCoordinates.longitude,
      );
      final destination = LatLng(
        destinationCoordinates.latitude,
        destinationCoordinates.longitude,
      );

      await _displaySingleDestinationDeliveryRoute(pickup, destination);
      _focusCameraOnDeliveryRoute();
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to display route: $e'));
    }
  }

  Future<void> _displaySingleDestinationDeliveryRoute(
    LatLng pickup,
    LatLng destination,
  ) async {
    dev.log(
      '🗺️ Displaying single destination delivery route with driver marker',
    );

    final routeResult = await _routeService.getRoute(pickup, destination);

    if (routeResult.isSuccess && routeResult.polyline != null) {
      final deliveryMarkers = _createDeliveryMarkersFromCoordinatesWithDriver(
        pickup,
        destination,
      );

      emit(
        state.copyWith(
          deliveryRoutePolylines: {routeResult.polyline!},
          deliveryRouteMarkers: deliveryMarkers,
          deliveryRouteDisplayed: true,
          currentDeliveryDriverPosition: pickup,
        ),
      );
    } else {}
  }

  Map<MarkerId, Marker> _createDeliveryMarkersFromCoordinatesWithDriver(
    LatLng pickup,
    LatLng destination,
  ) {
    final markers = <MarkerId, Marker>{};

    markers[const MarkerId('pickup')] = Marker(
      markerId: const MarkerId('pickup'),
      position: pickup,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(
        title: 'Pickup Location',
        snippet: _currentDeliveryRequest!.pickupLocation,
      ),
    );

    markers[const MarkerId('delivery_destination')] = Marker(
      markerId: const MarkerId('delivery_destination'),
      position: destination,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: 'Delivery Destination',
        snippet: _currentDeliveryRequest!.destinationLocation,
      ),
    );

    // Use consistent custom marker
    markers[const MarkerId('delivery_driver')] = Marker(
      markerId: const MarkerId('delivery_driver'),
      position: pickup,
      icon:
          state.deliveryDriverMarkerIcon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: const InfoWindow(title: 'Delivery Driver'),
      rotation: 0.0,
    );

    dev.log(
      '📍 Created 3 markers: pickup (green), destination (red), driver (custom)',
    );
    return markers;
  }

  Future<LatLng?> _getCoordinatesFromAddress(String address) async {
    try {
      final predictions = await locationRepository.getPlacePredictions(address);

      if (predictions.isNotEmpty) {
        final prediction = predictions.first;
        final placeDetails = await locationRepository.getPlaceDetails(
          prediction.placeId,
        );

        if (placeDetails != null) {
          return LatLng(placeDetails.latitude, placeDetails.longitude);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _ensureDeliveryMarkerIcons() async {
    try {
      if (state.deliveryDriverMarkerIcon == null) {
        await _createDeliveryDriverMarkerIcon();
      }
    } catch (e) {}
  }

  Future<void> _createDeliveryDriverMarkerIcon() async {
    try {
      final driverIcon = await _getConsistentDriverMarker();
      emit(state.copyWith(deliveryDriverMarkerIcon: driverIcon));
    } catch (e) {
      final defaultDriverIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueBlue,
      );
      emit(state.copyWith(deliveryDriverMarkerIcon: defaultDriverIcon));
    }
  }

  Future<BitmapDescriptor> _getConsistentDriverMarker() async {
    if (state.deliveryDriverMarkerIcon != null) {
      return state.deliveryDriverMarkerIcon!;
    }

    try {
      final driverIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(32, 32)),
        'assets/images/delivery_marker.png',
      );
      return driverIcon;
    } catch (e) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
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

  void _clearDeliveryRouteDisplay() {
    _stopDeliveryAnimation();
    _stopRealTimeDeliveryTracking();

    emit(
      state.copyWith(
        deliveryRoutePolylines: const {},
        deliveryRouteMarkers: const {},
        deliveryRouteDisplayed: false,
        deliveryRouteSegments: null,
        currentDeliveryDriverPosition: null,
        deliveryDriverAnimationComplete: false,
      ),
    );
  }

  void _focusCameraOnDeliveryRoute() {
    if (state.deliveryRoutePolylines.isEmpty) return;

    emit(state.copyWith(shouldUpdateCamera: true));

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!isClosed) {
        emit(state.copyWith(shouldUpdateCamera: false));
      }
    });
  }

  void centerCameraOnDeliveryDriver() {
    if (state.currentDeliveryDriverPosition != null) {
      emit(
        state.copyWith(
          shouldUpdateCamera: true,
          cameraTarget: state.currentDeliveryDriverPosition,
          streetLevelZoom: 30,
        ),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (!isClosed) {
          emit(state.copyWith(shouldUpdateCamera: false));
        }
      });
    }
  }

  void _handleDeliveryDriverReachedDestination() {
    _stopDeliveryAnimation();
    _stopRealTimeDeliveryTracking();

    emit(
      state.copyWith(
        isRealTimeDeliveryTrackingActive: false,
        deliveryTrackingStatusMessage:
            'Delivery completed - driver has arrived',
        deliveryDriverAnimationComplete: true,
      ),
    );
  }

  Future<void> requestDelivery(DeliveryModel deliveryRequestModel) async {
    dev.log('🚚 Requesting delivery: ${deliveryRequestModel.toJson()}');

    _currentDeliveryRequest = deliveryRequestModel;
    await _persistenceService.persistDeliveryRequest(deliveryRequestModel);

    emit(state.copyWith(status: DeliveryStatus.loading, errorMessage: null));

    try {
      final response = await deliveryRepository.requestDelivery(
        deliveryRequestModel,
      );

      log('requestDelivery() response: $response');

      response.fold(
        (failure) {
          emit(
            state.copyWith(
              status: DeliveryStatus.failure,
              errorMessage: failure.message,
            ),
          );
        },
        (deliveryResponse) {
          dev.log(
            '✅ Delivery request successful. Delivery ID: ${deliveryResponse.data?.deliveryId}',
          );

          if (deliveryResponse.success) {
            emit(
              state.copyWith(
                status: DeliveryStatus.success,
                deliveryData: deliveryResponse.data,
                showDeliverySearchSheet: true,
                currentDeliveryId: deliveryResponse.data?.deliveryId,
                deliveryModel: deliveryRequestModel,
                isSearching: true,
                riderFound: false,
              ),
            );
            _startTimer();
            _listenToDeliveryDriverStatus();
          } else {
            emit(
              state.copyWith(
                status: DeliveryStatus.failure,
                errorMessage: deliveryResponse.message,
              ),
            );
          }
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DeliveryStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _cancelAllSubscriptions() {
    _deliveryDriverStatusSubscription?.cancel();
    _deliveryManCancelledSubscription?.cancel();
    _deliveryDriverAcceptedSubscription?.cancel();
    _deliveryDriverArrivedSubscription?.cancel();
    _deliveryDriverCompletedSubscription?.cancel();
    _deliveryDriverStartedSubscription?.cancel();
    _deliveryDriverPositionSubscription?.cancel();
    _stopDeliveryAnimation();
    _stopRealTimeDeliveryTracking();
  }

  void _resetDeliveryState() {
    _clearDeliveryRouteDisplay();
    _persistenceService.clearPersistedState();
    emit(
      state.copyWith(
        status: DeliveryStatus.initial,
        showDeliverySearchSheet: false,
        riderFound: false,
        isSearching: false,
        searchTimeElapsed: 0,
        currentDeliveryId: null,
        deliveryData: null,
        errorMessage: null,
        deliveryRouteDisplayed: false,
        deliveryRoutePolylines: const {},
        deliveryRouteMarkers: const {},
        deliveryRouteSegments: null,
        currentDeliveryDriverPosition: null,
        deliveryDriverHasArrived: false,
        deliveryInProgress: false,
        isRealTimeDeliveryTrackingActive: false,
        deliveryTrackingStatusMessage: null,
        deliveryRouteRecalculated: false,
        currentDeliverySpeed: 0.0,
        deliveryDriverAnimationComplete: false,
      ),
    );
  }

  Future<void> _startRealTimeDeliveryTracking() async {
    try {
      if (_currentDeliveryRequest == null) {
        dev.log(
          '❌ Cannot start delivery tracking: no current delivery request',
        );
        return;
      }

      final destinationCoordinates = await _getCoordinatesFromAddress(
        _currentDeliveryRequest!.destinationLocation,
      );

      if (destinationCoordinates == null) {
        dev.log(
          '❌ Cannot start delivery tracking: failed to get destination coordinates',
        );
        emit(
          state.copyWith(
            errorMessage: 'Failed to locate destination for tracking',
            deliveryTrackingStatusMessage:
                'Cannot start tracking - invalid destination',
          ),
        );
        return;
      }

      final destination = LatLng(
        destinationCoordinates.latitude,
        destinationCoordinates.longitude,
      );

      final deliveryId =
          state.deliveryDriverAccepted?.deliveryId ??
          state.currentDeliveryId ??
          '';
      final driverId = state.deliveryDriverAccepted?.driverId ?? '';

      if (deliveryId.isEmpty || driverId.isEmpty) {
        dev.log(
          '❌ Cannot start delivery tracking: missing deliveryId($deliveryId) or driverId($driverId)',
        );
        return;
      }

      final gmapsDestination = gmaps.LatLng(
        destination.latitude,
        destination.longitude,
      );

      _realTimeTrackingService.startTracking(
        rideId: deliveryId,
        driverId: driverId,
        destination: gmapsDestination,
        onPositionUpdate: _handleRealTimeDeliveryPositionUpdate,
        onRouteUpdated: _updateDeliveryRouteOnMap,
        onStatusUpdate: _updateDeliveryTrackingStatus,
        onMarkerUpdate: _handlePreciseDeliveryMarkerUpdate,
      );

      emit(
        state.copyWith(
          shouldUpdateCamera: false,
          isRealTimeDeliveryTrackingActive: true,
          deliveryTrackingStatusMessage: 'Real-time tracking started',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Failed to start delivery tracking: $e',
          deliveryTrackingStatusMessage: 'Delivery tracking startup failed',
        ),
      );
    }
  }

  void _zoomToStreetLevel(LatLng position) {
    dev.log(
      '🔍 Zooming to street level at: ${position.latitude}, ${position.longitude}',
    );

    emit(
      state.copyWith(
        shouldUpdateCamera: true,
        cameraTarget: position,
        streetLevelZoom: 30,
      ),
    );

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!isClosed) {
        emit(state.copyWith(shouldUpdateCamera: false));
      }
    });
  }

  void _handleRealTimeDeliveryPositionUpdate(
    gmaps.LatLng position,
    double bearing,
    tracking.DriverLocationData locationData,
  ) {
    final uiPosition = LatLng(position.latitude, position.longitude);

    dev.log(
      '📍 Real-time delivery update: ${uiPosition.latitude.toStringAsFixed(6)}, ${uiPosition.longitude.toStringAsFixed(6)} (${bearing.toStringAsFixed(1)}°)',
    );

    _deliveryAnimationService.updateRealTimePosition(
      uiPosition,
      bearing,
      locationData: {
        'speed': locationData.speed,
        'accuracy': locationData.accuracy,
        'timestamp': locationData.lastUpdate.toIso8601String(),
      },
    );

    emit(
      state.copyWith(
        lastDeliveryPositionUpdate: locationData.lastUpdate,
        currentDeliverySpeed: locationData.speed,
        deliveryTrackingStatusMessage: _getEnhancedDeliveryTrackingMessage(
          locationData,
        ),
      ),
    );

    if (_realTimeTrackingService.hasReachedDestination(position)) {
      _handleDeliveryDriverReachedDestination();
    }
  }

  void _handlePreciseDeliveryMarkerUpdate(gmaps.LatLng position) {
    final uiPosition = LatLng(position.latitude, position.longitude);

    if (_deliveryAnimationService.isRealTimeTracking) {
      _deliveryAnimationService.updateRealTimePosition(
        uiPosition,
        _deliveryAnimationService.currentBearing,
      );
    }
  }

  void _updateDeliveryRouteOnMap(List<gmaps.LatLng> newRoutePoints) {
    try {
      if (state.deliveryRoutePolylines.isEmpty) {
        return;
      }

      dev.log(
        '🛣️ Updating delivery route with ${newRoutePoints.length} new points',
      );

      final uiRoutePoints =
          newRoutePoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

      final currentPolyline = state.deliveryRoutePolylines.first;
      final updatedPolyline = currentPolyline.copyWith(
        pointsParam: uiRoutePoints,
      );

      emit(
        state.copyWith(
          deliveryRoutePolylines: {updatedPolyline},
          deliveryRouteRecalculated: true,
          deliveryTrackingStatusMessage:
              'Delivery route updated - driver changed path',
        ),
      );

      Future.delayed(const Duration(seconds: 3), () {
        if (!isClosed) {
          emit(state.copyWith(deliveryRouteRecalculated: false));
        }
      });
    } catch (e) {
      emit(
        state.copyWith(
          deliveryTrackingStatusMessage: 'Delivery route update failed: $e',
        ),
      );
    }
  }

  void _updateDeliveryTrackingStatus(String status) {
    final currentTime = DateTime.now();
    if (_lastStatusUpdate != null &&
        currentTime.difference(_lastStatusUpdate!).inSeconds < 2 &&
        status.contains('position updated')) {
      return;
    }
    _lastStatusUpdate = currentTime;

    emit(state.copyWith(deliveryTrackingStatusMessage: status));

    final duration =
        status.contains('error') || status.contains('failed')
            ? const Duration(seconds: 8)
            : const Duration(seconds: 4);

    Future.delayed(duration, () {
      if (!isClosed) {
        emit(state.copyWith(deliveryTrackingStatusMessage: null));
      }
    });
  }

  String _getEnhancedDeliveryTrackingMessage(
    tracking.DriverLocationData locationData,
  ) {
    if (locationData.speed > 15.0) {
      return 'Delivery driver moving fast (${locationData.speed.toStringAsFixed(0)} km/h)';
    } else if (locationData.speed > 5.0) {
      return 'Delivery driver is moving (${locationData.speed.toStringAsFixed(0)} km/h)';
    } else if (locationData.speed > 1.0) {
      return 'Delivery driver moving slowly';
    } else {
      return 'Delivery driver is stationary';
    }
  }

  void _stopRealTimeDeliveryTracking() {
    _realTimeTrackingService.stopTracking();

    emit(
      state.copyWith(
        isRealTimeDeliveryTrackingActive: false,
        deliveryTrackingStatusMessage: null,
        currentDeliverySpeed: 0.0,
      ),
    );
  }

  Future<void> cancelDelivery({required String reason}) async {
    try {
      emit(
        state.copyWith(
          deliveryCancellationStatus: DeliveryCancellationStatus.canceling,
        ),
      );
      _stopSearchTimer();
      _stopDeliveryAnimation();
      _stopRealTimeDeliveryTracking();

      if (state.currentDeliveryId == null) {
        throw Exception('No active delivery to cancel');
      }

      final response = await deliveryRepository.cancelDelivery(
        state.currentDeliveryId!,
        reason,
      );

      response.fold(
        (failure) {
          emit(
            state.copyWith(
              deliveryCancellationStatus: DeliveryCancellationStatus.error,
              errorMessage: failure.message,
            ),
          );
        },
        (success) {
          emit(
            state.copyWith(
              deliveryCancellationStatus: DeliveryCancellationStatus.cancelled,
              message: 'Delivery cancelled successfully',
              showDeliverySearchSheet: false,
              riderFound: false,
            ),
          );
          _persistenceService.clearPersistedState();
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          deliveryCancellationStatus: DeliveryCancellationStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  RouteProgress? getCurrentDeliveryRouteProgress() {
    if (!_realTimeTrackingService.isTracking) {
      return null;
    }

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
    } catch (e) {}

    return null;
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

  double _calculateActualProgress(
    gmaps.LatLng driverPosition,
    List<gmaps.LatLng> routePoints,
  ) {
    if (routePoints.length < 2) return 0.0;

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

  TrackingStatus getDeliveryTrackingStatus() {
    return _realTimeTrackingService.getTrackingStatus();
  }

  Map<String, dynamic> getEnhancedDeliveryTrackingMetrics() {
    final baseMetrics = _realTimeTrackingService.getTrackingMetrics();
    final performanceMetrics = _realTimeTrackingService.getPerformanceMetrics();
    final issues = _realTimeTrackingService.validateTrackingState();

    return {
      ...baseMetrics,
      'performance': performanceMetrics,
      'issues': issues,
      'uiTrackingActive': state.isRealTimeDeliveryTrackingActive,
      'deliveryInProgress': state.deliveryInProgress,
      'socketConnected': getIt<SocketService>().isConnected,
      'currentDeliveryId': state.currentDeliveryId,
      'driverAcceptedId': state.deliveryDriverAccepted?.driverId,
      'animationServiceActive': _deliveryAnimationService.isRealTimeTracking,
      'animationPosition':
          _deliveryAnimationService.currentPosition?.toString(),
      'animationBearing': _deliveryAnimationService.currentBearing,
    };
  }

  bool get isRealTimeDeliveryTrackingActive {
    final serviceActive = _realTimeTrackingService.isTracking;
    final stateActive =
        state.deliveryInProgress && state.isRealTimeDeliveryTrackingActive;
    final animationActive = _deliveryAnimationService.isRealTimeTracking;

    if (serviceActive != stateActive) {
      dev.log(
        '🚨 Delivery tracking state mismatch - Service: $serviceActive, State: $stateActive',
      );
    }

    if (serviceActive && !animationActive) {}

    return serviceActive && stateActive;
  }

  Duration? get estimatedTimeToDeliveryDestination {
    final progress = getCurrentDeliveryRouteProgress();
    return progress?.estimatedTimeRemaining;
  }

  double? get distanceToDeliveryDestination {
    final progress = getCurrentDeliveryRouteProgress();
    return progress?.remainingDistance;
  }

  Duration? get timeSinceLastDeliveryUpdate {
    final lastUpdate = state.lastDeliveryPositionUpdate;
    if (lastUpdate == null) return null;
    return DateTime.now().difference(lastUpdate);
  }

  // DELIVERY LOCATION METHODS
  void addDeliveryDestination(TextEditingController controller) {
    final newController = TextEditingController();

    final currentControllers = List<TextEditingController>.from(
      state.deliveryControllers.isEmpty
          ? [controller]
          : state.deliveryControllers,
    )..add(newController);

    emit(
      state.copyWith(
        deliveryControllers: currentControllers,
        isMultipleDestination: true,
      ),
    );
  }

  void removeDestination(int index) {
    if (state.deliveryControllers.isEmpty ||
        index <= 0 ||
        index >= state.deliveryControllers.length) {
      return;
    }

    final newControllers = List<TextEditingController>.from(
      state.deliveryControllers,
    );

    newControllers[index].clear();
    newControllers.removeAt(index);

    emit(
      state.copyWith(
        deliveryControllers: newControllers,
        isMultipleDestination: newControllers.length > 1,
        activeDestinationIndex:
            index == state.activeDestinationIndex
                ? 0
                : (state.activeDestinationIndex > index
                    ? state.activeDestinationIndex - 1
                    : state.activeDestinationIndex),
      ),
    );
  }

  void setSingleDestination() {
    if (state.deliveryControllers.isEmpty) return;

    for (var i = 1; i < state.deliveryControllers.length; i++) {
      state.deliveryControllers[i].clear();
    }

    emit(
      state.copyWith(
        deliveryControllers:
            state.deliveryControllers.isNotEmpty
                ? [state.deliveryControllers.first]
                : [],
        isMultipleDestination: false,
        activeDestinationIndex: 0,
      ),
    );
  }

  List<String> getAllDestinationValues() {
    return state.deliveryControllers
        .map((controller) => controller.text)
        .toList();
  }

  void clearControllers() {
    final controllers = state.deliveryControllers;
    for (final controller in controllers) {
      controller.clear();
    }
  }

  void searchLocationDebounced(String query, {required bool isPickup}) {
    _debounceTimer?.cancel();
    if (query.isEmpty) {
      if (isPickup) {
        emit(
          state.copyWith(
            showPickupPredictions: false,
            showRecentPickUpLocations: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            showDestinationPredictions: false,
            showRecentDestinationLocations: true,
          ),
        );
      }
      return;
    }
    emit(state.copyWith(isLoadingPredictions: true));
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!state.islocationSelected) {
        dev.log(
          'Debounce timer fired, executing search for "$query" (isPickup: $isPickup, activeIndex: ${state.activeDestinationIndex})',
        );
        searchLocations(query, isPickup: isPickup);
      } else {
        emit(state.copyWith(islocationSelected: false));
      }
    });
  }

  Future<void> searchLocations(String query, {required bool isPickup}) async {
    try {
      dev.log(
        'Executing search for "$query" (isPickup: $isPickup, activeIndex: ${state.activeDestinationIndex})',
      );

      final predictions = await locationRepository.getPlacePredictions(query);

      emit(
        state.copyWith(
          pickupPredictions: isPickup ? predictions : state.pickupPredictions,
          destinationPredictions:
              isPickup ? state.destinationPredictions : predictions,
          showPickupPredictions:
              isPickup ? (predictions.isNotEmpty) : state.showPickupPredictions,
          showDestinationPredictions:
              isPickup
                  ? state.showDestinationPredictions
                  : (predictions.isNotEmpty),
          isLoadingPredictions: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Failed to search locations: ${e.toString()}',
          isLoadingPredictions: false,
        ),
      );
    }
  }

  void selectLocationAddress(
    PlacePrediction prediction, {
    required bool isPickup,
    required TextEditingController controller,
    required VoidCallback onBeforeTextChange,
    required VoidCallback onAfterTextChange,
    FocusNode? currentFocusNode,
    FocusNode? nextFocusNode,
  }) {
    dev.log(
      'Selecting location: ${prediction.description} (isPickup: $isPickup)',
    );
    onBeforeTextChange();
    controller.text = prediction.description;
    emit(
      state.copyWith(
        showPickupPredictions: false,
        showDestinationPredictions: false,
        showRecentPickUpLocations: false,
        showRecentDestinationLocations: false,
        isLoadingPredictions: false,
        islocationSelected: true,
      ),
    );
    onAfterTextChange();
    if (currentFocusNode != null) {
      currentFocusNode.unfocus();
    }
  }

  Future<void> handlePickUpLocation(
    PlacePrediction prediction,
    FocusNode pickUpNode,
    FocusNode destinationNode,
    TextEditingController pickUpController,
    TextEditingController destinationController,
    VoidCallback onBeforeTextChange,
    VoidCallback onAfterTextChange,
  ) async {
    emit(
      state.copyWith(
        isLoadingPredictions: false,
        showPickupPredictions: false,
        showDestinationPredictions: false,
        showRecentPickUpLocations: false,
        showRecentDestinationLocations: false,
      ),
    );

    selectLocationAddress(
      prediction,
      isPickup: true,
      controller: pickUpController,
      currentFocusNode: pickUpNode,
      nextFocusNode: null,
      onBeforeTextChange: onBeforeTextChange,
      onAfterTextChange: onAfterTextChange,
    );
  }

  Future<void> handleDestinationLocation(
    PlacePrediction prediction,
    FocusNode destinationNode,
    TextEditingController destinationController,
    VoidCallback onBeforeTextChange,
    VoidCallback onAfterTextChange,
  ) async {
    emit(
      state.copyWith(
        isLoadingPredictions: false,
        showPickupPredictions: false,
        showDestinationPredictions: false,
        showRecentPickUpLocations: false,
        showRecentDestinationLocations: false,
      ),
    );

    selectLocationAddress(
      prediction,
      isPickup: false,
      controller: destinationController,
      currentFocusNode: destinationNode,
      nextFocusNode: null,
      onBeforeTextChange: onBeforeTextChange,
      onAfterTextChange: onAfterTextChange,
    );
  }

  Future<void> handleAdditionalDestinationLocation(
    PlacePrediction prediction,
    FocusNode destinationNode,
    TextEditingController destinationController,
    int destinationIndex,
    VoidCallback onBeforeTextChange,
    VoidCallback onAfterTextChange,
  ) async {
    dev.log(
      'Handling location selection for destination #${destinationIndex}: ${prediction.mainText}',
    );
    emit(
      state.copyWith(
        isLoadingPredictions: false,
        showPickupPredictions: false,
        showDestinationPredictions: false,
        showRecentPickUpLocations: false,
        showRecentDestinationLocations: false,
      ),
    );
    selectLocationAddress(
      prediction,
      isPickup: false,
      controller: destinationController,
      currentFocusNode: destinationNode,
      nextFocusNode: null,
      onBeforeTextChange: onBeforeTextChange,
      onAfterTextChange: onAfterTextChange,
    );
  }

  void hideAllPredictionPanels() {
    emit(
      state.copyWith(
        showPickupPredictions: false,
        showDestinationPredictions: false,
        isLoadingPredictions: false,
      ),
    );
  }

  void togglePredictionVisibility({
    required bool isPickup,
    required bool isVisible,
  }) {
    emit(
      state.copyWith(
        showPickupPredictions:
            isPickup ? isVisible : state.showPickupPredictions,
        showDestinationPredictions:
            isPickup ? state.showDestinationPredictions : isVisible,
        isPickUpLocation: isPickup ? isVisible : state.isPickUpLocation,
        isDestinationLocation:
            isPickup ? state.isDestinationLocation : isVisible,
      ),
    );
  }

  void isPickUpLocation({required bool isPickUpLocation}) {
    emit(
      state.copyWith(
        isPickUpLocation: isPickUpLocation,
        isDestinationLocation:
            isPickUpLocation ? false : state.isDestinationLocation,
      ),
    );
  }

  void isDestinationLocation({required bool isDestinationLocation}) {
    emit(
      state.copyWith(
        isDestinationLocation: isDestinationLocation,
        isPickUpLocation:
            isDestinationLocation ? false : state.isPickUpLocation,
      ),
    );
  }

  void showRecentPickUpLocations({
    required bool showRecentlySearchedLocations,
  }) {
    emit(
      state.copyWith(
        showRecentPickUpLocations: showRecentlySearchedLocations,
        showDestinationPredictions: false,
        showPickupPredictions: false,
        showRecentDestinationLocations: false,
      ),
    );

    if (showRecentlySearchedLocations) {
      fetchRecentLocations();
    }
  }

  void showDestinationRecentlySearchedLocations({
    required bool showDestinationRecentlySearchedLocations,
  }) {
    emit(
      state.copyWith(
        showRecentDestinationLocations:
            showDestinationRecentlySearchedLocations,
        showPickupPredictions: false,
        showDestinationPredictions: false,
        showRecentPickUpLocations: false,
      ),
    );

    if (showDestinationRecentlySearchedLocations) {
      fetchRecentLocations();
    }
  }

  Future<void> clearPredictions() async {
    emit(
      state.copyWith(
        pickupPredictions: [],
        destinationPredictions: [],
        showPickupPredictions: false,
        showDestinationPredictions: false,
      ),
    );
  }

  Future<void> fetchRecentLocations() async {
    try {
      final locations = await locationRepository.getRecentLocations();
      emit(state.copyWith(recentLocations: locations));
    } catch (e) {}
  }

  Future<void> clearRecentLocations() async {
    try {
      await locationRepository.clearRecentLocations();
      emit(state.copyWith(recentLocations: []));
    } catch (e) {}
  }

  void setActiveDestinationIndex(int index) {
    emit(
      state.copyWith(
        activeDestinationIndex: index,
        isDestinationLocation: true,
        isPickUpLocation: false,
      ),
    );
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    _timer?.cancel();

    _animationService.dispose();
    _deliveryAnimationService.dispose();

    _stopDeliveryAnimation();
    _stopRealTimeDeliveryTracking();
    _cancelAllSubscriptions();

    return super.close();
  }
}
