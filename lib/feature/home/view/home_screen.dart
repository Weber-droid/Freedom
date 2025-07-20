import 'dart:developer' as dev;
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:freedom/app_preference.dart';
import 'package:freedom/core/config/api_constants.dart';
import 'package:freedom/core/services/app_restoration_manager.dart';
import 'package:freedom/core/services/delivery_persistence_service.dart';
import 'package:freedom/core/services/life_cycle_manager.dart';
import 'package:freedom/core/services/map_services.dart';
import 'package:freedom/core/services/push_notification_service/push_nofication_service.dart';
import 'package:freedom/core/services/ride_persistence_service.dart';
import 'package:freedom/core/services/socket_service.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/auth/local_data_source/register_local_data_source.dart';
import 'package:freedom/feature/home/audio_call_cubit/call_cubit.dart';
import 'package:freedom/feature/home/cubit/home_cubit.dart';
import 'package:freedom/feature/home/delivery_cubit/delivery_cubit.dart';
import 'package:freedom/feature/home/ride_cubit/ride_cubit.dart';
import 'package:freedom/feature/home/view/widget/restoration_snack_bar.dart';
import 'package:freedom/feature/home/view/widget/show_rider_search.dart';
import 'package:freedom/feature/home/view/widgets.dart';
import 'package:freedom/feature/home/view/widget/rider_found_sheet.dart' as rfd;
import 'package:freedom/feature/home/widgets/custom_drawer.dart';
import 'package:freedom/feature/home/widgets/stacked_bottom_sheet_component.dart';
import 'package:freedom/feature/profile/cubit/profile_cubit.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';
import 'package:freedom/feature/wallet/cubit/wallet_cubit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:freedom/feature/home/view/widget/rider_search.dart' as dlv;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<StackedBottomSheetComponentState> _bottomSheetKey =
      GlobalKey<StackedBottomSheetComponentState>();

  String defaultValue = 'Now';
  List<String> dropdownItems = ['Now', 'Later'];

  bool isFirstSelected = false;
  bool isSecondSelected = false;
  int trackSelectedIndex = 0;
  late RideCubit rideCubit;
  GoogleMapController? _mapController;

  late RidePersistenceService _persistenceService;
  late RideRestorationManager _restorationManager;
  bool _isRestorationInProgress = false;
  bool _hasAttemptedRestoration = false;

  // Camera interaction tracking
  bool _isUserInteracting = false;
  Timer? _userInteractionTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<ProfileCubit>().getUserProfile();
    PushNotificationService.askPermissions();
    rideCubit = context.read<RideCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeServices();
    });
  }

  @override
  void dispose() {
    _userInteractionTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ... keeping all existing initialization methods unchanged ...
  Future<void> _initializeServices() async {
    try {
      dev.log('🚀 Initializing HomeScreen services...');
      _persistenceService = getIt<RidePersistenceService>();
      _restorationManager = getIt<RideRestorationManager>();
      await _connectToSocket();
      final user = await RegisterLocalDataSource().getUser();
      await context.read<CallCubit>().initialize(
        userId: user!.userId ?? '',
        userName: user.firstName ?? '',
      );

      await _checkPersistedStates();
      await _getPaymentMethods();

      dev.log('✅ HomeScreen services initialized successfully');
    } catch (e, stack) {
      dev.log('❌ Error initializing HomeScreen services: $e\n$stack');
      context.read<HomeCubit>().checkPermissionStatus();
    }
  }

  Future<void> _checkPersistedStates() async {
    if (_hasAttemptedRestoration) {
      dev.log('⚠️ Restoration already attempted, skipping...');
      return;
    }

    try {
      dev.log('🔄 Checking for persisted states...');
      _hasAttemptedRestoration = true;
      final hasPersistedRide = await _persistenceService.hasActiveRide();

      if (hasPersistedRide) {
        dev.log('📱 Found persisted ride data - attempting restoration...');
        await _attemptRideRestoration();
      } else {
        dev.log('📭 No persisted ride found');
        await _checkPersistedDeliveryStates();
        context.read<HomeCubit>().checkPermissionStatus();
      }
    } catch (e) {
      dev.log('❌ Error checking persisted states: $e');
      context.read<HomeCubit>().checkPermissionStatus();
    }
  }

  Future<void> _checkPersistedDeliveryStates() async {
    try {
      dev.log('🔄 Checking for persisted delivery states...');

      final deliveryCubit = context.read<DeliveryCubit>();
      final persistenceService =
          getIt.isRegistered<DeliveryPersistenceService>()
              ? getIt<DeliveryPersistenceService>()
              : DeliveryPersistenceService(deliveryCubit.deliveryRepository);

      final hasPersistedDelivery =
          await persistenceService.hasPersistedDeliveryState();

      if (hasPersistedDelivery) {
        dev.log('✅ Found persisted delivery state - will be restored by cubit');
      } else {
        dev.log('📭 No persisted delivery state found');
      }
    } catch (e) {
      dev.log('❌ Error checking persisted delivery states: $e');
    }
  }

  Future<void> _attemptRideRestoration() async {
    if (_isRestorationInProgress) return;

    try {
      setState(() {
        _isRestorationInProgress = true;
      });

      dev.log('🔄 Starting ride restoration process...');

      // Show restoration indicator to user
      showRestorationSnackBar(context, 'Restoring your ride...');

      final restorationResult =
          await _restorationManager.attemptRideRestoration();

      if (restorationResult.success &&
          restorationResult.restoredState != null) {
        dev.log('✅ Ride restoration successful');

        // Execute post-restoration actions
        await _restorationManager.executePostRestorationActions(
          rideCubit,
          restorationResult.restoredState!,
        );

        showRestorationSnackBar(
          context,
          restorationResult.restoredState!.message,
          isSuccess: true,
        );
      } else {
        dev.log('❌ Ride restoration failed: ${restorationResult.error}');
        showRestorationSnackBar(
          context,
          'Unable to restore previous ride',
          isError: true,
        );

        // Fall back to normal flow
        context.read<HomeCubit>().checkPermissionStatus();
      }
    } catch (e, stack) {
      dev.log('❌ Critical error during ride restoration: $e\n$stack');
      showRestorationSnackBar(
        context,
        'Restoration failed - starting fresh',
        isError: true,
      );
      context.read<HomeCubit>().checkPermissionStatus();
    } finally {
      setState(() {
        _isRestorationInProgress = false;
      });
    }
  }

  Future<void> _getPaymentMethods() async {
    await context.read<WalletCubit>().loadWallet();
  }

  Future<void> _connectToSocket() async {
    dev.log('🔌 Connecting to socket...');
    getIt<SocketService>().connect(
      'https://api-freedom.com',
      authToken: await AppPreferences.getToken(),
    );

    await Future.delayed(const Duration(seconds: 2));

    final socketService = getIt<SocketService>();
    dev.log('🔌 Socket connected: ${socketService.isConnected}');
  }

  // ============================================================================
  // CAMERA INTERACTION HANDLERS
  // ============================================================================

  // void _onCameraMoveStarted() {
  //   dev.log('🎥 User started moving camera manually');
  //   _isUserInteracting = true;
  //   _userInteractionTimer?.cancel();

  //   // Notify cubit about manual camera movement
  //   rideCubit.handleManualCameraMove();
  // }

  void _onCameraMove(CameraPosition position) {
    if (_isUserInteracting) {
      dev.log('🎥 User moving camera to: ${position.target}');
    }
  }

  void _onCameraIdle() {
    dev.log('🎥 Camera stopped moving');
    if (_isUserInteracting) {
      // Set timer to re-enable auto-following after user stops interacting
      _userInteractionTimer?.cancel();
      _userInteractionTimer = Timer(const Duration(seconds: 5), () {
        _isUserInteracting = false;
        // Optionally re-enable auto-following
        if (rideCubit.state.isRealTimeTrackingActive &&
            !rideCubit.state.followDriverCamera) {
          dev.log('🎥 Re-enabling camera following after user interaction');
          rideCubit.enableDriverCameraFollow();
        }
      });
    }
  }

  // ============================================================================
  // ENHANCED CAMERA ANIMATION METHODS
  // ============================================================================

  Future<void> _handleCameraUpdates(RideState state) async {
    if (_mapController == null || !state.shouldUpdateCamera) return;

    try {
      dev.log('🎥 Handling camera update - Mode: ${state.cameraFollowingMode}');

      switch (state.cameraFollowingMode) {
        case CameraFollowingMode.followDriver:
          if (state.cameraTarget != null) {
            await _animateToPosition(
              state.cameraTarget!,
              zoom: 17.0,
              bearing: _calculateDriverBearing(state),
            );
          }
          break;

        case CameraFollowingMode.followWithRoute:
          if (state.cameraTarget != null && state.routePolylines.isNotEmpty) {
            await _animateToShowDriverAndRoute(state);
          }
          break;

        case CameraFollowingMode.showRoute:
          if (state.routePolylines.isNotEmpty) {
            await _animateToShowFullRoute(state);
          }
          break;

        case CameraFollowingMode.none:
          // No automatic camera updates
          break;

        default:
          dev.log(
            '🎥 Unknown camera following mode: ${state.cameraFollowingMode}',
          );
          break;
      }
    } catch (e) {
      dev.log('🎥 ❌ Camera animation error: $e');
    }
  }

  double _calculateDriverBearing(RideState state) {
    // You can implement bearing calculation based on driver movement
    // For now, return 0 (north-facing)
    return 0.0;
  }

  Future<void> _animateToPosition(
    LatLng target, {
    double zoom = 16.0,
    double bearing = 0.0,
    Duration duration = const Duration(milliseconds: 1000),
  }) async {
    if (_mapController == null) {
      dev.log('🎥 Cannot animate: no map controller');
      return;
    }

    try {
      dev.log(
        '🎥 Animating to position: $target (zoom: $zoom, bearing: $bearing)',
      );

      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: target,
            zoom: zoom,
            bearing: bearing,
            tilt: 0.0,
          ),
        ),
      );

      dev.log('🎥 ✅ Position animation completed');
    } catch (e) {
      dev.log('🎥 ❌ Error animating to position: $e');
    }
  }

  Future<void> _animateToShowDriverAndRoute(RideState state) async {
    if (_mapController == null ||
        state.currentDriverPosition == null ||
        state.routePolylines.isEmpty)
      return;

    try {
      final routePoints = state.routePolylines.first.points;
      final allPoints = [state.currentDriverPosition!, ...routePoints];

      final bounds = _calculateBounds(allPoints);

      dev.log('🎥 Animating to show driver and route');
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );

      dev.log('🎥 ✅ Driver and route animation completed');
    } catch (e) {
      dev.log('🎥 ❌ Error animating to show driver and route: $e');
    }
  }

  Future<void> _animateToShowFullRoute(RideState state) async {
    if (_mapController == null || state.routePolylines.isEmpty) return;

    try {
      final routePoints = state.routePolylines.first.points;
      final bounds = _calculateBounds(routePoints);

      dev.log('🎥 Animating to show full route');
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );

      dev.log('🎥 ✅ Full route animation completed');
    } catch (e) {
      dev.log('🎥 ❌ Error animating to show full route: $e');
    }
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(0, 0),
        northeast: const LatLng(0, 0),
      );
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    // Add some padding to the bounds
    const padding = 0.001; // Adjust as needed
    return LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const CustomDrawer(),
      body: BlocListener<RideCubit, RideState>(
        listenWhen: (previous, current) {
          return previous.status != current.status &&
              current.status == RideRequestStatus.noDriverFound;
        },
        listener: (context, state) {
          context.showToast(
            message: 'No drivers found. Please try again.',
            position: ToastPosition.top,
          );

          Future.delayed(const Duration(seconds: 3), () {
            context.read<HomeCubit>().resetDestinations();
            _bottomSheetKey.currentState?.clearDestinationControllers();
          });
        },
        child: BlocConsumer<HomeCubit, HomeState>(
          listener: (context, state) {
            final mapServices = getIt<MapService>();
            if (state.serviceStatus == LocationServiceStatus.located &&
                state.currentLocation != null) {
              mapServices.controller?.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(target: state.currentLocation!, zoom: 15.5),
                ),
              );
            }
          },
          builder: (context, state) {
            return BlocConsumer<RideCubit, RideState>(
              listenWhen: (previous, current) {
                // Enhanced listener conditions for camera following
                final cameraUpdateNeeded =
                    previous.shouldUpdateCamera != current.shouldUpdateCamera &&
                    current.shouldUpdateCamera;
                final cameraTargetChanged =
                    previous.cameraTarget != current.cameraTarget &&
                    current.cameraTarget != null;
                final cameraFollowingChanged =
                    previous.followDriverCamera != current.followDriverCamera ||
                    previous.cameraFollowingMode != current.cameraFollowingMode;
                final routeRecalculated =
                    previous.routeRecalculated != current.routeRecalculated &&
                    current.routeRecalculated;
                final statusMessageChanged =
                    previous.trackingStatusMessage !=
                        current.trackingStatusMessage &&
                    current.trackingStatusMessage != null;
                final trackingStateChanged =
                    previous.isRealTimeTrackingActive !=
                    current.isRealTimeTrackingActive;
                final driverPositionChanged =
                    previous.currentDriverPosition !=
                    current.currentDriverPosition;
                final rideProgressChanged =
                    previous.rideInProgress != current.rideInProgress;
                final markersChanged =
                    previous.routeMarkers != current.routeMarkers;
                final routeDisplayedChanged =
                    previous.routeDisplayed != current.routeDisplayed;

                final shouldListen =
                    routeDisplayedChanged ||
                    cameraUpdateNeeded ||
                    cameraTargetChanged ||
                    cameraFollowingChanged ||
                    routeRecalculated ||
                    statusMessageChanged ||
                    trackingStateChanged ||
                    driverPositionChanged ||
                    rideProgressChanged ||
                    markersChanged;

                if (shouldListen) {
                  dev.log(
                    '🎯 RideCubit listener triggered - Camera following enabled: ${current.followDriverCamera}',
                  );
                }

                return shouldListen;
              },
              listener: (context, rideState) async {
                // Handle camera updates with new system
                if (rideState.shouldUpdateCamera) {
                  await _handleCameraUpdates(rideState);
                } else if (rideState.routeDisplayed &&
                    rideState.routePolylines.isNotEmpty &&
                    !rideState.followDriverCamera) {
                  // Only show route if not following driver
                  _animateToShowRoute(rideState.routePolylines.first.points);
                }

                // Show status messages
                if (rideState.trackingStatusMessage != null) {
                  dev.log(
                    '📱 Tracking status: ${rideState.trackingStatusMessage}',
                  );
                }
              },
              builder: (context, rideState) {
                return BlocConsumer<DeliveryCubit, DeliveryState>(
                  listenWhen: (previous, current) {
                    final markerUpdated =
                        previous.deliveryRouteMarkers.length !=
                            current.deliveryRouteMarkers.length ||
                        (current.deliveryRouteMarkers.isNotEmpty &&
                            previous.currentDeliveryDriverPosition !=
                                current.currentDeliveryDriverPosition);
                    final routeDisplayedChanged =
                        previous.deliveryRouteDisplayed !=
                        current.deliveryRouteDisplayed;
                    final cameraUpdateNeeded =
                        previous.shouldUpdateCamera !=
                            current.shouldUpdateCamera &&
                        current.shouldUpdateCamera;
                    final trackingStatusChanged =
                        previous.isRealTimeDeliveryTrackingActive !=
                        current.isRealTimeDeliveryTrackingActive;
                    final statusMessageChanged =
                        previous.deliveryTrackingStatusMessage !=
                            current.deliveryTrackingStatusMessage &&
                        current.deliveryTrackingStatusMessage != null;
                    final routeRecalculated =
                        previous.deliveryRouteRecalculated !=
                            current.deliveryRouteRecalculated &&
                        current.deliveryRouteRecalculated;

                    final streetZoomChanged =
                        previous.streetLevelZoom != current.streetLevelZoom &&
                        current.streetLevelZoom != null;

                    final cameraTargetChanged =
                        previous.cameraTarget != current.cameraTarget &&
                        current.cameraTarget != null;
                    final shouldListen =
                        markerUpdated ||
                        routeDisplayedChanged ||
                        cameraUpdateNeeded ||
                        streetZoomChanged ||
                        cameraTargetChanged ||
                        trackingStatusChanged ||
                        statusMessageChanged ||
                        routeRecalculated;

                    if (shouldListen) {
                      dev.log('🎯 DeliveryCubit listener triggered');
                    }

                    return shouldListen;
                  },
                  listener: (context, deliveryState) {
                    dev.log('🎥 Enhanced DeliveryCubit listener triggered');

                    // Handle delivery route display
                    if (deliveryState.deliveryRouteDisplayed &&
                        deliveryState.deliveryRoutePolylines.isNotEmpty) {
                      dev.log(
                        '🔍 Street zoom: ${deliveryState.streetLevelZoom}',
                      );
                      _animateToShowRoute(
                        deliveryState.deliveryRoutePolylines.first.points,
                      );
                    } else if (deliveryState.shouldUpdateCamera &&
                        deliveryState.cameraTarget != null &&
                        deliveryState.streetLevelZoom != null) {
                      dev.log(
                        '🔍 Street zoom: ${deliveryState.streetLevelZoom}',
                      );
                      _animateToTargetWithZoom(
                        deliveryState.cameraTarget!,
                        deliveryState.streetLevelZoom!,
                      );
                      dev.log(
                        '🔍 Animating to street zoom: ${deliveryState.streetLevelZoom}',
                      );
                    } else if (deliveryState.shouldUpdateCamera &&
                        deliveryState.cameraTarget != null) {
                      _animateToTarget(deliveryState.cameraTarget!);
                    }
                  },
                  builder: (context, deliveryState) {
                    final sheetVisibility = _calculateSheetVisibility(
                      rideState,
                      deliveryState,
                    );

                    return Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition:
                              HomeState.initialCameraPosition,
                          myLocationEnabled:
                              state.serviceStatus ==
                              LocationServiceStatus.located,
                          compassEnabled: false,
                          mapToolbarEnabled: false,
                          markers: _getCombinedMarkers(
                            state,
                            rideState,
                            deliveryState,
                          ),
                          polylines: _getCombinedPolylines(
                            state,
                            rideState,
                            deliveryState,
                          ),
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                            final registered =
                                getIt.isRegistered<GoogleMapController>();
                            if (!registered) {
                              getIt.registerSingleton<GoogleMapController>(
                                controller,
                              );
                              getIt<MapService>().setController(controller);
                            }
                          },
                          onCameraMove: _onCameraMove,
                          onCameraIdle: _onCameraIdle,
                        ),

                        UserFloatingAccessBar(
                          scaffoldKey: _scaffoldKey,
                          state: state,
                        ),

                        // Main stacked bottom sheet (for initial ride/delivery search)
                        Visibility(
                          visible: sheetVisibility.showStackedBottomSheet,
                          child: StackedBottomSheetComponent(
                            key: _bottomSheetKey,
                            onFindRider: () => _handleFindRiderPressed(state),
                            onServiceSelected: (int index) {},
                          ),
                        ),

                        // Ride found bottom sheet
                        Visibility(
                          visible: sheetVisibility.showRideFound,
                          child: Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildEnhancedRiderFoundSheet(
                                  rideState,
                                  isDelivery: false,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Delivery found bottom sheet
                        Visibility(
                          visible: sheetVisibility.showDeliveryFound,
                          child: Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: rfd.RiderFoundBottomSheet<
                              DeliveryCubit,
                              DeliveryState
                            >(
                              isMultiDestinationSelector:
                                  (state) => state.isMultipleDestination,
                              stateBuilder:
                                  (context, state, isMultiStop) =>
                                      _buildDeliveryStateContent(
                                        context,
                                        state,
                                        isMultiStop,
                                      ),
                              onCancelPressed: () => _handleCancelDelivery(),
                              timerText:
                                  'The delivery driver will arrive in ....',
                              cancelButtonText: 'Cancel Delivery',
                            ),
                          ),
                        ),

                        // Ride search sheet
                        Visibility(
                          visible: sheetVisibility.showRideSearch,
                          child: const Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: ShowRiderSearch(),
                          ),
                        ),

                        // Delivery search sheet
                        Visibility(
                          visible: sheetVisibility.showDeliverySearch,
                          child: Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: dlv.ShowRiderSearch<
                              DeliveryCubit,
                              DeliveryState
                            >(
                              searchTimeElapsedSelector:
                                  (state) => state.searchTimeElapsed,
                              statusSelector: (state) => state.status,
                              rideDataSelector: (state) => state.deliveryData,
                              cancellationStatusSelector: (state) => {},
                              messageSelector: (state) => state.errorMessage,
                              onCancelPressed: () => _handleCancelDelivery(),
                              searchTimeDisplayText:
                                  'Searching for delivery driver in about',
                              cancelButtonText: 'Cancel Delivery',
                              estimatedDistanceLabel: 'Delivery Distance',
                              estimatedTimeLabel: 'Delivery Time',
                              fareLabel: 'Delivery Cost',
                            ),
                          ),
                        ),

                        // Enhanced camera control buttons
                        if (rideState.isRealTimeTrackingActive ||
                            deliveryState.isRealTimeDeliveryTrackingActive)
                          _buildEnhancedCameraControls(
                            rideState,
                            deliveryState,
                          ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ============================================================================
  // ENHANCED CAMERA CONTROL BUTTONS
  // ============================================================================

  Widget _buildEnhancedCameraControls(
    RideState rideState,
    DeliveryState deliveryState,
  ) {
    final hasActiveRideTracking =
        rideState.isRealTimeTrackingActive &&
        rideState.currentDriverPosition != null;
    final hasActiveDeliveryTracking =
        deliveryState.isRealTimeDeliveryTrackingActive &&
        deliveryState.currentDeliveryDriverPosition != null;

    if (!hasActiveRideTracking && !hasActiveDeliveryTracking) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: 16,
      top: 100,
      child: Column(
        children: [
          // Follow driver button (GPS tracking)
          if (hasActiveRideTracking) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color:
                    rideState.followDriverCamera ? Colors.blue : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  rideCubit.toggleCameraFollowingMode();
                },
                icon: Icon(
                  rideState.followDriverCamera
                      ? Icons.gps_fixed
                      : Icons.gps_not_fixed,
                  color:
                      rideState.followDriverCamera
                          ? Colors.white
                          : Colors.grey[600],
                ),
                tooltip:
                    rideState.followDriverCamera
                        ? 'Stop following driver'
                        : 'Follow driver',
              ),
            ),

            // Show full route button
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  rideCubit.focusCameraOnRoute();
                },
                icon: Icon(Icons.route, color: Colors.grey[600]),
                tooltip: 'Show full route',
              ),
            ),

            // Center on driver button
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  rideCubit.centerCameraOnDriver();
                },
                icon: Icon(Icons.directions_car, color: Colors.grey[600]),
                tooltip: 'Center on driver',
              ),
            ),
          ],

          // Delivery driver controls
          if (hasActiveDeliveryTracking) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  context.read<DeliveryCubit>().centerCameraOnDeliveryDriver();
                },
                icon: Icon(Icons.delivery_dining, color: Colors.grey[600]),
                tooltip: 'Center on delivery driver',
              ),
            ),
          ],

          // Debug controls (only in debug mode)
          if (kDebugMode && hasActiveRideTracking) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  rideCubit.forceRouteRecalculation();
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Force route recalculation',
              ),
            ),

            // Show tracking metrics
            Container(
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  _showTrackingMetrics(context, rideState);
                },
                icon: const Icon(Icons.analytics, color: Colors.white),
                tooltip: 'Show tracking metrics',
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================================
  // DEBUG METHODS
  // ============================================================================

  void _showTrackingMetrics(BuildContext context, RideState rideState) {
    final metrics = rideCubit.getEnhancedTrackingMetrics();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tracking Metrics'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Following Driver: ${rideState.followDriverCamera}'),
                  Text('Camera Mode: ${rideState.cameraFollowingMode}'),
                  Text(
                    'Real-time Tracking: ${rideState.isRealTimeTrackingActive}',
                  ),
                  Text('Driver Position: ${rideState.currentDriverPosition}'),
                  Text(
                    'Current Speed: ${rideState.currentSpeed?.toStringAsFixed(1) ?? 'N/A'} km/h',
                  ),
                  const Divider(),
                  Text('Tracking Status: ${metrics['statusSummary']}'),
                  Text(
                    'Updates Regular: ${metrics['isReceivingRegularUpdates']}',
                  ),
                  Text(
                    'Average Accuracy: ${metrics['averageAccuracy']?.toStringAsFixed(1) ?? 'N/A'}m',
                  ),
                  Text('History Points: ${metrics['locationHistoryCount']}'),
                  Text('Route Points: ${metrics['routePointsCount']}'),
                  if (metrics['distanceToDestination'] != null)
                    Text(
                      'Distance to Destination: ${metrics['formattedDistanceToDestination']}',
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  // ============================================================================
  // EXISTING METHODS (keeping unchanged)
  // ============================================================================

  // FIXED: Simplified sheet visibility calculation
  _BottomSheetVisibility _calculateSheetVisibility(
    RideState rideState,
    DeliveryState deliveryState,
  ) {
    // Check if any driver/delivery person has been found
    final rideFound = rideState.riderAvailable;
    final deliveryFound = deliveryState.riderFound;

    // Check if currently searching
    final rideSearching =
        rideState.status == RideRequestStatus.loading ||
        rideState.status == RideRequestStatus.searching;
    final deliverySearching = deliveryState.showDeliverySearchSheet;

    // If any driver/delivery person is found, show only the relevant found sheet
    if (rideFound) {
      return _BottomSheetVisibility(
        showStackedBottomSheet: false,
        showRideFound: true,
        showDeliveryFound: false,
        showRideSearch: false,
        showDeliverySearch: false,
      );
    }

    if (deliveryFound) {
      return _BottomSheetVisibility(
        showStackedBottomSheet: false,
        showRideFound: false,
        showDeliveryFound: true,
        showRideSearch: false,
        showDeliverySearch: false,
      );
    }

    // If searching, show only the relevant search sheet
    if (deliverySearching) {
      return _BottomSheetVisibility(
        showStackedBottomSheet: false,
        showRideFound: false,
        showDeliveryFound: false,
        showRideSearch: false,
        showDeliverySearch: true,
      );
    }

    if (rideSearching) {
      return _BottomSheetVisibility(
        showStackedBottomSheet: false,
        showRideFound: false,
        showDeliveryFound: false,
        showRideSearch: true,
        showDeliverySearch: false,
      );
    }

    // Default state: show main stacked bottom sheet
    return _BottomSheetVisibility(
      showStackedBottomSheet: true,
      showRideFound: false,
      showDeliveryFound: false,
      showRideSearch: false,
      showDeliverySearch: false,
    );
  }

  Widget _buildDeliveryStateContent(
    BuildContext context,
    DeliveryState state,
    bool isMultiStop,
  ) {
    // Build content specific to delivery state
    final deliveryData = state.deliveryData;
    if (deliveryData == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Delivery information header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.delivery_dining,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Delivery Service',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${deliveryData.currency} ${deliveryData.fare.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDeliveryInfoItem(
                      'Distance',
                      deliveryData.estimatedDistance.text,
                      Icons.straighten,
                    ),
                  ),
                  Expanded(
                    child: _buildDeliveryInfoItem(
                      'Duration',
                      deliveryData.estimatedDuration.text,
                      Icons.access_time,
                    ),
                  ),
                  if (deliveryData.isMultiStop)
                    Expanded(
                      child: _buildDeliveryInfoItem(
                        'Stops',
                        '${deliveryData.numberOfStops}',
                        Icons.flag,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Route information
        Text(
          'Delivery Route',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        _buildLocationRow(
          icon: Icons.location_on,
          iconColor: Colors.green,
          label: 'Pickup Location',
          address: state.deliveryModel?.pickupLocation ?? 'Pickup location',
        ),

        const SizedBox(height: 8),

        // Destination location(s)
        if (deliveryData.isMultiStop &&
            state.deliveryControllers.length > 1) ...[
          for (int i = 1; i < state.deliveryControllers.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildLocationRow(
                icon: Icons.flag,
                iconColor: Colors.orange,
                label: 'Stop $i',
                address:
                    state.deliveryControllers[i].text.isNotEmpty
                        ? state.deliveryControllers[i].text
                        : 'Destination $i',
              ),
            ),
        ] else ...[
          _buildLocationRow(
            icon: Icons.flag,
            iconColor: Colors.red,
            label: 'Delivery Destination',
            address:
                state.deliveryModel?.destinationLocation ?? 'Delivery location',
          ),
        ],

        const SizedBox(height: 12),

        // Payment method
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(
                deliveryData.paymentMethod.toLowerCase() == 'cash'
                    ? Icons.money
                    : Icons.credit_card,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                'Payment: ${deliveryData.paymentMethod}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String address,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              Text(
                address,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleCancelDelivery() {
    context.read<DeliveryCubit>().cancelDelivery(reason: 'User cancelled');
  }

  Widget _buildEnhancedRiderFoundSheet(
    RideState rideState, {
    required bool isDelivery,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RiderFoundBottomSheet(),
          if (rideState.rideInProgress && rideState.isRealTimeTrackingActive)
            _buildRealTimeTrackingSection(rideState),
        ],
      ),
    );
  }

  Widget _buildRealTimeTrackingSection(RideState rideState) {
    final progress = rideCubit.getCurrentRouteProgress();
    final trackingStatus = rideCubit.getTrackingStatus();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                trackingStatus.isReceivingRegularUpdates
                    ? Icons.navigation
                    : Icons.signal_wifi_connected_no_internet_4,
                color:
                    trackingStatus.isReceivingRegularUpdates
                        ? Colors.blue
                        : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                trackingStatus.isReceivingRegularUpdates
                    ? 'Trip Progress'
                    : 'Connection Issues',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      trackingStatus.isReceivingRegularUpdates
                          ? Colors.blue
                          : Colors.orange,
                ),
              ),
              const Spacer(),
              if (rideState.currentSpeed != null && rideState.currentSpeed! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getSpeedColor(rideState.currentSpeed!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${rideState.currentSpeed?.toStringAsFixed(0)} km/h',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),

          if (progress != null && trackingStatus.isReceivingRegularUpdates) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Distance Remaining',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        progress.formattedRemainingDistance,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'ETA',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        progress.formattedETA,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else if (!trackingStatus.isReceivingRegularUpdates) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Having trouble connecting to driver. Trying to reconnect...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getSpeedColor(double speed) {
    if (speed > 50) {
      return Colors.green.shade600;
    } else if (speed > 20) {
      return Colors.blue.shade600;
    } else if (speed > 5) {
      return Colors.orange.shade600;
    } else {
      return Colors.grey.shade600;
    }
  }

  Set<Marker> _getCombinedMarkers(
    HomeState homeState,
    RideState rideState,
    DeliveryState deliveryState,
  ) {
    final markers = <Marker>{};
    if (deliveryState.deliveryRouteDisplayed &&
        deliveryState.deliveryRouteMarkers.isNotEmpty) {
      markers.addAll(deliveryState.deliveryRouteMarkers.values);
    } else if (rideState.routeDisplayed && rideState.routeMarkers.isNotEmpty) {
      markers.addAll(rideState.routeMarkers.values);
    } else if (homeState.markers.isNotEmpty) {
      markers.addAll(homeState.markers.values);
    }
    return markers;
  }

  Set<Polyline> _getCombinedPolylines(
    HomeState homeState,
    RideState rideState,
    DeliveryState deliveryState,
  ) {
    final polylines = <Polyline>{};
    if (deliveryState.deliveryRouteDisplayed &&
        deliveryState.deliveryRoutePolylines.isNotEmpty) {
      polylines.addAll(deliveryState.deliveryRoutePolylines);
    } else if (rideState.routeDisplayed &&
        rideState.routePolylines.isNotEmpty) {
      polylines.addAll(rideState.routePolylines);
    } else {
      polylines.addAll(homeState.polylines);
    }
    return polylines;
  }

  void _animateToShowRoute(List<LatLng> points) async {
    final controller = _mapController ?? getIt<MapService>().controller;
    if (controller == null || points.isEmpty) {
      dev.log(
        '🎥 Cannot animate: controller=$controller, points=${points.length}',
      );
      return;
    }

    try {
      double minLat = points.first.latitude;
      double maxLat = points.first.latitude;
      double minLng = points.first.longitude;
      double maxLng = points.first.longitude;

      for (final point in points) {
        minLat = math.min(minLat, point.latitude);
        maxLat = math.max(maxLat, point.latitude);
        minLng = math.min(minLng, point.longitude);
        maxLng = math.max(maxLng, point.longitude);
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
      dev.log('🎥 ✅ Route bounds animation completed');
    } catch (e) {
      dev.log('🎥 ❌ Error animating to show route: $e');
    }
  }

  void _animateToTarget(LatLng target) async {
    final controller = _mapController ?? getIt<MapService>().controller;
    if (controller == null) {
      dev.log('🎥 Cannot animate to target: no controller');
      return;
    }

    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 30.0),
        ),
      );
      dev.log('🎥 ✅ Camera animation to target completed');
    } catch (e) {
      dev.log('🎥 ❌ Error animating to target: $e');
    }
  }

  void _animateToTargetWithZoom(LatLng target, double zoomLevel) async {
    final controller = _mapController ?? getIt<MapService>().controller;
    if (controller == null) {
      dev.log('🎥 Cannot animate to target with zoom: no controller');
      return;
    }

    try {
      dev.log('🔍 Animating to street zoom: $zoomLevel at $target');

      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: target,
            zoom: zoomLevel,
            tilt: 0.0,
            bearing: 0.0,
          ),
        ),
      );

      dev.log('🎥 ✅ Street zoom animation completed');
    } catch (e) {
      dev.log('🎥 ❌ Error animating to target with zoom: $e');
    }
  }

  Future<void> _handleFindRiderPressed(HomeState state) async {
    if (state.pickUpLocation == null) {
      context.showToast(
        message: 'Please select a pickup location',
        position: ToastPosition.top,
      );
      return;
    }

    if (state.destinationLocation == null) {
      context.showToast(
        message: 'Please select a destination',
        position: ToastPosition.top,
      );
      return;
    }

    final additionalDestinations =
        state.destinationLocations
            .where(
              (loc) =>
                  loc.latitude != 0 &&
                  loc.longitude != 0 &&
                  (loc.latitude != state.destinationLocation!.latitude ||
                      loc.longitude != state.destinationLocation!.longitude),
            )
            .toList();

    final rideRequest = rideCubit.createRideRequestFromHomeState(
      pickupLocation: state.pickUpLocation!,
      mainDestination: state.destinationLocation!,
      additionalDestinations: [],
      paymentMethod: rideCubit.state.paymentMethod ?? 'cash',
    );

    try {
      await rideCubit.requestRide(rideRequest);

      final service = getIt<SocketService>();
      if (!service.isConnected) {
        dev.log('🔌 Socket not connected, reconnecting...');
        service.connect(
          ApiConstants.baseUrl2,
          authToken: await AppPreferences.getToken(),
        );
      }
    } catch (e) {
      dev.log('Error requesting ride: $e');
      if (mounted) {
        context.showToast(
          message: 'Failed to request ride: ${e.toString()}',
          position: ToastPosition.top,
        );
      }
    }
  }
}

class _BottomSheetVisibility {
  final bool showStackedBottomSheet;
  final bool showRideFound;
  final bool showDeliveryFound;
  final bool showRideSearch;
  final bool showDeliverySearch;

  const _BottomSheetVisibility({
    required this.showStackedBottomSheet,
    required this.showRideFound,
    required this.showDeliveryFound,
    required this.showRideSearch,
    required this.showDeliverySearch,
  });

  @override
  String toString() {
    return '_BottomSheetVisibility('
        'stackedSheet: $showStackedBottomSheet, '
        'rideFound: $showRideFound, '
        'deliveryFound: $showDeliveryFound, '
        'rideSearch: $showRideSearch, '
        'deliverySearch: $showDeliverySearch'
        ')';
  }
}
