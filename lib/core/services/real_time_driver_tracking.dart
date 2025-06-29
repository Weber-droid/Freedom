import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:freedom/core/services/route_services.dart';
import 'package:freedom/di/locator.dart';

/// Real-time driver tracking service that handles live driver positions
/// and dynamic route updates during ride progress
class RealTimeDriverTrackingService {
  final RouteService _routeService = getIt<RouteService>();

  // Tracking state
  bool _isTracking = false;
  LatLng? _lastKnownDriverPosition;
  LatLng? _currentDestination;
  List<LatLng> _currentRoutePoints = [];
  DateTime? _lastPositionUpdate;

  // Route recalculation settings
  static const double _routeDeviationThresholdMeters =
      50.0; // 50 meters off route
  static const int _routeRecalculationCooldownSeconds =
      10; // Prevent spam recalculation
  DateTime? _lastRouteRecalculation;

  // Callbacks for UI updates
  void Function(LatLng position, double bearing)? onDriverPositionUpdate;
  void Function(List<LatLng> newRoute)? onRouteUpdate;
  void Function(String message)? onTrackingStatusUpdate;

  /// Initialize tracking for a ride in progress
  void startTracking({
    required LatLng destination,
    required void Function(LatLng position, double bearing) onPositionUpdate,
    required void Function(List<LatLng> newRoute) onRouteUpdated,
    void Function(String message)? onStatusUpdate,
  }) {
    dev.log('🔴 Starting real-time driver tracking');

    _isTracking = true;
    _currentDestination = destination;
    _lastKnownDriverPosition = null;
    _currentRoutePoints.clear();
    _lastRouteRecalculation = null;

    // Set callbacks
    onDriverPositionUpdate = onPositionUpdate;
    onRouteUpdate = onRouteUpdated;
    onTrackingStatusUpdate = onStatusUpdate;

    _notifyStatus('Real-time tracking started');
    dev.log('📍 Destination set: $destination');
  }

  /// Process incoming driver location from socket
  Future<void> processDriverLocation(Map<String, dynamic> locationData) async {
    if (!_isTracking) {
      dev.log('⚠️ Received location data but tracking is not active');
      return;
    }

    try {
      final driverLocation = _parseLocationData(locationData);
      if (driverLocation == null) return;

      dev.log('📍 Processing driver location: $driverLocation');

      // Update driver position
      await _updateDriverPosition(driverLocation, locationData);

      // Check if route recalculation is needed
      await _checkForRouteRecalculation(driverLocation);
    } catch (e) {
      dev.log('❌ Error processing driver location: $e');
    }
  }

  /// Parse location data from socket
  LatLng? _parseLocationData(Map<String, dynamic> data) {
    try {
      final latitude = data['latitude'] as double?;
      final longitude = data['longitude'] as double?;

      if (latitude == null || longitude == null) {
        dev.log('❌ Invalid location data: missing coordinates');
        return null;
      }

      return LatLng(latitude, longitude);
    } catch (e) {
      dev.log('❌ Error parsing location data: $e');
      return null;
    }
  }

  /// Update driver position and notify UI
  Future<void> _updateDriverPosition(
    LatLng position,
    Map<String, dynamic> data,
  ) async {
    final bearing = _calculateBearing(position, data);
    _lastKnownDriverPosition = position;
    _lastPositionUpdate = DateTime.now();

    // Calculate progress along route
    final progressInfo = _calculateRouteProgress(position);

    // Notify UI of position update
    onDriverPositionUpdate?.call(position, bearing);

    dev.log(
      '📍 Driver position updated: $position (bearing: ${bearing.toStringAsFixed(1)}°)',
    );

    if (progressInfo != null) {
      dev.log(
        '📊 Route progress: ${(progressInfo.progress * 100).toStringAsFixed(1)}%',
      );
    }
  }

  /// Calculate bearing from location data or movement
  double _calculateBearing(LatLng currentPosition, Map<String, dynamic> data) {
    // First try to get bearing from socket data
    final bearingFromData = data['bearing'] as double?;
    if (bearingFromData != null) {
      return bearingFromData;
    }

    // Calculate bearing from movement if we have previous position
    if (_lastKnownDriverPosition != null) {
      return _calculateBearingBetweenPoints(
        _lastKnownDriverPosition!,
        currentPosition,
      );
    }

    return 0.0; // Default bearing
  }

  /// Calculate bearing between two points
  double _calculateBearingBetweenPoints(LatLng start, LatLng end) {
    final lat1 = start.latitude * math.pi / 180;
    final lat2 = end.latitude * math.pi / 180;
    final dLng = (end.longitude - start.longitude) * math.pi / 180;

    final y = math.sin(dLng) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  /// Check if route recalculation is needed
  Future<void> _checkForRouteRecalculation(LatLng driverPosition) async {
    if (_currentDestination == null || _currentRoutePoints.isEmpty) {
      // No route exists, calculate initial route
      await _calculateNewRoute(driverPosition, _currentDestination!);
      return;
    }

    // Check if driver has deviated from route
    final distanceFromRoute = _calculateDistanceFromRoute(driverPosition);

    if (distanceFromRoute > _routeDeviationThresholdMeters) {
      dev.log(
        '🔄 Driver deviated ${distanceFromRoute.toStringAsFixed(1)}m from route',
      );

      // Check cooldown period to prevent spam recalculation
      if (_shouldRecalculateRoute()) {
        await _calculateNewRoute(driverPosition, _currentDestination!);
      }
    }
  }

  /// Calculate distance from current route
  double _calculateDistanceFromRoute(LatLng driverPosition) {
    if (_currentRoutePoints.isEmpty) return double.infinity;

    double minDistance = double.infinity;

    for (int i = 0; i < _currentRoutePoints.length - 1; i++) {
      final segmentDistance = _distanceToLineSegment(
        driverPosition,
        _currentRoutePoints[i],
        _currentRoutePoints[i + 1],
      );

      if (segmentDistance < minDistance) {
        minDistance = segmentDistance;
      }
    }

    return minDistance;
  }

  /// Calculate distance from point to line segment
  double _distanceToLineSegment(
    LatLng point,
    LatLng lineStart,
    LatLng lineEnd,
  ) {
    // Simplified distance calculation - in production, use proper geospatial calculation
    final A = point.latitude - lineStart.latitude;
    final B = point.longitude - lineStart.longitude;
    final C = lineEnd.latitude - lineStart.latitude;
    final D = lineEnd.longitude - lineStart.longitude;

    final dot = A * C + B * D;
    final lenSq = C * C + D * D;

    if (lenSq == 0) {
      // Line segment is a point
      return _calculateDistanceInMeters(point, lineStart);
    }

    final param = dot / lenSq;

    late LatLng closestPoint;
    if (param < 0) {
      closestPoint = lineStart;
    } else if (param > 1) {
      closestPoint = lineEnd;
    } else {
      closestPoint = LatLng(
        lineStart.latitude + param * C,
        lineStart.longitude + param * D,
      );
    }

    return _calculateDistanceInMeters(point, closestPoint);
  }

  /// Calculate distance between two points in meters
  double _calculateDistanceInMeters(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth's radius in meters

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

    return earthRadius * c;
  }

  /// Check if route should be recalculated (respecting cooldown)
  bool _shouldRecalculateRoute() {
    if (_lastRouteRecalculation == null) return true;

    final timeSinceLastRecalculation = DateTime.now().difference(
      _lastRouteRecalculation!,
    );
    return timeSinceLastRecalculation.inSeconds >=
        _routeRecalculationCooldownSeconds;
  }

  /// Calculate new route from driver position to destination
  Future<void> _calculateNewRoute(LatLng from, LatLng to) async {
    try {
      dev.log('🛣️ Calculating new route from $from to $to');
      _lastRouteRecalculation = DateTime.now();

      final routeResult = await _routeService.getRoute(from, to);

      if (routeResult.isSuccess && routeResult.polyline != null) {
        _currentRoutePoints = routeResult.polyline!.points;

        dev.log(
          '✅ New route calculated with ${_currentRoutePoints.length} points',
        );
        _notifyStatus('Route updated - ${_currentRoutePoints.length} points');

        // Notify UI of route update
        onRouteUpdate?.call(_currentRoutePoints);
      } else {
        dev.log('❌ Failed to calculate route: ${routeResult.errorMessage}');
        _notifyStatus('Route calculation failed');
      }
    } catch (e) {
      dev.log('❌ Error calculating route: $e');
      _notifyStatus('Route calculation error');
    }
  }

  /// Calculate progress along current route
  RouteProgress? _calculateRouteProgress(LatLng driverPosition) {
    if (_currentRoutePoints.isEmpty) return null;

    // Find closest point on route
    double minDistance = double.infinity;
    int closestSegmentIndex = 0;

    for (int i = 0; i < _currentRoutePoints.length - 1; i++) {
      final distance = _distanceToLineSegment(
        driverPosition,
        _currentRoutePoints[i],
        _currentRoutePoints[i + 1],
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestSegmentIndex = i;
      }
    }

    // Calculate total distance and distance covered
    double totalDistance = 0;
    double distanceCovered = 0;

    for (int i = 0; i < _currentRoutePoints.length - 1; i++) {
      final segmentDistance = _calculateDistanceInMeters(
        _currentRoutePoints[i],
        _currentRoutePoints[i + 1],
      );

      totalDistance += segmentDistance;

      if (i < closestSegmentIndex) {
        distanceCovered += segmentDistance;
      }
    }

    final progress = totalDistance > 0 ? distanceCovered / totalDistance : 0.0;
    final remainingDistance = totalDistance - distanceCovered;

    return RouteProgress(
      progress: progress,
      distanceCovered: distanceCovered,
      remainingDistance: remainingDistance,
      totalDistance: totalDistance,
      estimatedTimeRemaining: _calculateETA(remainingDistance),
    );
  }

  /// Calculate estimated time of arrival
  Duration _calculateETA(double remainingDistanceMeters) {
    const double averageSpeedMps = 8.33; // ~30 km/h in m/s
    final etaSeconds = remainingDistanceMeters / averageSpeedMps;
    return Duration(seconds: etaSeconds.round());
  }

  /// Get current tracking status
  TrackingStatus getTrackingStatus() {
    return TrackingStatus(
      isTracking: _isTracking,
      lastKnownPosition: _lastKnownDriverPosition,
      destination: _currentDestination,
      routePointsCount: _currentRoutePoints.length,
      lastUpdateTime: _lastPositionUpdate,
      timeSinceLastUpdate:
          _lastPositionUpdate != null
              ? DateTime.now().difference(_lastPositionUpdate!)
              : null,
    );
  }

  /// Stop tracking
  void stopTracking() {
    dev.log('🛑 Stopping real-time driver tracking');

    _isTracking = false;
    _lastKnownDriverPosition = null;
    _currentDestination = null;
    _currentRoutePoints.clear();
    _lastPositionUpdate = null;
    _lastRouteRecalculation = null;

    // Clear callbacks
    onDriverPositionUpdate = null;
    onRouteUpdate = null;
    onTrackingStatusUpdate = null;

    _notifyStatus('Tracking stopped');
  }

  /// Notify status updates
  void _notifyStatus(String message) {
    onTrackingStatusUpdate?.call(message);
    dev.log('📊 Tracking status: $message');
  }

  /// Check if driver has reached destination
  bool hasReachedDestination(LatLng driverPosition) {
    if (_currentDestination == null) return false;

    final distanceToDestination = _calculateDistanceInMeters(
      driverPosition,
      _currentDestination!,
    );

    const double arrivalThresholdMeters = 100.0; // 100 meters
    return distanceToDestination <= arrivalThresholdMeters;
  }

  /// Get current route points
  List<LatLng> get currentRoutePoints => List.unmodifiable(_currentRoutePoints);

  /// Check if tracking is active
  bool get isTracking => _isTracking;

  /// Get last known driver position
  LatLng? get lastKnownDriverPosition => _lastKnownDriverPosition;

  /// Get current destination
  LatLng? get currentDestination => _currentDestination;
}

/// Route progress information
class RouteProgress {
  final double progress; // 0.0 to 1.0
  final double distanceCovered; // in meters
  final double remainingDistance; // in meters
  final double totalDistance; // in meters
  final Duration estimatedTimeRemaining;

  const RouteProgress({
    required this.progress,
    required this.distanceCovered,
    required this.remainingDistance,
    required this.totalDistance,
    required this.estimatedTimeRemaining,
  });

  String get formattedProgress => '${(progress * 100).toStringAsFixed(1)}%';

  String get formattedRemainingDistance {
    if (remainingDistance < 1000) {
      return '${remainingDistance.toStringAsFixed(0)}m';
    } else {
      return '${(remainingDistance / 1000).toStringAsFixed(1)}km';
    }
  }

  String get formattedETA {
    final hours = estimatedTimeRemaining.inHours;
    final minutes = estimatedTimeRemaining.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

/// Tracking status information
class TrackingStatus {
  final bool isTracking;
  final LatLng? lastKnownPosition;
  final LatLng? destination;
  final int routePointsCount;
  final DateTime? lastUpdateTime;
  final Duration? timeSinceLastUpdate;

  const TrackingStatus({
    required this.isTracking,
    this.lastKnownPosition,
    this.destination,
    required this.routePointsCount,
    this.lastUpdateTime,
    this.timeSinceLastUpdate,
  });

  bool get isStale {
    if (timeSinceLastUpdate == null) return false;
    return timeSinceLastUpdate!.inSeconds >
        30; // Consider stale after 30 seconds
  }
}
