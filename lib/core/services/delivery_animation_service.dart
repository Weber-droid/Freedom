import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

typedef DeliveryMarkerUpdateCallback =
    void Function(LatLng position, double rotation);

/// Dedicated animation service for delivery driver tracking
class DeliveryAnimationService {
  Timer? _animationTimer;
  Timer? _realTimeTimer;

  // Animation state
  bool _isAnimating = false;
  bool _isRealTimeMode = false;

  // Real-time tracking state
  LatLng? _currentPosition;
  LatLng? _targetPosition;
  double _currentBearing = 0.0;

  // Callbacks
  DeliveryMarkerUpdateCallback? _markerUpdateCallback;

  // Animation configuration
  static const Duration _realTimeUpdateInterval = Duration(milliseconds: 100);
  static const double _interpolationSpeed = 15.0; // m/s for smooth movement

  /// Start real-time tracking mode for delivery driver
  void startRealTimeTracking({
    required DeliveryMarkerUpdateCallback onMarkerUpdate,
    LatLng? initialPosition,
  }) {
    dev.log('🚚 DeliveryAnimationService: Starting real-time tracking mode');

    // Stop any existing animations
    stopAllAnimations();

    _isRealTimeMode = true;
    _markerUpdateCallback = onMarkerUpdate;
    _currentPosition = initialPosition;
    _targetPosition = initialPosition;

    // Start the smooth interpolation timer
    _startRealTimeInterpolation();

    // If we have an initial position, update the marker immediately
    if (initialPosition != null) {
      _markerUpdateCallback?.call(initialPosition, _currentBearing);
    }
  }

  /// Update the target position for real-time tracking
  void updateRealTimePosition(
    LatLng newPosition,
    double bearing, {
    Map<String, dynamic>? locationData,
  }) {
    if (!_isRealTimeMode) {
      dev.log(
        '⚠️ DeliveryAnimationService: Received position update but not in real-time mode',
      );
      return;
    }

    dev.log(
      '🚚 DeliveryAnimationService: Position update - ${newPosition.latitude.toStringAsFixed(6)}, ${newPosition.longitude.toStringAsFixed(6)} (${bearing.toStringAsFixed(1)}°)',
    );

    // Set current position if this is the first update
    _currentPosition ??= newPosition;

    // Update target position and bearing
    _targetPosition = newPosition;
    _currentBearing = bearing;

    // Log movement distance for debugging
    if (_currentPosition != null) {
      final distance = _calculateDistance(_currentPosition!, newPosition);
      dev.log('🚚 Movement distance: ${distance.toStringAsFixed(1)}m');
    }
  }

  /// Start the smooth interpolation between current and target positions
  void _startRealTimeInterpolation() {
    _realTimeTimer?.cancel();

    _realTimeTimer = Timer.periodic(_realTimeUpdateInterval, (timer) {
      if (!_isRealTimeMode ||
          _currentPosition == null ||
          _targetPosition == null ||
          _markerUpdateCallback == null) {
        return;
      }

      // Calculate distance to target
      final distanceToTarget = _calculateDistance(
        _currentPosition!,
        _targetPosition!,
      );

      // If we're close enough, just snap to target
      if (distanceToTarget < 1.0) {
        _currentPosition = _targetPosition;
        _markerUpdateCallback!(_currentPosition!, _currentBearing);
        return;
      }

      // Calculate how much to move this frame
      final moveDistancePerFrame =
          _interpolationSpeed *
          (_realTimeUpdateInterval.inMilliseconds / 1000.0);
      final moveRatio = math.min(moveDistancePerFrame / distanceToTarget, 1.0);

      // Interpolate position
      final newLat =
          _currentPosition!.latitude +
          ((_targetPosition!.latitude - _currentPosition!.latitude) *
              moveRatio);
      final newLng =
          _currentPosition!.longitude +
          ((_targetPosition!.longitude - _currentPosition!.longitude) *
              moveRatio);

      _currentPosition = LatLng(newLat, newLng);

      // Update the marker with new position
      _markerUpdateCallback!(_currentPosition!, _currentBearing);

      // Throttled debug logging
      if (DateTime.now().millisecondsSinceEpoch % 5000 < 100) {
        dev.log(
          '🚚 Interpolating: ${distanceToTarget.toStringAsFixed(1)}m to target',
        );
      }
    });
  }

  /// Stop real-time tracking
  void stopRealTimeTracking() {
    dev.log('🚚 DeliveryAnimationService: Stopping real-time tracking');

    _realTimeTimer?.cancel();
    _realTimeTimer = null;
    _isRealTimeMode = false;
    _markerUpdateCallback = null;
    _currentPosition = null;
    _targetPosition = null;
  }

  /// Stop all animations and tracking
  void stopAllAnimations() {
    dev.log('🚚 DeliveryAnimationService: Stopping all animations');

    _animationTimer?.cancel();
    _animationTimer = null;
    _isAnimating = false;

    stopRealTimeTracking();
  }

  /// Dispose of all resources
  void dispose() {
    dev.log('🚚 DeliveryAnimationService: Disposing');
    stopAllAnimations();
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(LatLng point1, LatLng point2) {
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

  /// Getters for current state
  bool get isRealTimeTracking =>
      _isRealTimeMode && (_realTimeTimer?.isActive ?? false);
  bool get isAnimating => _isAnimating;
  LatLng? get currentPosition => _currentPosition;
  double get currentBearing => _currentBearing;
}
