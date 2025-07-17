import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freedom/feature/home/cubit/home_cubit.dart';
import 'package:freedom/feature/home/repository/models/place_prediction.dart';
import 'package:freedom/feature/home/repository/models/location.dart';
import 'package:freedom/feature/home/use_cases/clear_recent_location.dart';
import 'package:freedom/feature/home/use_cases/get_place_detail.dart';
import 'package:freedom/feature/home/use_cases/get_place_prediction.dart';
import 'package:freedom/feature/home/use_cases/get_recent_locations.dart';
import 'package:freedom/feature/home/use_cases/get_saved_location.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  static const routeName = '/welcome';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 33),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const VSpace(164),
            Text(
              'Welcome to GoFreedom',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 35.80,
                fontWeight: FontWeight.w500,
              ),
            ),
            const VSpace(10),
            Text(
              'We are customising your Experience',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
            ),
            const VSpace(58),
            SvgPicture.asset('assets/images/location_icon.svg'),
          ],
        ),
      ),
    );
  }
}

class SmartPickupLocationWidget extends StatefulWidget {
  const SmartPickupLocationWidget({
    required this.state,
    required this.hintText,
    required this.iconPath,
    required this.iconBaseColor,
    required this.isPickUpLocation,
    required this.isInitialDestinationField,
    required this.onLocationSelected,
    required this.getPlacePredictions,
    required this.getPlaceDetails,
    required this.getSavedLocations,
    required this.getRecentLocations,
    required this.clearRecentLocations,
    super.key,
    this.initialText,
    this.showSavedLocations = true,
  });

  final HomeState state;
  final String hintText;
  final String iconPath;
  final Color iconBaseColor;
  final bool isPickUpLocation;
  final bool isInitialDestinationField;
  final String? initialText;
  final bool showSavedLocations;
  final void Function(FreedomLocation) onLocationSelected;
  final GetPlacePredictions getPlacePredictions;
  final GetPlaceDetails getPlaceDetails;
  final GetSavedLocations getSavedLocations;
  final GetRecentLocations getRecentLocations;
  final ClearRecentLocations clearRecentLocations;

  @override
  _SmartPickupLocationWidgetState createState() =>
      _SmartPickupLocationWidgetState();
}

class _SmartPickupLocationWidgetState extends State<SmartPickupLocationWidget>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<PlacePrediction> _predictions = [];
  List<FreedomLocation> _savedLocations = [];
  List<FreedomLocation> _recentLocations = [];

  bool _isLoading = false;
  bool _showResults = false;

  late AnimationController _animationController;
  late Animation<double> _animation;

  // Debounce timer for search
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    // Set up animation for results panel
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Set initial text if provided
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _searchController.text = widget.initialText!;
    }

    // Load saved and recent locations
    _loadLocations();

    // Listen for focus changes
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _showResults = true;
        });
        _animationController.forward();
      } else {
        _animationController.reverse().then((_) {
          setState(() {
            _showResults = false;
          });
        });
      }
    });

    // Listen for text changes to update suggestions
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _focusNode.dispose();
    _animationController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Load user's saved and recent locations
  Future<void> _loadLocations() async {
    try {
      final savedLocations = await widget.getSavedLocations();
      final recentLocations = await widget.getRecentLocations();

      if (mounted) {
        setState(() {
          _savedLocations = savedLocations;
          _recentLocations = recentLocations;
        });
      }
    } catch (e) {
      print('Error loading locations: $e');
    }
  }

  // Called when search text changes with debounce
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchPredictions(_searchController.text);
    });
  }

  // Fetch predictions from the API
  Future<void> _fetchPredictions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _predictions = [];
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
          _predictions = predictions;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching predictions: $e');
      if (mounted) {
        setState(() {
          _predictions = [];
          _isLoading = false;
        });
      }
    }
  }

  // Handle selection of a place from predictions
  void _selectPlace(PlacePrediction prediction) async {
    // Clear focus and close suggestions
    _focusNode.unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      // Get place details
      final locationDetails = await widget.getPlaceDetails(prediction.placeId);

      if (locationDetails != null && mounted) {
        // Update text field with selected location
        _searchController.text = locationDetails.name;

        // Notify parent
        widget.onLocationSelected(locationDetails);

        // Refresh location lists
        _loadLocations();
      }
    } catch (e) {
      print('Error selecting place: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Handle selection of a saved or recent location
  void _selectSavedLocation(FreedomLocation location) async {
    // Clear focus and close suggestions
    _focusNode.unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      // Get fresh place details
      final locationDetails = await widget.getPlaceDetails(location.placeId);

      if (locationDetails != null && mounted) {
        // Update text field with selected location
        _searchController.text = locationDetails.name;

        // Notify parent
        widget.onLocationSelected(locationDetails);

        // Refresh location lists
        await _loadLocations();
      }
    } catch (e) {
      print('Error selecting saved location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Clear recent locations history
  Future<void> _clearRecentLocations() async {
    try {
      await widget.clearRecentLocations();
      await _loadLocations();
    } catch (e) {
      print('Error clearing recent locations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HSpace(8),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    cursorColor: Colors.black,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: textFieldFillColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(6),
                        ),
                        borderSide: BorderSide(color: textFieldFillColor),
                      ),
                      hintText: widget.hintText,
                      hintStyle: const TextStyle(
                        fontSize: 10.13,
                        color: Color(0xFFBEBCBC),
                        fontWeight: FontWeight.w500,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: thickFillColor),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(6),
                        ),
                      ),
                      // Suffix icon (delete button for non-pickup locations)
                      suffixIcon:
                          widget.isPickUpLocation ||
                                  widget.isInitialDestinationField
                              ? _isLoading
                                  ? Container(
                                    width: 24,
                                    height: 24,
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        widget.iconBaseColor,
                                      ),
                                    ),
                                  )
                                  : _searchController.text.isNotEmpty
                                  ? Padding(
                                    padding: const EdgeInsets.only(
                                      top: 12,
                                      bottom: 12,
                                      left: 15.5,
                                      right: 7,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                        setState(() {
                                          _predictions = [];
                                        });
                                      },
                                      child: Container(
                                        decoration: ShapeDecoration(
                                          color: const Color(0xFFE61D2A),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              7,
                                            ),
                                          ),
                                        ),
                                        child: Icon(
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
                                    context
                                        .read<HomeCubit>()
                                        .removeLastDestination();
                                  },
                                  child: Container(
                                    decoration: ShapeDecoration(
                                      color: const Color(0xFFE61D2A),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                    ),
                                    child: SvgPicture.asset(
                                      'assets/images/delete_field.svg',
                                    ),
                                  ),
                                ),
                              ),
                      // Prefix icon (location icon)
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(
                          top: 6,
                          left: 5,
                          bottom: 7,
                          right: 10.8,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: widget.iconBaseColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: SvgPicture.asset(widget.iconPath),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Results panel
        if (_showResults)
          SizeTransition(
            sizeFactor: _animation,
            child: Container(
              margin: EdgeInsets.only(top: 4, left: 8, right: 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Saved locations section
                    if (widget.showSavedLocations &&
                        _savedLocations.isNotEmpty) ...[
                      _buildSectionHeader("Saved Places"),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _savedLocations.length,
                        itemBuilder: (context, index) {
                          final location = _savedLocations[index];
                          return _buildLocationItem(
                            iconData: Icons.star,
                            title: location.name,
                            subtitle: location.address,
                            onTap: () => _selectSavedLocation(location),
                          );
                        },
                      ),
                      const Divider(height: 1),
                    ],

                    // Recent locations section
                    if (_recentLocations.isNotEmpty &&
                        _searchController.text.isEmpty) ...[
                      _buildSectionHeader("Recent Searches"),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _recentLocations.length,
                        itemBuilder: (context, index) {
                          final location = _recentLocations[index];
                          return _buildLocationItem(
                            iconData: Icons.history,
                            title: location.name,
                            subtitle: location.address,
                            onTap: () => _selectSavedLocation(location),
                          );
                        },
                      ),
                      const Divider(height: 1),
                    ],

                    // Prediction results section
                    if (_predictions.isNotEmpty) ...[
                      _buildSectionHeader("Suggestions"),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _predictions.length,
                        itemBuilder: (context, index) {
                          final prediction = _predictions[index];

                          // Get icon based on the place type
                          IconData iconData;
                          switch (prediction.iconType) {
                            case 'local_airport':
                              iconData = Icons.local_airport;
                              break;
                            case 'train':
                              iconData = Icons.train;
                              break;
                            case 'hotel':
                              iconData = Icons.hotel;
                              break;
                            case 'restaurant':
                              iconData = Icons.restaurant;
                              break;
                            case 'shopping_cart':
                              iconData = Icons.shopping_cart;
                              break;
                            case 'local_hospital':
                              iconData = Icons.local_hospital;
                              break;
                            case 'home':
                              iconData = Icons.home;
                              break;
                            case 'work':
                              iconData = Icons.work;
                              break;
                            default:
                              iconData = Icons.location_on;
                          }

                          return _buildLocationItem(
                            iconData: iconData,
                            title: prediction.mainText,
                            subtitle: prediction.secondaryText,
                            onTap: () => _selectPlace(prediction),
                          );
                        },
                      ),
                    ],

                    // No results message
                    if (_predictions.isEmpty &&
                        _searchController.text.isNotEmpty &&
                        !_isLoading)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            "No results found",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

        // Add option to clear results
        if (_showResults &&
            _recentLocations.isNotEmpty &&
            _searchController.text.isEmpty)
          SizeTransition(
            sizeFactor: _animation,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0, right: 8.0),
                child: TextButton(
                  onPressed: _clearRecentLocations,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size(60, 24),
                    foregroundColor: widget.iconBaseColor,
                    textStyle: TextStyle(fontSize: 10),
                  ),
                  child: Text("Clear History"),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Build section header widget
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 12.0,
        left: 16.0,
        right: 16.0,
        bottom: 4.0,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  // Build location item widget
  Widget _buildLocationItem({
    required IconData iconData,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: widget.iconBaseColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(iconData, color: widget.iconBaseColor, size: 16),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle:
          subtitle.isNotEmpty
              ? Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
              : null,
      onTap: onTap,
    );
  }
}

class DestinationLocationFieldWidget extends StatelessWidget {
  const DestinationLocationFieldWidget({
    required this.state,
    required this.destinationController,
    required this.hintText,
    required this.iconPath,
    required this.iconBaseColor,
    required this.isPickUpLocation,
    required this.isInitialDestinationField,
    super.key,
  });

  final HomeState state;
  final TextEditingController? destinationController;
  final String hintText;
  final String iconPath;
  final Color iconBaseColor;
  final bool isPickUpLocation;
  final bool isInitialDestinationField;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HSpace(8),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              TextField(
                controller: destinationController,
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: textFieldFillColor,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                    borderSide: BorderSide(color: textFieldFillColor),
                  ),
                  hintText: hintText,
                  hintStyle: const TextStyle(
                    fontSize: 10.13,
                    color: Color(0xFFBEBCBC),
                    fontWeight: FontWeight.w500,
                  ),
                  suffixIcon:
                      isPickUpLocation || isInitialDestinationField
                          ? null
                          : Padding(
                            padding: const EdgeInsets.only(
                              top: 12,
                              bottom: 12,
                              left: 15.5,
                              right: 7,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                context
                                    .read<HomeCubit>()
                                    .removeLastDestination();
                              },
                              child: Container(
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFE61D2A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                                child: SvgPicture.asset(
                                  'assets/images/delete_field.svg',
                                ),
                              ),
                            ),
                          ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(
                      top: 6,
                      left: 5,
                      bottom: 7,
                      right: 10.8,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: iconBaseColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: SvgPicture.asset(iconPath),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: thickFillColor),
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
