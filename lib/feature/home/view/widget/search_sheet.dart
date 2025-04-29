import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  List<PlacePrediction> _pickUpPredictions = [];
  List<PlacePrediction> _destinationPredictions = [];
  List<Location> _recentLocations = [];
  bool _isLoading = false;
  bool _showResults = false;
  Timer? _debounce;
  Location? _pickUpLocation;
  Location? _destinationLocation;
  BitmapDescriptor? bikeIcon;

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
    _pickUpNode.addListener(() {
      if (_pickUpNode.hasFocus) {
        log('Pickup location field focused');
        setState(() {
          _showResults = true;
          isPickUpLocation = true;
          isDestinationLocation = false;
        });
        _animationController.forward();
      } else {
        _animationController.reverse().then((_) {
          setState(() {
            _showResults = false;
            isPickUpLocation = false;
            isDestinationLocation = false;
          });
        });
      }
    });

    _destinationNode.addListener(() {
      if (_destinationNode.hasFocus) {
        log('Destination field focused');
        setState(() {
          _showResults = true;
          isDestinationLocation = true;
          isPickUpLocation = false;
        });
        _animationController.forward();
      } else {
        _animationController.reverse().then((_) {
          setState(() {
            _showResults = false;
            isDestinationLocation = false;
            isPickUpLocation = false;
          });
        });
      }
    });

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

  void _onSearchChangedPickup() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchPredictions(widget.pickUpLocationController.text);
    });
  }

  void _onSearchChangedDestination() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchPredictions(widget.destinationController.text);
    });
  }

  Future<void> _fetchPredictions(String query) async {
    if (query.isEmpty) {
      setState(() {
        if (isPickUpLocation) {
          _pickUpPredictions = [];
        } else {
          _destinationPredictions = [];
        }
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final predictions = await widget.getPlacePredictions(query);

      if (mounted) {
        setState(() {
          if (isPickUpLocation) {
            _pickUpPredictions = predictions;
            _isLoading = false;
          } else {
            _destinationPredictions = predictions;
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      print('Error fetching predictions: $e');
      if (mounted) {
        setState(() {
          if (isPickUpLocation) {
            _pickUpPredictions = [];
            _isLoading = false;
          } else {
            _destinationPredictions = [];
            _isLoading = false;
          }
        });
      }
    }
  }

  // Load user's saved and recent locations
  Future<void> _loadLocations() async {
    try {
      final recentLocations = await getIt<GetRecentLocations>()();
      setState(() {
        _recentLocations = recentLocations;
      });
    } catch (e) {
      print('Error loading locations: $e');
    }
  }

  Future<void> _handlePickUpSelection(
    PlacePrediction prediction,
  ) async {
    _pickUpNode.unfocus();
    try {
      setState(() {
        _isLoading = true;
      });
      final placeDetail = await widget.getPlaceDetails(prediction.placeId);
      if (placeDetail != null && mounted) {
        widget.pickUpLocationController.text = placeDetail.name;
        await _loadLocations();
        setState(() {
          _isLoading = false;
          _pickUpLocation = placeDetail;
        });
        upDateMarkers();
        await upDateLocation();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching location details: $e');
    }
  }

  Future<void> _handleDestinationSelection(
    PlacePrediction prediction,
  ) async {
    _pickUpNode.unfocus();
    try {
      setState(() {
        _isLoading = true;
      });
      final placeDetail = await widget.getPlaceDetails(prediction.placeId);
      if (placeDetail != null && mounted) {
        widget.destinationController.text = placeDetail.name;
        await _loadLocations();
        setState(() {
          _isLoading = false;
          _destinationLocation = placeDetail;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching location details: $e');
    }
  }

  void upDateMarkers() {
    final markers = <Marker>{};
    if (_pickUpLocation != null && bikeIcon != null) {
      log('Adding pickup marker ${bikeIcon?.toJson()}');
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
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
        ),
      );
    }
    if (context.mounted) {
      context.read<HomeCubit>().setMarkers(markers);
    }
  }

  Future<void> createMotorcycleIcon() async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const size = Size(80, 80);

    // Define the gradient for the motorcycle
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xffF59E0B), Color(0xffE61D2A)], // Orange to Red gradient
    );

    // Create a paint with the gradient
    final Paint gradientPaint = Paint()
      ..shader =
          gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Draw a motorcycle icon or "M" text with gradient
    // Using "M" text as a simple representation of a motorcycle
    const textStyle = TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.bold,
    );

    final textSpan = TextSpan(
      text: "🏍️", // Motorcycle emoji (or use "M" if emoji doesn't work well)
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // For a text character with gradient fill
    final path = Path();
    textPainter.paint(
      canvas,
      Offset(
        size.width / 2 - textPainter.width / 2,
        size.height / 2 - textPainter.height / 2,
      ),
    );

    // Alternative approach using a custom motorcycle shape with path
    // This is a simplified motorcycle shape
    final motorcyclePath = Path()
      ..moveTo(size.width * 0.3, size.height * 0.6) // Bottom left
      ..lineTo(size.width * 0.4, size.height * 0.4) // Top left
      ..lineTo(size.width * 0.6, size.height * 0.4) // Top right
      ..lineTo(size.width * 0.7, size.height * 0.6) // Bottom right
      ..close();

    // Add wheels (circles)
    final wheelPaint = Paint()
      ..shader =
          gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Front wheel
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.65),
        size.width * 0.1, wheelPaint);

    // Rear wheel
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.65),
        size.width * 0.1, wheelPaint);

    // Draw the motorcycle body with gradient
    canvas.drawPath(motorcyclePath, gradientPaint);

    // Add handlebars
    canvas.drawLine(
        Offset(size.width * 0.4, size.height * 0.45),
        Offset(size.width * 0.3, size.height * 0.5),
        Paint()
          ..shader = gradient
              .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke);

    // Convert to image
    final picture = recorder.endRecording();
    final image =
        await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ImageByteFormat.png);

    bikeIcon = BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  void journeyRoute() {}

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

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeCubit>(
          create: (context) => getIt<HomeCubit>(),
        ),
      ],
      child: Container(
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
                                        child: const CircularProgressIndicator(
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
                                                widget.pickUpLocationController
                                                    .clear();
                                                setState(() {
                                                  _pickUpPredictions = [];
                                                });
                                              },
                                              child: Container(
                                                decoration: ShapeDecoration(
                                                  color: const Color(
                                                    0xFFE61D2A,
                                                  ),
                                                  shape: RoundedRectangleBorder(
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
                                      borderRadius: BorderRadius.circular(7)),
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
                if (_showResults)
                  SizeTransition(
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
                        else if (_pickUpPredictions.isNotEmpty ||
                            _destinationPredictions.isNotEmpty) ...[
                          if (_pickUpPredictions.isNotEmpty) ...[
                            ..._pickUpPredictions.map((prediction) {
                              return Builder(
                                builder: (context) {
                                  return buildPredictionList(
                                    context,
                                    getIconData(prediction.iconType),
                                    prediction,
                                  );
                                },
                              );
                            }),
                          ] else if (_destinationPredictions.isNotEmpty) ...[
                            ..._destinationPredictions.map((prediction) {
                              return buildPredictionList(
                                context,
                                getIconData(prediction.iconType),
                                prediction,
                              );
                            }),
                          ],
                        ] else if (_recentLocations.isNotEmpty) ...[
                          ..._recentLocations
                              .map((e) => buildRecentLocation(context, e)),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPredictionList(
      BuildContext context, IconData iconData, PlacePrediction prediction) {
    return GestureDetector(
      onTap: () async {
        await _handlePickUpSelection(prediction);
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Column(
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
      ),
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
