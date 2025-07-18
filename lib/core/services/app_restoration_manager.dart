import 'dart:async';
import 'dart:developer' as dev;
import 'package:freedom/app_preference.dart';
import 'package:freedom/core/services/real_time_driver_tracking.dart';
import 'package:freedom/core/services/ride_persistence_service.dart';
import 'package:freedom/feature/home/repository/ride_request_repository.dart';
import 'package:freedom/feature/home/ride_cubit/ride_cubit.dart';
import 'package:freedom/core/services/socket_service.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/shared/enums/enums.dart';
import 'package:freedom/shared/utils/marker_converter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideRestorationManager {
  final RidePersistenceService _persistenceService;
  final RideRequestRepository _rideRepository;

  RideRestorationManager({
    required RidePersistenceService persistenceService,
    required RideRequestRepository rideRepository,
  }) : _persistenceService = persistenceService,
       _rideRepository = rideRepository;

  Future<RideRestorationResult> attemptRideRestoration() async {
    try {
      dev.log('🔄 Starting ride restoration process...');

      final hasActiveRide = await _persistenceService.hasActiveRide();
      if (!hasActiveRide) {
        dev.log('📭 No active ride found to restore');
        return RideRestorationResult.noRideToRestore();
      }

      final persistedData = await _persistenceService.loadCompleteRideState();
      if (persistedData == null) {
        dev.log('❌ Failed to load persisted ride data');
        await _persistenceService.clearAllPersistedData();
        return RideRestorationResult.failed('Failed to load persisted data');
      }

      dev.log(
        '📱 Loaded persisted ride: ${persistedData.rideId} (${persistedData.status})',
      );

      final serverValidation = await _validateRideWithServer(
        persistedData.rideId!,
      );
      if (!serverValidation.isValid) {
        dev.log('❌ Server validation failed: ${serverValidation.reason}');
        await _persistenceService.clearAllPersistedData();
        return RideRestorationResult.failed(serverValidation.reason!);
      }

      final restorationStrategy = _determineRestorationStrategy(
        persistedData,
        serverValidation.currentStatus!,
      );

      final restorationResult = await _executeRestoration(
        persistedData,
        restorationStrategy,
        serverValidation.currentStatus!,
      );

      if (restorationResult.success) {
        await _persistenceService.recordAppStateOnKill({
          'restorationSuccessful': true,
          'restoredAt': DateTime.now().toIso8601String(),
          'strategy': restorationStrategy.toString(),
        });
      } else {
        dev.log('❌ Ride restoration failed: ${restorationResult.error}');
        await _persistenceService.clearRideData();
      }

      return restorationResult;
    } catch (e, stack) {
      dev.log('❌ Critical error during ride restoration: $e\n$stack');
      await _persistenceService.clearAllPersistedData();
      return RideRestorationResult.failed('Critical restoration error: $e');
    }
  }

  Future<ServerValidationResult> _validateRideWithServer(String rideId) async {
    try {
      final response = await _rideRepository.checkRideStatus(rideId);

      return await response.fold(
        (failure) => ServerValidationResult.invalid(
          'Server validation failed: ${failure.message}',
        ),
        (statusResponse) {
          final currentStatus = statusResponse.data?.status;
          dev.log('📊 Server says ride status is: $currentStatus');

          if (currentStatus == null) {
            return ServerValidationResult.invalid(
              'No status returned from server',
            );
          }

          if (_isRideStatusInvalid(currentStatus)) {
            return ServerValidationResult.invalid(
              'Ride is no longer active (status: $currentStatus)',
            );
          }

          return ServerValidationResult.valid(currentStatus, statusResponse);
        },
      );
    } catch (e) {
      return ServerValidationResult.invalid('Server validation error: $e');
    }
  }

  RestorationStrategy _determineRestorationStrategy(
    PersistedRideData persistedData,
    String currentServerStatus,
  ) {
    dev.log('🎯 Determining restoration strategy...');
    dev.log('   Persisted status: ${persistedData.status}');
    dev.log('   Server status: $currentServerStatus');
    dev.log(
      '   Real-time tracking was: ${persistedData.isRealTimeTrackingActive}',
    );
    dev.log('   Ride in progress: ${persistedData.rideInProgress}');

    if (_isRideFinished(currentServerStatus)) {
      return RestorationStrategy.showFinalState;
    }

    if (currentServerStatus == 'searching' ||
        currentServerStatus == 'pending') {
      dev.log(
        '⚠️ Search in progress detected after restart - will cancel and reset',
      );
      return RestorationStrategy.cancelSearchAndReset;
    }

    if (currentServerStatus == 'accepted' && !persistedData.rideInProgress) {
      return RestorationStrategy.restoreStaticRoute;
    }

    if (currentServerStatus == 'in_progress' ||
        currentServerStatus == 'started') {
      return RestorationStrategy.restoreRealTimeTracking;
    }

    if (currentServerStatus == 'arrived') {
      return RestorationStrategy.restoreDriverArrived;
    }

    return RestorationStrategy.cancelSearchAndReset;
  }

  Future<RideRestorationResult> _executeRestoration(
    PersistedRideData persistedData,
    RestorationStrategy strategy,
    String currentStatus,
  ) async {
    try {
      dev.log('🚀 Executing restoration strategy: $strategy');

      switch (strategy) {
        case RestorationStrategy.cancelSearchAndReset:
          return await _cancelSearchAndReset(persistedData);

        case RestorationStrategy.restoreStaticRoute:
          return await _restoreStaticRouteState(persistedData);

        case RestorationStrategy.restoreRealTimeTracking:
          return await _restoreRealTimeTrackingState(persistedData);

        case RestorationStrategy.restoreDriverArrived:
          return await _restoreDriverArrivedState(persistedData);

        case RestorationStrategy.showFinalState:
          return await _restoreFinalState(persistedData, currentStatus);
      }
    } catch (e, stack) {
      dev.log('❌ Error executing restoration strategy: $e\n$stack');
      return RideRestorationResult.failed('Restoration execution failed: $e');
    }
  }

  Future<RideRestorationResult> _cancelSearchAndReset(
    PersistedRideData persistedData,
  ) async {
    dev.log('🛑 Cancelling search and resetting to initial state...');

    try {
      if (persistedData.rideId != null) {
        dev.log('📞 Cancelling ride ${persistedData.rideId} on server...');

        final cancelResult = await _rideRepository.cancelRide(
          persistedData.rideId!,
          'App restarted during search - timer accuracy lost',
        );

        cancelResult.fold(
          (failure) => dev.log('⚠️ Server cancel failed: ${failure.message}'),
          (success) =>
              dev.log('✅ Server cancel successful: ${success.message}'),
        );
      }

      await _persistenceService.clearAllPersistedData();

      return RideRestorationResult.success(
        RestoredRideState(
          rideState: const RideState(
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
            rideRequestModel: null,
          ),
          nextAction: RestorationAction.resetToInitialState,
          message: 'Search cancelled - please request a new ride',
        ),
      );
    } catch (e) {
      dev.log('❌ Error cancelling search: $e');

      await _persistenceService.clearAllPersistedData();

      return RideRestorationResult.success(
        RestoredRideState(
          rideState: const RideState(
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
            errorMessage: 'Previous search was cancelled due to app restart',
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
            rideRequestModel: null,
          ),
          nextAction: RestorationAction.resetToInitialState,
          message:
              'Search cancelled due to app restart - you can request a new ride',
        ),
      );
    }
  }

  Future<RideRestorationResult> _restoreStaticRouteState(
    PersistedRideData persistedData,
  ) async {
    dev.log('🗺️ Restoring static route state...');

    final restoredMarkers =
        await _persistenceService.loadPersistedMarkers() ?? {};
    final restoredPolylines =
        await _persistenceService.loadPersistedPolylines() ?? <Polyline>{};
    final routeData = await _persistenceService.loadRouteData();
    final convertedMarkers = await MarkerConverter.convertRestoredMarkers(
      restoredMarkers,
    );
    dev.log(
      '📍 Restored ${restoredMarkers.entries.map((e) => e.value.toJson())} markers and ${restoredPolylines.length} polylines',
    );

    return RideRestorationResult.success(
      RestoredRideState(
        rideState: RideState(
          status: RideRequestStatus.success,
          currentRideId: persistedData.rideId,
          rideResponse: persistedData.rideResponse,
          showRiderFound: true,
          riderAvailable: true,
          showStackedBottomSheet: false,
          routeDisplayed:
              restoredMarkers.isNotEmpty || restoredPolylines.isNotEmpty,
          currentDriverPosition: persistedData.currentDriverPosition,
          paymentMethod: persistedData.paymentMethod ?? 'cash',
          isMultiDestination: persistedData.isMultiDestination,
          rideRequestModel: persistedData.rideRequest,
          driverAccepted: persistedData.driverAccepted,
          driverStarted: persistedData.driverStarted,
          driverArrived: persistedData.driverArrived,
          driverCompleted: persistedData.driverCompleted,
          driverCancelled: persistedData.driverCancelled,
          driverRejected: persistedData.driverRejected,
          isSearching: false,
          searchTimeElapsed: 0,
          driverHasArrived: persistedData.driverHasArrived,
          rideInProgress: persistedData.rideInProgress,
          isRealTimeTrackingActive: false,
          trackingStatusMessage: 'Route and markers restored from cache',
          routeRecalculated: false,
          currentSpeed: persistedData.currentSpeed ?? 0.0,
          lastPositionUpdate: persistedData.lastPositionUpdate,
          routeProgress: persistedData.routeProgress,
          driverOffRoute: persistedData.driverOffRoute,
          driverAnimationComplete: persistedData.driverAnimationComplete,
          currentSegmentIndex: persistedData.currentSegmentIndex,
          estimatedDistance: persistedData.estimatedDistance,
          estimatedTimeArrival: persistedData.estimatedTimeArrival,
          nearestDriverDistance: persistedData.nearestDriverDistance,
          lastRouteRecalculation: persistedData.lastRouteRecalculation,
          cameraTarget: persistedData.cameraTarget,
          routePolylines: restoredPolylines,
          routeMarkers: restoredMarkers,
          routeSegments: persistedData.routeSegments,
        ),
        nextAction: RestorationAction.displayStaticRoute,
        message: 'Driver accepted. Route and markers restored...',
        routeData: routeData,
      ),
    );
  }

  Future<RideRestorationResult> _restoreRealTimeTrackingState(
    PersistedRideData persistedData,
  ) async {
    dev.log('🔴 Restoring real-time tracking state...');

    final lastLocation = await _persistenceService.loadLastDriverLocation();
    final trackingState = await _persistenceService.loadTrackingState();
    final routeData = await _persistenceService.loadRouteData();

    Set<Polyline> restoredPolylines = {};
    if (persistedData.polylines != null) {
      restoredPolylines = persistedData.polylines!;
    }

    Map<MarkerId, Marker> restoredMarkers = {};
    if (persistedData.markers != null) {
      restoredMarkers = persistedData.markers!;
    }

    return RideRestorationResult.success(
      RestoredRideState(
        rideState: RideState(
          status: RideRequestStatus.success,
          currentRideId: persistedData.rideId,
          rideResponse: persistedData.rideResponse,
          showRiderFound: true,
          riderAvailable: true,
          rideInProgress: true,
          isRealTimeTrackingActive: false,
          routeDisplayed: persistedData.routeDisplayed,
          currentDriverPosition:
              lastLocation?.latLng ?? persistedData.currentDriverPosition,
          lastPositionUpdate:
              lastLocation?.timestamp ?? persistedData.lastPositionUpdate,
          currentSpeed: lastLocation?.speed ?? persistedData.currentSpeed,
          paymentMethod: persistedData.paymentMethod ?? 'cash',
          isMultiDestination: persistedData.isMultiDestination,
          trackingStatusMessage: 'Reconnecting to live tracking...',
          rideRequestModel: persistedData.rideRequest,
          driverAccepted: persistedData.driverAccepted,
          driverStarted: persistedData.driverStarted,
          driverArrived: persistedData.driverArrived,
          driverCompleted: persistedData.driverCompleted,
          driverCancelled: persistedData.driverCancelled,
          driverRejected: persistedData.driverRejected,
          isSearching: false,
          searchTimeElapsed: 0,
          showStackedBottomSheet: false,
          driverHasArrived: persistedData.driverHasArrived,
          routeRecalculated: persistedData.routeRecalculated,
          routeProgress: persistedData.routeProgress,
          driverOffRoute: persistedData.driverOffRoute,
          driverAnimationComplete: persistedData.driverAnimationComplete,
          currentSegmentIndex: persistedData.currentSegmentIndex,
          estimatedDistance: persistedData.estimatedDistance,
          estimatedTimeArrival: persistedData.estimatedTimeArrival,
          nearestDriverDistance: persistedData.nearestDriverDistance,
          lastRouteRecalculation: persistedData.lastRouteRecalculation,
          cameraTarget: persistedData.cameraTarget,

          routePolylines: restoredPolylines,
          routeMarkers: restoredMarkers,
          routeSegments: persistedData.routeSegments,
        ),
        nextAction: RestorationAction.resumeRealTimeTracking,
        message: 'Reconnecting to live ride tracking...',
        lastKnownLocation: lastLocation,
        trackingState: trackingState,
        routeData: routeData,
      ),
    );
  }

  Future<RideRestorationResult> _restoreDriverArrivedState(
    PersistedRideData persistedData,
  ) async {
    dev.log('🚗 Restoring driver arrived state...');

    Set<Polyline> restoredPolylines = {};
    if (persistedData.polylines != null) {
      restoredPolylines = persistedData.polylines!;
    }

    Map<MarkerId, Marker> restoredMarkers = {};
    if (persistedData.markers != null) {
      restoredMarkers = persistedData.markers!;
    }

    return RideRestorationResult.success(
      RestoredRideState(
        rideState: RideState(
          status: RideRequestStatus.success,
          currentRideId: persistedData.rideId,
          rideResponse: persistedData.rideResponse,
          showRiderFound: true,
          riderAvailable: true,
          driverHasArrived: true,
          routeDisplayed: persistedData.routeDisplayed,
          currentDriverPosition: persistedData.currentDriverPosition,
          paymentMethod: persistedData.paymentMethod ?? 'cash',
          isMultiDestination: persistedData.isMultiDestination,
          rideRequestModel: persistedData.rideRequest,
          driverAccepted: persistedData.driverAccepted,
          driverStarted: persistedData.driverStarted,
          driverArrived: persistedData.driverArrived,
          driverCompleted: persistedData.driverCompleted,
          driverCancelled: persistedData.driverCancelled,
          driverRejected: persistedData.driverRejected,
          isSearching: false,
          searchTimeElapsed: 0,
          showStackedBottomSheet: false,
          rideInProgress: persistedData.rideInProgress,
          isRealTimeTrackingActive: false,
          trackingStatusMessage: 'Driver has arrived',
          routeRecalculated: false,
          currentSpeed: persistedData.currentSpeed ?? 0.0,
          lastPositionUpdate: persistedData.lastPositionUpdate,
          routeProgress: persistedData.routeProgress,
          driverOffRoute: persistedData.driverOffRoute,
          driverAnimationComplete: persistedData.driverAnimationComplete,
          currentSegmentIndex: persistedData.currentSegmentIndex,
          estimatedDistance: persistedData.estimatedDistance,
          estimatedTimeArrival: persistedData.estimatedTimeArrival,
          nearestDriverDistance: persistedData.nearestDriverDistance,
          lastRouteRecalculation: persistedData.lastRouteRecalculation,
          cameraTarget: persistedData.cameraTarget,

          routePolylines: restoredPolylines,
          routeMarkers: restoredMarkers,
          routeSegments: persistedData.routeSegments,
        ),
        nextAction: RestorationAction.showDriverArrived,
        message: 'Driver has arrived at pickup location',
      ),
    );
  }

  Future<RideRestorationResult> _restoreFinalState(
    PersistedRideData persistedData,
    String currentStatus,
  ) async {
    dev.log('🏁 Restoring final state: $currentStatus');

    final isCompleted = currentStatus == 'completed';

    return RideRestorationResult.success(
      RestoredRideState(
        rideState: RideState(
          status:
              isCompleted
                  ? RideRequestStatus.completed
                  : RideRequestStatus.cancelled,
          currentRideId: persistedData.rideId,
          rideResponse: persistedData.rideResponse,
          showStackedBottomSheet: true,
          showRiderFound: false,
          driverCompleted: isCompleted ? persistedData.driverCompleted : null,
          driverCancelled: !isCompleted ? persistedData.driverCancelled : null,
          paymentMethod: persistedData.paymentMethod ?? 'cash',
          isSearching: false,
          searchTimeElapsed: 0,
          riderAvailable: false,
          isMultiDestination: false,
          rideRequestModel: null,
          routeDisplayed: false,
          routePolylines: const {},
          routeMarkers: const {},
          routeSegments: null,
          currentDriverPosition: null,
          driverHasArrived: false,
          rideInProgress: false,
          isRealTimeTrackingActive: false,
          trackingStatusMessage:
              isCompleted ? 'Ride completed' : 'Ride cancelled',
          routeRecalculated: false,
          currentSpeed: 0.0,
        ),
        nextAction: RestorationAction.clearPersistedData,
        message:
            isCompleted ? 'Ride completed successfully' : 'Ride was cancelled',
      ),
    );
  }

  bool _isRideStatusInvalid(String status) {
    return [
      'cancelled',
      'completed',
      'expired',
      'failed',
    ].contains(status.toLowerCase());
  }

  bool _isRideFinished(String status) {
    return ['completed', 'cancelled'].contains(status.toLowerCase());
  }

  Future<void> executePostRestorationActions(
    RideCubit rideCubit,
    RestoredRideState restoredState,
  ) async {
    try {
      dev.log(
        '⚡ Executing post-restoration actions: ${restoredState.nextAction}',
      );

      switch (restoredState.nextAction) {
        case RestorationAction.resetToInitialState:
          rideCubit.emit(restoredState.rideState);
          await _persistenceService.clearAllPersistedData();
          break;

        case RestorationAction.displayStaticRoute:
          rideCubit.emit(restoredState.rideState);
          await _restoreStaticRoute(rideCubit, restoredState);
          break;

        case RestorationAction.resumeRealTimeTracking:
          rideCubit.emit(restoredState.rideState);
          await _restoreRealTimeTracking(rideCubit, restoredState);
          break;

        case RestorationAction.showDriverArrived:
          rideCubit.emit(restoredState.rideState);
          break;

        case RestorationAction.clearPersistedData:
          rideCubit.emit(restoredState.rideState);
          await _persistenceService.clearRideData();
          break;
      }

      await _reestablishSocketConnection(rideCubit);
    } catch (e, stack) {
      dev.log('❌ Error in post-restoration actions: $e\n$stack');
    }
  }

  Future<void> _restoreStaticRoute(
    RideCubit rideCubit,
    RestoredRideState restoredState,
  ) async {
    try {
      if (restoredState.routeData != null &&
          restoredState.routeData!.routePoints.isNotEmpty) {
        dev.log(
          '🗺️ Restoring route with ${restoredState.routeData!.routePoints.length} points',
        );

        await rideCubit.restoreStaticRoute();
        rideCubit.focusCameraOnRoute();
      } else {
        dev.log('🔄 Regenerating route from ride request');
        if (rideCubit.currentRideRequest != null) {
          await rideCubit.displayStaticRouteOnly();
        }
      }
    } catch (e) {
      dev.log('❌ Error restoring static route: $e');
    }
  }

  Future<void> _restoreRealTimeTracking(
    RideCubit rideCubit,
    RestoredRideState restoredState,
  ) async {
    try {
      dev.log('🔴 Restoring real-time tracking...');

      await _restoreStaticRoute(rideCubit, restoredState);

      await Future.delayed(const Duration(milliseconds: 1000));

      await rideCubit.restoreRealTimeTracking();

      if (restoredState.lastKnownLocation != null) {
        final location = restoredState.lastKnownLocation!;
        dev.log('📍 Updating to last known position: ${location.latLng}');

        rideCubit.handleRealTimePositionUpdate(
          location.latLng,
          location.bearing ?? 0.0,
          DriverLocationData(
            position: location.latLng,
            isMultiStop: false,
            isSignificantMovement: false,
            speed: location.speed ?? 0.0,
            accuracy: 10.0,
            lastUpdate: location.timestamp,
          ),
        );
      }

      dev.log('✅ Real-time tracking restoration completed');
    } catch (e) {
      dev.log('❌ Error restoring real-time tracking: $e');
    }
  }

  Future<void> _reestablishSocketConnection(RideCubit rideCubit) async {
    try {
      final socketService = getIt<SocketService>();

      if (!socketService.isConnected) {
        dev.log('🔌 Reconnecting to socket...');

        final authToken = await AppPreferences.getToken();
        socketService.connect('wss:', authToken: authToken);

        await Future.delayed(const Duration(seconds: 2));
      }

      rideCubit.listenToDriverStatus();

      dev.log('✅ Socket connection re-established');
    } catch (e) {
      dev.log('❌ Error re-establishing socket connection: $e');
    }
  }
}

enum RestorationStrategy {
  cancelSearchAndReset,
  restoreStaticRoute,
  restoreRealTimeTracking,
  restoreDriverArrived,
  showFinalState,
}

enum RestorationAction {
  resetToInitialState,
  displayStaticRoute,
  resumeRealTimeTracking,
  showDriverArrived,
  clearPersistedData,
}

class ServerValidationResult {
  final bool isValid;
  final String? reason;
  final String? currentStatus;
  final dynamic statusResponse;

  const ServerValidationResult._(
    this.isValid,
    this.reason,
    this.currentStatus,
    this.statusResponse,
  );

  factory ServerValidationResult.valid(String status, dynamic response) {
    return ServerValidationResult._(true, null, status, response);
  }

  factory ServerValidationResult.invalid(String reason) {
    return ServerValidationResult._(false, reason, null, null);
  }
}

class RideRestorationResult {
  final bool success;
  final String? error;
  final RestoredRideState? restoredState;

  const RideRestorationResult._(this.success, this.error, this.restoredState);

  factory RideRestorationResult.success(RestoredRideState state) {
    return RideRestorationResult._(true, null, state);
  }

  factory RideRestorationResult.failed(String error) {
    return RideRestorationResult._(false, error, null);
  }

  factory RideRestorationResult.noRideToRestore() {
    return const RideRestorationResult._(false, 'No ride to restore', null);
  }
}

class RestoredRideState {
  final RideState rideState;
  final RestorationAction nextAction;
  final String message;
  final PersistedLocation? lastKnownLocation;
  final PersistedTrackingState? trackingState;
  final PersistedRouteData? routeData;

  const RestoredRideState({
    required this.rideState,
    required this.nextAction,
    required this.message,
    this.lastKnownLocation,
    this.trackingState,
    this.routeData,
  });
}
