import 'dart:developer' as dev;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:freedom/app_preference.dart';
import 'package:freedom/core/config/api_constants.dart';
import 'package:freedom/core/services/map_services.dart';
import 'package:freedom/core/services/push_notification_service/push_nofication_service.dart';
import 'package:freedom/core/services/socket_service.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/auth/local_data_source/register_local_data_source.dart';
import 'package:freedom/feature/home/audio_call_cubit/call_cubit.dart';
import 'package:freedom/feature/home/cubit/home_cubit.dart';
import 'package:freedom/feature/home/delivery_cubit/delivery_cubit.dart';
import 'package:freedom/feature/home/ride_cubit/ride_cubit.dart';
import 'package:freedom/feature/home/view/widget/show_rider_search.dart';
import 'package:freedom/feature/home/view/widgets.dart';
import 'package:freedom/feature/home/widgets/custom_drawer.dart';
import 'package:freedom/feature/home/widgets/stacked_bottom_sheet_component.dart';
import 'package:freedom/feature/profile/cubit/profile_cubit.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:freedom/feature/home/view/widget/rider_search.dart' as dlv;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().checkPermissionStatus();
    context.read<ProfileCubit>().getUserProfile();
    PushNotificationService.askPermissions();
    rideCubit = context.read<RideCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _connectToSocket();

      final user = await RegisterLocalDataSource().getUser();
      dev.log('user: ${await AppPreferences.getToken()}');

      await context.read<CallCubit>().initialize(
        userId: user!.userId ?? '',
        userName: user.firstName ?? '',
      );
      _checkRideStatus();
    });
  }

  Future<void> _checkRideStatus() async {
    final id = await AppPreferences.getRideId();
    dev.log('🔍 Checking ride status for ID: $id');
    context.read<RideCubit>().checkRideStatus(id);
  }

  Future<void> _connectToSocket() async {
    dev.log('🔌 Connecting to socket...');
    getIt<SocketService>().connect(
      'https://api-freedom.com',
      authToken: await AppPreferences.getToken(),
    );

    // Add a delay to ensure connection is established
    await Future.delayed(const Duration(seconds: 2));

    final socketService = getIt<SocketService>();
    dev.log('🔌 Socket connected: ${socketService.isConnected}');
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
                // ENHANCED: Add more specific listening conditions for debugging
                final shouldListen =
                    (previous.routeDisplayed != current.routeDisplayed) ||
                    (previous.shouldUpdateCamera !=
                            current.shouldUpdateCamera &&
                        current.shouldUpdateCamera) ||
                    (previous.cameraTarget != current.cameraTarget &&
                        current.cameraTarget != null) ||
                    (previous.routeRecalculated != current.routeRecalculated &&
                        current.routeRecalculated) ||
                    (previous.trackingStatusMessage !=
                            current.trackingStatusMessage &&
                        current.trackingStatusMessage != null) ||
                    // CRITICAL: Listen for real-time tracking state changes
                    (previous.isRealTimeTrackingActive !=
                        current.isRealTimeTrackingActive) ||
                    // CRITICAL: Listen for driver position changes
                    (previous.currentDriverPosition !=
                        current.currentDriverPosition) ||
                    // CRITICAL: Listen for ride progress changes
                    (previous.rideInProgress != current.rideInProgress);

                if (shouldListen) {
                  dev.log('🎯 BlocConsumer will trigger listener - reason:');
                  if (previous.routeDisplayed != current.routeDisplayed) {
                    dev.log(
                      '  - Route displayed changed: ${previous.routeDisplayed} -> ${current.routeDisplayed}',
                    );
                  }
                  if (previous.isRealTimeTrackingActive !=
                      current.isRealTimeTrackingActive) {
                    dev.log(
                      '  - Tracking active changed: ${previous.isRealTimeTrackingActive} -> ${current.isRealTimeTrackingActive}',
                    );
                  }
                  if (previous.currentDriverPosition !=
                      current.currentDriverPosition) {
                    dev.log(
                      '  - Driver position changed: ${previous.currentDriverPosition} -> ${current.currentDriverPosition}',
                    );
                  }
                  if (previous.rideInProgress != current.rideInProgress) {
                    dev.log(
                      '  - Ride progress changed: ${previous.rideInProgress} -> ${current.rideInProgress}',
                    );
                  }
                }

                return shouldListen;
              },
              listener: (context, rideState) {
                dev.log('🎥 RideCubit listener triggered');
                dev.log('🎥 Route displayed: ${rideState.routeDisplayed}');
                dev.log(
                  '🎥 Real-time tracking active: ${rideState.isRealTimeTrackingActive}',
                );
                dev.log('🎥 Ride in progress: ${rideState.rideInProgress}');
                dev.log(
                  '🎥 Current driver position: ${rideState.currentDriverPosition}',
                );
                dev.log(
                  '🎥 Should update camera: ${rideState.shouldUpdateCamera}',
                );
                dev.log('🎥 Camera target: ${rideState.cameraTarget}');

                // Handle route recalculation notification
                if (rideState.routeRecalculated) {
                  dev.log('🔄 Route was recalculated - showing notification');
                  _showRouteUpdateNotification();
                }

                // Handle tracking status messages
                if (rideState.trackingStatusMessage != null) {
                  dev.log(
                    '📢 Tracking status message: ${rideState.trackingStatusMessage}',
                  );
                  _showTrackingStatusMessage(rideState.trackingStatusMessage!);
                }

                // Handle real-time tracking activation
                if (rideState.isRealTimeTrackingActive &&
                    !rideCubit.getTrackingStatus().isTracking) {
                  dev.log(
                    '🚨 Real-time tracking should be active but tracking service is not running!',
                  );
                  _debugTrackingState(rideState);
                }

                // Handle route display
                if (rideState.routeDisplayed &&
                    rideState.routePolylines.isNotEmpty) {
                  dev.log('🎥 Animating to show route');
                  _animateToShowRoute(rideState);
                } else if (rideState.shouldUpdateCamera &&
                    rideState.cameraTarget != null) {
                  dev.log(
                    '🎥 Animating to specific target: ${rideState.cameraTarget}',
                  );
                  _animateToTarget(rideState.cameraTarget!);
                }
              },
              builder: (context, rideState) {
                // ENHANCED: Add debug logging for each rebuild
                dev.log(
                  '🏗️ Building HomeScreen - tracking active: ${rideState.isRealTimeTrackingActive}',
                );

                final showStackedBottomSheet = rideState.showStackedBottomSheet;
                final showRideFound = rideState.riderAvailable;
                final showDeliverySheet = context.select<DeliveryCubit, bool>(
                  (DeliveryCubit cubit) => cubit.state.showDeliverySearchSheet,
                );

                return Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: HomeState.initialCameraPosition,
                      myLocationEnabled:
                          state.serviceStatus == LocationServiceStatus.located,
                      compassEnabled: false,
                      mapToolbarEnabled: false,
                      markers: _getCombinedMarkers(state, rideState),
                      polylines: _getCombinedPolylines(state, rideState),
                      onMapCreated: (GoogleMapController controller) {
                        dev.log('🗺️ GoogleMap created, setting up controller');
                        _mapController = controller;
                        final registered =
                            getIt.isRegistered<GoogleMapController>();
                        if (registered) {
                          dev.log('🗺️ Controller already registered');
                          return;
                        } else {
                          getIt.registerSingleton<GoogleMapController>(
                            controller,
                          );
                          getIt<MapService>().setController(controller);
                          dev.log('🗺️ Controller registered successfully');
                        }
                      },
                    ),

                    // Real-time tracking overlay with enhanced debugging
                    if (rideState.isRealTimeTrackingActive) ...[
                      _buildTrackingOverlay(rideState),
                    ],

                    UserFloatingAccessBar(
                      scaffoldKey: _scaffoldKey,
                      state: state,
                    ),

                    Visibility(
                      visible: showStackedBottomSheet,
                      child: StackedBottomSheetComponent(
                        key: _bottomSheetKey,
                        onFindRider: () => _handleFindRiderPressed(state),
                        onServiceSelected: (int index) {},
                      ),
                    ),

                    Visibility(
                      visible: showRideFound,
                      child: Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [_buildEnhancedRiderFoundSheet(rideState)],
                        ),
                      ),
                    ),

                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ShowRiderSearch(),
                    ),

                    Visibility(
                      visible: showDeliverySheet,
                      child: Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child:
                            dlv.ShowRiderSearch<DeliveryCubit, DeliveryState>(
                              searchTimeElapsedSelector:
                                  (state) => state.searchTimeElapsed,
                              statusSelector: (state) => state.status,
                              rideDataSelector: (state) => state.deliveryData,
                              cancellationStatusSelector: (state) => {},
                              messageSelector: (state) => state.errorMessage,
                              onCancelPressed: () {},
                              searchTimeDisplayText:
                                  'Searching for delivery driver in about',
                              cancelButtonText: 'Cancel Delivery',
                              estimatedDistanceLabel: 'Delivery Distance',
                              estimatedTimeLabel: 'Delivery Time',
                              fareLabel: 'Delivery Cost',
                            ),
                      ),
                    ),

                    // Center on driver button with debugging
                    if (rideState.isRealTimeTrackingActive)
                      _buildCenterOnDriverButton(rideState),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ENHANCED: Debug tracking state
  void _debugTrackingState(RideState rideState) {
    dev.log('🚨 DEBUGGING TRACKING STATE:');
    dev.log('  - UI tracking active: ${rideState.isRealTimeTrackingActive}');
    dev.log(
      '  - Service tracking active: ${rideCubit.getTrackingStatus().isTracking}',
    );
    dev.log('  - Ride in progress: ${rideState.rideInProgress}');
    dev.log('  - Current ride ID: ${rideState.currentRideId}');
    dev.log('  - Driver accepted: ${rideState.driverAccepted?.driverId}');
    dev.log('  - Socket connected: ${getIt<SocketService>().isConnected}');
    dev.log('  - Driver position: ${rideState.currentDriverPosition}');
    dev.log('  - Route markers count: ${rideState.routeMarkers.length}');

    // Check if driver marker exists
    final driverMarker = rideState.routeMarkers[const MarkerId('driver')];
    if (driverMarker != null) {
      dev.log('  - Driver marker position: ${driverMarker.position}');
      dev.log('  - Driver marker rotation: ${driverMarker.rotation}');
    } else {
      dev.log('  - ❌ No driver marker found!');
    }
  }

  // ENHANCED: Build real-time tracking overlay with better error handling
  Widget _buildTrackingOverlay(RideState rideState) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Live Tracking',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Spacer(),
                // FIXED: Handle potential null values
                if (rideState.currentSpeed! > 0)
                  Text(
                    '${rideState.currentSpeed?.toStringAsFixed(0)} km/h',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _getTrackingStatusText(rideState),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
                if (rideCubit.estimatedTimeToDestination != null)
                  Text(
                    _formatDuration(rideCubit.estimatedTimeToDestination!),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ENHANCED: Build real-time tracking section with better null handling
  Widget _buildRealTimeTrackingSection(RideState rideState) {
    final progress = rideCubit.getCurrentRouteProgress();

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
              const Icon(Icons.navigation, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Trip Progress',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const Spacer(),
              // FIXED: Better null handling for speed
              if (rideState.currentSpeed! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${rideState.currentSpeed?.toStringAsFixed(0)} km/h',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),

          if (progress != null) ...[
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
          ],

          if (rideState.lastPositionUpdate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Last updated: ${_formatLastUpdate(rideState.lastPositionUpdate!)}',
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  // ENHANCED: Enhanced rider found sheet
  Widget _buildEnhancedRiderFoundSheet(RideState rideState) {
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

  // ENHANCED: Center on driver button with debug info
  Widget _buildCenterOnDriverButton(RideState rideState) {
    return Positioned(
      right: 16,
      bottom: 200,
      child: Column(
        children: [
          FloatingActionButton(
            mini: true,
            onPressed: () {
              dev.log('🎯 Center on driver button pressed');
              dev.log(
                '🎯 Current driver position: ${rideState.currentDriverPosition}',
              );

              if (rideState.currentDriverPosition != null) {
                rideCubit.centerCameraOnDriver();
              } else {
                dev.log('🎯 No driver position to center on!');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No driver position available')),
                );
              }
            },
            backgroundColor: Colors.white,
            child: const Icon(Icons.my_location, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          // DEBUG: Add manual refresh button
          FloatingActionButton(
            mini: true,
            onPressed: () {
              dev.log('🔄 Manual refresh button pressed');
              _debugTrackingState(rideState);
              rideCubit.forceRouteRecalculation();
            },
            backgroundColor: Colors.orange,
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ENHANCED: Get combined markers with detailed logging
  Set<Marker> _getCombinedMarkers(HomeState homeState, RideState rideState) {
    final markers = <Marker>{};

    if (!rideState.routeDisplayed) {
      markers.addAll(homeState.markers.values);
      dev.log('📍 Using home markers: ${homeState.markers.length}');
    }

    if (rideState.routeDisplayed) {
      markers.addAll(rideState.routeMarkers.values);
      dev.log('📍 Using route markers: ${rideState.routeMarkers.length}');

      // DEBUG: Log each route marker
      rideState.routeMarkers.forEach((key, marker) {
        dev.log(
          '📍 Route marker: ${key.value} at ${marker.position} (rotation: ${marker.rotation})',
        );
      });
    }

    dev.log('📍 Total combined markers: ${markers.length}');
    return markers;
  }

  // Rest of the methods remain the same but with enhanced logging...
  Set<Polyline> _getCombinedPolylines(
    HomeState homeState,
    RideState rideState,
  ) {
    final polylines = <Polyline>{};

    if (!rideState.routeDisplayed) {
      polylines.addAll(homeState.polylines);
    }

    if (rideState.routeDisplayed) {
      polylines.addAll(rideState.routePolylines);
    }

    dev.log('🛣️ Combined polylines count: ${polylines.length}');
    return polylines;
  }

  void _animateToShowRoute(RideState rideState) async {
    dev.log('🎥 _animateToShowRoute: Animating to show route...');

    final controller = _mapController ?? getIt<MapService>().controller;
    if (controller == null || rideState.routePolylines.isEmpty) {
      dev.log(
        '🎥 Cannot animate: controller=$controller, polylines=${rideState.routePolylines.length}',
      );
      return;
    }

    try {
      final points = rideState.routePolylines.first.points;
      if (points.isEmpty) {
        dev.log('🎥 Cannot animate: no points in polyline');
        return;
      }

      dev.log('🎥 Calculating bounds for ${points.length} points');

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

      dev.log('🎥 Bounds: SW(${minLat}, ${minLng}) NE(${maxLat}, ${maxLng})');

      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
      dev.log('🎥 ✅ Camera animation completed');
    } catch (e) {
      dev.log('🎥 ❌ Error animating to show route: $e');
    }
  }

  void _animateToTarget(LatLng target) async {
    dev.log('🎥 _animateToTarget: Animating to target $target');

    final controller = _mapController ?? getIt<MapService>().controller;
    if (controller == null) {
      dev.log('🎥 Cannot animate to target: no controller');
      return;
    }

    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 16.0),
        ),
      );
      dev.log('🎥 ✅ Camera animation to target completed');
    } catch (e) {
      dev.log('🎥 ❌ Error animating to target: $e');
    }
  }

  // Helper methods for notifications and formatting...
  void _showRouteUpdateNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.route, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Route updated - driver changed path'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showTrackingStatusMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _getTrackingStatusText(RideState rideState) {
    if (rideState.trackingStatusMessage != null) {
      return rideState.trackingStatusMessage!;
    }

    if (rideState.currentDriverPosition != null) {
      final lastUpdate = rideState.lastPositionUpdate;
      if (lastUpdate != null) {
        final timeDiff = DateTime.now().difference(lastUpdate);
        if (timeDiff.inSeconds > 30) {
          return 'Last seen ${timeDiff.inMinutes}m ago';
        }
      }
      return 'Driver is on the way';
    }

    return 'Waiting for driver location...';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _formatLastUpdate(DateTime lastUpdate) {
    final now = DateTime.now();
    final diff = now.difference(lastUpdate);

    if (diff.inSeconds < 30) {
      return 'just now';
    } else if (diff.inMinutes < 1) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
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

    final isMultiDestination = additionalDestinations.isNotEmpty;

    dev.log(
      'Requesting ${isMultiDestination ? "multi-destination" : "single-destination"} ride',
    );

    if (isMultiDestination) {
      dev.log(
        'Number of additional destinations: ${additionalDestinations.length}',
      );
    }

    final rideRequest = rideCubit.createRideRequestFromHomeState(
      pickupLocation: state.pickUpLocation!,
      mainDestination: state.destinationLocation!,
      additionalDestinations: additionalDestinations,
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
