import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:freedom/feature/home/cubit/home_cubit.dart';
import 'package:freedom/feature/home/repository/models/location.dart';
import 'package:freedom/feature/home/repository/models/place_prediction.dart';
import 'package:freedom/feature/home/use_cases/clear_recent_location.dart';
import 'package:freedom/feature/home/use_cases/get_place_detail.dart';
import 'package:freedom/feature/home/use_cases/get_place_prediction.dart';
import 'package:freedom/feature/home/use_cases/get_recent_locations.dart';
import 'package:freedom/feature/home/use_cases/get_saved_location.dart';
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
  BitmapDescriptor? bikeIcon;
  final FocusNode _pickUpNode = FocusNode();
  final FocusNode _destinationNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _animation;

  List<FocusNode> _destinationNodes = [];
  int _activeDestinationIndex = 0;
  int get activeDestinationIndex => _activeDestinationIndex;

  final Map<TextEditingController, VoidCallback> _destinationListeners = {};
  late final HomeCubit _homeCubit;

  @override
  void initState() {
    super.initState();
    _loadLiveLocation();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();

    _loadLocations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateDestinationFocusNodes(
          context.read<HomeCubit>().state.locations.length);

      // Set up listeners for additional destination controllers
      _setupAdditionalDestinationListeners();

      context.read<HomeCubit>()
        ..createMotorcycleIcon()
        ..showRecentPickUpLocations(showRecentlySearchedLocations: true)
        ..clearPredictions()
        ..isPickUpLocation(isPickUpLocation: true);
    });

    widget.pickUpLocationController.addListener(_onSearchChangedPickup);
    widget.destinationController.addListener(_onSearchChangedDestination);

    pickNodeFocusListener();
    destinationNodeFocusListener();
  }

  void _setupAdditionalDestinationListeners() {
    // Clear existing listeners first
    _destinationListeners
      ..forEach((controller, listener) {
        controller.removeListener(listener);
      })
      ..clear();

    // Set up listeners for each destination controller
    for (var i = 0; i < widget.destinationControllers.length; i++) {
      final controller = widget.destinationControllers[i];
      final index = i +
          1; // Index offset by 1 because first destination uses destinationController

      void listener() {
        _onSearchChangedAdditionalDestination(controller, index);
      }

      controller.addListener(listener);
      _destinationListeners[controller] = listener;
    }
  }

  void _onSearchChangedAdditionalDestination(
      TextEditingController controller, int index) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final cubit = context.read<HomeCubit>();

    // Set active destination index
    _activeDestinationIndex = index;
    cubit
      ..setActiveDestinationIndex(index)

      // Update destination location state
      ..isDestinationLocation(isDestinationLocation: true)
      ..isPickUpLocation(isPickUpLocation: false);

    if (controller.text.isEmpty) {
      cubit
        ..clearPredictions()
        ..showDestinationRecentlySearchedLocations(
          showDestinationRecentlySearchedLocations: true,
        );
    } else {
      _debounce = Timer(const Duration(milliseconds: 300), () {
        setState(() {
          _isLoading = true;
        });

        cubit.fetchPredictions(controller.text).then((_) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });
      });
    }
  }

  @override
  void dispose() {
    widget.pickUpLocationController.removeListener(_onSearchChangedPickup);
    widget.destinationController.removeListener(_onSearchChangedDestination);
    _pickUpNode.dispose();
    _destinationNode.dispose();
    _debounce?.cancel();
    for (final node in _destinationNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _updateDestinationFocusNodes(int count) {
    // Remove listeners from existing nodes first
    for (var node in _destinationNodes) {
      node.removeListener(() {});
    }

    // Create new nodes if needed
    while (_destinationNodes.length < count) {
      final node = FocusNode();
      final index = _destinationNodes.length + 1; // Index offset by 1

      node.addListener(() {
        if (node.hasFocus) {
          final cubit = context.read<HomeCubit>();
          _activeDestinationIndex = index;
          cubit
            ..isDestinationLocation(isDestinationLocation: true)
            ..isPickUpLocation(isPickUpLocation: false)
            ..setActiveDestinationIndex(index)
            ..showDestinationRecentlySearchedLocations(
              showDestinationRecentlySearchedLocations: true,
            );
        }
      });

      _destinationNodes.add(node);
    }

    while (_destinationNodes.length > count) {
      _destinationNodes.removeLast().dispose();
    }
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
      } else {
        cubit.isDestinationLocation(isDestinationLocation: false);
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
          ..showRecentPickUpLocations(showRecentlySearchedLocations: true);
      } else {
        cubit.isPickUpLocation(isPickUpLocation: false);
      }
    });
  }

  void _onSearchChangedPickup() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final cubit = context.read<HomeCubit>()
      ..isPickUpLocation(isPickUpLocation: true);

    if (widget.pickUpLocationController.text.isEmpty) {
      cubit
        ..clearPredictions()
        ..showRecentPickUpLocations(showRecentlySearchedLocations: true);
    } else {
      _debounce = Timer(const Duration(milliseconds: 300), () {
        setState(() {
          _isLoading = true;
        });

        cubit.fetchPredictions(widget.pickUpLocationController.text).then((_) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });
      });
    }
  }

  void _onSearchChangedDestination() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final cubit = context.read<HomeCubit>()
      ..isDestinationLocation(isDestinationLocation: true);

    if (widget.destinationController.text.isEmpty) {
      cubit
        ..clearPredictions()
        ..showDestinationRecentlySearchedLocations(
          showDestinationRecentlySearchedLocations: true,
        );
    } else {
      _debounce = Timer(const Duration(milliseconds: 300), () {
        setState(() {
          _isLoading = true;
        });

        cubit.fetchPredictions(widget.destinationController.text).then((_) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });
      });
    }
  }

  Future<void> _loadLocations() async {
    try {
      await context.read<HomeCubit>().fetchRecentLocations();
    } catch (e) {
      debugPrint('Error loading locations: $e');
    }
  }

  Future<void> _loadLiveLocation() async {
    try {
      _homeCubit = context.read<HomeCubit>();
      if (_homeCubit.state.currentLocation != null) {
        widget.pickUpLocationController.text =
            _homeCubit.state.userAddress ?? '';
        widget.destinationController.text = '';
        _pickUpNode.requestFocus();
      }
    } catch (e) {
      debugPrint('Error loading live location: $e');
    }
  }

  List<Widget> _buildDestinationFields(
      BuildContext context, List<String> destinations) {
    final widgets = <Widget>[];
    while (widget.destinationControllers.length < destinations.length) {
      widget.destinationControllers.add(TextEditingController());
    }
    _updateDestinationFocusNodes(destinations.length);
    widgets.add(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 12),
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
                    context.read<HomeCubit>().addDestination();

                    if (widget.destinationControllers.length <=
                        context.read<HomeCubit>().state.locations.length) {
                      widget.destinationControllers
                          .add(TextEditingController());
                      _updateDestinationFocusNodes(
                          context.read<HomeCubit>().state.locations.length);
                      _setupAdditionalDestinationListeners();
                    }
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
          TextFieldFactory.location(
            controller: widget.destinationController,
            fillColor: textFieldFillColor,
            focusNode: _destinationNode,
            hinText: 'Enter Destination',
            suffixIcon: widget.destinationController.text.isNotEmpty
                ? ClearFieldAndResetState(
                    widget: widget, state: _SearchSheetState())
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
          ),
        ],
      ),
    );

    // Add additional destination fields
    for (var i = 1; i < destinations.length; i++) {
      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const VSpace(10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    'Destination ${i + 1}',
                    style: const TextStyle(
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
                      context.read<HomeCubit>().removeLastDestination();

                      if (widget.destinationControllers.length > 1) {
                        widget.destinationControllers.removeLast().dispose();
                        _updateDestinationFocusNodes(
                            context.read<HomeCubit>().state.locations.length);
                        _setupAdditionalDestinationListeners();
                      }
                    },
                    child: Container(
                      width: 23,
                      height: 23,
                      decoration: ShapeDecoration(
                        color: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.remove,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const VSpace(3),
            TextFieldFactory.location(
              controller: widget.destinationControllers[i -
                  1], // Adjust index because first destination uses destinationController
              fillColor: textFieldFillColor,
              focusNode: _destinationNodes[i - 1],
              hinText: 'Enter Destination ${i + 1}',
              suffixIcon: widget.destinationControllers[i - 1].text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        widget.destinationControllers[i - 1].clear();
                        context.read<HomeCubit>().clearPredictions();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: ShapeDecoration(
                          color: const Color(0xFFE61D2A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
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
            ),
          ],
        ),
      );
    }

    return widgets;
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
                        const VSpace(3),
                        ..._buildDestinationFields(context, state.locations),
                      ],
                    ),
                  ),
                  const VSpace(19.65),
                  SizeTransition(
                    sizeFactor: _animation,
                    child: _buildResultsPanel(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultsPanel(BuildContext context) {
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
    final activeDestinationIndex =
        context.select((HomeCubit c) => c.activeDestinationIndex);

    final pickupText = widget.pickUpLocationController.text;
    final destinationText = activeDestinationIndex == 0
        ? widget.destinationController.text
        : (activeDestinationIndex - 1 < widget.destinationControllers.length
            ? widget.destinationControllers[activeDestinationIndex - 1].text
            : '');

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (_isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (isPickUpLocation && pickupText.isNotEmpty) {
          if (pickUpPredictions.isNotEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...pickUpPredictions.map((prediction) {
                  return GestureDetector(
                    onTap: () async {
                      await context.read<HomeCubit>().handlePickUpLocation(
                            prediction,
                            _pickUpNode,
                            _destinationNode,
                            widget.pickUpLocationController,
                            widget.destinationController,
                          );
                    },
                    child: buildPredictionList(
                      context,
                      getIconData(prediction.iconType),
                      prediction,
                    ),
                  );
                }),
              ],
            );
          } else {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No results found',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            );
          }
        } else if (isDestinationLocation && destinationText.isNotEmpty) {
          if (destinationPredictions.isNotEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 8),
                  child: Text(
                    'Search Results for Destination ${activeDestinationIndex > 0 ? activeDestinationIndex + 1 : ""}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ...destinationPredictions.map((destination) {
                  return GestureDetector(
                    onTap: () async {
                      // Handle click based on active destination index
                      if (activeDestinationIndex == 0) {
                        // Original destination field
                        await context
                            .read<HomeCubit>()
                            .handleDestinationLocation(
                              destination,
                              _destinationNode,
                              widget.destinationController,
                            );
                      } else {
                        // Additional destination field
                        final index = activeDestinationIndex - 1;
                        if (index < widget.destinationControllers.length) {
                          await context
                              .read<HomeCubit>()
                              .handleAdditionalDestinationLocation(
                                destination,
                                _destinationNodes[index],
                                widget.destinationControllers[index],
                                activeDestinationIndex,
                              );
                        }
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
            );
          } else {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No results found',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            );
          }
        } else {
          if (recentLocations.isNotEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 8),
                  child: Text(
                    'Recent Searches',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ...recentLocations.map((e) {
                  dev.log('Recent Location: ${e.name}, ${e.address}');
                  return GestureDetector(
                    onTap: () async {
                      await context.read<HomeCubit>().handleRecentLocation(
                            e,
                            _destinationNode,
                            widget.destinationController,
                          );
                    },
                    child: buildRecentLocation(context, e),
                  );
                }),
              ],
            );
          } else {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No recent searches',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            );
          }
        }
      },
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

  Column buildRecentLocation(BuildContext context, FreedomLocation recent) {
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  recent.address,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
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
    this.state,
    super.key,
  });

  final SearchSheet widget;
  final _SearchSheetState? state;
  @override
  Widget build(BuildContext context) {
    final isPickUp = context.select(
      (HomeCubit cubit) => cubit.state.isPickUpLocation,
    );
    return Padding(
      padding: const EdgeInsets.only(
        top: 12,
        bottom: 12,
        left: 15.5,
        right: 7,
      ),
      child: GestureDetector(
        onTap: () {
          if (widget.pickUpLocationController.text.isNotEmpty && isPickUp) {
            dev.log('I have focus');
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
