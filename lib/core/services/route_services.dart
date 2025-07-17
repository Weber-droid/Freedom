import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:freedom/feature/home/repository/models/location.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteService {
  static const double _earthRadius = 6371000;
  static const double _defaultSpeedMetersPerSecond = 5.0;
  static const int _defaultUpdateIntervalMs = 100;

  /// Gets a route between two locations
  Future<RouteResult> getRoute(
    LatLng startLocation,
    LatLng endLocation, {
    TravelMode mode = TravelMode.driving,
    String? polylineId,
  }) async {
    log('Getting route from $startLocation to $endLocation');
    try {
      final routeCoordinates = <LatLng>[];
      final polylineIdValue = polylineId ?? 'route';
      final polylineIdObj = PolylineId(polylineIdValue);
      final polylinePoints = PolylinePoints();
      log('Directions key: ${dotenv.env['DIRECTIONS_API_KEY']}');
      final result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: dotenv.env['DIRECTIONS_API_KEY'],
        request: PolylineRequest(
          origin: PointLatLng(startLocation.latitude, startLocation.longitude),
          destination: PointLatLng(endLocation.latitude, endLocation.longitude),
          mode: mode,
        ),
      );

      if (result.points.isEmpty) {
        return RouteResult.failure('No route found');
      }

      // Convert points to LatLng
      for (final point in result.points) {
        routeCoordinates.add(LatLng(point.latitude, point.longitude));
      }

      // Create polyline
      final polyline = Polyline(
        polylineId: polylineIdObj,
        color: Colors.orange,
        points: routeCoordinates,
        width: 5,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      );

      // Create interpolated points for smooth animation
      final interpolatedPoints = interpolatePoints(routeCoordinates, 5);

      return RouteResult.success(
        polyline: polyline,
        routePoints: routeCoordinates,
        interpolatedPoints: interpolatedPoints,
      );
    } catch (e) {
      return RouteResult.failure('Failed to get route: $e');
    }
  }

  Future<MultipleRoutesResult> getRoutesForMultipleDestinations(
    LatLng startLocation,
    List<LatLng> destinationLocations, {
    TravelMode mode = TravelMode.driving,
  }) async {
    if (destinationLocations.isEmpty) {
      return MultipleRoutesResult.failure('No destinations provided');
    }

    try {
      final routes = <Polyline>{};
      final routeSegments = <RouteSegment>[];
      var currentStartLocation = startLocation;

      // Process each destination one by one
      for (var i = 0; i < destinationLocations.length; i++) {
        final endLocation = destinationLocations[i];

        final routeResult = await getRoute(
          currentStartLocation,
          endLocation,
          mode: mode,
          polylineId: 'route_$i',
        );

        if (!routeResult.isSuccess) {
          return MultipleRoutesResult.failure(
            'Failed to get route for segment $i: ${routeResult.errorMessage}',
          );
        }

        // Customize polyline color for each segment
        final customPolyline = routeResult.polyline!.copyWith(
          colorParam: getRouteColor(i),
        );

        routes.add(customPolyline);
        routeSegments.add(
          RouteSegment(
            startLocation: currentStartLocation,
            endLocation: endLocation,
            polyline: customPolyline,
            routePoints: routeResult.routePoints!,
            segmentIndex: i,
          ),
        );

        currentStartLocation = endLocation;
      }

      return MultipleRoutesResult.success(
        polylines: routes,
        routeSegments: routeSegments,
      );
    } catch (e) {
      return MultipleRoutesResult.failure('Failed to get routes: $e');
    }
  }

  /// Creates markers for multiple locations
  Map<MarkerId, Marker> createMarkersForMultipleLocations(
    List<FreedomLocation> locations,
    BitmapDescriptor? pickupIcon,
  ) {
    final markersMap = <MarkerId, Marker>{};

    if (locations.isEmpty) return markersMap;

    // Add pickup marker
    if (pickupIcon != null) {
      const pickupMarkerId = MarkerId('pickup');
      markersMap[pickupMarkerId] = Marker(
        markerId: pickupMarkerId,
        position: LatLng(locations.first.latitude, locations.first.longitude),
        infoWindow: InfoWindow(title: 'Pickup', snippet: locations.first.name),
        icon: pickupIcon,
        anchor: const Offset(0.5, 0.5),
      );
    }

    // Add destination markers
    for (var i = 1; i < locations.length; i++) {
      final location = locations[i];
      final markerId = MarkerId('destination_${i - 1}');

      markersMap[markerId] = Marker(
        markerId: markerId,
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(title: 'Destination $i', snippet: location.name),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          i == locations.length - 1
              ? BitmapDescriptor.hueRed
              : BitmapDescriptor.hueAzure + (i * 30) % 360,
        ),
      );
    }

    return markersMap;
  }

  /// Creates markers for pickup and destination
  Map<MarkerId, Marker> createMarkers(
    FreedomLocation? pickUpLocation,
    FreedomLocation? destinationLocation,
    BitmapDescriptor? pickupIcon,
  ) {
    final markersMap = <MarkerId, Marker>{};

    if (pickUpLocation != null && pickupIcon != null) {
      const pickupMarkerId = MarkerId('pickup');
      markersMap[pickupMarkerId] = Marker(
        markerId: pickupMarkerId,
        position: LatLng(pickUpLocation.latitude, pickUpLocation.longitude),
        infoWindow: InfoWindow(title: 'Pickup', snippet: pickUpLocation.name),
        icon: pickupIcon,
        anchor: const Offset(0.5, 0.5),
      );
    }

    if (destinationLocation != null) {
      const destinationMarkerId = MarkerId('destination');
      markersMap[destinationMarkerId] = Marker(
        markerId: destinationMarkerId,
        position: LatLng(
          destinationLocation.latitude,
          destinationLocation.longitude,
        ),
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: destinationLocation.name,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
    }

    return markersMap;
  }

  /// Gets a color for route segments
  Color getRouteColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }

  /// Interpolates points between route coordinates for smooth animation
  List<LatLng> interpolatePoints(List<LatLng> points, int insertPointsCount) {
    final result = <LatLng>[];

    for (var i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];

      result.add(start);

      for (var j = 1; j <= insertPointsCount; j++) {
        final fraction = j / (insertPointsCount + 1);
        result.add(
          LatLng(
            start.latitude + (end.latitude - start.latitude) * fraction,
            start.longitude + (end.longitude - start.longitude) * fraction,
          ),
        );
      }
    }

    if (points.isNotEmpty) {
      result.add(points.last);
    }

    return result;
  }

  /// Calculates distance between two points using Haversine formula
  double calculateDistance(LatLng point1, LatLng point2) {
    final lat1Rad = point1.latitude * math.pi / 180;
    final lat2Rad = point2.latitude * math.pi / 180;
    final dLat = (point2.latitude - point1.latitude) * math.pi / 180;
    final dLng = (point2.longitude - point1.longitude) * math.pi / 180;

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return _earthRadius * c;
  }

  /// Calculates total distance for a route
  double calculateRouteDistance(List<LatLng> points) {
    var totalDistance = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      totalDistance += calculateDistance(points[i], points[i + 1]);
    }
    return totalDistance;
  }

  /// Calculates marker rotation based on direction
  double calculateMarkerRotation(LatLng currentPoint, LatLng previousPoint) {
    final dx = currentPoint.longitude - previousPoint.longitude;
    final dy = currentPoint.latitude - previousPoint.latitude;
    return math.atan2(dx, dy) * 180 / math.pi;
  }

  /// Calculates animation parameters
  AnimationParameters calculateAnimationParameters(
    List<LatLng> points, {
    double speedMetersPerSecond = _defaultSpeedMetersPerSecond,
    int updateIntervalMs = _defaultUpdateIntervalMs,
  }) {
    final totalDistance = calculateRouteDistance(points);
    final totalTimeSeconds = totalDistance / speedMetersPerSecond;
    final totalSteps = (totalTimeSeconds * 1000 / updateIntervalMs).ceil();

    return AnimationParameters(
      totalDistance: totalDistance,
      totalTimeSeconds: totalTimeSeconds,
      totalSteps: totalSteps,
      updateIntervalMs: updateIntervalMs,
    );
  }
}

/// Result class for single route operations
class RouteResult {
  const RouteResult._({
    required this.isSuccess,
    this.errorMessage,
    this.polyline,
    this.routePoints,
    this.interpolatedPoints,
  });

  factory RouteResult.success({
    required Polyline polyline,
    required List<LatLng> routePoints,
    required List<LatLng> interpolatedPoints,
  }) {
    return RouteResult._(
      isSuccess: true,
      polyline: polyline,
      routePoints: routePoints,
      interpolatedPoints: interpolatedPoints,
    );
  }

  factory RouteResult.failure(String errorMessage) {
    return RouteResult._(isSuccess: false, errorMessage: errorMessage);
  }
  final bool isSuccess;
  final String? errorMessage;
  final Polyline? polyline;
  final List<LatLng>? routePoints;
  final List<LatLng>? interpolatedPoints;
}

class MultipleRoutesResult {
  const MultipleRoutesResult._({
    required this.isSuccess,
    this.errorMessage,
    this.polylines,
    this.routeSegments,
  });

  factory MultipleRoutesResult.success({
    required Set<Polyline> polylines,
    required List<RouteSegment> routeSegments,
  }) {
    return MultipleRoutesResult._(
      isSuccess: true,
      polylines: polylines,
      routeSegments: routeSegments,
    );
  }

  factory MultipleRoutesResult.failure(String errorMessage) {
    return MultipleRoutesResult._(isSuccess: false, errorMessage: errorMessage);
  }
  final bool isSuccess;
  final String? errorMessage;
  final Set<Polyline>? polylines;
  final List<RouteSegment>? routeSegments;
}

/// Represents a segment of a route
class RouteSegment {
  const RouteSegment({
    required this.startLocation,
    required this.endLocation,
    required this.polyline,
    required this.routePoints,
    required this.segmentIndex,
  });
  final LatLng startLocation;
  final LatLng endLocation;
  final Polyline polyline;
  final List<LatLng> routePoints;
  final int segmentIndex;
}

/// Animation parameters for route animation
class AnimationParameters {
  const AnimationParameters({
    required this.totalDistance,
    required this.totalTimeSeconds,
    required this.totalSteps,
    required this.updateIntervalMs,
  });
  final double totalDistance;
  final double totalTimeSeconds;
  final int totalSteps;
  final int updateIntervalMs;
}
