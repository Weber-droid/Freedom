import 'dart:developer' as dev;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:freedom/app_preference.dart';
import 'package:freedom/core/config/api_constants.dart';
import 'package:freedom/core/services/delivery_persistence_service.dart';
import 'package:freedom/core/services/map_services.dart';
import 'package:freedom/core/services/push_notification_service/push_nofication_service.dart';
import 'package:freedom/core/services/real_time_driver_tracking.dart';
import 'package:freedom/core/services/socket_service.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/auth/local_data_source/register_local_data_source.dart';
import 'package:freedom/feature/home/audio_call_cubit/call_cubit.dart';
import 'package:freedom/feature/home/cubit/home_cubit.dart';
import 'package:freedom/feature/home/delivery_cubit/delivery_cubit.dart';
import 'package:freedom/feature/home/ride_cubit/ride_cubit.dart';
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
      _checkPersistedStates();
      _getPaymentMethods();
    });
  }

  Future<void> _checkPersistedStates() async {
    final deliveryCubit = context.read<DeliveryCubit>();
    try {
      dev.log('🔄 Checking for persisted states...');

      final rideId = await AppPreferences.getRideId();
      if (rideId.isNotEmpty) {
        await context.read<RideCubit>().checkRideStatus(rideId);
      }

      final persistenceService =
          getIt.isRegistered<DeliveryPersistenceService>()
              ? getIt<DeliveryPersistenceService>()
              : DeliveryPersistenceService(deliveryCubit.deliveryRepository);

      final hasPersistedDelivery =
          await persistenceService.hasPersistedDeliveryState();

      if (hasPersistedDelivery) {
        dev.log('✅ Found persisted delivery state - will be loaded by cubit');
      } else {
        dev.log('📭 No persisted delivery state found');
        context.read<HomeCubit>().checkPermissionStatus();
      }
    } catch (e) {
      dev.log('❌ Error checking persisted states: $e');
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
                final routeDisplayedChanged =
                    previous.routeDisplayed != current.routeDisplayed;
                final cameraUpdateNeeded =
                    previous.shouldUpdateCamera != current.shouldUpdateCamera &&
                    current.shouldUpdateCamera;
                final cameraTargetChanged =
                    previous.cameraTarget != current.cameraTarget &&
                    current.cameraTarget != null;
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

                final shouldListen =
                    routeDisplayedChanged ||
                    cameraUpdateNeeded ||
                    cameraTargetChanged ||
                    routeRecalculated ||
                    statusMessageChanged ||
                    trackingStateChanged ||
                    driverPositionChanged ||
                    rideProgressChanged ||
                    markersChanged;

                if (shouldListen) {
                  dev.log('🎯 RideCubit listener triggered');
                }

                return shouldListen;
              },
              listener: (context, rideState) {
                dev.log('🎥 Enhanced RideCubit listener triggered');

                if (rideState.routeRecalculated) {
                  _showEnhancedRouteUpdateNotification();
                }

                if (rideState.trackingStatusMessage != null) {
                  _showEnhancedTrackingStatusMessage(
                    rideState.trackingStatusMessage!,
                  );
                }

                if (rideState.routeDisplayed &&
                    rideState.routePolylines.isNotEmpty) {
                  _animateToShowRoute(rideState.routePolylines.first.points);
                } else if (rideState.shouldUpdateCamera &&
                    rideState.cameraTarget != null) {
                  _animateToTarget(rideState.cameraTarget!);
                }
              },
              builder: (context, rideState) {
                return BlocConsumer<DeliveryCubit, DeliveryState>(
                  // FIXED: Simplified listenWhen to avoid excessive triggering
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
                      log('🔍 Street zoom: ${deliveryState.streetLevelZoom}');
                      _animateToShowRoute(
                        deliveryState.deliveryRoutePolylines.first.points,
                      );
                    } else if (deliveryState.shouldUpdateCamera &&
                        deliveryState.cameraTarget != null &&
                        deliveryState.streetLevelZoom != null) {
                      log('🔍 Street zoom: ${deliveryState.streetLevelZoom}');
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

                    // Handle delivery tracking status messages
                    if (deliveryState.deliveryTrackingStatusMessage != null) {
                      _showEnhancedTrackingStatusMessage(
                        deliveryState.deliveryTrackingStatusMessage!,
                      );
                    }

                    // Handle delivery route recalculation
                    if (deliveryState.deliveryRouteRecalculated) {
                      _showEnhancedRouteUpdateNotification();
                    }
                  },
                  builder: (context, deliveryState) {
                    // Calculate which sheets should be visible
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
                        ),

                        // Real-time tracking overlay for rides
                        if (rideState.isRealTimeTrackingActive) ...[
                          _buildTrackingOverlay(rideState, isDelivery: false),
                        ],

                        // Real-time tracking overlay for deliveries
                        if (deliveryState.isRealTimeDeliveryTrackingActive) ...[
                          _buildDeliveryTrackingOverlay(deliveryState),
                        ],

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

                        // Center on driver/delivery driver button
                        if (rideState.isRealTimeTrackingActive ||
                            deliveryState.isRealTimeDeliveryTrackingActive)
                          _buildCenterOnDriverButton(rideState, deliveryState),
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

        // Pickup location - get from delivery controllers if available
        _buildLocationRow(
          icon: Icons.location_on,
          iconColor: Colors.green,
          label: 'Pickup Location',
          address:
              state.deliveryControllers.isNotEmpty &&
                      state.deliveryControllers.first.text.isNotEmpty
                  ? state.deliveryControllers.first.text
                  : 'Pickup location',
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
                state.deliveryControllers.length > 1 &&
                        state.deliveryControllers[1].text.isNotEmpty
                    ? state.deliveryControllers[1].text
                    : 'Delivery destination',
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

  Widget _buildDeliveryTrackingOverlay(DeliveryState deliveryState) {
    final trackingStatus =
        context.read<DeliveryCubit>().getDeliveryTrackingStatus();
    final isTrackingHealthy =
        trackingStatus.isReceivingRegularUpdates &&
        trackingStatus.hasGoodAccuracy;
    final deliveryData = deliveryState.deliveryData;

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
          border: Border.all(
            color: isTrackingHealthy ? Colors.green : Colors.orange,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isTrackingHealthy ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isTrackingHealthy
                      ? 'Live Delivery Tracking'
                      : 'Delivery Tracking Issues',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isTrackingHealthy ? Colors.green : Colors.orange,
                  ),
                ),
                const Spacer(),
                // Show multi-stop indicator if applicable
                if (deliveryData?.isMultiStop == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${deliveryData?.numberOfStops} stops',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.purple.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                if (deliveryState.currentDeliverySpeed > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${deliveryState.currentDeliverySpeed.toStringAsFixed(0)} km/h',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.delivery_dining, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _getDeliveryTrackingStatusText(
                      deliveryState,
                      trackingStatus,
                    ),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
                if (context
                        .read<DeliveryCubit>()
                        .estimatedTimeToDeliveryDestination !=
                    null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _formatDuration(
                        context
                            .read<DeliveryCubit>()
                            .estimatedTimeToDeliveryDestination!,
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            // Add delivery-specific information if available
            if (deliveryData != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Delivery ID: ${deliveryData.deliveryId.length > 10 ? "${deliveryData.deliveryId.substring(0, 10)}..." : deliveryData.deliveryId}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ),
                  Text(
                    '${deliveryData.currency} ${deliveryData.fare.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            // Add tracking accuracy indicator if tracking is active
            if (trackingStatus.isTracking) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.gps_fixed,
                    size: 12,
                    color:
                        trackingStatus.hasGoodAccuracy
                            ? Colors.green
                            : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'GPS: ${trackingStatus.averageAccuracy.toStringAsFixed(0)}m',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                  const Spacer(),
                  if (trackingStatus.locationHistoryCount > 0)
                    Text(
                      '${trackingStatus.locationHistoryCount} updates',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDeliveryTrackingStatusText(
    DeliveryState deliveryState,
    TrackingStatus trackingStatus,
  ) {
    if (deliveryState.deliveryTrackingStatusMessage != null) {
      return deliveryState.deliveryTrackingStatusMessage!;
    }

    if (!trackingStatus.isTracking) {
      return 'Delivery tracking not active';
    }

    if (trackingStatus.isStale) {
      return 'Connection issues - last seen ${trackingStatus.formattedLastUpdate}';
    }

    if (!trackingStatus.isReceivingRegularUpdates) {
      return 'Irregular updates from delivery driver';
    }

    if (!trackingStatus.hasGoodAccuracy) {
      return 'Poor GPS signal (${trackingStatus.averageAccuracy.toStringAsFixed(0)}m)';
    }

    if (deliveryState.currentDeliveryDriverPosition != null) {
      final distance =
          context.read<DeliveryCubit>().distanceToDeliveryDestination;
      if (distance != null) {
        if (distance < 100) {
          return 'Delivery driver is arriving now';
        } else if (distance < 500) {
          return 'Delivery driver is nearby (${(distance / 1000).toStringAsFixed(1)}km away)';
        } else {
          return 'Delivery driver is on the way (${(distance / 1000).toStringAsFixed(1)}km away)';
        }
      }

      // Check if it's a multi-stop delivery
      final deliveryData = deliveryState.deliveryData;
      if (deliveryData != null && deliveryData.isMultiStop) {
        return 'Delivery driver is making ${deliveryData.numberOfStops} stops';
      }

      return 'Delivery driver is on the way';
    }

    return 'Waiting for delivery driver location...';
  }

  void _showEnhancedRouteUpdateNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.route, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text('Route updated automatically - driver changed path'),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'Center',
          textColor: Colors.white,
          onPressed: () {
            rideCubit.centerCameraOnDriver();
            context.read<DeliveryCubit>().centerCameraOnDeliveryDriver();
          },
        ),
      ),
    );
  }

  void _showEnhancedTrackingStatusMessage(String message) {
    Color backgroundColor = Colors.blue;
    IconData icon = Icons.info_outline;

    if (message.toLowerCase().contains('error') ||
        message.toLowerCase().contains('failed')) {
      backgroundColor = Colors.red;
      icon = Icons.error_outline;
    } else if (message.toLowerCase().contains('stale') ||
        message.toLowerCase().contains('issue')) {
      backgroundColor = Colors.orange;
      icon = Icons.warning_outlined;
    } else if (message.toLowerCase().contains('success') ||
        message.toLowerCase().contains('updated')) {
      backgroundColor = Colors.green;
      icon = Icons.check_circle_outline;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: message.length > 50 ? 5 : 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildTrackingOverlay(
    RideState rideState, {
    required bool isDelivery,
  }) {
    final trackingStatus = rideCubit.getTrackingStatus();
    final isTrackingHealthy =
        trackingStatus.isReceivingRegularUpdates &&
        trackingStatus.hasGoodAccuracy;

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
          border: Border.all(
            color: isTrackingHealthy ? Colors.green : Colors.orange,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isTrackingHealthy ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isTrackingHealthy ? 'Live Tracking' : 'Tracking Issues',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isTrackingHealthy ? Colors.green : Colors.orange,
                  ),
                ),
                const Spacer(),
                if (rideState.currentSpeed != null &&
                    rideState.currentSpeed! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${rideState.currentSpeed?.toStringAsFixed(0)} km/h',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
                    _getEnhancedTrackingStatusText(rideState, trackingStatus),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
                if (rideCubit.estimatedTimeToDestination != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _formatDuration(rideCubit.estimatedTimeToDestination!),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getEnhancedTrackingStatusText(
    RideState rideState,
    TrackingStatus trackingStatus,
  ) {
    if (rideState.trackingStatusMessage != null) {
      return rideState.trackingStatusMessage!;
    }

    if (!trackingStatus.isTracking) {
      return 'Tracking not active';
    }

    if (trackingStatus.isStale) {
      return 'Connection issues - last seen ${trackingStatus.formattedLastUpdate}';
    }

    if (!trackingStatus.isReceivingRegularUpdates) {
      return 'Irregular updates from driver';
    }

    if (!trackingStatus.hasGoodAccuracy) {
      return 'Poor GPS signal (${trackingStatus.averageAccuracy.toStringAsFixed(0)}m)';
    }

    if (rideState.currentDriverPosition != null) {
      final distance = rideCubit.distanceToDestination;
      if (distance != null) {
        if (distance < 100) {
          return 'Driver is arriving now';
        } else if (distance < 500) {
          return 'Driver is nearby (${(distance / 1000).toStringAsFixed(1)}km away)';
        } else {
          return 'Driver is on the way (${(distance / 1000).toStringAsFixed(1)}km away)';
        }
      }
      return 'Driver is on the way';
    }

    return 'Waiting for driver location...';
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

          if (rideState.lastPositionUpdate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Last updated: ${_formatLastUpdate(rideState.lastPositionUpdate!)}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
                const Spacer(),
                if (trackingStatus.isTracking)
                  Text(
                    trackingStatus.statusSummary,
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          trackingStatus.isReceivingRegularUpdates
                              ? Colors.green[600]
                              : Colors.orange[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
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

  Widget _buildCenterOnDriverButton(
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
      bottom: 200,
      child: Column(
        children: [
          FloatingActionButton(
            mini: true,
            onPressed: () {
              if (hasActiveRideTracking) {
                rideCubit.centerCameraOnDriver();
              } else if (hasActiveDeliveryTracking) {
                context.read<DeliveryCubit>().centerCameraOnDeliveryDriver();
              }
            },
            backgroundColor: Colors.white,
            child: Icon(
              hasActiveRideTracking
                  ? Icons.directions_car
                  : Icons.delivery_dining,
              color: Colors.blue,
            ),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 8),
            FloatingActionButton(
              mini: true,
              onPressed: () {
                if (hasActiveRideTracking) {
                  rideCubit.forceRouteRecalculation();
                } else if (hasActiveDeliveryTracking) {
                  // Add delivery route recalculation if needed
                }
              },
              backgroundColor: Colors.orange,
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  // FIXED: Simplified _getCombinedMarkers with less verbose logging
  Set<Marker> _getCombinedMarkers(
    HomeState homeState,
    RideState rideState,
    DeliveryState deliveryState,
  ) {
    final markers = <Marker>{};

    // Priority: Delivery markers > Ride markers > Home markers
    if (deliveryState.deliveryRouteDisplayed &&
        deliveryState.deliveryRouteMarkers.isNotEmpty) {
      markers.addAll(deliveryState.deliveryRouteMarkers.values);
      dev.log(
        '📍 Using delivery markers: ${deliveryState.deliveryRouteMarkers.length}',
      );
    } else if (rideState.routeDisplayed && rideState.routeMarkers.isNotEmpty) {
      markers.addAll(rideState.routeMarkers.values);
      dev.log('📍 Using ride markers: ${rideState.routeMarkers.length}');
    } else {
      markers.addAll(homeState.markers.values);
      dev.log('📍 Using home markers: ${homeState.markers.length}');
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
      dev.log(
        '🛣️ Using delivery polylines: ${deliveryState.deliveryRoutePolylines.length}',
      );
    } else if (rideState.routeDisplayed &&
        rideState.routePolylines.isNotEmpty) {
      polylines.addAll(rideState.routePolylines);
      dev.log('🛣️ Using ride polylines: ${rideState.routePolylines.length}');
    } else {
      polylines.addAll(homeState.polylines);
      dev.log('🛣️ Using home polylines: ${homeState.polylines.length}');
    }

    dev.log('🛣️ Total combined polylines: ${polylines.length}');
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
          CameraPosition(target: target, zoom: 16.0),
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
