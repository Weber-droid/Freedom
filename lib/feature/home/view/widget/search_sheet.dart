import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/home/cubit/home_cubit.dart';
import 'package:freedom/feature/location_search/cubit/map_search_cubit.dart';
import 'package:freedom/feature/location_search/repository/models/PlacePrediction.dart';
import 'package:freedom/feature/location_search/repository/models/location.dart';
import 'package:freedom/feature/location_search/use_cases/clear_recent_location.dart';
import 'package:freedom/feature/location_search/use_cases/get_place_detail.dart';
import 'package:freedom/feature/location_search/use_cases/get_place_prediction.dart';
import 'package:freedom/feature/location_search/use_cases/get_recent_locations.dart';
import 'package:freedom/feature/location_search/use_cases/get_saved_location.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:freedom/shared/widgets/text_field_factory.dart';
import 'package:google_fonts/google_fonts.dart';

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

    // Listen for text changes to update suggestions
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

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MapSearchCubit>(
          create: (context) => getIt<MapSearchCubit>(),
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
                      BlocBuilder<MapSearchCubit, MapSearchState>(
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
                      BlocBuilder<MapSearchCubit, MapSearchState>(
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
                // Conditionally show either search results or history list
                if (_showResults)
                  SizeTransition(
                    sizeFactor: _animation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_pickUpPredictions.isNotEmpty ||
                            _destinationPredictions.isNotEmpty) ...[
                          if (_pickUpPredictions.isNotEmpty) ...[
                            ..._pickUpPredictions.map((prediction) {
                              return buildPredictionList(
                                  getIconData(prediction.iconType), prediction);
                            }),
                          ] else if (_destinationPredictions.isNotEmpty) ...[
                            ..._destinationPredictions.map((prediction) {
                              return buildPredictionList(
                                  getIconData(prediction.iconType), prediction);
                            }),
                          ],
                        ] else if (_recentLocations.isNotEmpty) ...[
                          ..._recentLocations.map(buildRecentLocation),
                        ],
                      ],
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Column buildPredictionList(IconData iconData, PlacePrediction prediction) {
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

  Column buildRecentLocation(Location recent) {
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
