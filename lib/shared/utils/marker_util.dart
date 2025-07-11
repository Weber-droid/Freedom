import 'package:flutter/animation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'dart:developer' as dev;
import 'dart:math' as math;

/// Utility class for precise marker management and coordinate handling
/// Inspired by the accuracy of the JavaScript implementation
class MarkerManagerUtility {
  static const String _driverMarkerId = 'driver_marker';
  static const String _pickupMarkerId = 'pickup_marker';
  static const String _dropoffMarkerId = 'dropoff_marker';

  // Animation and smoothing settings
  static const Duration _markerAnimationDuration = Duration(milliseconds: 300);
  static const double _coordinatePrecision = 6; // 6 decimal places
  static const double _markerAnchorX = 0.5;
  static const double _markerAnchorY = 0.5;

  /// Create or update driver marker with precise positioning
  static gmaps.Marker createDriverMarker({
    required gmaps.LatLng position,
    double bearing = 0.0,
    bool isMoving = false,
    String? customTitle,
  }) {
    // Ensure precise coordinate formatting
    final precisePosition = gmaps.LatLng(
      _roundToPrecision(position.latitude, _coordinatePrecision),
      _roundToPrecision(position.longitude, _coordinatePrecision),
    );

    dev.log(
      '🚗 Creating/updating driver marker at: '
      '${precisePosition.latitude.toStringAsFixed(6)}, '
      '${precisePosition.longitude.toStringAsFixed(6)} '
      '(bearing: ${bearing.toStringAsFixed(1)}°)',
    );

    return gmaps.Marker(
      markerId: const gmaps.MarkerId(_driverMarkerId),
      position: precisePosition,
      icon: _createDriverIcon(bearing, isMoving),
      infoWindow: gmaps.InfoWindow(
        title: customTitle ?? 'Driver - Live Location',
        snippet:
            'Speed: ${isMoving ? "Moving" : "Stationary"} | Bearing: ${bearing.toStringAsFixed(0)}°',
      ),
      anchor: Offset(_markerAnchorX, _markerAnchorY),
      flat: true, // Keeps marker flat against map for better rotation
      rotation: bearing,
    );
  }

  /// Create pickup location marker
  static gmaps.Marker createPickupMarker({
    required gmaps.LatLng position,
    String title = 'Pickup Location',
    String? snippet,
  }) {
    final precisePosition = gmaps.LatLng(
      _roundToPrecision(position.latitude, _coordinatePrecision),
      _roundToPrecision(position.longitude, _coordinatePrecision),
    );

    dev.log(
      '📍 Creating pickup marker at: ${_formatCoordinateForDisplay(precisePosition)}',
    );

    return gmaps.Marker(
      markerId: const gmaps.MarkerId(_pickupMarkerId),
      position: precisePosition,
      icon: _createPickupIcon(),
      infoWindow: gmaps.InfoWindow(
        title: title,
        snippet: snippet ?? 'Pickup point',
      ),
      anchor: const Offset(_markerAnchorX, _markerAnchorY),
    );
  }

  /// Create dropoff location marker
  static gmaps.Marker createDropoffMarker({
    required gmaps.LatLng position,
    String title = 'Dropoff Location',
    String? snippet,
  }) {
    final precisePosition = gmaps.LatLng(
      _roundToPrecision(position.latitude, _coordinatePrecision),
      _roundToPrecision(position.longitude, _coordinatePrecision),
    );

    dev.log(
      '🎯 Creating dropoff marker at: ${_formatCoordinateForDisplay(precisePosition)}',
    );

    return gmaps.Marker(
      markerId: const gmaps.MarkerId(_dropoffMarkerId),
      position: precisePosition,
      icon: _createDropoffIcon(),
      infoWindow: gmaps.InfoWindow(
        title: title,
        snippet: snippet ?? 'Destination',
      ),
      anchor: const Offset(_markerAnchorX, _markerAnchorY),
    );
  }

  /// Update marker set with new positions
  static Set<gmaps.Marker> updateMarkerSet({
    required Set<gmaps.Marker> currentMarkers,
    gmaps.LatLng? driverPosition,
    double driverBearing = 0.0,
    bool isDriverMoving = false,
    gmaps.LatLng? pickupPosition,
    gmaps.LatLng? dropoffPosition,
    String? pickupTitle,
    String? dropoffTitle,
  }) {
    final newMarkers = <gmaps.Marker>{};

    // Add driver marker if position provided
    if (driverPosition != null) {
      newMarkers.add(
        createDriverMarker(
          position: driverPosition,
          bearing: driverBearing,
          isMoving: isDriverMoving,
        ),
      );
    }

    // Add pickup marker if position provided
    if (pickupPosition != null) {
      newMarkers.add(
        createPickupMarker(
          position: pickupPosition,
          title: pickupTitle ?? 'Pickup Location',
        ),
      );
    }

    // Add dropoff marker if position provided
    if (dropoffPosition != null) {
      newMarkers.add(
        createDropoffMarker(
          position: dropoffPosition,
          title: dropoffTitle ?? 'Dropoff Location',
        ),
      );
    }

    dev.log('📌 Updated marker set with ${newMarkers.length} markers');
    return newMarkers;
  }

  /// Calculate map bounds to fit all markers with padding
  static gmaps.LatLngBounds calculateBoundsForMarkers({
    required List<gmaps.LatLng> positions,
    double paddingFactor = 0.1, // 10% padding
  }) {
    if (positions.isEmpty) {
      throw ArgumentError('Cannot calculate bounds for empty position list');
    }

    if (positions.length == 1) {
      // Single point - create small bounds around it
      final pos = positions.first;
      const offset = 0.001; // Small offset for single point
      return gmaps.LatLngBounds(
        southwest: gmaps.LatLng(pos.latitude - offset, pos.longitude - offset),
        northeast: gmaps.LatLng(pos.latitude + offset, pos.longitude + offset),
      );
    }

    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final pos in positions) {
      minLat = math.min(minLat, pos.latitude);
      maxLat = math.max(maxLat, pos.latitude);
      minLng = math.min(minLng, pos.longitude);
      maxLng = math.max(maxLng, pos.longitude);
    }

    // Add padding
    final latPadding = (maxLat - minLat) * paddingFactor;
    final lngPadding = (maxLng - minLng) * paddingFactor;

    return gmaps.LatLngBounds(
      southwest: gmaps.LatLng(minLat - latPadding, minLng - lngPadding),
      northeast: gmaps.LatLng(maxLat + latPadding, maxLng + lngPadding),
    );
  }

  /// Validate coordinate ranges (similar to JS implementation)
  static bool validateCoordinates(double latitude, double longitude) {
    if (latitude < -90 || latitude > 90) {
      dev.log('❌ Invalid latitude: $latitude (must be -90 to 90)');
      return false;
    }

    if (longitude < -180 || longitude > 180) {
      dev.log('❌ Invalid longitude: $longitude (must be -180 to 180)');
      return false;
    }

    return true;
  }

  /// Format coordinates for display (similar to JS coordinateUtils)
  static String formatCoordinateForDisplay(gmaps.LatLng position) {
    return _formatCoordinateForDisplay(position);
  }

  /// Create driver icon with direction indication
  static gmaps.BitmapDescriptor _createDriverIcon(
    double bearing,
    bool isMoving,
  ) {
    // You can customize this to use custom icons or create programmatic icons
    // For now, using default markers with different colors based on movement
    if (isMoving) {
      return gmaps.BitmapDescriptor.defaultMarkerWithHue(
        gmaps.BitmapDescriptor.hueBlue,
      );
    } else {
      return gmaps.BitmapDescriptor.defaultMarkerWithHue(
        gmaps.BitmapDescriptor.hueAzure,
      );
    }
  }

  /// Create pickup icon
  static gmaps.BitmapDescriptor _createPickupIcon() {
    return gmaps.BitmapDescriptor.defaultMarkerWithHue(
      gmaps.BitmapDescriptor.hueGreen,
    );
  }

  /// Create dropoff icon
  static gmaps.BitmapDescriptor _createDropoffIcon() {
    return gmaps.BitmapDescriptor.defaultMarkerWithHue(
      gmaps.BitmapDescriptor.hueRed,
    );
  }

  /// Round to specified decimal places
  static double _roundToPrecision(double value, double precision) {
    final factor = math.pow(10, precision);
    return (value * factor).round() / factor;
  }

  /// Format coordinate for display
  static String _formatCoordinateForDisplay(gmaps.LatLng position) {
    return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
  }

  /// Debug coordinate information (similar to JS debugCoordinates)
  static String debugCoordinates(double latitude, double longitude) {
    return 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)} '
        '${validateCoordinates(latitude, longitude) ? "✓" : "✗"}';
  }

  /// Calculate distance between markers for validation
  static double calculateDistanceBetweenMarkers(
    gmaps.LatLng pos1,
    gmaps.LatLng pos2,
  ) {
    const double earthRadius = 6371000; // Earth's radius in meters

    final lat1Rad = pos1.latitude * math.pi / 180;
    final lat2Rad = pos2.latitude * math.pi / 180;
    final dLat = (pos2.latitude - pos1.latitude) * math.pi / 180;
    final dLng = (pos2.longitude - pos1.longitude) * math.pi / 180;

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Get marker IDs for reference
  static List<String> get allMarkerIds => [
    _driverMarkerId,
    _pickupMarkerId,
    _dropoffMarkerId,
  ];

  static String get driverMarkerId => _driverMarkerId;
  static String get pickupMarkerId => _pickupMarkerId;
  static String get dropoffMarkerId => _dropoffMarkerId;
}

/// Extension for coordinate utilities (similar to JS coordinateUtils)
extension CoordinateUtilities on gmaps.LatLng {
  /// Convert to display format
  String toDisplayFormat() {
    return MarkerManagerUtility.formatCoordinateForDisplay(this);
  }

  /// Validate coordinates
  bool get isValid =>
      MarkerManagerUtility.validateCoordinates(latitude, longitude);

  /// Round to precision
  gmaps.LatLng roundToPrecision(int decimalPlaces) {
    final factor = math.pow(10, decimalPlaces);
    return gmaps.LatLng(
      (latitude * factor).round() / factor,
      (longitude * factor).round() / factor,
    );
  }

  /// Get debug string
  String get debugString =>
      MarkerManagerUtility.debugCoordinates(latitude, longitude);
}

/// Camera position utilities for smooth map updates
class CameraUtility {
  /// Create camera position for following driver
  static gmaps.CameraPosition createFollowDriverCamera({
    required gmaps.LatLng position,
    double bearing = 0.0,
    double zoom = 16.0,
    double tilt = 0.0,
  }) {
    return gmaps.CameraPosition(
      target: position.roundToPrecision(6),
      zoom: zoom,
      bearing: bearing,
      tilt: tilt,
    );
  }

  /// Create camera position to show all markers
  static gmaps.CameraPosition createShowAllMarkersCamera({
    required List<gmaps.LatLng> positions,
    double zoom = 14.0,
  }) {
    if (positions.isEmpty) {
      throw ArgumentError('Cannot create camera for empty position list');
    }

    if (positions.length == 1) {
      return gmaps.CameraPosition(
        target: positions.first.roundToPrecision(6),
        zoom: zoom,
      );
    }

    // Calculate center point
    double totalLat = 0.0;
    double totalLng = 0.0;

    for (final pos in positions) {
      totalLat += pos.latitude;
      totalLng += pos.longitude;
    }

    final centerLat = totalLat / positions.length;
    final centerLng = totalLng / positions.length;

    return gmaps.CameraPosition(
      target: gmaps.LatLng(centerLat, centerLng).roundToPrecision(6),
      zoom: zoom,
    );
  }

  /// Calculate appropriate zoom level for bounds
  static double calculateZoomForBounds(
    gmaps.LatLngBounds bounds, {
    double mapWidth = 400.0,
    double mapHeight = 400.0,
  }) {
    // Simple zoom calculation - can be enhanced based on screen size
    final latDiff =
        (bounds.northeast.latitude - bounds.southwest.latitude).abs();
    final lngDiff =
        (bounds.northeast.longitude - bounds.southwest.longitude).abs();

    final maxDiff = math.max(latDiff, lngDiff);

    if (maxDiff > 10) return 6;
    if (maxDiff > 5) return 8;
    if (maxDiff > 2) return 10;
    if (maxDiff > 1) return 12;
    if (maxDiff > 0.5) return 14;
    if (maxDiff > 0.1) return 16;
    return 18;
  }
}
