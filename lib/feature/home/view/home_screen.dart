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
import 'package:freedom/feature/home/ride_cubit/ride_cubit.dart';
import 'package:freedom/feature/home/view/widget/show_rider_search.dart';
import 'package:freedom/feature/home/view/widgets.dart';
import 'package:freedom/feature/home/widgets/custom_drawer.dart';
import 'package:freedom/feature/home/widgets/stacked_bottom_sheet_component.dart';
import 'package:freedom/feature/profile/cubit/profile_cubit.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
    context.read<RideCubit>().checkRideStatus(id);
  }

  Future<void> _connectToSocket() async {
    getIt<SocketService>().connect(
      'https://api-freedom.com',
      authToken: await AppPreferences.getToken(),
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
                return (previous.routeDisplayed != current.routeDisplayed) ||
                    (previous.shouldUpdateCamera !=
                            current.shouldUpdateCamera &&
                        current.shouldUpdateCamera) ||
                    (previous.cameraTarget != current.cameraTarget &&
                        current.cameraTarget != null);
              },
              listener: (context, rideState) {
                dev.log('🎥 RideCubit listener triggered');
                dev.log('🎥 Route displayed: ${rideState.routeDisplayed}');
                dev.log(
                  '🎥 Should update camera: ${rideState.shouldUpdateCamera}',
                );
                dev.log('🎥 Camera target: ${rideState.cameraTarget}');

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
                final showStackedBottomSheet = rideState.showStackedBottomSheet;
                final showRideFound = rideState.riderAvailable;
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
                        _mapController = controller;
                        final registered =
                            getIt.isRegistered<GoogleMapController>();
                        if (registered) {
                          return;
                        } else {
                          getIt.registerSingleton<GoogleMapController>(
                            controller,
                          );
                          getIt<MapService>().setController(controller);
                        }
                      },
                    ),
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
                          children: [const RiderFoundBottomSheet()],
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ShowRiderSearch(),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Set<Marker> _getCombinedMarkers(HomeState homeState, RideState rideState) {
    final markers = <Marker>{};
    if (!rideState.routeDisplayed) {
      markers.addAll(homeState.markers.values);
    }
    if (rideState.routeDisplayed) {
      markers.addAll(rideState.routeMarkers.values);
    }

    dev.log('📍 Combined markers count: ${markers.length}');
    if (rideState.routeDisplayed) {
      dev.log(
        '📍 Route markers: ${rideState.routeMarkers.keys.map((k) => k.value).toList()}',
      );
    }
    return markers;
  }

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
