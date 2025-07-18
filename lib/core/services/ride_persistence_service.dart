import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:freedom/core/services/persistence_serializer_helper.dart';
import 'package:freedom/core/services/push_notification_service/socket_ride_models.dart';
import 'package:freedom/core/services/route_services.dart';
import 'package:freedom/feature/home/models/request_ride_model.dart';
import 'package:freedom/feature/home/models/request_ride_response.dart';
import 'package:freedom/feature/home/ride_cubit/ride_cubit.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enhanced persistence service for ride state management
class RidePersistenceService {
  static const String _rideStateKey = 'persisted_ride_state';
  static const String _rideRequestKey = 'persisted_ride_request';
  static const String _activeRideIdKey = 'active_ride_id';
  static const String _lastLocationKey = 'last_known_location';
  static const String _trackingStateKey = 'tracking_state';
  static const String _routeDataKey = 'route_data';
  static const String _driverDataKey = 'driver_data';
  static const String _rideTimestampKey = 'ride_timestamp';
  static const String _appStateKey = 'app_state_when_killed';

  final SharedPreferences _prefs;

  RidePersistenceService(this._prefs);

  /// Initialize persistence service
  static Future<RidePersistenceService> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    return RidePersistenceService(prefs);
  }

  /// Persist complete ride state with all necessary data
  Future<void> persistCompleteRideState(RideState rideState) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final stateData = {
        'timestamp': timestamp,
        'status': rideState.status.toString(),
        'currentRideId': rideState.currentRideId,
        'showRiderFound': rideState.showRiderFound,
        'riderAvailable': rideState.riderAvailable,
        'isSearching': rideState.isSearching,
        'searchTimeElapsed': rideState.searchTimeElapsed,
        'rideInProgress': rideState.rideInProgress,
        'driverHasArrived': rideState.driverHasArrived,
        'isRealTimeTrackingActive': rideState.isRealTimeTrackingActive,
        'routeDisplayed': rideState.routeDisplayed,
        'isMultiDestination': rideState.isMultiDestination,
        'paymentMethod': rideState.paymentMethod,
        'currentSpeed': rideState.currentSpeed,
        'lastPositionUpdate': rideState.lastPositionUpdate?.toIso8601String(),
        'trackingStatusMessage': rideState.trackingStatusMessage,
        'routeRecalculated': rideState.routeRecalculated,
        'routeProgress': rideState.routeProgress,
        'driverOffRoute': rideState.driverOffRoute,
        'driverAnimationComplete': rideState.driverAnimationComplete,
        'currentSegmentIndex': rideState.currentSegmentIndex,
        'estimatedDistance': rideState.estimatedDistance,
        'estimatedTimeArrival': rideState.estimatedTimeArrival,
        'nearestDriverDistance': rideState.nearestDriverDistance,
        'lastRouteRecalculation':
            rideState.lastRouteRecalculation?.toIso8601String(),

        // Driver position
        'currentDriverPosition':
            rideState.currentDriverPosition != null
                ? {
                  'latitude': rideState.currentDriverPosition!.latitude,
                  'longitude': rideState.currentDriverPosition!.longitude,
                }
                : null,

        // Camera target
        'cameraTarget':
            rideState.cameraTarget != null
                ? {
                  'latitude': rideState.cameraTarget!.latitude,
                  'longitude': rideState.cameraTarget!.longitude,
                }
                : null,

        // Response data
        'rideResponse': rideState.rideResponse?.toJson(),

        // Driver models
        'driverAccepted': rideState.driverAccepted,
        'driverStarted': rideState.driverStarted,
        'driverArrived': rideState.driverArrived,
        'driverCompleted': rideState.driverCompleted,
        'driverCancelled': rideState.driverCancelled,
        'driverRejected': rideState.driverRejected,

        // Properly serialize route data using the new helpers
        'routePolylines': PersistenceSerializationHelper.serializePolylines(
          rideState.routePolylines,
        ),
        'routeMarkers': PersistenceSerializationHelper.serializeMarkers(
          rideState.routeMarkers,
        ),
        'routeSegments': _serializeRouteSegments(rideState.routeSegments),

        // Ride request model
        'rideRequestModel': rideState.rideRequestModel?.toJson(),

        // App metadata
        'appVersion': '1.0.0',
        'persistenceVersion': '2.0',
      };

      await _prefs.setString(_rideStateKey, jsonEncode(stateData));
      await _prefs.setString(_rideTimestampKey, timestamp);

      // Also persist active ride ID separately for quick access
      if (rideState.currentRideId != null) {
        await _prefs.setString(_activeRideIdKey, rideState.currentRideId!);
      }

      dev.log('✅ Complete ride state persisted successfully');
      dev.log('   - Polylines: ${rideState.routePolylines.length}');
      dev.log('   - Markers: ${rideState.routeMarkers.length}');
      dev.log('   - Route displayed: ${rideState.routeDisplayed}');
    } catch (e, stack) {
      dev.log('❌ Error persisting complete ride state: $e\n$stack');
    }
  }

  /// Persist driver location data for real-time tracking
  Future<void> persistDriverLocation(
    LatLng position, {
    double? speed,
    double? bearing,
    DateTime? timestamp,
  }) async {
    try {
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': speed,
        'bearing': bearing,
        'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
      };

      await _prefs.setString(_lastLocationKey, jsonEncode(locationData));
    } catch (e) {
      dev.log('❌ Error persisting driver location: $e');
    }
  }

  Future<void> persistPolylines(Set<Polyline> polylines) async {
    try {
      final polylinesData = <String, Map<String, dynamic>>{};

      for (final polyline in polylines) {
        polylinesData[polyline.polylineId.value] = {
          'polylineId': polyline.polylineId.value,
          'points':
              polyline.points
                  .map(
                    (point) => {
                      'latitude': point.latitude,
                      'longitude': point.longitude,
                    },
                  )
                  .toList(),
          'color': polyline.color.value,
          'width': polyline.width,
          'patterns':
              polyline.patterns
                  .map((pattern) => {'type': pattern.runtimeType.toString()})
                  .toList(),
        };
      }

      await _prefs.setString('persisted_polylines', jsonEncode(polylinesData));
      dev.log('✅ Persisted ${polylines.length} polylines');
    } catch (e) {
      dev.log('❌ Error persisting polylines: $e');
    }
  }

  Future<Set<Polyline>?> loadPersistedPolylines() async {
    try {
      final polylinesJson = _prefs.getString('persisted_polylines');
      if (polylinesJson == null) return null;

      final polylinesData = jsonDecode(polylinesJson) as Map<String, dynamic>;
      dev.log('PolyLibejson data: $polylinesData');
      final restoredPolylines = <Polyline>{};

      for (final entry in polylinesData.entries) {
        final polylineData = entry.value as Map<String, dynamic>;

        final points =
            (polylineData['points'] as List)
                .map(
                  (point) => LatLng(
                    point['latitude'] as double,
                    point['longitude'] as double,
                  ),
                )
                .toList();
        log('points: $points');
        final polyline = Polyline(
          polylineId: PolylineId(polylineData['polylineId'] as String),
          points: points,
          color: Color(polylineData['color'] as int),
          width: polylineData['width'] as int,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        );

        restoredPolylines.add(polyline);
      }

      dev.log('✅ Restored ${restoredPolylines.length} polylines');
      return restoredPolylines;
    } catch (e) {
      dev.log('❌ Error loading persisted polylines: $e');
      return null;
    }
  }

  Future<void> persistMarkers(Map<MarkerId, Marker> markers) async {
    try {
      final markersData = <String, Map<String, dynamic>>{};

      for (final entry in markers.entries) {
        final markerId = entry.key;
        final marker = entry.value;

        markersData[markerId.value] = {
          'markerId': markerId.value,
          'latitude': marker.position.latitude,
          'longitude': marker.position.longitude,
          'infoWindowTitle': marker.infoWindow.title,
          'infoWindowSnippet': marker.infoWindow.snippet,
          'rotation': marker.rotation,
          'anchor': {'dx': marker.anchor.dx, 'dy': marker.anchor.dy},
          'consumeTapEvents': marker.consumeTapEvents,
          'draggable': marker.draggable,
          'flat': marker.flat,
          'visible': marker.visible,
          'zIndex': marker.zIndex,
          'iconType': _getIconType(markerId, marker),
        };
      }

      await _prefs.setString('persisted_markers', jsonEncode(markersData));
      dev.log('✅ Persisted ${markers.length} markers');
    } catch (e) {
      dev.log('❌ Error persisting markers: $e');
    }
  }

  Future<Map<MarkerId, Marker>?> loadPersistedMarkers() async {
    try {
      final markersJson = _prefs.getString('persisted_markers');
      if (markersJson == null) return null;

      final markersData = jsonDecode(markersJson) as Map<String, dynamic>;
      final restoredMarkers = <MarkerId, Marker>{};

      for (final entry in markersData.entries) {
        final markerData = entry.value as Map<String, dynamic>;
        final markerId = MarkerId(markerData['markerId'] as String);

        // Recreate the marker icon based on type
        final icon = await _recreateMarkerIcon(
          markerData['iconType'] as String,
          markerId.value,
        );

        final marker = Marker(
          markerId: markerId,
          position: LatLng(
            markerData['latitude'] as double,
            markerData['longitude'] as double,
          ),
          infoWindow: InfoWindow(
            title: markerData['infoWindowTitle'] as String?,
            snippet: markerData['infoWindowSnippet'] as String?,
          ),
          icon: icon,
          rotation: markerData['rotation'] as double? ?? 0.0,
          anchor: Offset(
            markerData['anchor']['dx'] as double? ?? 0.5,
            markerData['anchor']['dy'] as double? ?? 1.0,
          ),
          consumeTapEvents: markerData['consumeTapEvents'] as bool? ?? false,
          draggable: markerData['draggable'] as bool? ?? false,
          flat: markerData['flat'] as bool? ?? false,
          visible: markerData['visible'] as bool? ?? true,
          zIndex: markerData['zIndex'] as double? ?? 0.0,
        );

        restoredMarkers[markerId] = marker;
      }

      dev.log('✅ Restored ${restoredMarkers.length} markers');
      return restoredMarkers;
    } catch (e) {
      dev.log('❌ Error loading persisted markers: $e');
      return null;
    }
  }

  /// Helper method to determine icon type for persistence
  String _getIconType(MarkerId markerId, Marker marker) {
    final id = markerId.value.toLowerCase();
    final title = marker.infoWindow.title?.toLowerCase() ?? '';

    if (id.contains('driver') || title.contains('driver')) {
      return 'driver';
    } else if (id.contains('pickup') ||
        id.contains('origin') ||
        title.contains('pickup')) {
      return 'pickup';
    } else if (id.contains('destination') ||
        id.contains('dropoff') ||
        title.contains('destination')) {
      return 'destination';
    } else if (id.contains('stop') || title.contains('stop')) {
      return 'stop';
    }

    return 'default';
  }

  Future<BitmapDescriptor> _recreateMarkerIcon(
    String iconType,
    String markerId,
  ) async {
    try {
      switch (iconType) {
        case 'driver':
          try {
            return await BitmapDescriptor.asset(
              const ImageConfiguration(size: Size(48, 48)),
              'assets/images/bike_marker.png',
            );
          } catch (e) {
            return BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            );
          }

        case 'pickup':
          try {
            return await BitmapDescriptor.asset(
              const ImageConfiguration(size: Size(40, 40)),
              'assets/images/user_pin.png',
            );
          } catch (e) {
            return BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            );
          }

        case 'destination':
          return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

        case 'stop':
          return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          );

        default:
          return BitmapDescriptor.defaultMarker;
      }
    } catch (e) {
      dev.log('❌ Error recreating marker icon for $iconType: $e');
      return BitmapDescriptor.defaultMarker;
    }
  }

  /// Persist tracking state for real-time mode
  Future<void> persistTrackingState({
    required bool isActive,
    required String rideId,
    required String driverId,
    LatLng? destination,
    Map<String, dynamic>? trackingMetrics,
  }) async {
    try {
      final trackingData = {
        'isActive': isActive,
        'rideId': rideId,
        'driverId': driverId,
        'destination':
            destination != null
                ? {
                  'latitude': destination.latitude,
                  'longitude': destination.longitude,
                }
                : null,
        'trackingMetrics': trackingMetrics,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _prefs.setString(_trackingStateKey, jsonEncode(trackingData));
    } catch (e) {
      dev.log('❌ Error persisting tracking state: $e');
    }
  }

  /// Persist route data for route reconstruction
  Future<void> persistRouteData(
    List<LatLng> routePoints, {
    List<RouteSegment>? segments,
    double? totalDistance,
    Duration? estimatedDuration,
  }) async {
    try {
      final routeData = {
        'routePoints':
            routePoints
                .map(
                  (point) => {
                    'latitude': point.latitude,
                    'longitude': point.longitude,
                  },
                )
                .toList(),
        'segments':
            segments
                ?.map(
                  (segment) => {
                    'startLat': segment.startLocation.latitude,
                    'startLng': segment.startLocation.longitude,
                    'endLat': segment.endLocation.latitude,
                    'endLng': segment.endLocation.longitude,
                    'segmentIndex': segment.segmentIndex,
                    'points':
                        segment.routePoints
                            .map(
                              (point) => {
                                'latitude': point.latitude,
                                'longitude': point.longitude,
                              },
                            )
                            .toList(),
                  },
                )
                .toList(),
        'totalDistance': totalDistance,
        'estimatedDuration': estimatedDuration?.inSeconds,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _prefs.setString(_routeDataKey, jsonEncode(routeData));
    } catch (e) {
      dev.log('❌ Error persisting route data: $e');
    }
  }

  /// Record app state when killed/backgrounded
  Future<void> recordAppStateOnKill(Map<String, dynamic> appState) async {
    try {
      final stateData = {
        ...appState,
        'killedAt': DateTime.now().toIso8601String(),
        'wasInForeground': true,
      };

      await _prefs.setString(_appStateKey, jsonEncode(stateData));
    } catch (e) {
      dev.log('❌ Error recording app state on kill: $e');
    }
  }

  /// Load complete persisted ride state
  Future<PersistedRideData?> loadCompleteRideState() async {
    try {
      final stateJson = _prefs.getString(_rideStateKey);
      if (stateJson == null) return null;

      final stateData = jsonDecode(stateJson) as Map<String, dynamic>;

      // Check if state is too old (older than 24 hours)
      final timestamp = DateTime.tryParse(stateData['timestamp'] ?? '');
      if (timestamp != null &&
          DateTime.now().difference(timestamp).inHours > 24) {
        dev.log('⚠️ Persisted state is too old, clearing...');
        await clearAllPersistedData();
        return null;
      }

      // Use the enhanced deserialization method
      return PersistedRideData.fromJsonWithDeserialization(stateData);
    } catch (e, stack) {
      dev.log('❌ Error loading complete ride state: $e\n$stack');
      return null;
    }
  }

  /// Load last known driver location
  Future<PersistedLocation?> loadLastDriverLocation() async {
    try {
      final locationJson = _prefs.getString(_lastLocationKey);
      if (locationJson == null) return null;

      final locationData = jsonDecode(locationJson) as Map<String, dynamic>;
      return PersistedLocation.fromJson(locationData);
    } catch (e) {
      dev.log('❌ Error loading last driver location: $e');
      return null;
    }
  }

  /// Load tracking state
  Future<PersistedTrackingState?> loadTrackingState() async {
    try {
      final trackingJson = _prefs.getString(_trackingStateKey);
      if (trackingJson == null) return null;

      final trackingData = jsonDecode(trackingJson) as Map<String, dynamic>;
      return PersistedTrackingState.fromJson(trackingData);
    } catch (e) {
      dev.log('❌ Error loading tracking state: $e');
      return null;
    }
  }

  /// Load route data
  Future<PersistedRouteData?> loadRouteData() async {
    try {
      final routeJson = _prefs.getString(_routeDataKey);
      if (routeJson == null) return null;

      final routeData = jsonDecode(routeJson) as Map<String, dynamic>;
      return PersistedRouteData.fromJson(routeData);
    } catch (e) {
      dev.log('❌ Error loading route data: $e');
      return null;
    }
  }

  /// Get active ride ID quickly
  Future<String?> getActiveRideId() async {
    return _prefs.getString(_activeRideIdKey);
  }

  /// Check if we have any persisted ride data
  Future<bool> hasActiveRide() async {
    final rideId = await getActiveRideId();
    final stateData = _prefs.getString(_rideStateKey);
    return rideId != null && stateData != null;
  }

  Future<bool> wasAppKilledDuringRide() async {
    final appStateJson = _prefs.getString(_appStateKey);
    if (appStateJson == null) return false;

    try {
      final appState = jsonDecode(appStateJson) as Map<String, dynamic>;
      final killedAt = DateTime.tryParse(appState['killedAt'] ?? '');

      if (killedAt == null) return false;

      final timeSinceKill = DateTime.now().difference(killedAt);
      return timeSinceKill.inHours < 12;
    } catch (e) {
      return false;
    }
  }

  /// Clear all persisted data
  Future<void> clearAllPersistedData() async {
    try {
      await Future.wait([
        _prefs.remove(_rideStateKey),
        _prefs.remove(_rideRequestKey),
        _prefs.remove(_activeRideIdKey),
        _prefs.remove(_lastLocationKey),
        _prefs.remove(_trackingStateKey),
        _prefs.remove(_routeDataKey),
        _prefs.remove(_driverDataKey),
        _prefs.remove(_rideTimestampKey),
        _prefs.remove(_appStateKey),
      ]);

      dev.log('✅ All persisted data cleared');
    } catch (e) {
      dev.log('❌ Error clearing persisted data: $e');
    }
  }

  /// Clear only completed ride data (keep app state)
  Future<void> clearRideData() async {
    try {
      await Future.wait([
        _prefs.remove(_rideStateKey),
        _prefs.remove(_rideRequestKey),
        _prefs.remove(_activeRideIdKey),
        _prefs.remove(_lastLocationKey),
        _prefs.remove(_trackingStateKey),
        _prefs.remove(_routeDataKey),
        _prefs.remove(_driverDataKey),
        _prefs.remove(_rideTimestampKey),
      ]);

      dev.log('✅ Ride data cleared');
    } catch (e) {
      dev.log('❌ Error clearing ride data: $e');
    }
  }

  /// Get persistence statistics for debugging
  Future<Map<String, dynamic>> getPersistenceStats() async {
    final rideStateSize = _prefs.getString(_rideStateKey)?.length ?? 0;
    final locationSize = _prefs.getString(_lastLocationKey)?.length ?? 0;
    final routeSize = _prefs.getString(_routeDataKey)?.length ?? 0;

    return {
      'hasActiveRide': await hasActiveRide(),
      'rideStateSize': rideStateSize,
      'locationSize': locationSize,
      'routeSize': routeSize,
      'totalSize': rideStateSize + locationSize + routeSize,
      'lastPersisted': _prefs.getString(_rideTimestampKey),
      'wasAppKilled': await wasAppKilledDuringRide(),
    };
  }

  // Helper methods for serialization
  List<Map<String, dynamic>> _serializePolylines(Set<Polyline> polylines) {
    return polylines
        .map(
          (polyline) => {
            'polylineId': polyline.polylineId.value,
            'points':
                polyline.points
                    .map(
                      (point) => {
                        'latitude': point.latitude,
                        'longitude': point.longitude,
                      },
                    )
                    .toList(),
            'color': polyline.color.value,
            'width': polyline.width,
          },
        )
        .toList();
  }

  List<Map<String, dynamic>> _serializeMarkers(Map<MarkerId, Marker> markers) {
    return markers.values
        .map(
          (marker) => {
            'markerId': marker.markerId.value,
            'latitude': marker.position.latitude,
            'longitude': marker.position.longitude,
            'infoWindowTitle': marker.infoWindow.title,
            'infoWindowSnippet': marker.infoWindow.snippet,
            'rotation': marker.rotation,
          },
        )
        .toList();
  }

  List<Map<String, dynamic>>? _serializeRouteSegments(
    List<RouteSegment>? segments,
  ) {
    return segments
        ?.map(
          (segment) => {
            'startLat': segment.startLocation.latitude,
            'startLng': segment.startLocation.longitude,
            'endLat': segment.endLocation.latitude,
            'endLng': segment.endLocation.longitude,
            'segmentIndex': segment.segmentIndex,
            'routePoints':
                segment.routePoints
                    .map(
                      (point) => {
                        'latitude': point.latitude,
                        'longitude': point.longitude,
                      },
                    )
                    .toList(),
          },
        )
        .toList();
  }
}

/// Enhanced persisted ride data model
class PersistedRideData {
  final String timestamp;
  final RideRequestStatus status;
  final String? rideId;
  final bool showRiderFound;
  final bool riderAvailable;
  final bool isSearching;
  final int searchTimeElapsed;
  final bool rideInProgress;
  final bool driverHasArrived;
  final bool isRealTimeTrackingActive;
  final bool routeDisplayed;
  final bool isMultiDestination;
  final String? paymentMethod;
  final double? currentSpeed;
  final DateTime? lastPositionUpdate;
  final String? trackingStatusMessage;
  final bool routeRecalculated;
  final double? routeProgress;
  final bool driverOffRoute;
  final bool driverAnimationComplete;
  final int currentSegmentIndex;
  final double? estimatedDistance;
  final int? estimatedTimeArrival;
  final double nearestDriverDistance;
  final DateTime? lastRouteRecalculation;
  final LatLng? currentDriverPosition;
  final LatLng? cameraTarget;
  final RequestRideResponse? rideResponse;
  final RideRequestModel? rideRequest;

  // Driver models
  final DriverAcceptedModel? driverAccepted;
  final DriverStarted? driverStarted;
  final DriverArrived? driverArrived;
  final DriverCompleted? driverCompleted;
  final DriverCancelled? driverCancelled;
  final DriverRejected? driverRejected;

  // Route data
  final Set<Polyline>? polylines;
  final Map<MarkerId, Marker>? markers;
  final List<RouteSegment>? routeSegments;

  const PersistedRideData({
    required this.timestamp,
    required this.status,
    this.rideId,
    required this.showRiderFound,
    required this.riderAvailable,
    required this.isSearching,
    required this.searchTimeElapsed,
    required this.rideInProgress,
    required this.driverHasArrived,
    required this.isRealTimeTrackingActive,
    required this.routeDisplayed,
    required this.isMultiDestination,
    this.paymentMethod,
    this.currentSpeed,
    this.lastPositionUpdate,
    this.trackingStatusMessage,
    required this.routeRecalculated,
    this.routeProgress,
    required this.driverOffRoute,
    required this.driverAnimationComplete,
    required this.currentSegmentIndex,
    this.estimatedDistance,
    this.estimatedTimeArrival,
    required this.nearestDriverDistance,
    this.lastRouteRecalculation,
    this.currentDriverPosition,
    this.cameraTarget,
    this.rideResponse,
    this.rideRequest,
    this.driverAccepted,
    this.driverStarted,
    this.driverArrived,
    this.driverCompleted,
    this.driverCancelled,
    this.driverRejected,
    this.polylines,
    this.markers,
    this.routeSegments,
  });

  Map<String, dynamic> toJson() {
    return {
      'hasMarkers': markers != null && markers!.isNotEmpty,
      'markersCount': markers?.length ?? 0,
      'hasPolylines': polylines != null && polylines!.isNotEmpty,
      'polylinesCount': polylines?.length ?? 0,
    };
  }

  factory PersistedRideData.fromJson(Map<String, dynamic> json) {
    log('PersistedRideData.fromJson(): json: $json');
    return PersistedRideData(
      timestamp: json['timestamp'] ?? '',
      status: _parseRideStatus(json['status']),
      rideId: json['currentRideId'],
      showRiderFound: json['showRiderFound'] ?? false,
      riderAvailable: json['riderAvailable'] ?? false,
      isSearching: json['isSearching'] ?? false,
      searchTimeElapsed: json['searchTimeElapsed'] ?? 0,
      rideInProgress: json['rideInProgress'] ?? false,
      driverHasArrived: json['driverHasArrived'] ?? false,
      isRealTimeTrackingActive: json['isRealTimeTrackingActive'] ?? false,
      routeDisplayed: json['routeDisplayed'] ?? false,
      isMultiDestination: json['isMultiDestination'] ?? false,
      paymentMethod: json['paymentMethod'],
      currentSpeed: json['currentSpeed']?.toDouble(),
      lastPositionUpdate:
          json['lastPositionUpdate'] != null
              ? DateTime.tryParse(json['lastPositionUpdate'])
              : null,
      trackingStatusMessage: json['trackingStatusMessage'],
      routeRecalculated: json['routeRecalculated'] ?? false,
      routeProgress: json['routeProgress']?.toDouble(),
      driverOffRoute: json['driverOffRoute'] ?? false,
      driverAnimationComplete: json['driverAnimationComplete'] ?? false,
      currentSegmentIndex: json['currentSegmentIndex'] ?? 0,
      estimatedDistance: json['estimatedDistance']?.toDouble(),
      estimatedTimeArrival: json['estimatedTimeArrival'],
      nearestDriverDistance: json['nearestDriverDistance']?.toDouble() ?? 0.0,
      lastRouteRecalculation:
          json['lastRouteRecalculation'] != null
              ? DateTime.tryParse(json['lastRouteRecalculation'])
              : null,
      currentDriverPosition:
          json['currentDriverPosition'] != null
              ? LatLng(
                json['currentDriverPosition']['latitude'],
                json['currentDriverPosition']['longitude'],
              )
              : null,
      cameraTarget:
          json['cameraTarget'] != null
              ? LatLng(
                json['cameraTarget']['latitude'],
                json['cameraTarget']['longitude'],
              )
              : null,
      rideResponse:
          json['rideResponse'] != null
              ? RequestRideResponse.fromJson(json['rideResponse'])
              : null,
      rideRequest:
          json['rideRequestModel'] != null
              ? RideRequestModel.fromJson(json['rideRequestModel'])
              : null,
      driverAccepted:
          json['driverAccepted'] != null
              ? DriverAcceptedModel.fromJson(json['driverAccepted'])
              : null,
      driverStarted: DriverStarted.fromJson(json['driverStarted']),
      driverArrived: DriverArrived.fromJson(json['driverArrived']),
      driverCompleted: DriverCompleted.fromJson(json['driverCompleted']),
      driverCancelled: DriverCancelled.fromJson(json['driverCancelled']),
      driverRejected: DriverRejected.fromJson(json['driverRejected']),
      polylines: null,
      markers: null,
      routeSegments: null,
    );
  }

  static PersistedRideData fromJsonWithDeserialization(
    Map<String, dynamic> json,
  ) {
    try {
      Set<Polyline>? polylines;
      final polylinesData = json['routePolylines'] as List<dynamic>?;
      if (polylinesData != null && polylinesData.isNotEmpty) {
        polylines = PersistenceSerializationHelper.deserializePolylines(
          polylinesData,
        );
      }

      Map<MarkerId, Marker>? markers;
      final markersData = json['routeMarkers'] as List<dynamic>?;
      if (markersData != null && markersData.isNotEmpty) {
        markers = PersistenceSerializationHelper.deserializeMarkers(
          markersData,
        );
      }

      return PersistedRideData(
        timestamp: json['timestamp'] ?? '',
        status: _parseRideStatus(json['status']),
        rideId: json['currentRideId'],
        showRiderFound: json['showRiderFound'] ?? false,
        riderAvailable: json['riderAvailable'] ?? false,
        isSearching: json['isSearching'] ?? false,
        searchTimeElapsed: json['searchTimeElapsed'] ?? 0,
        rideInProgress: json['rideInProgress'] ?? false,
        driverHasArrived: json['driverHasArrived'] ?? false,
        isRealTimeTrackingActive: json['isRealTimeTrackingActive'] ?? false,
        routeDisplayed: json['routeDisplayed'] ?? false,
        isMultiDestination: json['isMultiDestination'] ?? false,
        paymentMethod: json['paymentMethod'],
        currentSpeed: json['currentSpeed']?.toDouble(),
        lastPositionUpdate:
            json['lastPositionUpdate'] != null
                ? DateTime.tryParse(json['lastPositionUpdate'])
                : null,
        trackingStatusMessage: json['trackingStatusMessage'],
        routeRecalculated: json['routeRecalculated'] ?? false,
        routeProgress: json['routeProgress']?.toDouble(),
        driverOffRoute: json['driverOffRoute'] ?? false,
        driverAnimationComplete: json['driverAnimationComplete'] ?? false,
        currentSegmentIndex: json['currentSegmentIndex'] ?? 0,
        estimatedDistance: json['estimatedDistance']?.toDouble(),
        estimatedTimeArrival: json['estimatedTimeArrival'],
        nearestDriverDistance: json['nearestDriverDistance']?.toDouble() ?? 0.0,
        lastRouteRecalculation:
            json['lastRouteRecalculation'] != null
                ? DateTime.tryParse(json['lastRouteRecalculation'])
                : null,
        currentDriverPosition:
            json['currentDriverPosition'] != null
                ? LatLng(
                  json['currentDriverPosition']['latitude'],
                  json['currentDriverPosition']['longitude'],
                )
                : null,
        cameraTarget:
            json['cameraTarget'] != null
                ? LatLng(
                  json['cameraTarget']['latitude'],
                  json['cameraTarget']['longitude'],
                )
                : null,
        rideResponse:
            json['rideResponse'] != null
                ? RequestRideResponse.fromJson(json['rideResponse'])
                : null,
        rideRequest:
            json['rideRequestModel'] != null
                ? RideRequestModel.fromJson(json['rideRequestModel'])
                : null,
        driverAccepted: DriverAcceptedModel.fromJson(json['driverAccepted']),
        driverStarted: DriverStarted.fromJson(json['driverStarted']),
        driverArrived: DriverArrived.fromJson(json['driverArrived']),
        driverCompleted: DriverCompleted.fromJson(json['driverCompleted']),
        driverCancelled: DriverCancelled.fromJson(json['driverCancelled']),
        driverRejected: DriverRejected.fromJson(json['driverRejected']),
        polylines: polylines,
        markers: markers,
        routeSegments: _deserializeRouteSegments(json['routeSegments']),
      );
    } catch (e, stack) {
      print(
        '❌ Error in PersistedRideData.fromJsonWithDeserialization: $e\n$stack',
      );
      // Fallback to basic deserialization without polylines/markers
      return PersistedRideData.fromJson(json);
    }
  }

  static List<RouteSegment>? _deserializeRouteSegments(dynamic segmentsData) {
    if (segmentsData == null || segmentsData is! List) return null;

    try {
      return (segmentsData)
          .map((segmentData) {
            if (segmentData is Map<String, dynamic>) {
              final startLat = segmentData['startLat'] as double?;
              final startLng = segmentData['startLng'] as double?;
              final endLat = segmentData['endLat'] as double?;
              final endLng = segmentData['endLng'] as double?;
              final segmentIndex = segmentData['segmentIndex'] as int?;
              final pointsData = segmentData['points'] as List<dynamic>?;

              if (startLat != null &&
                  startLng != null &&
                  endLat != null &&
                  endLng != null &&
                  segmentIndex != null &&
                  pointsData != null) {
                final points =
                    pointsData
                        .map((pointData) {
                          if (pointData is Map<String, dynamic>) {
                            final lat = pointData['latitude'] as double?;
                            final lng = pointData['longitude'] as double?;
                            if (lat != null && lng != null) {
                              return LatLng(lat, lng);
                            }
                          }
                          return null;
                        })
                        .where((point) => point != null)
                        .cast<LatLng>()
                        .toList();

                // Create polyline for this segment
                final polyline = Polyline(
                  polylineId: PolylineId('segment_$segmentIndex'),
                  points: points,
                  color: Colors.blue,
                  width: 4,
                );

                return RouteSegment(
                  startLocation: LatLng(startLat, startLng),
                  endLocation: LatLng(endLat, endLng),
                  segmentIndex: segmentIndex,
                  routePoints: points,
                  polyline: polyline,
                );
              }
            }
            return null;
          })
          .where((segment) => segment != null)
          .cast<RouteSegment>()
          .toList();
    } catch (e) {
      print('❌ Error deserializing route segments: $e');
      return null;
    }
  }

  static RideRequestStatus _parseRideStatus(String? status) {
    switch (status) {
      case 'RideRequestStatus.initial':
        return RideRequestStatus.initial;
      case 'RideRequestStatus.loading':
        return RideRequestStatus.loading;
      case 'RideRequestStatus.searching':
        return RideRequestStatus.searching;
      case 'RideRequestStatus.success':
        return RideRequestStatus.success;
      case 'RideRequestStatus.error':
        return RideRequestStatus.error;
      case 'RideRequestStatus.noDriverFound':
        return RideRequestStatus.noDriverFound;
      case 'RideRequestStatus.completed':
        return RideRequestStatus.completed;
      case 'RideRequestStatus.cancelled':
        return RideRequestStatus.cancelled;
      default:
        return RideRequestStatus.initial;
    }
  }

  @override
  String toString() {
    return 'PersistedRideData(status: $status, rideId: $rideId, '
        'rideInProgress: $rideInProgress, tracking: $isRealTimeTrackingActive)';
  }
}

/// Persisted location data
class PersistedLocation {
  final double latitude;
  final double longitude;
  final double? speed;
  final double? bearing;
  final DateTime timestamp;

  const PersistedLocation({
    required this.latitude,
    required this.longitude,
    this.speed,
    this.bearing,
    required this.timestamp,
  });

  factory PersistedLocation.fromJson(Map<String, dynamic> json) {
    return PersistedLocation(
      latitude: json['latitude'],
      longitude: json['longitude'],
      speed: json['speed']?.toDouble(),
      bearing: json['bearing']?.toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  LatLng get latLng => LatLng(latitude, longitude);
}

/// Persisted tracking state
class PersistedTrackingState {
  final bool isActive;
  final String rideId;
  final String driverId;
  final LatLng? destination;
  final Map<String, dynamic>? trackingMetrics;
  final DateTime timestamp;

  const PersistedTrackingState({
    required this.isActive,
    required this.rideId,
    required this.driverId,
    this.destination,
    this.trackingMetrics,
    required this.timestamp,
  });

  factory PersistedTrackingState.fromJson(Map<String, dynamic> json) {
    return PersistedTrackingState(
      isActive: json['isActive'] ?? false,
      rideId: json['rideId'] ?? '',
      driverId: json['driverId'] ?? '',
      destination:
          json['destination'] != null
              ? LatLng(
                json['destination']['latitude'],
                json['destination']['longitude'],
              )
              : null,
      trackingMetrics: json['trackingMetrics'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// Persisted route data
class PersistedRouteData {
  final List<LatLng> routePoints;
  final List<Map<String, dynamic>>? segments;
  final double? totalDistance;
  final Duration? estimatedDuration;
  final DateTime timestamp;

  const PersistedRouteData({
    required this.routePoints,
    this.segments,
    this.totalDistance,
    this.estimatedDuration,
    required this.timestamp,
  });

  factory PersistedRouteData.fromJson(Map<String, dynamic> json) {
    final routePointsList = json['routePoints'] as List<dynamic>? ?? [];
    final routePoints =
        routePointsList
            .map((point) => LatLng(point['latitude'], point['longitude']))
            .toList();

    return PersistedRouteData(
      routePoints: routePoints,
      segments: json['segments']?.cast<Map<String, dynamic>>(),
      totalDistance: json['totalDistance']?.toDouble(),
      estimatedDuration:
          json['estimatedDuration'] != null
              ? Duration(seconds: json['estimatedDuration'])
              : null,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
