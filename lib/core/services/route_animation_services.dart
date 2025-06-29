import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

typedef AnimationUpdateCallback =
    void Function(LatLng position, double rotation);

/// Service for handling route marker animations
class RouteAnimationService {
  Timer? _animationTimer;
  int _currentAnimationIndex = 0;
  List<LatLng> _animationPoints = [];

  static const double _defaultSpeedMetersPerSecond = 5.0;
  static const int _defaultUpdateIntervalMs = 100;

  /// Callback type for animation updates

  /// Starts animating a marker along the given route points
  void animateMarkerAlongRoute(
    List<LatLng> routePoints, {
    required AnimationUpdateCallback onPositionUpdate,
    double speedMetersPerSecond = _defaultSpeedMetersPerSecond,
    int updateIntervalMs = _defaultUpdateIntervalMs,
    VoidCallback? onAnimationComplete,
  }) {
    log(
      'Animating marker along route with ${routePoints.length} points at speed $speedMetersPerSecond m/s',
    );
    if (routePoints.isEmpty) {
      debugPrint('No points to animate along');
      return;
    }

    // Stop any existing animation
    stopAnimation();

    _animationPoints = routePoints;
    _currentAnimationIndex = 0;
    final totalPoints = _animationPoints.length;

    // Calculate total distance
    var totalDistance = 0.0;
    for (var i = 0; i < _animationPoints.length - 1; i++) {
      totalDistance += _calculateDistance(
        _animationPoints[i],
        _animationPoints[i + 1],
      );
    }

    // Calculate animation parameters
    final totalTimeSeconds = totalDistance / speedMetersPerSecond;
    final totalSteps = (totalTimeSeconds * 1000 / updateIntervalMs).ceil();

    var progress = 0.0;

    _animationTimer = Timer.periodic(Duration(milliseconds: updateIntervalMs), (
      timer,
    ) {
      if (progress >= 1.0) {
        timer.cancel();
        onAnimationComplete?.call();
        return;
      }

      progress += 1.0 / totalSteps;
      if (progress > 1.0) progress = 1.0;

      // Calculate interpolated position
      final indexDouble = progress * (totalPoints - 1);
      final index1 = indexDouble.floor();
      final index2 = math.min(index1 + 1, totalPoints - 1);
      final weight = indexDouble - index1;

      final position = LatLng(
        _animationPoints[index1].latitude * (1 - weight) +
            _animationPoints[index2].latitude * weight,
        _animationPoints[index1].longitude * (1 - weight) +
            _animationPoints[index2].longitude * weight,
      );

      // Calculate rotation
      double rotation = 0.0;
      if (index1 > 0) {
        rotation = _calculateMarkerRotation(
          position,
          _animationPoints[index1 - 1],
        );
      }

      _currentAnimationIndex = index1;
      onPositionUpdate(position, rotation);
    });
  }

  /// Animates marker with custom easing
  void animateMarkerWithEasing(
    List<LatLng> routePoints, {
    required AnimationUpdateCallback onPositionUpdate,
    Curve curve = Curves.easeInOut,
    Duration duration = const Duration(seconds: 10),
    int updateIntervalMs = _defaultUpdateIntervalMs,
    VoidCallback? onAnimationComplete,
  }) {
    if (routePoints.isEmpty) {
      debugPrint('No points to animate along');
      return;
    }

    // Stop any existing animation
    stopAnimation();

    _animationPoints = routePoints;
    _currentAnimationIndex = 0;
    final totalPoints = _animationPoints.length;

    final totalSteps = (duration.inMilliseconds / updateIntervalMs).ceil();
    var currentStep = 0;

    _animationTimer = Timer.periodic(Duration(milliseconds: updateIntervalMs), (
      timer,
    ) {
      if (currentStep >= totalSteps) {
        timer.cancel();
        onAnimationComplete?.call();
        return;
      }

      final rawProgress = currentStep / totalSteps;
      final easedProgress = curve.transform(rawProgress);

      // Calculate interpolated position
      final indexDouble = easedProgress * (totalPoints - 1);
      final index1 = indexDouble.floor();
      final index2 = math.min(index1 + 1, totalPoints - 1);
      final weight = indexDouble - index1;

      final position = LatLng(
        _animationPoints[index1].latitude * (1 - weight) +
            _animationPoints[index2].latitude * weight,
        _animationPoints[index1].longitude * (1 - weight) +
            _animationPoints[index2].longitude * weight,
      );

      // Calculate rotation
      double rotation = 0.0;
      if (index1 > 0) {
        rotation = _calculateMarkerRotation(
          position,
          _animationPoints[index1 - 1],
        );
      }

      _currentAnimationIndex = index1;
      onPositionUpdate(position, rotation);
      currentStep++;
    });
  }

  /// Stops the current animation
  void stopAnimation() {
    _animationTimer?.cancel();
    _animationTimer = null;
  }

  /// Pauses the current animation
  void pauseAnimation() {
    _animationTimer?.cancel();
  }

  /// Checks if animation is currently running
  bool get isAnimating => _animationTimer?.isActive ?? false;

  /// Gets the current animation progress (0.0 to 1.0)
  double get animationProgress {
    if (_animationPoints.isEmpty) return 0.0;
    return _currentAnimationIndex / (_animationPoints.length - 1);
  }

  /// Calculates distance between two points using Haversine formula
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

  /// Calculates marker rotation based on direction
  double _calculateMarkerRotation(LatLng currentPoint, LatLng previousPoint) {
    final dx = currentPoint.longitude - previousPoint.longitude;
    final dy = currentPoint.latitude - previousPoint.latitude;
    return math.atan2(dx, dy) * 180 / math.pi;
  }

  /// Disposes of resources
  void dispose() {
    stopAnimation();
  }
}

/// Utility class for creating common animation configurations
class AnimationConfig {
  /// Fast animation configuration
  static const fast = AnimationConfigData(
    speedMetersPerSecond: 10.0,
    updateIntervalMs: 50,
  );

  /// Normal animation configuration
  static const normal = AnimationConfigData(
    speedMetersPerSecond: 5.0,
    updateIntervalMs: 100,
  );

  /// Slow animation configuration
  static const slow = AnimationConfigData(
    speedMetersPerSecond: 2.0,
    updateIntervalMs: 150,
  );
}

/// Data class for animation configuration
class AnimationConfigData {
  const AnimationConfigData({
    required this.speedMetersPerSecond,
    required this.updateIntervalMs,
  });
  final double speedMetersPerSecond;
  final int updateIntervalMs;
}
