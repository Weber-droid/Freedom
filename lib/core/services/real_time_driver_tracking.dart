import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:freedom/core/services/route_services.dart';
import 'package:freedom/di/locator.dart';
import 'package:latlong2/latlong.dart' as ll;

class RealTimeDriverTrackingService {
  final RouteService _routeService = getIt<RouteService>();

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
  static const double _maxJumpDistanceMeters = 200.0;

  void Function(gmaps.LatLng position, double bearing, DriverLocationData data)?
  onDriverPositionUpdate;
  void Function(List<gmaps.LatLng> newRoute)? onRouteUpdate;
  void Function(String message)? onTrackingStatusUpdate;
  void Function(gmaps.LatLng position)? onDriverMarkerUpdate;

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

    onDriverPositionUpdate = onPositionUpdate;
    onRouteUpdate = onRouteUpdated;
    onTrackingStatusUpdate = onStatusUpdate;
    onDriverMarkerUpdate = onMarkerUpdate;

    _startUpdateMonitoring();

    _notifyStatus('Enhanced real-time tracking started (3s intervals)');
    dev.log('📍 Destination set: $destination');
  }

  void _startUpdateMonitoring() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _checkForStaleUpdates();
    });
  }

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

      _updateLocationHistory(driverLocationData);

      await _updateDriverPosition(smoothedPosition);

      onDriverMarkerUpdate?.call(smoothedPosition.position);

      await _checkForRouteRecalculation(smoothedPosition.position);
    } catch (e) {
      dev.log('❌ Error processing driver location: $e');
    }
  }

  DriverLocationData? _parseLocationData(Map<String, dynamic> data) {
    try {
      dev.log('🔍 Raw driver location data: $data');
      final coordinates = data['coordinates'] as List<dynamic>?;
      if (coordinates == null || coordinates.length < 2) {
        dev.log('❌ Invalid location data: missing or invalid coordinates');
        return null;
      }
      final serverLongitude = (coordinates[0] as num).toDouble();
      final serverLatitude = (coordinates[1] as num).toDouble();

      dev.log(
        '🔍 Server coordinates (GeoJSON format): [lng=$serverLongitude, lat=$serverLatitude]',
      );

      // Create LatLng with CORRECT order: latitude first, longitude second
      final position = gmaps.LatLng(serverLatitude, serverLongitude);

      dev.log(
        '✅ Corrected driver position: LatLng(lat=$serverLatitude, lng=$serverLongitude)',
      );

      // Validate coordinates are in valid ranges
      if (!_isValidCoordinateRange(serverLatitude, serverLongitude)) {
        dev.log('❌ Coordinates out of valid range');
        return null;
      }

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

      EtaData? eta;
      final etaMap = data['eta'] as Map<String, dynamic>?;
      if (etaMap != null) {
        eta = EtaData(
          value: math.max(0.0, (etaMap['value'] as num?)?.toDouble() ?? 0.0),
          text: etaMap['text'] as String? ?? '0 min',
        );
      }

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

  bool _isValidCoordinateRange(double latitude, double longitude) {
    if (latitude < -90 || latitude > 90) {
      dev.log('❌ Invalid latitude: $latitude (must be between -90 and 90)');
      return false;
    }
    if (longitude < -180 || longitude > 180) {
      dev.log('❌ Invalid longitude: $longitude (must be between -180 and 180)');
      return false;
    }
    return true;
  }

  bool _isValidPosition(DriverLocationData data) {
    if (data.accuracy > 50.0) {
      dev.log('⚠️ Poor GPS accuracy: ${data.accuracy}m');
      return false;
    }

    if (data.speed > _maxSpeedKmh) {
      dev.log('⚠️ Unrealistic speed: ${data.speed} km/h');
      return false;
    }

    if (_lastKnownDriverPosition != null) {
      final distance = _calculateDistanceInMeters(
        _lastKnownDriverPosition!,
        data.position,
      );

      final timeDiff =
          _lastPositionUpdate != null
              ? data.lastUpdate.difference(_lastPositionUpdate!).inSeconds
              : 3;

      if (distance > _maxJumpDistanceMeters && timeDiff < 10) {
        dev.log(
          '⚠️ Unrealistic position jump: ${distance.toStringAsFixed(1)}m in ${timeDiff}s',
        );
        return false;
      }
    }

    return true;
  }

  DriverLocationData? _applySmoothening(DriverLocationData newData) {
    if (_locationHistory.isEmpty) {
      return newData;
    }

    final recentPositions =
        _locationHistory
            .where((h) => DateTime.now().difference(h.timestamp).inSeconds < 15)
            .toList();

    if (recentPositions.length < 2) {
      return newData;
    }

    double totalWeight = 0.0;
    double weightedLat = 0.0;
    double weightedLng = 0.0;

    for (int i = 0; i < recentPositions.length; i++) {
      final history = recentPositions[i];
      final weight = (i + 1).toDouble();

      totalWeight += weight;
      weightedLat += history.position.latitude * weight;
      weightedLng += history.position.longitude * weight;
    }

    final smoothedLat = weightedLat / totalWeight;
    final smoothedLng = weightedLng / totalWeight;

    final smoothedPosition = gmaps.LatLng(smoothedLat, smoothedLng);

    final distanceFromNew = _calculateDistanceInMeters(
      smoothedPosition,
      newData.position,
    );

    if (distanceFromNew > 100.0) {
      dev.log(
        '⚠️ Smoothed position too far from new data: ${distanceFromNew.toStringAsFixed(1)}m',
      );
      return newData;
    }

    return newData.copyWith(position: smoothedPosition);
  }

  void _updateLocationHistory(DriverLocationData data) {
    _locationHistory.add(
      LocationHistory(
        position: data.position,
        timestamp: data.lastUpdate,
        speed: data.speed,
        heading: data.heading ?? 0.0,
        accuracy: data.accuracy,
      ),
    );

    if (_locationHistory.length > _maxHistoryLength) {
      _locationHistory.removeAt(0);
    }

    dev.log(
      '📊 Location history updated: ${_locationHistory.length} points (avg accuracy: ${_calculateAverageAccuracy().toStringAsFixed(1)}m)',
    );
  }

  Future<void> _updateDriverPosition(DriverLocationData data) async {
    _lastKnownDriverPosition = data.position;
    _lastPositionUpdate = data.lastUpdate;

    final bearing = _calculateBearingFromHistory();

    dev.log(
      '📍 Driver position updated: ${data.position.latitude.toStringAsFixed(6)}, '
      '${data.position.longitude.toStringAsFixed(6)} '
      '(speed: ${data.speed.toStringAsFixed(1)}km/h, bearing: ${bearing.toStringAsFixed(1)}°, '
      'accuracy: ${data.accuracy.toStringAsFixed(1)}m)',
    );

    onDriverPositionUpdate?.call(data.position, bearing, data);
  }

  Future<void> _checkForRouteRecalculation(gmaps.LatLng currentPosition) async {
    if (_currentDestination == null) return;

    if (_currentRoutePoints.isEmpty) {
      dev.log('📍 No route exists, calculating initial route');
      await _calculateNewRoute(currentPosition, _currentDestination!);
      return;
    }

    final distanceFromRoute = _calculateDistanceFromRoute(currentPosition);

    if (distanceFromRoute > _routeDeviationThresholdMeters) {
      final now = DateTime.now();
      final canRecalculate =
          _lastRouteRecalculation == null ||
          now.difference(_lastRouteRecalculation!).inSeconds >=
              _routeRecalculationCooldownSeconds;

      if (canRecalculate) {
        dev.log(
          '🔄 Route deviation detected: ${distanceFromRoute.toStringAsFixed(1)}m - Recalculating route',
        );
        await _calculateNewRoute(currentPosition, _currentDestination!);
      } else {
        dev.log(
          '⚠️ Route deviation detected but cooldown active: ${distanceFromRoute.toStringAsFixed(1)}m',
        );
      }
    }
  }

  Future<void> _calculateNewRoute(gmaps.LatLng start, gmaps.LatLng end) async {
    try {
      dev.log('🗺️ Calculating new route from $start to $end');

      final routeResult = await _routeService.getRoute(start, end);

      if (routeResult.isSuccess && routeResult.routePoints != null) {
        _currentRoutePoints = routeResult.routePoints!;
        _lastRouteRecalculation = DateTime.now();

        dev.log(
          '✅ New route calculated: ${_currentRoutePoints.length} points, '
          '${_routeService.calculateRouteDistance(_currentRoutePoints).toStringAsFixed(0)}m',
        );

        onRouteUpdate?.call(_currentRoutePoints);
        _notifyStatus('Route updated');
      } else {
        dev.log('❌ Route calculation failed: ${routeResult.errorMessage}');
        _notifyStatus('Route calculation failed');
      }
    } catch (e) {
      dev.log('❌ Error calculating route: $e');
      _notifyStatus('Route calculation error');
    }
  }

  double _calculateDistanceFromRoute(gmaps.LatLng point) {
    if (_currentRoutePoints.isEmpty) return double.infinity;

    double minDistance = double.infinity;

    for (int i = 0; i < _currentRoutePoints.length - 1; i++) {
      final distance = _distanceToLineSegment(
        point,
        _currentRoutePoints[i],
        _currentRoutePoints[i + 1],
      );
      minDistance = math.min(minDistance, distance);
    }

    return minDistance;
  }

  double _distanceToLineSegment(
    gmaps.LatLng point,
    gmaps.LatLng lineStart,
    gmaps.LatLng lineEnd,
  ) {
    final x0 = point.latitude;
    final y0 = point.longitude;
    final x1 = lineStart.latitude;
    final y1 = lineStart.longitude;
    final x2 = lineEnd.latitude;
    final y2 = lineEnd.longitude;

    final dx = x2 - x1;
    final dy = y2 - y1;

    if (dx == 0 && dy == 0) {
      return _calculateDistanceInMeters(point, lineStart);
    }

    final t = math.max(
      0,
      math.min(1, ((x0 - x1) * dx + (y0 - y1) * dy) / (dx * dx + dy * dy)),
    );

    final nearestPoint = gmaps.LatLng(x1 + t * dx, y1 + t * dy);
    return _calculateDistanceInMeters(point, nearestPoint);
  }

  double _calculateBearingFromHistory() {
    if (_locationHistory.length < 2) {
      return _locationHistory.lastOrNull?.heading ?? 0.0;
    }

    final recent = _locationHistory.last;
    final previous = _locationHistory[_locationHistory.length - 2];

    if (recent.position == previous.position) {
      return recent.heading;
    }

    final lat1 = previous.position.latitude * math.pi / 180;
    final lat2 = recent.position.latitude * math.pi / 180;
    final dLng =
        (recent.position.longitude - previous.position.longitude) *
        math.pi /
        180;

    final y = math.sin(dLng) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  double _calculateAverageAccuracy() {
    if (_locationHistory.isEmpty) return 0.0;

    final totalAccuracy = _locationHistory.fold<double>(
      0.0,
      (sum, item) => sum + item.accuracy,
    );
    return totalAccuracy / _locationHistory.length;
  }

  void _notifyStatus(String message) {
    onTrackingStatusUpdate?.call(message);
  }

  // ============================================================================
  // PUBLIC GETTERS AND UTILITY METHODS
  // ============================================================================

  /// Gets current route points for the active tracking
  List<gmaps.LatLng> get currentRoutePoints => _currentRoutePoints;

  /// Gets location history
  List<LocationHistory> get locationHistory => _locationHistory;

  /// Checks if tracking is active
  bool get isTracking => _isTracking;

  /// Gets current driver position
  gmaps.LatLng? get currentDriverPosition => _lastKnownDriverPosition;

  /// Gets last known driver position (alias for backward compatibility)
  gmaps.LatLng? get lastKnownDriverPosition => _lastKnownDriverPosition;

  /// Gets current destination
  gmaps.LatLng? get destination => _currentDestination;

  /// Gets current destination (alias for backward compatibility)
  gmaps.LatLng? get currentDestination => _currentDestination;

  /// Checks if driver has reached destination
  bool hasReachedDestination(gmaps.LatLng currentPosition) {
    if (_currentDestination == null) return false;

    final distance = _calculateDistanceInMeters(
      currentPosition,
      _currentDestination!,
    );

    // Consider arrived if within 50 meters
    const arrivalThreshold = 50.0;
    final hasArrived = distance <= arrivalThreshold;

    if (hasArrived) {
      dev.log(
        '🎯 Driver has reached destination (${distance.toStringAsFixed(1)}m away)',
      );
    }

    return hasArrived;
  }

  /// Gets distance to destination from current position
  double? getDistanceToDestination(gmaps.LatLng? currentPosition) {
    if (currentPosition == null || _currentDestination == null) return null;
    return _calculateDistanceInMeters(currentPosition, _currentDestination!);
  }

  void stopTracking() {
    dev.log('🛑 Stopping real-time driver tracking');

    _isTracking = false;
    _updateTimer?.cancel();
    _updateTimer = null;
    _currentRideId = null;
    _currentDriverId = null;
    _currentDestination = null;
    _lastKnownDriverPosition = null;
    _currentRoutePoints.clear();
    _locationHistory.clear();
    _lastPositionUpdate = null;
    _lastRouteRecalculation = null;

    onDriverPositionUpdate = null;
    onRouteUpdate = null;
    onTrackingStatusUpdate = null;
    onDriverMarkerUpdate = null;

    _notifyStatus('Tracking stopped');
  }

  void dispose() {
    stopTracking();
    dev.log('🗑️ RealTimeDriverTrackingService disposed');
  }

  TrackingStatus getTrackingStatus() {
    return TrackingStatus(
      isTracking: _isTracking,
      rideId: _currentRideId,
      driverId: _currentDriverId,
      lastKnownPosition: _lastKnownDriverPosition,
      destination: _currentDestination,
      routePointsCount: _currentRoutePoints.length,
      locationHistoryCount: _locationHistory.length,
      lastPositionUpdate: _lastPositionUpdate,
      averageAccuracy: _calculateAverageAccuracy(),
      currentRoutePoints: _currentRoutePoints,
    );
  }

  double _calculateDistanceInMeters(gmaps.LatLng point1, gmaps.LatLng point2) {
    const double earthRadius = 6371000;

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
}

class DriverLocationData {
  final String? driverId;
  final String? rideId;
  final gmaps.LatLng position;
  final String? status;
  final bool isMultiStop;
  final EtaData? eta;
  final double speed;
  final double? heading;
  final double accuracy;
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

  DriverLocationData copyWith({
    String? driverId,
    String? rideId,
    gmaps.LatLng? position,
    String? status,
    bool? isMultiStop,
    EtaData? eta,
    double? speed,
    double? heading,
    double? accuracy,
    DateTime? lastUpdate,
    bool? isSignificantMovement,
  }) {
    return DriverLocationData(
      driverId: driverId ?? this.driverId,
      rideId: rideId ?? this.rideId,
      position: position ?? this.position,
      status: status ?? this.status,
      isMultiStop: isMultiStop ?? this.isMultiStop,
      eta: eta ?? this.eta,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      accuracy: accuracy ?? this.accuracy,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      isSignificantMovement:
          isSignificantMovement ?? this.isSignificantMovement,
    );
  }
}

class EtaData {
  final double value;
  final String text;

  const EtaData({required this.value, required this.text});
}

class LocationHistory {
  final gmaps.LatLng position;
  final DateTime timestamp;
  final double speed;
  final double heading;
  final double accuracy;

  const LocationHistory({
    required this.position,
    required this.timestamp,
    required this.speed,
    required this.heading,
    required this.accuracy,
  });
}

class TrackingStatus {
  final bool isTracking;
  final String? rideId;
  final String? driverId;
  final gmaps.LatLng? lastKnownPosition;
  final gmaps.LatLng? destination;
  final int routePointsCount;
  final int locationHistoryCount;
  final DateTime? lastPositionUpdate;
  final double averageAccuracy;
  final List<gmaps.LatLng> currentRoutePoints;

  const TrackingStatus({
    required this.isTracking,
    this.rideId,
    this.driverId,
    this.lastKnownPosition,
    this.destination,
    required this.routePointsCount,
    required this.locationHistoryCount,
    this.lastPositionUpdate,
    required this.averageAccuracy,
    required this.currentRoutePoints,
  });

  bool get isStale {
    if (lastPositionUpdate == null) return true;
    return DateTime.now().difference(lastPositionUpdate!) >
        RealTimeDriverTrackingService._staleUpdateThreshold;
  }

  bool get hasGoodAccuracy => averageAccuracy < 20.0;

  bool get isReceivingRegularUpdates {
    if (lastPositionUpdate == null) return false;
    return DateTime.now().difference(lastPositionUpdate!) <
        RealTimeDriverTrackingService._expectedUpdateInterval * 2;
  }

  Duration? get timeSinceLastUpdate {
    if (lastPositionUpdate == null) return null;
    return DateTime.now().difference(lastPositionUpdate!);
  }

  String get statusSummary {
    if (!isTracking) return 'Not tracking';
    if (isStale) return 'Stale data';
    if (!hasGoodAccuracy) return 'Poor accuracy';
    if (!isReceivingRegularUpdates) return 'Irregular updates';
    return 'Tracking active';
  }

  String get formattedPosition {
    if (lastKnownPosition == null) return 'Unknown';
    return '${lastKnownPosition!.latitude.toStringAsFixed(6)}, ${lastKnownPosition!.longitude.toStringAsFixed(6)}';
  }

  String get formattedLastUpdate {
    if (lastPositionUpdate == null) return 'Never';
    final duration = DateTime.now().difference(lastPositionUpdate!);
    if (duration.inSeconds < 60) return '${duration.inSeconds}s ago';
    if (duration.inMinutes < 60) return '${duration.inMinutes}m ago';
    return '${duration.inHours}h ago';
  }

  double? get distanceToDestination {
    if (lastKnownPosition == null || destination == null) return null;

    const double earthRadius = 6371000;

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

  bool get isValid {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  gmaps.LatLng roundToPrecision(int decimalPlaces) {
    final factor = math.pow(10, decimalPlaces);
    return gmaps.LatLng(
      (latitude * factor).round() / factor,
      (longitude * factor).round() / factor,
    );
  }

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

  String get debugString {
    return 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)} ${isValid ? "✓" : "✗"}';
  }
}

extension RealTimeDriverTrackingServiceExtensions
    on RealTimeDriverTrackingService {
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

  Future<void> forceRouteRecalculation() async {
    if (_lastKnownDriverPosition != null && _currentDestination != null) {
      _lastRouteRecalculation = null;
      await _calculateNewRoute(_lastKnownDriverPosition!, _currentDestination!);
    }
  }

  void clearLocationHistory() {
    _locationHistory.clear();
    dev.log('📊 Location history cleared');
  }

  Map<String, dynamic> getPerformanceMetrics() {
    final now = DateTime.now();

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

    final accuracyValues = _locationHistory.map((h) => h.accuracy).toList();
    double minAccuracy =
        accuracyValues.isNotEmpty ? accuracyValues.reduce(math.min) : 0.0;
    double maxAccuracy =
        accuracyValues.isNotEmpty ? accuracyValues.reduce(math.max) : 0.0;

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
