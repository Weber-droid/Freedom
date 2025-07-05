import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math' as math;
import 'package:freedom/core/services/service_extension.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:freedom/core/services/route_services.dart';
import 'package:freedom/di/locator.dart';
import 'package:geodesy/geodesy.dart' as geo;
import 'package:latlong2/latlong.dart' as ll;

class RealTimeDriverTrackingService {
  final RouteService _routeService = getIt<RouteService>();

  // Tracking state
  bool _isTracking = false;
  gmaps.LatLng? _lastKnownDriverPosition;
  gmaps.LatLng? _currentDestination;
  List<gmaps.LatLng> _currentRoutePoints =
      []; // Fixed: Use gmaps.LatLng consistently
  DateTime? _lastPositionUpdate;
  String? _currentRideId;
  String? _currentDriverId;

  // Route recalculation settings
  static const double _routeDeviationThresholdMeters =
      50.0; // 50 meters off route
  static const int _routeRecalculationCooldownSeconds =
      10; // Prevent spam recalculation
  DateTime? _lastRouteRecalculation;

  // Callbacks for UI updates
  void Function(gmaps.LatLng position, double bearing, DriverLocationData data)?
  onDriverPositionUpdate;
  void Function(List<gmaps.LatLng> newRoute)? onRouteUpdate;
  void Function(String message)? onTrackingStatusUpdate;

  /// Initialize tracking for a ride in progress
  void startTracking({
    required String rideId,
    required String driverId,
    required gmaps.LatLng destination,
    required void Function(
      gmaps.LatLng position,
      double bearing,
      DriverLocationData data,
    )
    onPositionUpdate,
    required void Function(List<gmaps.LatLng> newRoute) onRouteUpdated,
    void Function(String message)? onStatusUpdate,
  }) {
    dev.log('To wait na waitse');
    dev.log('🔴 Starting real-time driver tracking for ride: $rideId');

    _isTracking = true;
    _currentRideId = rideId;
    _currentDriverId = driverId;
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
      final driverLocationData = _parseLocationData(locationData);
      if (driverLocationData == null) return;

      // Update driver position
      await _updateDriverPosition(driverLocationData);

      // Check if route recalculation is needed
      await _checkForRouteRecalculation(driverLocationData.position);
    } catch (e) {
      dev.log('❌ Error processing driver location: $e');
    }
  }

  /// Parse location data from socket
  DriverLocationData? _parseLocationData(Map<String, dynamic> data) {
    try {
      // Extract coordinates array [longitude, latitude]
      final coordinates = data['coordinates'] as List<dynamic>?;
      if (coordinates == null || coordinates.length < 2) {
        dev.log('❌ Invalid location data: missing or invalid coordinates');
        return null;
      }

      final longitude = (coordinates[0] as num).toDouble();
      final latitude = (coordinates[1] as num).toDouble();
      final position = gmaps.LatLng(latitude, longitude);

      // Extract other fields
      final driverId = data['driverId'] as String?;
      final rideId = data['rideId'] as String?;
      final status = data['status'] as String?;
      final isMultiStop = data['isMultiStop'] as bool? ?? false;
      final speed = (data['speed'] as num?)?.toDouble() ?? 0.0;
      final heading = (data['heading'] as num?)?.toDouble() ?? 0.0;
      final accuracy = (data['accuracy'] as num?)?.toDouble() ?? 0.0;
      final isSignificantMovement =
          data['isSignificantMovement'] as bool? ?? false;

      // Parse ETA
      EtaData? eta;
      final etaMap = data['eta'] as Map<String, dynamic>?;
      if (etaMap != null) {
        eta = EtaData(
          value: (etaMap['value'] as num?)?.toDouble() ?? 0.0,
          text: etaMap['text'] as String? ?? '',
        );
      }

      // Parse lastUpdate
      DateTime? lastUpdate;
      final lastUpdateStr = data['lastUpdate'] as String?;
      if (lastUpdateStr != null) {
        lastUpdate = DateTime.tryParse(lastUpdateStr);
      }

      return DriverLocationData(
        driverId: driverId,
        rideId: rideId,
        position: position,
        status: status,
        isMultiStop: isMultiStop,
        eta: eta,
        speed: speed,
        heading: heading,
        accuracy: accuracy,
        lastUpdate: lastUpdate ?? DateTime.now(),
        isSignificantMovement: isSignificantMovement,
      );
    } catch (e) {
      dev.log('❌ Error parsing location data: $e');
      return null;
    }
  }

  /// Validate that the location update is for the current ride and driver
  bool _isValidLocationUpdate(DriverLocationData data) {
    if (_currentRideId != null && data.rideId != _currentRideId) {
      return false;
    }
    if (_currentDriverId != null && data.driverId != _currentDriverId) {
      return false;
    }
    return true;
  }

  /// Update driver position and notify UI
  Future<void> _updateDriverPosition(DriverLocationData locationData) async {
    final position = locationData.position;
    final bearing = _calculateBearing(position, locationData);

    _lastKnownDriverPosition = position;
    _lastPositionUpdate = locationData.lastUpdate;
    final progressInfo = _calculateRouteProgress(position);
    onDriverPositionUpdate?.call(position, bearing, locationData);

    dev.log(
      '📍 Driver position updated: $position (bearing: ${bearing.toStringAsFixed(1)}°, speed: ${locationData.speed} km/h)',
    );

    if (progressInfo != null) {
      dev.log(
        '📊 Route progress: ${(progressInfo.progress * 100).toStringAsFixed(1)}%',
      );
    }
  }

  double _calculateBearing(
    gmaps.LatLng currentPosition,
    DriverLocationData data,
  ) {
    if (data.heading != null && data.heading! > 0) {
      return data.heading!;
    }

    if (_lastKnownDriverPosition != null) {
      return _calculateBearingBetweenPoints(
        _lastKnownDriverPosition!,
        currentPosition,
      );
    }

    return 0.0;
  }

  double _calculateBearingBetweenPoints(gmaps.LatLng start, gmaps.LatLng end) {
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

  Future<void> _checkForRouteRecalculation(gmaps.LatLng driverPosition) async {
    if (_currentDestination == null || _currentRoutePoints.isEmpty) {
      await _calculateNewRoute(driverPosition, _currentDestination!);
      return;
    }
    final distanceFromRoute = _calculateDistanceFromRoute(driverPosition);

    if (distanceFromRoute > _routeDeviationThresholdMeters) {
      dev.log(
        '🔄 Driver deviated ${distanceFromRoute.toStringAsFixed(1)}m from route',
      );

      if (_shouldRecalculateRoute()) {
        await _calculateNewRoute(driverPosition, _currentDestination!);
      }
    }
  }

  double _calculateDistanceFromRoute(gmaps.LatLng driverPosition) {
    if (_currentRoutePoints.isEmpty) return double.infinity;

    double minDistance = double.infinity;

    for (int i = 0; i < _currentRoutePoints.length - 1; i++) {
      final segmentDistance = distanceToLineSegment(
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
  double distanceToLineSegment(
    gmaps.LatLng point,
    gmaps.LatLng lineStart,
    gmaps.LatLng lineEnd,
  ) {
    final geodesy = geo.Geodesy();

    // Convert to latlong2 format for geodesy calculations
    final projectedPoint = geodesy.projectPointOntoGeodesicLine(
      point.toLatLong2(),
      lineStart.toLatLong2(),
      lineEnd.toLatLong2(),
    );

    final distance = geodesy.distanceBetweenTwoGeoPoints(
      point.toLatLong2(),
      projectedPoint,
    );

    // Check if projection falls within the line segment
    final segmentLength = geodesy.distanceBetweenTwoGeoPoints(
      lineStart.toLatLong2(),
      lineEnd.toLatLong2(),
    );

    final distanceToProjection = geodesy.distanceBetweenTwoGeoPoints(
      lineStart.toLatLong2(),
      projectedPoint,
    );

    // If projection is outside the segment, return distance to closest endpoint
    if (distanceToProjection < 0 || distanceToProjection > segmentLength) {
      final distanceToStart = geodesy.distanceBetweenTwoGeoPoints(
        point.toLatLong2(),
        lineStart.toLatLong2(),
      );
      final distanceToEnd = geodesy.distanceBetweenTwoGeoPoints(
        point.toLatLong2(),
        lineEnd.toLatLong2(),
      );
      return math.min(distanceToStart.toDouble(), distanceToEnd.toDouble());
    }

    return distance.toDouble();
  }

  /// Calculate distance between two points in meters
  double _calculateDistanceInMeters(gmaps.LatLng point1, gmaps.LatLng point2) {
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
  Future<void> _calculateNewRoute(gmaps.LatLng from, gmaps.LatLng to) async {
    try {
      dev.log('🛣️ Calculating new route from $from to $to');
      _lastRouteRecalculation = DateTime.now();

      final routeResult = await _routeService.getRoute(from, to);

      if (routeResult.isSuccess && routeResult.polyline != null) {
        // Convert route points to gmaps.LatLng if they're not already
        _currentRoutePoints =
            routeResult.polyline!.points
                .map((point) => gmaps.LatLng(point.latitude, point.longitude))
                .toList();

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
  RouteProgress? _calculateRouteProgress(gmaps.LatLng driverPosition) {
    if (_currentRoutePoints.isEmpty) return null;

    // Find closest point on route
    double minDistance = double.infinity;
    int closestSegmentIndex = 0;

    for (int i = 0; i < _currentRoutePoints.length - 1; i++) {
      final distance = distanceToLineSegment(
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
      rideId: _currentRideId,
      driverId: _currentDriverId,
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
    _currentRideId = null;
    _currentDriverId = null;
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
  bool hasReachedDestination(gmaps.LatLng driverPosition) {
    if (_currentDestination == null) return false;

    final distanceToDestination = _calculateDistanceInMeters(
      driverPosition,
      _currentDestination!,
    );

    const double arrivalThresholdMeters = 100.0; // 100 meters
    return distanceToDestination <= arrivalThresholdMeters;
  }

  /// Get current route points
  List<gmaps.LatLng> get currentRoutePoints =>
      List.unmodifiable(_currentRoutePoints);

  /// Check if tracking is active
  bool get isTracking => _isTracking;

  /// Get last known driver position
  gmaps.LatLng? get lastKnownDriverPosition => _lastKnownDriverPosition;

  /// Get current destination
  gmaps.LatLng? get currentDestination => _currentDestination;

  /// Get current ride ID
  String? get currentRideId => _currentRideId;

  /// Get current driver ID
  String? get currentDriverId => _currentDriverId;
}

/// Driver location data from server
class DriverLocationData {
  final String? driverId;
  final String? rideId;
  final gmaps.LatLng position;
  final String? status;
  final bool isMultiStop;
  final EtaData? eta;
  final double speed; // km/h
  final double? heading; // degrees
  final double accuracy; // meters
  final DateTime lastUpdate;
  final bool isSignificantMovement;

  const DriverLocationData({
    this.driverId,
    this.rideId,
    required this.position,
    this.status,
    required this.isMultiStop,
    this.eta,
    required this.speed,
    this.heading,
    required this.accuracy,
    required this.lastUpdate,
    required this.isSignificantMovement,
  });

  @override
  String toString() {
    return 'DriverLocationData(driverId: $driverId, rideId: $rideId, position: $position, status: $status, speed: $speed, heading: $heading)';
  }
}

/// ETA information
class EtaData {
  final double value; // in minutes
  final String text; // human readable format

  const EtaData({required this.value, required this.text});

  @override
  String toString() => 'EtaData(value: $value, text: $text)';
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
  final String? rideId;
  final String? driverId;
  final gmaps.LatLng? lastKnownPosition;
  final gmaps.LatLng? destination;
  final int routePointsCount;
  final DateTime? lastUpdateTime;
  final Duration? timeSinceLastUpdate;

  const TrackingStatus({
    required this.isTracking,
    this.rideId,
    this.driverId,
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
