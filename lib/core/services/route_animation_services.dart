import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

typedef AnimationUpdateCallback =
    void Function(LatLng position, double rotation);
typedef RealTimeUpdateCallback =
    void Function(
      LatLng position,
      double bearing,
      Map<String, dynamic> locationData,
    );

/// Enhanced service for handling route marker animations with real-time integration
class RouteAnimationService {
  Timer? _animationTimer;
  Timer? _realTimeTimer;
  int _currentAnimationIndex = 0;
  List<LatLng> _animationPoints = [];

  // Real-time tracking state
  bool _isRealTimeMode = false;
  LatLng? _currentRealTimePosition;
  LatLng? _targetRealTimePosition;
  double _currentBearing = 0.0;
  AnimationUpdateCallback? _realTimeCallback;

  // Animation smoothing for real-time updates
  static const Duration _realTimeUpdateInterval = Duration(milliseconds: 100);
  static const double _defaultSpeedMetersPerSecond = 5.0;
  static const int _defaultUpdateIntervalMs = 100;

  /// Starts animating a marker along the given route points (for initial route display)
  void animateMarkerAlongRoute(
    List<LatLng> routePoints, {
    required AnimationUpdateCallback onPositionUpdate,
    double speedMetersPerSecond = _defaultSpeedMetersPerSecond,
    int updateIntervalMs = _defaultUpdateIntervalMs,
    VoidCallback? onAnimationComplete,
  }) {
    dev.log(
      '🎬 Starting route animation with ${routePoints.length} points at ${speedMetersPerSecond}m/s',
    );

    if (routePoints.isEmpty) {
      dev.log('❌ No points to animate along');
      return;
    }

    // Stop any existing animation
    stopAnimation();

    _isRealTimeMode = false;
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

    dev.log(
      '🎬 Animation: ${totalDistance.toStringAsFixed(0)}m in ${totalTimeSeconds.toStringAsFixed(1)}s (${totalSteps} steps)',
    );

    _animationTimer = Timer.periodic(Duration(milliseconds: updateIntervalMs), (
      timer,
    ) {
      if (progress >= 1.0) {
        timer.cancel();
        dev.log('✅ Route animation completed');
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

      // Calculate rotation based on movement direction
      double rotation = 0.0;
      if (index2 < totalPoints) {
        rotation = _calculateMarkerRotation(
          _animationPoints[index1],
          _animationPoints[index2],
        );
      }

      _currentAnimationIndex = index1;
      onPositionUpdate(position, rotation);
    });
  }

  /// Starts real-time tracking mode with smooth position interpolation
  void startRealTimeTracking({
    required AnimationUpdateCallback onPositionUpdate,
    LatLng? initialPosition,
  }) {
    dev.log('🔴 Starting real-time tracking mode');

    // Stop route animation if running
    stopAnimation();

    _isRealTimeMode = true;
    _realTimeCallback = onPositionUpdate;
    _currentRealTimePosition = initialPosition;
    _targetRealTimePosition = initialPosition;

    // Start smooth interpolation timer
    _startRealTimeInterpolation();
  }

  /// Updates real-time position with smooth animation to new location
  void updateRealTimePosition(
    LatLng newPosition,
    double bearing, {
    Map<String, dynamic>? locationData,
  }) {
    if (!_isRealTimeMode) {
      dev.log('⚠️ Received real-time update but not in real-time mode');
      return;
    }

    dev.log(
      '📍 Real-time position update: ${newPosition.latitude.toStringAsFixed(6)}, ${newPosition.longitude.toStringAsFixed(6)} (${bearing.toStringAsFixed(1)}°)',
    );

    // Set current position as starting point if this is the first update
    _currentRealTimePosition ??= newPosition;

    _targetRealTimePosition = newPosition;
    _currentBearing = bearing;

    // Log movement distance for debugging
    if (_currentRealTimePosition != null) {
      final distance = _calculateDistance(
        _currentRealTimePosition!,
        newPosition,
      );
      dev.log('📏 Movement distance: ${distance.toStringAsFixed(1)}m');
    }
  }

  /// Starts smooth interpolation between current and target positions
  void _startRealTimeInterpolation() {
    _realTimeTimer?.cancel();

    _realTimeTimer = Timer.periodic(_realTimeUpdateInterval, (timer) {
      if (!_isRealTimeMode ||
          _currentRealTimePosition == null ||
          _targetRealTimePosition == null) {
        return;
      }

      // Check if we're close enough to target
      final distance = _calculateDistance(
        _currentRealTimePosition!,
        _targetRealTimePosition!,
      );
      if (distance < 1.0) {
        // Within 1 meter, consider arrived
        return;
      }

      // Calculate smooth movement towards target
      const double moveSpeedMps = 15.0; // 15 m/s (realistic driving speed)
      final double moveDistancePerUpdate =
          moveSpeedMps * (_realTimeUpdateInterval.inMilliseconds / 1000);

      final double progress = math.min(moveDistancePerUpdate / distance, 1.0);

      // Interpolate position
      final newLat =
          _currentRealTimePosition!.latitude +
          ((_targetRealTimePosition!.latitude -
                  _currentRealTimePosition!.latitude) *
              progress);
      final newLng =
          _currentRealTimePosition!.longitude +
          ((_targetRealTimePosition!.longitude -
                  _currentRealTimePosition!.longitude) *
              progress);

      _currentRealTimePosition = LatLng(newLat, newLng);

      // Update marker position with smooth movement
      _realTimeCallback?.call(_currentRealTimePosition!, _currentBearing);

      // Debug logging (throttled)
      if (DateTime.now().millisecondsSinceEpoch % 2000 < 100) {
        dev.log(
          '🎬 Interpolating to target: ${distance.toStringAsFixed(1)}m remaining',
        );
      }
    });
  }

  /// Animates marker with custom easing (for special effects)
  void animateMarkerWithEasing(
    List<LatLng> routePoints, {
    required AnimationUpdateCallback onPositionUpdate,
    Curve curve = Curves.easeInOut,
    Duration duration = const Duration(seconds: 10),
    int updateIntervalMs = _defaultUpdateIntervalMs,
    VoidCallback? onAnimationComplete,
  }) {
    dev.log('🎬 Starting eased animation over ${duration.inSeconds}s');

    if (routePoints.isEmpty) {
      dev.log('❌ No points to animate along');
      return;
    }

    // Stop any existing animation
    stopAnimation();

    _isRealTimeMode = false;
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
        dev.log('✅ Eased animation completed');
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
      if (index2 < totalPoints) {
        rotation = _calculateMarkerRotation(
          _animationPoints[index1],
          _animationPoints[index2],
        );
      }

      _currentAnimationIndex = index1;
      onPositionUpdate(position, rotation);
      currentStep++;
    });
  }

  /// Smoothly transitions from route animation to real-time tracking
  void transitionToRealTimeTracking({
    required AnimationUpdateCallback onPositionUpdate,
    LatLng? firstRealTimePosition,
  }) {
    dev.log('🔄 Transitioning from route animation to real-time tracking');

    // Get current position from animation
    LatLng? currentPosition;
    if (_animationPoints.isNotEmpty &&
        _currentAnimationIndex < _animationPoints.length) {
      currentPosition = _animationPoints[_currentAnimationIndex];
    }

    // Stop route animation
    stopAnimation();

    // Start real-time tracking from current position
    startRealTimeTracking(
      onPositionUpdate: onPositionUpdate,
      initialPosition: currentPosition ?? firstRealTimePosition,
    );

    // If we have a first real-time position, animate to it
    if (firstRealTimePosition != null) {
      updateRealTimePosition(firstRealTimePosition, _currentBearing);
    }
  }

  /// Stops all animations and real-time tracking
  void stopAnimation() {
    _animationTimer?.cancel();
    _animationTimer = null;
    dev.log('🛑 Route animation stopped');
  }

  void stopRealTimeTracking() {
    _realTimeTimer?.cancel();
    _realTimeTimer = null;
    _isRealTimeMode = false;
    _realTimeCallback = null;
    dev.log('🛑 Real-time tracking stopped');
  }

  void stopAll() {
    stopAnimation();
    stopRealTimeTracking();
    dev.log('🛑 All animations and tracking stopped');
  }

  /// Pauses current animation (route animation only)
  void pauseAnimation() {
    _animationTimer?.cancel();
    dev.log('⏸️ Animation paused');
  }

  /// Checks if route animation is currently running
  bool get isAnimating => _animationTimer?.isActive ?? false;

  /// Checks if real-time tracking is active
  bool get isRealTimeTracking =>
      _isRealTimeMode && (_realTimeTimer?.isActive ?? false);

  /// Gets the current animation progress (0.0 to 1.0)
  double get animationProgress {
    if (_animationPoints.isEmpty) return 0.0;
    return _currentAnimationIndex / (_animationPoints.length - 1);
  }

  /// Gets current real-time position
  LatLng? get currentRealTimePosition => _currentRealTimePosition;

  /// Gets current bearing
  double get currentBearing => _currentBearing;

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
  double _calculateMarkerRotation(LatLng fromPoint, LatLng toPoint) {
    final lat1 = fromPoint.latitude * math.pi / 180;
    final lat2 = toPoint.latitude * math.pi / 180;
    final dLng = (toPoint.longitude - fromPoint.longitude) * math.pi / 180;

    final y = math.sin(dLng) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  /// Disposes of resources
  void dispose() {
    stopAll();
    dev.log('🗑️ RouteAnimationService disposed');
  }
}

/// Enhanced utility class for creating animation configurations
class AnimationConfig {
  /// Fast animation for initial route display
  static const fast = AnimationConfigData(
    speedMetersPerSecond: 15.0,
    updateIntervalMs: 50,
  );

  /// Normal animation for regular route display
  static const normal = AnimationConfigData(
    speedMetersPerSecond: 8.0,
    updateIntervalMs: 100,
  );

  /// Slow animation for detailed route viewing
  static const slow = AnimationConfigData(
    speedMetersPerSecond: 3.0,
    updateIntervalMs: 150,
  );

  /// Real-time configuration optimized for live tracking
  static const realTime = AnimationConfigData(
    speedMetersPerSecond: 12.0, // Realistic driving speed
    updateIntervalMs: 100, // Smooth updates
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

/// Animation state tracker for debugging
class AnimationState {
  final bool isRouteAnimating;
  final bool isRealTimeTracking;
  final double routeProgress;
  final LatLng? currentPosition;
  final double currentBearing;
  final int totalRoutePoints;

  const AnimationState({
    required this.isRouteAnimating,
    required this.isRealTimeTracking,
    required this.routeProgress,
    this.currentPosition,
    required this.currentBearing,
    required this.totalRoutePoints,
  });

  @override
  String toString() {
    return 'AnimationState(route: $isRouteAnimating, realTime: $isRealTimeTracking, '
        'progress: ${(routeProgress * 100).toStringAsFixed(1)}%, '
        'position: $currentPosition, bearing: ${currentBearing.toStringAsFixed(1)}°)';
  }
}
