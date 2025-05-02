import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  bool isInitialDestinationField = false;
  bool _isLoading = false;
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
      context.read<HomeCubit>().createMotorcycleIcon();
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
      final cubit = context.read<HomeCubit>();
      if (_destinationNode.hasFocus) {
        cubit
          ..isDestinationLocation(isDestinationLocation: true)
          ..isPickUpLocation(isPickUpLocation: false)
          ..showDestinationRecentlySearchedLocations(
            showDestinationRecentlySearchedLocations: true,
          );
        _animationController.forward();
      } else {
        _animationController.reverse().then((_) {
          cubit
            ..isDestinationLocation(isDestinationLocation: false)
            ..isPickUpLocation(isPickUpLocation: false)
            ..showDestinationRecentlySearchedLocations(
              showDestinationRecentlySearchedLocations: false,
            );
        });
      }
    });
  }

  void pickNodeFocusListener() {
    final cubit = context.read<HomeCubit>();
    _pickUpNode.addListener(() {
      if (_pickUpNode.hasFocus) {
        cubit
          ..isPickUpLocation(isPickUpLocation: true)
          ..isDestinationLocation(isDestinationLocation: false)
          ..showRecentPickUpLocations(showRecentlySearchedLocations: true)
          ..showDestinationRecentlySearchedLocations(
            showDestinationRecentlySearchedLocations: false,
          );
        if (widget.pickUpLocationController.text.isEmpty) {
          cubit.showRecentPickUpLocations(showRecentlySearchedLocations: true);
        }

        _animationController.forward();
      } else {
        _animationController.reverse().then((_) {
          cubit
            ..isPickUpLocation(isPickUpLocation: false)
            ..isDestinationLocation(isDestinationLocation: false)
            ..showRecentPickUpLocations(showRecentlySearchedLocations: false);
        });
      }
    });
  }

  void _onSearchChangedPickup() {
    final cubit = context.read<HomeCubit>()
      ..isPickUpLocation(isPickUpLocation: true);
    if (widget.pickUpLocationController.text.isEmpty) {
      cubit
        ..clearPredictions()
        ..showRecentPickUpLocations(showRecentlySearchedLocations: true);
    } else {
      cubit.fetchPredictions(widget.pickUpLocationController.text);
    }
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
                              suffixIcon: context.select<HomeCubit, bool>(
                                (icon) => icon.state.isPickUpLocation,
                              )
                                  ? _isLoading
                                      ? const LoadingWidget()
                                      : widget.pickUpLocationController.text
                                              .isNotEmpty
                                          ? ClearFieldAndResetState(
                                              widget: widget,
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
                              controller: widget.destinationController,
                              fillColor: textFieldFillColor,
                              focusNode: _destinationNode,
                              hinText: 'Enter Destination',
                              suffixIcon:
                                  widget.destinationController.text.isNotEmpty
                                      ? ClearFieldAndResetState(
                                          widget: widget,
                                        )
                                      : null,
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
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  SizeTransition _buildRecentLocation(BuildContext context) {
    final isPickUpLocation = context
        .select<HomeCubit, bool>((cubit) => cubit.state.isPickUpLocation);
    final isDestinationLocation = context
        .select<HomeCubit, bool>((cubit) => cubit.state.isDestinationLocation);
    final pickUpPredictions =
        context.select((HomeCubit c) => c.state.pickUpPredictions);
    final destinationPredictions =
        context.select((HomeCubit c) => c.state.destinationPredictions);
    final recentLocations =
        context.select((HomeCubit c) => c.state.recentLocations);
    final pickupText = widget.pickUpLocationController.text;
    final destinationText = widget.destinationController.text;

    return SizeTransition(
      sizeFactor: _animation,
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return Column(
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
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pickUpPredictions.length,
                    itemBuilder: (context, index) {
                      final prediction = pickUpPredictions[index];
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
                  ),
                ] else if (isDestinationLocation &&
                    destinationPredictions.isNotEmpty) ...[
                  ...destinationPredictions.map((destination) {
                    return GestureDetector(
                      onTap: () async {
                        await context
                            .read<HomeCubit>()
                            .handleDestinationLocation(
                              destination,
                              _destinationNode,
                              widget.destinationController,
                            );
                        Navigator.of(context).pop();
                      },
                      child: buildPredictionList(
                        context,
                        getIconData(destination.iconType),
                        destination,
                      ),
                    );
                  }),
                ],
              ] else if (recentLocations.isNotEmpty &&
                  ((isPickUpLocation && pickupText.isEmpty) ||
                      (isDestinationLocation && destinationText.isEmpty))) ...[
                ...recentLocations.map((e) => buildRecentLocation(context, e)),
              ],
            ],
          );
        },
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

class ClearFieldAndResetState extends StatelessWidget {
  const ClearFieldAndResetState({
    required this.widget,
    super.key,
  });

  final SearchSheet widget;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 12,
        bottom: 12,
        left: 15.5,
        right: 7,
      ),
      child: GestureDetector(
        onTap: () {
          if (widget.pickUpLocationController.text.isNotEmpty) {
            widget.pickUpLocationController.clear();
            context.read<HomeCubit>().clearPredictions().then((_) {
              if (context.mounted) {
                context.read<HomeCubit>().showRecentPickUpLocations(
                      showRecentlySearchedLocations: true,
                    );
              }
            });
          } else if (widget.destinationController.text.isNotEmpty) {
            widget.destinationController.clear();
            context.read<HomeCubit>().clearPredictions().then((_) {
              if (context.mounted) {
                context
                    .read<HomeCubit>()
                    .showDestinationRecentlySearchedLocations(
                      showDestinationRecentlySearchedLocations: true,
                    );
              }
            });
          }
        },
        child: Container(
          decoration: ShapeDecoration(
            color: const Color(
              0xFFE61D2A,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
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
    );
  }
}

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      padding: const EdgeInsets.all(12),
      child: const CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          Colors.orange,
        ),
      ),
    );
  }
}
