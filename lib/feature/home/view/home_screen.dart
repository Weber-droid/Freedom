import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/auth/local_data_source/register_local_data_source.dart';
import 'package:freedom/feature/home/audio_call_cubit/call_cubit.dart';
import 'package:freedom/feature/home/location_cubit/location_cubit.dart';
import 'package:freedom/feature/home/view/widgets.dart';
import 'package:freedom/feature/home/widgets/custom_drawer.dart';
import 'package:freedom/feature/home/widgets/stacked_bottom_sheet_component.dart';
import 'package:freedom/feature/location_search/cubit/map_search_cubit.dart';
import 'package:freedom/feature/location_search/repository/models/location.dart';
import 'package:freedom/feature/profile/cubit/profile_cubit.dart';
import 'package:freedom/shared/enums/enums.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late GoogleMapController _mapController;

  String defaultValue = 'Now';
  List<String> dropdownItems = ['Now', 'Later'];

  bool isFirstSelected = false;
  bool isSecondSelected = false;
  int trackSelectedIndex = 0;

  bool hideStackedBottomSheet = false;
  final Completer<GoogleMapController> _controller = Completer();
  Location? _pickupLocation;
  Location? _destinationLocation;
  // Markers set
  Set<Marker> _markers = {};

  // Route polylines
  Set<Polyline> _polylines = {};

  // Initial camera position
  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(0, 0),
    zoom: 14,
  );

  Future<void> _getCurrentLocation() async {
    try {
      await context.read<LocationCubit>().getCurrentLocation();
    } catch (e) {
      log('Error getting current location: $e');
    }
  }

  void _onPickupSelected(Location location) {
    setState(() {
      _pickupLocation = location;
      _updateMarkers();
    });

    _moveCameraToLocation(location);
    _calculateRoute();
  }

  // Handle selection of destination location
  void _onDestinationSelected(Location location) {
    setState(() {
      _destinationLocation = location;
      _updateMarkers();
    });

    _moveCameraToLocation(location);
    _calculateRoute();
  }

  // Move camera to selected location
  Future<void> _moveCameraToLocation(Location location) async {
    final controller = await _controller.future;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            location.latitude,
            location.longitude,
          ),
          zoom: 16.0,
        ),
      ),
    );
  }

  // Update markers on the map
  void _updateMarkers() {
    final markers = <Marker>{};

    if (_pickupLocation != null) {
      markers.add(
        Marker(
          markerId: MarkerId("pickup"),
          position: LatLng(
            _pickupLocation!.latitude,
            _pickupLocation!.longitude,
          ),
          infoWindow: InfoWindow(
            title: "Pickup",
            snippet: _pickupLocation!.latitude.toString(),
          ),
          icon:
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    if (_destinationLocation != null) {
      markers.add(
        Marker(
          markerId: MarkerId("destination"),
          position: LatLng(
            _destinationLocation!.latitude,
            _destinationLocation!.longitude,
          ),
          infoWindow: InfoWindow(
            title: "Destination",
            snippet: _destinationLocation!.longitude.toString(),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  // Calculate route between locations
  Future<void> _calculateRoute() async {
    if (_pickupLocation == null || _destinationLocation == null) {
      return;
    }

    // Route calculation logic
    // ...
  }

  @override
  void initState() {
    super.initState();
    context.read<LocationCubit>().checkPermissionStatus();
    context.read<ProfileCubit>().getUserProfile();
   WidgetsBinding.instance.addPostFrameCallback((_) {
     initCallCubit();
   });
  }
  Future<void> initCallCubit()async {
    final user = await RegisterLocalDataSource().getUser();
    log('user: ${user!.token}');
   if(mounted){
     await context
         .read<CallCubit>()
         .initialize(userId: user.id!, userName: user.firstName!);
   }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MapSearchCubit>(
          create: (context) => getIt<MapSearchCubit>(),
        ),
      ],
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const CustomDrawer(),
        body: BlocConsumer<LocationCubit, LocationState>(
          listener: (context, state) {
            if (state.serviceStatus == LocationServiceStatus.located &&
                state.currentLocation != null) {
              _mapController.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: state.currentLocation!,
                    zoom: 15.5,
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            final Widget mapWidget = GoogleMap(
              initialCameraPosition: LocationState.initialCameraPosition,
              myLocationEnabled:
              state.serviceStatus == LocationServiceStatus.located,
              markers: _markers,
              polylines: _polylines,
              compassEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _controller.complete(controller);
              },
            );

            return Stack(
              children: [
                mapWidget,
                UserFloatingAccessBar(scaffoldKey: _scaffoldKey, state: state),
                Visibility(
                  visible: !hideStackedBottomSheet,
                  child: StackedBottomSheetComponent(
                    onFindRider: () {
                      setState(() {
                        hideStackedBottomSheet = true;
                      });
                      _showRiderFoundBottomSheet(context).then((_) {
                        setState(() {
                          hideStackedBottomSheet = false;
                        });
                      });
                    },
                    onServiceSelected: (int index) {},
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }


  Future<void> _showRiderFoundBottomSheet(BuildContext context) async {
    await showModalBottomSheet<dynamic>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return const RiderFoundBottomSheet();
      },
    );
  }
}