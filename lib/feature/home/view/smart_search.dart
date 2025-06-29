import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freedom/feature/home/repository/models/place_prediction.dart';
import 'package:freedom/feature/home/repository/models/location.dart';
import 'package:freedom/feature/home/use_cases/clear_recent_location.dart';
import 'package:freedom/feature/home/use_cases/get_place_detail.dart';
import 'package:freedom/feature/home/use_cases/get_place_prediction.dart';
import 'package:freedom/feature/home/use_cases/get_recent_locations.dart';
import 'package:freedom/feature/home/use_cases/get_saved_location.dart';

class SmartLocationSearch extends StatefulWidget {
  const SmartLocationSearch({
    required this.hint,
    required this.onLocationSelected,
    required this.getPlacePredictions,
    required this.getPlaceDetails,
    required this.getSavedLocations,
    required this.getRecentLocations,
    required this.clearRecentLocations,
    super.key,
    this.showSavedLocations = true,
    this.initialText,
  });
  final String hint;
  final void Function(Location) onLocationSelected;
  final bool showSavedLocations;
  final String? initialText;
  final GetPlacePredictions getPlacePredictions;
  final GetPlaceDetails getPlaceDetails;
  final GetSavedLocations getSavedLocations;
  final GetRecentLocations getRecentLocations;
  final ClearRecentLocations clearRecentLocations;

  @override
  _SmartLocationSearchState createState() => _SmartLocationSearchState();
}

class _SmartLocationSearchState extends State<SmartLocationSearch>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<PlacePrediction> _predictions = [];
  List<Location> _savedLocations = [];
  List<Location> _recentLocations = [];

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
      duration: const Duration(milliseconds: 300),
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

  // Load user's saved and recent locations using repository
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

  // Fetch predictions from repository
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
      // Get place details using the repository
      final locationDetails = await widget.getPlaceDetails(prediction.placeId);

      if (locationDetails != null && mounted) {
        // Update text field with selected location
        _searchController.text = locationDetails.name;

        // Notify parent
        widget.onLocationSelected(locationDetails);

        // Refresh location lists
        await _loadLocations();
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
  void _selectSavedLocation(Location location) async {
    // Clear focus and close suggestions
    _focusNode.unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      // Get fresh place details from repository
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
        // Search TextField
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isLoading
                  ? Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(6),
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _predictions = [];
                            });
                          },
                        )
                      : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            ),
            onTap: () {
              setState(() {
                _showResults = true;
              });
              _animationController.forward();
            },
          ),
        ),

        // Results panel
        if (_showResults)
          SizeTransition(
            sizeFactor: _animation,
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
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
                        physics: const NeverScrollableScrollPhysics(),
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
                    ],

                    // Recent locations section
                    if (_recentLocations.isNotEmpty &&
                        _searchController.text.isEmpty) ...[
                      _buildSectionHeader("Recent Searches"),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
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
                    ],

                    // Prediction results section
                    if (_predictions.isNotEmpty) ...[
                      _buildSectionHeader("Suggestions"),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
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
                              fontSize: 16,
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
                padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                child: TextButton(
                  onPressed: _clearRecentLocations,
                  child: const Text("Clear History"),
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
          top: 16.0, left: 16.0, right: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
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
      leading: Icon(
        iconData,
        color: Colors.grey[700],
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      dense: true,
      onTap: onTap,
    );
  }
}
