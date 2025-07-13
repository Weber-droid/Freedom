import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math' as math;
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
  List<gmaps.LatLng> _currentRoutePoints = [];
  DateTime? _lastPositionUpdate;
  String? _currentRideId;
  String? _currentDriverId;

  Timer? _updateTimer;
  List<LocationHistory> _locationHistory = [];
  static const int _maxHistoryLength = 10;
  static const Duration _expectedUpdateInterval = Duration(seconds: 3);
  static const Duration _staleUpdateThreshold = Duration(seconds: 10);

  static const double _routeDeviationThresholdMeters = 30.0;
  static const int _routeRecalculationCooldownSeconds = 8;
  DateTime? _lastRouteRecalculation;

  static const double _maxSpeedKmh = 120.0;
  static const double _minAccuracyMeters = 5.0;
  static const double _maxJumpDistanceMeters =
      200.0; // Max distance between updates

  // Callbacks for UI updates
  void Function(gmaps.LatLng position, double bearing, DriverLocationData data)?
  onDriverPositionUpdate;
  void Function(List<gmaps.LatLng> newRoute)? onRouteUpdate;
  void Function(String message)? onTrackingStatusUpdate;
  void Function(gmaps.LatLng position)? onDriverMarkerUpdate;

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
    void Function(gmaps.LatLng position)? onMarkerUpdate,
  }) {
    dev.log('🔴 Starting enhanced real-time driver tracking for ride: $rideId');

    _isTracking = true;
    _currentRideId = rideId;
    _currentDriverId = driverId;
    _currentDestination = destination;
    _lastKnownDriverPosition = null;
    _currentRoutePoints.clear();
    _lastRouteRecalculation = null;
    _locationHistory.clear();

    // Set callbacks
    onDriverPositionUpdate = onPositionUpdate;
    onRouteUpdate = onRouteUpdated;
    onTrackingStatusUpdate = onStatusUpdate;
    onDriverMarkerUpdate = onMarkerUpdate;

    // Start monitoring timer for stale updates
    _startUpdateMonitoring();

    _notifyStatus('Enhanced real-time tracking started (3s intervals)');
    dev.log('📍 Destination set: $destination');
  }

  /// Start monitoring for stale updates
  void _startUpdateMonitoring() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _checkForStaleUpdates();
    });
  }

  /// Check for stale location updates
  void _checkForStaleUpdates() {
    if (!_isTracking || _lastPositionUpdate == null) return;

    final timeSinceLastUpdate = DateTime.now().difference(_lastPositionUpdate!);
    if (timeSinceLastUpdate > _staleUpdateThreshold) {
      _notifyStatus(
        '⚠️ Location updates are stale (${timeSinceLastUpdate.inSeconds}s ago)',
      );
      dev.log(
        '⚠️ Stale location updates detected: ${timeSinceLastUpdate.inSeconds}s',
      );
    }
  }

  /// Process incoming driver location from socket with enhanced precision
  Future<void> processDriverLocation(Map<String, dynamic> locationData) async {
    if (!_isTracking) {
      dev.log('⚠️ Received location data but tracking is not active');
      return;
    }

    try {
      final driverLocationData = _parseLocationData(locationData);
      if (driverLocationData == null) return;

      if (!_isValidPosition(driverLocationData)) {
        dev.log('⚠️ Poor quality position data rejected');
        return;
      }
      final smoothedPosition = _applySmoothening(driverLocationData);
      if (smoothedPosition == null) {
        dev.log('⚠️ Position rejected by smoothing algorithm');
        return;
      }

      // Update location history
      _updateLocationHistory(driverLocationData);

      // Update driver position with smoothed data
      await _updateDriverPosition(smoothedPosition);

      // Update marker with precise position
      onDriverMarkerUpdate?.call(smoothedPosition.position);

      // Check if route recalculation is needed
      await _checkForRouteRecalculation(smoothedPosition.position);
    } catch (e) {
      dev.log('❌ Error processing driver location: $e');
    }
  }

  /// Enhanced location data parsing with better validation
  DriverLocationData? _parseLocationData(Map<String, dynamic> data) {
    try {
      dev.log('🔍 Raw driver location data: $data');
      final coordinates = data['coordinates'] as List<dynamic>?;
      if (coordinates == null || coordinates.length < 2) {
        dev.log('❌ Invalid location data: missing or invalid coordinates');
        return null;
      }

      // Server sends [longitude, latitude] but we need [latitude, longitude]
      final serverLatitude = (coordinates[0] as num).toDouble();
      final serverLongitude = (coordinates[1] as num).toDouble();

      dev.log(
        '🔍 Server coordinates: [lng=$serverLongitude, lat=$serverLatitude]',
      );

      final position = gmaps.LatLng(serverLatitude, serverLongitude);

      dev.log(
        '✅ Corrected driver position: LatLng($serverLatitude, $serverLongitude)',
      );

      // Extract other fields with better defaults
      final driverId = data['driverId'] as String?;
      final rideId = data['rideId'] as String?;
      final status = data['status'] as String?;
      final isMultiStop = data['isMultiStop'] as bool? ?? false;
      final speed = math.max(0.0, (data['speed'] as num?)?.toDouble() ?? 0.0);
      final heading = (data['heading'] as num?)?.toDouble();
      final accuracy = math.max(
        1.0,
        (data['accuracy'] as num?)?.toDouble() ?? 10.0,
      );
      final isSignificantMovement =
          data['isSignificantMovement'] as bool? ?? true;

      // Parse ETA
      EtaData? eta;
      final etaMap = data['eta'] as Map<String, dynamic>?;
      if (etaMap != null) {
        eta = EtaData(
          value: math.max(0.0, (etaMap['value'] as num?)?.toDouble() ?? 0.0),
          text: etaMap['text'] as String? ?? '0 min',
        );
      }

      // Parse lastUpdate with fallback
      DateTime lastUpdate = DateTime.now();
      final lastUpdateStr = data['lastUpdate'] as String?;
      if (lastUpdateStr != null) {
        lastUpdate = DateTime.tryParse(lastUpdateStr) ?? DateTime.now();
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
        lastUpdate: lastUpdate,
        isSignificantMovement: isSignificantMovement,
      );
    } catch (e) {
      dev.log('❌ Error parsing location data: $e');
      return null;
    }
  }

  bool _isValidPosition(DriverLocationData data) {
    // Check GPS accuracy
    if (data.accuracy > 50.0) {
      dev.log('⚠️ Poor GPS accuracy: ${data.accuracy}m');
      return false;
    }

    // Check for unrealistic speed
    if (data.speed > _maxSpeedKmh) {
      dev.log('⚠️ Unrealistic speed: ${data.speed} km/h');
      return false;
    }

    // Check for position jumps if we have previous position
    if (_lastKnownDriverPosition != null) {
      final distance = _calculateDistanceInMeters(
        _lastKnownDriverPosition!,
        data.position,
      );

      // Calculate time since last update
      final timeDiff =
          _lastPositionUpdate != null
              ? data.lastUpdate.difference(_lastPositionUpdate!).inSeconds
              : 3;

      // Check for unrealistic position jumps
      if (distance > _maxJumpDistanceMeters && timeDiff < 10) {
        dev.log(
          '⚠️ Unrealistic position jump: ${distance.toStringAsFixed(1)}m in ${timeDiff}s',
        );
        return false;
      }
    }

    return true;
  }

  /// Apply position smoothing using location history
  DriverLocationData? _applySmoothening(DriverLocationData newData) {
    if (_locationHistory.isEmpty) {
      return newData;
    }

    // Simple moving average for smoothing
    final recentPositions =
        _locationHistory
            .where((h) => DateTime.now().difference(h.timestamp).inSeconds < 15)
            .toList();

    if (recentPositions.length < 2) {
      return newData;
    }

    // Calculate weighted average position
    double totalWeight = 0.0;
    double weightedLat = 0.0;
    double weightedLng = 0.0;

    for (int i = 0; i < recentPositions.length; i++) {
      final history = recentPositions[i];
      final weight = (i + 1).toDouble(); // More recent = higher weight

      totalWeight += weight;
      weightedLat += history.position.latitude * weight;
      weightedLng += history.position.longitude * weight;
    }

    // Include new position with highest weight
    final newWeight = recentPositions.length + 1.0;
    totalWeight += newWeight;
    weightedLat += newData.position.latitude * newWeight;
    weightedLng += newData.position.longitude * newWeight;

    final smoothedPosition = gmaps.LatLng(
      weightedLat / totalWeight,
      weightedLng / totalWeight,
    );

    return DriverLocationData(
      driverId: newData.driverId,
      rideId: newData.rideId,
      position: smoothedPosition,
      status: newData.status,
      isMultiStop: newData.isMultiStop,
      eta: newData.eta,
      speed: newData.speed,
      heading: newData.heading,
      accuracy: newData.accuracy,
      lastUpdate: newData.lastUpdate,
      isSignificantMovement: newData.isSignificantMovement,
    );
  }

  /// Update location history
  void _updateLocationHistory(DriverLocationData data) {
    _locationHistory.add(
      LocationHistory(
        position: data.position,
        timestamp: data.lastUpdate,
        speed: data.speed,
        accuracy: data.accuracy,
      ),
    );

    // Keep only recent history
    if (_locationHistory.length > _maxHistoryLength) {
      _locationHistory.removeAt(0);
    }

    // Remove old entries
    final cutoffTime = DateTime.now().subtract(Duration(minutes: 2));
    _locationHistory.removeWhere((h) => h.timestamp.isBefore(cutoffTime));
  }

  /// Enhanced driver position update with better bearing calculation
  Future<void> _updateDriverPosition(DriverLocationData locationData) async {
    final position = locationData.position;
    final bearing = _calculateEnhancedBearing(position, locationData);

    _lastKnownDriverPosition = position;
    _lastPositionUpdate = locationData.lastUpdate;

    // Calculate precise route progress
    final progressInfo = _calculateRouteProgress(position);

    // Notify UI with enhanced data
    onDriverPositionUpdate?.call(position, bearing, locationData);

    dev.log(
      '📍 Driver position updated: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)} '
      '(bearing: ${bearing.toStringAsFixed(1)}°, speed: ${locationData.speed.toStringAsFixed(1)} km/h, '
      'accuracy: ${locationData.accuracy.toStringAsFixed(1)}m)',
    );

    if (progressInfo != null) {
      dev.log(
        '📊 Route progress: ${(progressInfo.progress * 100).toStringAsFixed(1)}% '
        '(${progressInfo.formattedRemainingDistance} remaining)',
      );
    }
  }

  /// Enhanced bearing calculation using multiple methods
  double _calculateEnhancedBearing(
    gmaps.LatLng currentPosition,
    DriverLocationData data,
  ) {
    if (data.heading != null && data.heading! > 0 && data.speed > 5.0) {
      return data.heading!;
    }

    // Calculate bearing from movement history
    if (_locationHistory.length >= 2) {
      final recentPositions =
          _locationHistory
              .where(
                (h) => DateTime.now().difference(h.timestamp).inSeconds < 30,
              )
              .toList();

      if (recentPositions.length >= 2) {
        final oldPosition = recentPositions[0].position;
        return _calculateBearingBetweenPoints(oldPosition, currentPosition);
      }
    }

    // Fallback to previous position
    if (_lastKnownDriverPosition != null) {
      return _calculateBearingBetweenPoints(
        _lastKnownDriverPosition!,
        currentPosition,
      );
    }

    return 0.0;
  }

  /// Calculate bearing between two points
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

  /// Enhanced route recalculation with better thresholds
  Future<void> _checkForRouteRecalculation(gmaps.LatLng driverPosition) async {
    if (_currentDestination == null) return;

    // Always calculate route if we don't have one
    if (_currentRoutePoints.isEmpty) {
      await _calculateNewRoute(driverPosition, _currentDestination!);
      return;
    }

    final distanceFromRoute = _calculateDistanceFromRoute(driverPosition);

    // More aggressive recalculation for better tracking
    if (distanceFromRoute > _routeDeviationThresholdMeters) {
      dev.log(
        '🔄 Driver deviated ${distanceFromRoute.toStringAsFixed(1)}m from route '
        '(threshold: ${_routeDeviationThresholdMeters}m)',
      );

      if (_shouldRecalculateRoute()) {
        await _calculateNewRoute(driverPosition, _currentDestination!);
      }
    }
  }

  /// Calculate distance from current route
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
      LatLngExtensions(point).toLatLong2(),
      LatLngExtensions(lineStart).toLatLong2(),
      LatLngExtensions(lineEnd).toLatLong2(),
    );

    final distance = geodesy.distanceBetweenTwoGeoPoints(
      LatLngExtensions(point).toLatLong2(),
      projectedPoint,
    );

    // Check if projection falls within the line segment
    final segmentLength = geodesy.distanceBetweenTwoGeoPoints(
      LatLngExtensions(lineStart).toLatLong2(),
      LatLngExtensions(lineEnd).toLatLong2(),
    );

    final distanceToProjection = geodesy.distanceBetweenTwoGeoPoints(
      LatLngExtensions(lineStart).toLatLong2(),
      projectedPoint,
    );

    // If projection is outside the segment, return distance to closest endpoint
    if (distanceToProjection < 0 || distanceToProjection > segmentLength) {
      final distanceToStart = geodesy.distanceBetweenTwoGeoPoints(
        LatLngExtensions(point).toLatLong2(),
        LatLngExtensions(lineStart).toLatLong2(),
      );
      final distanceToEnd = geodesy.distanceBetweenTwoGeoPoints(
        LatLngExtensions(point).toLatLong2(),
        LatLngExtensions(lineEnd).toLatLong2(),
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

  /// Enhanced route calculation with better error handling
  Future<void> _calculateNewRoute(gmaps.LatLng from, gmaps.LatLng to) async {
    try {
      dev.log(
        '🛣️ Calculating new route from ${from.latitude.toStringAsFixed(6)}, ${from.longitude.toStringAsFixed(6)} to ${to.latitude.toStringAsFixed(6)}, ${to.longitude.toStringAsFixed(6)}',
      );
      _lastRouteRecalculation = DateTime.now();

      final routeResult = await _routeService.getRoute(from, to);

      if (routeResult.isSuccess && routeResult.polyline != null) {
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
        _notifyStatus('Route calculation failed: ${routeResult.errorMessage}');
      }
    } catch (e) {
      dev.log('❌ Error calculating route: $e');
      _notifyStatus('Route calculation error: $e');
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

  /// Get enhanced tracking status
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
      locationHistoryCount: _locationHistory.length,
      averageAccuracy: _calculateAverageAccuracy(),
      isReceivingRegularUpdates: _isReceivingRegularUpdates(),
    );
  }

  /// Calculate average GPS accuracy from recent history
  double _calculateAverageAccuracy() {
    if (_locationHistory.isEmpty) return 0.0;

    final recentHistory =
        _locationHistory
            .where((h) => DateTime.now().difference(h.timestamp).inSeconds < 30)
            .toList();

    if (recentHistory.isEmpty) return 0.0;

    final totalAccuracy = recentHistory.fold(0.0, (sum, h) => sum + h.accuracy);
    return totalAccuracy / recentHistory.length;
  }

  /// Check if receiving regular updates
  bool _isReceivingRegularUpdates() {
    if (_lastPositionUpdate == null) return false;

    final timeSinceLastUpdate = DateTime.now().difference(_lastPositionUpdate!);
    return timeSinceLastUpdate <
        Duration(seconds: 6); // Within 2x expected interval
  }

  /// Stop tracking with proper cleanup
  void stopTracking() {
    dev.log('🛑 Stopping enhanced real-time driver tracking');

    _isTracking = false;
    _currentRideId = null;
    _currentDriverId = null;
    _lastKnownDriverPosition = null;
    _currentDestination = null;
    _currentRoutePoints.clear();
    _lastPositionUpdate = null;
    _lastRouteRecalculation = null;
    _locationHistory.clear();

    // Clean up timer
    _updateTimer?.cancel();
    _updateTimer = null;

    // Clear callbacks
    onDriverPositionUpdate = null;
    onRouteUpdate = null;
    onTrackingStatusUpdate = null;
    onDriverMarkerUpdate = null;

    _notifyStatus('Enhanced tracking stopped');
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

  /// Get location history for debugging/analysis
  List<LocationHistory> get locationHistory =>
      List.unmodifiable(_locationHistory);
}

/// Location history for position smoothing
class LocationHistory {
  final gmaps.LatLng position;
  final DateTime timestamp;
  final double speed;
  final double accuracy;

  const LocationHistory({
    required this.position,
    required this.timestamp,
    required this.speed,
    required this.accuracy,
  });

  @override
  String toString() {
    return 'LocationHistory(position: $position, timestamp: $timestamp, speed: $speed, accuracy: $accuracy)';
  }
}

/// Enhanced driver location data
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
    return 'DriverLocationData(driverId: $driverId, rideId: $rideId, '
        'position: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}, '
        'status: $status, speed: ${speed.toStringAsFixed(1)}, heading: $heading, '
        'accuracy: ${accuracy.toStringAsFixed(1)})';
  }
}

/// ETA information
class EtaData {
  final double value;
  final String text;
  const EtaData({required this.value, required this.text});

  @override
  String toString() => 'EtaData(value: $value, text: $text)';
}

/// Route progress information
class RouteProgress {
  final double progress;
  final double distanceCovered;
  final double remainingDistance;
  final double totalDistance;
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

  @override
  String toString() {
    return 'RouteProgress(progress: $formattedProgress, '
        'distanceCovered: ${(distanceCovered / 1000).toStringAsFixed(1)}km, '
        'remainingDistance: $formattedRemainingDistance, '
        'totalDistance: ${(totalDistance / 1000).toStringAsFixed(1)}km, '
        'eta: $formattedETA)';
  }
}

/// Enhanced tracking status information
class TrackingStatus {
  final bool isTracking;
  final String? rideId;
  final String? driverId;
  final gmaps.LatLng? lastKnownPosition;
  final gmaps.LatLng? destination;
  final int routePointsCount;
  final DateTime? lastUpdateTime;
  final Duration? timeSinceLastUpdate;
  final int locationHistoryCount;
  final double averageAccuracy;
  final bool isReceivingRegularUpdates;

  const TrackingStatus({
    required this.isTracking,
    this.rideId,
    this.driverId,
    this.lastKnownPosition,
    this.destination,
    required this.routePointsCount,
    this.lastUpdateTime,
    this.timeSinceLastUpdate,
    required this.locationHistoryCount,
    required this.averageAccuracy,
    required this.isReceivingRegularUpdates,
  });

  bool get isStale {
    if (timeSinceLastUpdate == null) return false;
    return timeSinceLastUpdate!.inSeconds > 10;
  }

  bool get hasGoodAccuracy {
    return averageAccuracy > 0 && averageAccuracy <= 20.0;
  }

  String get statusSummary {
    if (!isTracking) return 'Not tracking';
    if (isStale) return 'Stale updates';
    if (!isReceivingRegularUpdates) return 'Irregular updates';
    if (!hasGoodAccuracy) return 'Poor GPS accuracy';
    return 'Tracking active';
  }

  String get formattedLastUpdate {
    if (lastUpdateTime == null) return 'Never';
    if (timeSinceLastUpdate == null) return 'Unknown';

    final seconds = timeSinceLastUpdate!.inSeconds;
    if (seconds < 60) {
      return '${seconds}s ago';
    } else {
      final minutes = timeSinceLastUpdate!.inMinutes;
      return '${minutes}m ${seconds % 60}s ago';
    }
  }

  String get formattedPosition {
    if (lastKnownPosition == null) return 'Unknown';
    return '${lastKnownPosition!.latitude.toStringAsFixed(6)}, ${lastKnownPosition!.longitude.toStringAsFixed(6)}';
  }

  double? get distanceToDestination {
    if (lastKnownPosition == null || destination == null) return null;

    const double earthRadius = 6371000; // Earth's radius in meters
    final lat1Rad = lastKnownPosition!.latitude * math.pi / 180;
    final lat2Rad = destination!.latitude * math.pi / 180;
    final dLat =
        (destination!.latitude - lastKnownPosition!.latitude) * math.pi / 180;
    final dLng =
        (destination!.longitude - lastKnownPosition!.longitude) * math.pi / 180;

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  String get formattedDistanceToDestination {
    final distance = distanceToDestination;
    if (distance == null) return 'Unknown';

    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }

  @override
  String toString() {
    return 'TrackingStatus(isTracking: $isTracking, '
        'status: $statusSummary, '
        'rideId: $rideId, '
        'driverId: $driverId, '
        'position: $formattedPosition, '
        'lastUpdate: $formattedLastUpdate, '
        'accuracy: ${averageAccuracy.toStringAsFixed(1)}m, '
        'historyPoints: $locationHistoryCount, '
        'routePoints: $routePointsCount, '
        'distanceToDestination: $formattedDistanceToDestination)';
  }
}

extension LatLngExtensions on gmaps.LatLng {
  ll.LatLng toLatLong2() {
    return ll.LatLng(latitude, longitude);
  }

  String toDisplayFormat({int precision = 6}) {
    return '${latitude.toStringAsFixed(precision)}, ${longitude.toStringAsFixed(precision)}';
  }

  /// Validate if coordinates are within valid ranges
  bool get isValid {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  /// Round coordinates to specified decimal places
  gmaps.LatLng roundToPrecision(int decimalPlaces) {
    final factor = math.pow(10, decimalPlaces);
    return gmaps.LatLng(
      (latitude * factor).round() / factor,
      (longitude * factor).round() / factor,
    );
  }

  /// Calculate distance to another point in meters
  double distanceTo(gmaps.LatLng other) {
    const double earthRadius = 6371000;

    final lat1Rad = latitude * math.pi / 180;
    final lat2Rad = other.latitude * math.pi / 180;
    final dLat = (other.latitude - latitude) * math.pi / 180;
    final dLng = (other.longitude - longitude) * math.pi / 180;

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Calculate bearing to another point in degrees
  double bearingTo(gmaps.LatLng other) {
    final lat1 = latitude * math.pi / 180;
    final lat2 = other.latitude * math.pi / 180;
    final dLng = (other.longitude - longitude) * math.pi / 180;

    final y = math.sin(dLng) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  /// Get debug string with validation status
  String get debugString {
    return 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)} ${isValid ? "✓" : "✗"}';
  }
}

/// Additional utility methods for the tracking service
extension RealTimeDriverTrackingServiceExtensions
    on RealTimeDriverTrackingService {
  /// Get detailed tracking metrics for debugging
  Map<String, dynamic> getTrackingMetrics() {
    final status = getTrackingStatus();

    return {
      'isTracking': status.isTracking,
      'isStale': status.isStale,
      'hasGoodAccuracy': status.hasGoodAccuracy,
      'statusSummary': status.statusSummary,
      'rideId': status.rideId,
      'driverId': status.driverId,
      'lastKnownPosition': status.lastKnownPosition?.toDisplayFormat(),
      'destination': status.destination?.toDisplayFormat(),
      'routePointsCount': status.routePointsCount,
      'locationHistoryCount': status.locationHistoryCount,
      'averageAccuracy': status.averageAccuracy,
      'isReceivingRegularUpdates': status.isReceivingRegularUpdates,
      'timeSinceLastUpdate': status.timeSinceLastUpdate?.inSeconds,
      'distanceToDestination': status.distanceToDestination,
      'formattedDistanceToDestination': status.formattedDistanceToDestination,
      'lastUpdateFormatted': status.formattedLastUpdate,
    };
  }

  /// Force route recalculation (bypassing cooldown) - useful for debugging
  Future<void> forceRouteRecalculation() async {
    if (_lastKnownDriverPosition != null && _currentDestination != null) {
      _lastRouteRecalculation = null; // Reset cooldown
      await _calculateNewRoute(_lastKnownDriverPosition!, _currentDestination!);
    }
  }

  /// Clear location history - useful for resetting tracking state
  void clearLocationHistory() {
    _locationHistory.clear();
    dev.log('📊 Location history cleared');
  }

  /// Get current tracking performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    final now = DateTime.now();

    // Calculate update frequency
    double averageUpdateInterval = 0.0;
    if (_locationHistory.length > 1) {
      final intervals = <double>[];
      for (int i = 1; i < _locationHistory.length; i++) {
        final interval =
            _locationHistory[i].timestamp
                .difference(_locationHistory[i - 1].timestamp)
                .inMilliseconds
                .toDouble();
        intervals.add(interval);
      }
      averageUpdateInterval =
          intervals.reduce((a, b) => a + b) / intervals.length;
    }

    // Calculate accuracy stats
    final accuracyValues = _locationHistory.map((h) => h.accuracy).toList();
    double minAccuracy =
        accuracyValues.isNotEmpty ? accuracyValues.reduce(math.min) : 0.0;
    double maxAccuracy =
        accuracyValues.isNotEmpty ? accuracyValues.reduce(math.max) : 0.0;

    // Calculate speed stats
    final speedValues = _locationHistory.map((h) => h.speed).toList();
    double averageSpeed =
        speedValues.isNotEmpty
            ? speedValues.reduce((a, b) => a + b) / speedValues.length
            : 0.0;
    double maxSpeed =
        speedValues.isNotEmpty ? speedValues.reduce(math.max) : 0.0;

    return {
      'averageUpdateInterval': averageUpdateInterval,
      'expectedUpdateInterval':
          RealTimeDriverTrackingService._expectedUpdateInterval.inMilliseconds,
      'updateVariance':
          (averageUpdateInterval -
                  RealTimeDriverTrackingService
                      ._expectedUpdateInterval
                      .inMilliseconds)
              .abs(),
      'minAccuracy': minAccuracy,
      'maxAccuracy': maxAccuracy,
      'averageAccuracy': _calculateAverageAccuracy(),
      'averageSpeed': averageSpeed,
      'maxSpeed': maxSpeed,
      'totalUpdatesReceived': _locationHistory.length,
      'routeRecalculations': _lastRouteRecalculation != null ? 1 : 0,
      'trackingDuration':
          _lastPositionUpdate != null
              ? now.difference(_lastPositionUpdate!).inSeconds
              : 0,
    };
  }

  /// Validate current tracking state and return issues
  List<String> validateTrackingState() {
    final issues = <String>[];
    final status = getTrackingStatus();

    if (!status.isTracking) {
      issues.add('Tracking is not active');
      return issues;
    }

    if (status.isStale) {
      issues.add(
        'Location updates are stale (>${RealTimeDriverTrackingService._staleUpdateThreshold.inSeconds}s)',
      );
    }

    if (!status.isReceivingRegularUpdates) {
      issues.add('Not receiving regular updates');
    }

    if (!status.hasGoodAccuracy) {
      issues.add('Poor GPS accuracy (>${20.0}m average)');
    }

    if (status.routePointsCount == 0) {
      issues.add('No route calculated');
    }

    if (status.locationHistoryCount < 2) {
      issues.add('Insufficient location history for smoothing');
    }

    if (status.lastKnownPosition == null) {
      issues.add('No driver position available');
    }

    if (status.destination == null) {
      issues.add('No destination set');
    }

    return issues;
  }

  /// Get summary of recent location updates
  List<Map<String, dynamic>> getRecentLocationSummary({int count = 5}) {
    final recentHistory =
        _locationHistory
            .skip(math.max(0, _locationHistory.length - count))
            .toList();

    return recentHistory
        .map(
          (history) => {
            'position': history.position.toDisplayFormat(),
            'timestamp': history.timestamp.toIso8601String(),
            'speed': history.speed,
            'accuracy': history.accuracy,
            'ageSeconds':
                DateTime.now().difference(history.timestamp).inSeconds,
          },
        )
        .toList();
  }
}
