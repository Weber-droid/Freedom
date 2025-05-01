import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:freedom/core/services/map_services.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/home/cubit/home_cubit.dart';
import 'package:freedom/feature/location_search/repository/models/PlacePrediction.dart';
import 'package:freedom/feature/location_search/repository/models/location.dart';
import 'package:freedom/feature/location_search/use_cases/clear_recent_location.dart';
import 'package:freedom/feature/location_search/use_cases/get_place_detail.dart';
import 'package:freedom/feature/location_search/use_cases/get_place_prediction.dart';
import 'package:freedom/feature/location_search/use_cases/get_recent_locations.dart';
import 'package:freedom/feature/location_search/use_cases/get_saved_location.dart';
import 'package:freedom/shared/enums/enums.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:freedom/shared/widgets/text_field_factory.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SearchSheet extends StatefulWidget {
  const SearchSheet({
    required this.destinationController,
    required this.pickUpLocationController,
    required this.getPlacePredictions,
    required this.getPlaceDetails,
    required this.getSavedLocations,
    required this.getRecentLocations,
    required this.clearRecentLocations,
    super.key,
    this.destinationControllers = const [],
  });

  final List<TextEditingController> destinationControllers;
  final TextEditingController pickUpLocationController;
  final TextEditingController destinationController;
  final GetPlacePredictions getPlacePredictions;
  final GetPlaceDetails getPlaceDetails;
  final GetSavedLocations getSavedLocations;
  final GetRecentLocations getRecentLocations;
  final ClearRecentLocations clearRecentLocations;
  @override
  State<SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<SearchSheet>
    with SingleTickerProviderStateMixin {
  bool isPickUpLocation = false;
  bool isDestinationLocation = false;
  bool isInitialDestinationField = false;
  List<Location> _recentLocations = [];
  bool _isLoading = false;
  bool _showResults = false;
  Timer? _debounce;
  Location? _pickUpLocation;
  Location? _destinationLocation;
  BitmapDescriptor? bikeIcon;
  Map<String, Marker> _markersMap = {};
  final List<LatLng> _routeCoordinates = [];
  final _polylineId = const PolylineId('route');
  Set<Polyline> _polylines = {};
  final FocusNode _pickUpNode = FocusNode();
  final FocusNode _destinationNode = FocusNode();

  // Animation for search results
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Set up animation for results panel
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _loadLocations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      createMotorcycleIcon();
    });

    // Listen for focus changes
    pickNodeFocusListener();
    destinationNodeFocusListener();

    widget.pickUpLocationController.addListener(_onSearchChangedPickup);
    widget.destinationController.addListener(_onSearchChangedDestination);
  }

  @override
  void dispose() {
    widget.pickUpLocationController.removeListener(_onSearchChangedPickup);
    widget.destinationController.removeListener(_onSearchChangedDestination);
    _pickUpNode.dispose();
    _destinationNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void destinationNodeFocusListener() {
    _destinationNode.addListener(() {
      if (_destinationNode.hasFocus) {
        dev.log('Destination field focused');
        context.read<HomeCubit>().isDestinationLocation(
              isDestinationLocation: true,
            );
        context.read<HomeCubit>().isPickUpLocation(
              isPickUpLocation: false,
            );
        context.read<HomeCubit>().showDestinationRecentlySearchedLocations(
              showDestinationRecentlySearchedLocations: true,
            );
        _animationController.forward();
      } else {
        _animationController.reverse().then((_) {
          context.read<HomeCubit>().isDestinationLocation(
                isDestinationLocation: false,
              );
          context.read<HomeCubit>().isPickUpLocation(
                isPickUpLocation: false,
              );
          context.read<HomeCubit>().showDestinationRecentlySearchedLocations(
                showDestinationRecentlySearchedLocations: false,
              );
        });
      }
    });
  }

  void pickNodeFocusListener() {
    dev.log('PickUpNode listener added');
    _pickUpNode.addListener(() {
      if (_pickUpNode.hasFocus) {
        dev.log('Pickup location field focused');
        context.read<HomeCubit>().isPickUpLocation(isPickUpLocation: true);
        context
            .read<HomeCubit>()
            .isDestinationLocation(isDestinationLocation: false);
        context
            .read<HomeCubit>()
            .showRecentPickUpLocations(showRecentlySearchedLocations: true);
        context.read<HomeCubit>().showDestinationRecentlySearchedLocations(
            showDestinationRecentlySearchedLocations: false);
        _animationController.forward();
      } else {
        _animationController.reverse().then((_) {
          context.read<HomeCubit>().isPickUpLocation(isPickUpLocation: false);
          context
              .read<HomeCubit>()
              .isDestinationLocation(isDestinationLocation: false);
          context
              .read<HomeCubit>()
              .showRecentPickUpLocations(showRecentlySearchedLocations: false);
        });
      }
    });
  }

  void _onSearchChangedPickup() {
    context.read<HomeCubit>().isPickUpLocation(isPickUpLocation: true);
    context
        .read<HomeCubit>()
        .fetchPredictions(widget.pickUpLocationController.text);
  }

  void _onSearchChangedDestination() {
    context
        .read<HomeCubit>()
        .isDestinationLocation(isDestinationLocation: true);
    context
        .read<HomeCubit>()
        .fetchPredictions(widget.destinationController.text);
  }

  // Load user's saved and recent locations
  Future<void> _loadLocations() async {
    try {
      await context.read<HomeCubit>().fetchRecentLocations();
    } catch (e) {
      print('Error loading locations: $e');
    }
  }

  void upDateMarkers() {
    final newMarkersMap = Map<String, Marker>.from(_markersMap);

    if (_pickUpLocation != null && bikeIcon != null) {
      const pickupMarkerId = 'pickup';
      dev.log('Adding pickup marker with ID: $pickupMarkerId');

      newMarkersMap[pickupMarkerId] = Marker(
        markerId: const MarkerId(pickupMarkerId),
        position: LatLng(
          _pickUpLocation!.latitude,
          _pickUpLocation!.longitude,
        ),
        infoWindow: InfoWindow(
          title: 'Pickup',
          snippet: _pickUpLocation?.name,
        ),
        icon: bikeIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      );
    }

    if (_destinationLocation != null) {
      const destinationMarkerId = 'destination';

      newMarkersMap[destinationMarkerId] = Marker(
        markerId: const MarkerId(destinationMarkerId),
        position: LatLng(
          _destinationLocation!.latitude,
          _destinationLocation!.longitude,
        ),
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: _destinationLocation?.name,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
    }

    setState(() {
      _markersMap = newMarkersMap;
    });

    if (context.mounted) {
      context.read<HomeCubit>().setMarkers(_markersMap.values.toSet());
    }
  }

  Future<void> createMotorcycleIcon({int width = 15, int height = 15}) async {
    final imageData = await rootBundle.load('assets/images/bike_marker.png');
    final originalBytes = imageData.buffer.asUint8List();

    final codec = await ui.instantiateImageCodec(originalBytes);
    final frameInfo = await codec.getNextFrame();
    final image = frameInfo.image;

    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint(),
    );

    final picture = recorder.endRecording();
    final resizedImage = await picture.toImage(width, height);
    final resizedByteData =
        await resizedImage.toByteData(format: ui.ImageByteFormat.png);

    if (resizedByteData != null) {
      bikeIcon = BitmapDescriptor.bytes(resizedByteData.buffer.asUint8List());
    } else {
      bikeIcon = BitmapDescriptor.bytes(originalBytes);
    }
  }

  Future<void> upDateLocation() async {
    final mapServices = getIt<MapService>();
    if (_pickUpLocation != null) {
      await mapServices.controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _pickUpLocation!.latitude,
              _pickUpLocation!.longitude,
            ),
            zoom: 15,
          ),
        ),
      );
    }
  }

  void addDriverMarker(String driverId, LatLng position,
      {bool isOnline = true}) {
    if (!isOnline) {
      removeDriverMarker(driverId);
      return;
    }

    final markerId = 'driver_$driverId';

    final driverMarker = Marker(
      markerId: MarkerId(markerId),
      position: position,
      infoWindow: InfoWindow(
        title: 'Driver $driverId',
        snippet: isOnline ? 'Online' : 'Offline',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    setState(() {
      _markersMap[markerId] = driverMarker;
    });

    if (context.mounted) {
      context.read<HomeCubit>().setMarkers(_markersMap.values.toSet());
    }
  }

  void removeDriverMarker(String driverId) {
    final markerId = 'driver_$driverId';

    // Remove from map if exists
    if (_markersMap.containsKey(markerId)) {
      setState(() {
        _markersMap.remove(markerId);
      });

      // Update the map with the updated set of markers
      if (context.mounted) {
        context.read<HomeCubit>().setMarkers(_markersMap.values.toSet());
      }
    }
  }

  void updateDriverStatus(String driverId, LatLng position, {bool? isOnline}) {
    if (isOnline != null) {
      // Update or add driver marker
      addDriverMarker(driverId, position);
    } else {
      removeDriverMarker(driverId);
    }
  }

  Marker? getMarkerById(String markerId) {
    return _markersMap[markerId];
  }

  Future<void> getRoutePoints() async {
    if (_pickUpLocation == null || _destinationLocation == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create PolylinePoints object
      final polylinePoints = PolylinePoints();
      final result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: dotenv.env['DIRECTIONS_API_KEY'],
        request: PolylineRequest(
          origin: PointLatLng(
            _pickUpLocation!.latitude,
            _pickUpLocation!.longitude,
          ),
          destination: PointLatLng(
            _destinationLocation!.latitude,
            _destinationLocation!.longitude,
          ),
          mode: TravelMode.driving,
        ),
      );

      dev.log('result: ${result.points}');
      // Clear previous route
      _routeCoordinates.clear();

      // Add all points to the route
      if (result.points.isNotEmpty) {
        dev.log('Adding points to route');
        for (var point in result.points) {
          _routeCoordinates.add(LatLng(point.latitude, point.longitude));
        }
      }

      // Create polyline
      final polyline = Polyline(
        polylineId: _polylineId,
        color: Colors.orange,
        points: _routeCoordinates,
        width: 5,
        patterns: [
          PatternItem.dash(20),
          PatternItem.gap(10)
        ], // Optional: Creates a dashed line
      );

      // Update polylines
      setState(() {
        _polylines = {polyline};
        _isLoading = false;
      });

      // Update the map with the new polylines
      if (context.mounted) {
        context.read<HomeCubit>().setPolylines(_polylines);
      }

      // Zoom the map to fit the route
      _centerCameraWithZoom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      dev.log('Error getting route: $e');
    }
  }

// Add this function to fit both markers and route on map
  void _centerCameraWithZoom() {
    if (_pickUpLocation == null || _destinationLocation == null) {
      return;
    }

    // Calculate center point between origin and destination
    final centerLat =
        (_pickUpLocation!.latitude + _destinationLocation!.latitude) / 2;
    final centerLng =
        (_pickUpLocation!.longitude + _destinationLocation!.longitude) / 2;

    // Calculate approximate zoom level based on distance
    // This is a simple approach - you might want to refine this calculation
    final latDiff =
        (_pickUpLocation!.latitude - _destinationLocation!.latitude).abs();
    final lngDiff =
        (_pickUpLocation!.longitude - _destinationLocation!.longitude).abs();
    final double maxDiff = max(latDiff, lngDiff);

    // Simple logarithmic scale for zoom - adjust constants as needed
    // Lower value = more zoomed out
    double zoom = 14; // Default medium zoom
    if (maxDiff > 0.1) zoom = 11;
    if (maxDiff > 0.5) zoom = 9;
    if (maxDiff > 1.0) zoom = 7;

    // Animate to center with calculated zoom
    getIt<MapService>().controller?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(centerLat, centerLng),
              zoom: zoom,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCubit, HomeState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.only(top: 18),
          decoration: BoxDecoration(
            gradient: whiteAmberGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14.32),
              topRight: Radius.circular(14.32),
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.only(right: 11, bottom: 11, left: 11),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          strokeAlign: BorderSide.strokeAlignOutside,
                          color: Colors.black.withValues(alpha: 0.059),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const HSpace(6.4),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                left: 12,
                                bottom: 4.62,
                                top: 6.38,
                              ),
                              child: Text(
                                'Pickup Location',
                                style: TextStyle(
                                  fontSize: 10.13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        BlocBuilder<HomeCubit, HomeState>(
                          buildWhen: (previous, current) {
                            return current.status == MapSearchStatus.success;
                          },
                          builder: (context, state) {
                            return TextFieldFactory.location(
                              controller: widget.pickUpLocationController,
                              fillColor: textFieldFillColor,
                              focusNode: _pickUpNode,
                              suffixIcon: isPickUpLocation
                                  ? _isLoading
                                      ? Container(
                                          width: 24,
                                          height: 24,
                                          padding: const EdgeInsets.all(12),
                                          child:
                                              const CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.orange,
                                            ),
                                          ),
                                        )
                                      : widget.pickUpLocationController.text
                                              .isNotEmpty
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                top: 12,
                                                bottom: 12,
                                                left: 15.5,
                                                right: 7,
                                              ),
                                              child: GestureDetector(
                                                onTap: () {
                                                  widget
                                                      .pickUpLocationController
                                                      .clear();
                                                },
                                                child: Container(
                                                  decoration: ShapeDecoration(
                                                    color: const Color(
                                                      0xFFE61D2A,
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        7,
                                                      ),
                                                    ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : null
                                  : Padding(
                                      padding: const EdgeInsets.only(
                                        top: 12,
                                        bottom: 12,
                                        left: 15.5,
                                        right: 7,
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          // context
                                          //     .read<HomeCubit>()
                                          //     .removeLastDestination();
                                        },
                                        child: Container(
                                          decoration: ShapeDecoration(
                                            color: const Color(0xFFE61D2A),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(7),
                                            ),
                                          ),
                                          child: SvgPicture.asset(
                                            'assets/images/delete_field.svg',
                                          ),
                                        ),
                                      ),
                                    ),
                              prefixText: Padding(
                                padding: const EdgeInsets.only(
                                  top: 6,
                                  left: 5,
                                  bottom: 7,
                                  right: 10.8,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/images/location_pointer_icon.svg',
                                  ),
                                ),
                              ),
                              hinText: 'Enter pickup location',
                              hintTextStyle: GoogleFonts.poppins(
                                fontSize: 10.13,
                                color: const Color(0xFFBEBCBC),
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(
                                left: 12,
                              ),
                              child: Text(
                                'Destination',
                                style: TextStyle(
                                  fontSize: 10.13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 4,
                                right: 9,
                                bottom: 1,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  widget.destinationControllers.add(
                                    TextEditingController(),
                                  );
                                  context.read<HomeCubit>().addDestination();
                                },
                                child: Container(
                                  width: 23,
                                  height: 23,
                                  decoration: ShapeDecoration(
                                    color: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.add,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const VSpace(3),
                        //Destination TextField
                        BlocBuilder<HomeCubit, HomeState>(
                          buildWhen: (previous, current) {
                            return current.status == MapSearchStatus.success;
                          },
                          builder: (context, state) {
                            return TextFieldFactory.location(
                              fillColor: textFieldFillColor,
                              focusNode: _destinationNode,
                              hinText: 'Enter Destination',
                              prefixText: Padding(
                                padding: const EdgeInsets.only(
                                  top: 6,
                                  left: 5,
                                  bottom: 7,
                                  right: 10.8,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/images/maps_icon.svg',
                                  ),
                                ),
                              ),
                              hintTextStyle: GoogleFonts.poppins(
                                fontSize: 10.13,
                                color: const Color(0xFFBEBCBC),
                                fontWeight: FontWeight.w500,
                              ),
                              controller: widget.destinationController,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const VSpace(19.65),
                  BlocBuilder<HomeCubit, HomeState>(
                    builder: (context, state) {
                      if (state.isPickUpLocation) {
                        return _buildRecentLocation(context);
                      } else if (state.isDestinationLocation) {
                        return _buildRecentLocation(context);
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  SizeTransition _buildRecentLocation(BuildContext context) {
    final pickUpPredictions =
        context.select((HomeCubit c) => c.state.pickUpPredictions);
    final destinationPredictions =
        context.select((HomeCubit c) => c.state.destinationPredictions);
    final recentLocations =
        context.select((HomeCubit c) => c.state.recentLocations);
    dev.log('recentLocations: $recentLocations');
    return SizeTransition(
      sizeFactor: _animation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (pickUpPredictions.isNotEmpty ||
              destinationPredictions.isNotEmpty) ...[
            if (isPickUpLocation && pickUpPredictions.isNotEmpty) ...[
              ...pickUpPredictions.map((prediction) {
                return Builder(
                  builder: (context) {
                    return GestureDetector(
                      onTap: () async {
                        await context.read<HomeCubit>().handlePickUpLocation(
                              prediction,
                              _pickUpNode,
                              _destinationNode,
                              widget.pickUpLocationController,
                              widget.destinationController,
                            );
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: buildPredictionList(
                        context,
                        getIconData(prediction.iconType),
                        prediction,
                      ),
                    );
                  },
                );
              }),
            ] else if (isDestinationLocation &&
                destinationPredictions.isNotEmpty) ...[
              ...destinationPredictions.map((destination) {
                return GestureDetector(
                  onTap: () async {
                    await context.read<HomeCubit>().handleDestinationLocation(
                        destination,
                        _destinationNode,
                        widget.destinationController);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: buildPredictionList(
                    context,
                    getIconData(destination.iconType),
                    destination,
                  ),
                );
              }),
            ],
          ] else if (recentLocations.isNotEmpty) ...[
            ...recentLocations.map((e) => buildRecentLocation(context, e)),
          ],
        ],
      ),
    );
  }

  Widget buildPredictionList(
    BuildContext context,
    IconData iconData,
    PlacePrediction prediction,
  ) {
    return Column(
      children: [
        Divider(
          thickness: 2,
          color: Colors.black.withValues(alpha: 0.019),
        ),
        Row(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 8,
              ),
              width: 30,
              height: 30,
              decoration: ShapeDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    strokeAlign: BorderSide.strokeAlignOutside,
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Icon(
                iconData,
                color: Colors.orange,
                size: 20,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prediction.mainText,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  prediction.mainText,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Column buildRecentLocation(BuildContext context, Location recent) {
    return Column(
      children: [
        Divider(
          thickness: 2,
          color: Colors.black.withValues(alpha: 0.019),
        ),
        Row(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 8,
              ),
              width: 30,
              height: 30,
              decoration: ShapeDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    strokeAlign: BorderSide.strokeAlignOutside,
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Icon(
                Icons.history,
                color: Colors.orange,
                size: 20,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recent.name,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  recent.address,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  IconData getIconData(String iconType) {
    switch (iconType) {
      case 'local_airport':
        return Icons.local_airport;
      case 'train':
        return Icons.train;
      case 'hotel':
        return Icons.hotel;
      case 'restaurant':
        return Icons.restaurant;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      default:
        return Icons.location_on;
    }
  }
}
