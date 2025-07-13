import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:freedom/core/services/push_notification_service/socket_delivery_model.dart';
import 'package:freedom/feature/home/delivery_cubit/delivery_cubit.dart';
import 'package:freedom/feature/home/models/delivery_request_response.dart';
import 'package:freedom/feature/home/repository/models/delivery_status_response.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:freedom/app_preference.dart';
import 'package:freedom/feature/home/models/delivery_model.dart';
import 'package:freedom/feature/home/repository/delivery_repository.dart';

class DeliveryPersistenceService {
  static const String _keyDeliveryState = 'persisted_delivery_state';
  static const String _keyDeliveryRoute = 'persisted_delivery_route';
  static const String _keyDeliveryMarkers = 'persisted_delivery_markers';
  static const String _keyDeliveryRequest = 'persisted_delivery_request';
  static const String _keyDeliveryDriverInfo = 'persisted_delivery_driver_info';

  final DeliveryRepositoryImpl deliveryRepository;

  DeliveryPersistenceService(this.deliveryRepository);

  Future<void> persistDeliveryState(DeliveryState state) async {
    try {
      if (!state.hasActiveDelivery || state.currentDeliveryId == null) {
        await clearPersistedState();
        return;
      }

      dev.log(
        '🔄 Persisting delivery state for ID: ${state.currentDeliveryId}',
      );

      final stateData = {
        'currentDeliveryId': state.currentDeliveryId,
        'status': state.status.index,
        'riderFound': state.riderFound,
        'deliveryInProgress': state.deliveryInProgress,
        'deliveryDriverHasArrived': state.deliveryDriverHasArrived,
        'isRealTimeDeliveryTrackingActive':
            state.isRealTimeDeliveryTrackingActive,
        'deliveryRouteDisplayed': state.deliveryRouteDisplayed,
        'currentDeliverySpeed': state.currentDeliverySpeed,
        'lastDeliveryPositionUpdate':
            state.lastDeliveryPositionUpdate?.toIso8601String(),
        'deliveryTrackingStatusMessage': state.deliveryTrackingStatusMessage,
        'timestamp': DateTime.now().toIso8601String(),
      };
      dev.log('Persisted state data: ${stateData.toString()}');

      if (state.currentDeliveryDriverPosition != null) {
        stateData['currentDeliveryDriverPosition'] = {
          'latitude': state.currentDeliveryDriverPosition!.latitude,
          'longitude': state.currentDeliveryDriverPosition!.longitude,
        };
      }

      if (state.deliveryData != null) {
        stateData['deliveryData'] = {
          'deliveryId': state.deliveryData!.deliveryId,
          'fare': state.deliveryData!.fare,
          'currency': state.deliveryData!.currency,
          'estimatedDistance': {
            'text': state.deliveryData!.estimatedDistance.text,
            'value': state.deliveryData!.estimatedDistance.value,
          },
          'estimatedDuration': {
            'text': state.deliveryData!.estimatedDuration.text,
            'value': state.deliveryData!.estimatedDuration.value,
          },
          'paymentMethod': state.deliveryData!.paymentMethod,
          'isMultiStop': state.deliveryData!.isMultiStop,
          'numberOfStops': state.deliveryData!.numberOfStops,
        };
      }

      if (state.deliveryDriverAccepted != null) {
        stateData['deliveryDriverAccepted'] = {
          'deliveryId': state.deliveryDriverAccepted!.deliveryId,
          'driverId': state.deliveryDriverAccepted!.driverId,
          'status': state.deliveryDriverAccepted!.status,
          'phone': state.deliveryDriverAccepted!.phone,
        };
      }

      if (state.deliveryDriverStarted != null) {
        stateData['deliveryDriverStarted'] = {
          'deliveryId': state.deliveryDriverStarted!.deliveryId,
          'status': state.deliveryDriverStarted!.status,
        };
      }

      await AppPreferences.setString(_keyDeliveryState, jsonEncode(stateData));

      await _persistRouteData(state);
      await _persistMarkersData(state);

      dev.log('✅ Delivery state persisted successfully');
    } catch (e) {
      dev.log('❌ Error persisting delivery state: $e');
    }
  }

  Future<void> _persistRouteData(DeliveryState state) async {
    try {
      if (state.deliveryRoutePolylines.isEmpty) return;

      final routeData = <String, dynamic>{};
      final polylines = <Map<String, dynamic>>[];

      for (final polyline in state.deliveryRoutePolylines) {
        final points =
            polyline.points
                .map(
                  (point) => {
                    'latitude': point.latitude,
                    'longitude': point.longitude,
                  },
                )
                .toList();

        polylines.add({
          'polylineId': polyline.polylineId.value,
          'points': points,
          'color': polyline.color.value,
          'width': polyline.width,
          'patterns':
              polyline.patterns
                  .map(
                    (p) => {
                      'length': p,
                      'type': p.runtimeType.toString().toLowerCase().replaceAll(
                        'pattern',
                        '',
                      ),
                    },
                  )
                  .toList(),
        });
      }

      routeData['polylines'] = polylines;
      routeData['timestamp'] = DateTime.now().toIso8601String();

      await AppPreferences.setString(_keyDeliveryRoute, jsonEncode(routeData));
    } catch (e) {
      dev.log('❌ Error persisting route data: $e');
    }
  }

  Future<void> _persistMarkersData(DeliveryState state) async {
    try {
      if (state.deliveryRouteMarkers.isEmpty) return;

      final markersData = <String, dynamic>{};
      final markers = <Map<String, dynamic>>[];

      for (final marker in state.deliveryRouteMarkers.values) {
        markers.add({
          'markerId': marker.markerId.value,
          'position': {
            'latitude': marker.position.latitude,
            'longitude': marker.position.longitude,
          },
          'infoWindow': {
            'title': marker.infoWindow.title,
            'snippet': marker.infoWindow.snippet,
          },
          'rotation': marker.rotation,
          'visible': marker.visible,
          'consumeTapEvents': marker.consumeTapEvents,
        });
      }

      markersData['markers'] = markers;
      markersData['timestamp'] = DateTime.now().toIso8601String();

      await AppPreferences.setString(
        _keyDeliveryMarkers,
        jsonEncode(markersData),
      );
    } catch (e) {
      dev.log('❌ Error persisting markers data: $e');
    }
  }

  Future<void> persistDeliveryRequest(DeliveryModel deliveryRequest) async {
    try {
      final requestData = {
        'deliveryRequest': deliveryRequest.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await AppPreferences.setString(
        _keyDeliveryRequest,
        jsonEncode(requestData),
      );
      dev.log('✅ Delivery request persisted');
    } catch (e) {
      dev.log('❌ Error persisting delivery request: $e');
    }
  }

  Future<PersistedDeliveryData?> loadPersistedDeliveryState() async {
    try {
      final stateJson = await AppPreferences.getString(_keyDeliveryState);

      if (stateJson == null || stateJson.isEmpty) {
        dev.log('📭 No persisted delivery state found');
        return null;
      }

      final stateData = jsonDecode(stateJson) as Map<String, dynamic>?;

      if (stateData == null) {
        dev.log('❌ Failed to decode persisted state');
        await clearPersistedState();
        return null;
      }

      final deliveryId = stateData['currentDeliveryId'] as String?;
      if (deliveryId == null) {
        dev.log('❌ No delivery ID in persisted state');
        await clearPersistedState();
        return null;
      }

      // Timestamp validation
      final timestampStr = stateData['timestamp'] as String?;
      if (timestampStr != null) {
        final timestamp = DateTime.tryParse(timestampStr);
        if (timestamp != null) {
          final hoursSincePersist =
              DateTime.now().difference(timestamp).inHours;
          if (hoursSincePersist > 24) {
            dev.log(
              '🗑️ Persisted state too old (${hoursSincePersist}h), clearing',
            );
            await clearPersistedState();
            return null;
          }
        }
      }

      dev.log('🔄 Checking delivery status for ID: $deliveryId');

      final statusCheck = await _checkDeliveryStatus(deliveryId);
      if (statusCheck == null) {
        dev.log('❌ Delivery no longer active, clearing persisted state');
        await clearPersistedState();
        return null;
      }

      dev.log('✅ Loading persisted delivery state for active delivery');

      // Optional enriched data
      final routeData = await _loadRouteData();
      final markersData = await _loadMarkersData();
      final requestData = await _loadDeliveryRequest();

      dev.log('✅ Persisted delivery state ${stateData.toString()}');

      return PersistedDeliveryData(
        deliveryId: deliveryId,
        status: DeliveryStatus.values[stateData['status'] as int? ?? 0],
        riderFound: stateData['riderFound'] as bool? ?? false,
        deliveryInProgress: stateData['deliveryInProgress'] as bool? ?? false,
        deliveryDriverHasArrived:
            stateData['deliveryDriverHasArrived'] as bool? ?? false,
        isRealTimeDeliveryTrackingActive:
            stateData['isRealTimeDeliveryTrackingActive'] as bool? ?? false,
        deliveryRouteDisplayed:
            stateData['deliveryRouteDisplayed'] as bool? ?? false,
        currentDeliverySpeed:
            (stateData['currentDeliverySpeed'] as num?)?.toDouble() ?? 0.0,
        lastDeliveryPositionUpdate: DateTime.tryParse(
          stateData['lastDeliveryPositionUpdate'] as String? ?? '',
        ),
        deliveryTrackingStatusMessage:
            stateData['deliveryTrackingStatusMessage'] as String?,
        currentDeliveryDriverPosition: _parseLatLng(
          stateData['currentDeliveryDriverPosition'],
        ),
        deliveryData:
            stateData['deliveryData'] is Map<String, dynamic>
                ? _parseDeliveryData(stateData['deliveryData'])
                : null,
        deliveryDriverAccepted: DeliveryManAcceptedModel.fromJson(
          stateData['deliveryDriverAccepted'] is Map<String, dynamic>
              ? stateData['deliveryDriverAccepted']
              : null,
        ),
        deliveryDriverStarted:
            stateData['deliveryDriverStarted'] is Map<String, dynamic>
                ? DeliveryManStarted.fromJson(
                  stateData['deliveryDriverStarted'] as Map<String, dynamic>,
                )
                : null,

        polylines: routeData,
        markers: markersData,
        deliveryRequest: requestData,
        deliveryStatusResponse: statusCheck,
      );
    } catch (e, stack) {
      dev.log('❌ Error loading persisted delivery state: $e\n$stack');
      await clearPersistedState();
      return null;
    }
  }

  LatLng? _parseLatLng(dynamic data) {
    if (data is Map<String, dynamic>) {
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }
    return null;
  }

  Future<DeliveryStatusResponse?> _checkDeliveryStatus(
    String deliveryId,
  ) async {
    try {
      final response = await deliveryRepository.checkDeliveryStatus(deliveryId);
      return response.fold((failure) {
        dev.log('❌ Failed to check delivery status: ${failure.message}');
        return null;
      }, (status) => status);
    } catch (e) {
      dev.log('❌ Error checking delivery status: $e');
      return null;
    }
  }

  DeliveryData _parseDeliveryData(Map<String, dynamic> json) {
    final fareBreakdown = json['fareBreakdown'];
    dev.log(' _parseDeliveryData(): Parsed fareBreakdown: $fareBreakdown');
    return DeliveryData(
      deliveryId: json['deliveryId'] as String,
      fare: (json['fare'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? '',
      estimatedDistance:
          json['estimatedDistance'] != null
              ? EstimatedDistanceAndTimer.fromJson(
                json['estimatedDistance'] as Map<String, dynamic>,
              )
              : EstimatedDistanceAndTimer(text: '', value: 0),
      estimatedDuration:
          json['estimatedDuration'] != null
              ? EstimatedDistanceAndTimer.fromJson(
                json['estimatedDuration'] as Map<String, dynamic>,
              )
              : EstimatedDistanceAndTimer(text: '', value: 0),
      fareBreakdown:
          json['fareBreakdown'] != null
              ? FareBreakdown.fromJson(
                json['fareBreakdown'] as Map<String, dynamic>,
              )
              : FareBreakdown(
                baseFare: 0.0,
                distanceFare: 0.0,
                timeFare: 0.0,
                packageSizeMultiplier: 0.0,
                surgeMultiplier: 0.0,
              ),
      status: json['status'] as String? ?? '',
      driversNotified: json['driversNotified'] as int? ?? 0,
      paymentMethod: json['paymentMethod'] as String? ?? '',
      isMultiStop: json['isMultiStop'] as bool? ?? false,
      numberOfStops: json['numberOfStops'] as int? ?? 1,
    );
  }

  Future<Set<Polyline>?> _loadRouteData() async {
    try {
      final routeJson = await AppPreferences.getString(_keyDeliveryRoute);
      dev.log('Print routeJson: $routeJson');
      if (routeJson == null || routeJson.isEmpty) return null;

      final routeData = jsonDecode(routeJson) as Map<String, dynamic>;
      final polylinesData = routeData['polylines'] as List<dynamic>?;

      if (polylinesData == null) return null;

      final polylines = <Polyline>{};

      for (final polylineData in polylinesData) {
        final points =
            (polylineData['points'] as List<dynamic>)
                .map(
                  (point) => LatLng(
                    (point['latitude'] as num).toDouble(),
                    (point['longitude'] as num).toDouble(),
                  ),
                )
                .toList();

        final patterns = polylineData['patterns'] as List<dynamic>?;
        List<PatternItem>? patternItems;

        if (patterns != null) {
          patternItems =
              patterns.map<PatternItem>((pattern) {
                final lengthData = pattern['length'];
                double length = 10.0;
                String type = pattern['type'] as String? ?? 'gap';

                // Handle legacy {"length": 10.0} and new ["dash", 20.0]
                if (lengthData is List && lengthData.length == 2) {
                  type = lengthData[0] as String? ?? 'gap';
                  length = (lengthData[1] as num?)?.toDouble() ?? 10.0;
                } else if (lengthData is num) {
                  length = lengthData.toDouble();
                }

                switch (type.toLowerCase()) {
                  case 'dash':
                    return PatternItem.dash(length);
                  case 'gap':
                    return PatternItem.gap(length);
                  default:
                    return PatternItem.gap(length);
                }
              }).toList();
        }

        polylines.add(
          Polyline(
            polylineId: PolylineId(polylineData['polylineId'] as String),
            points: points,
            color: Color(polylineData['color'] as int),
            width: polylineData['width'] as int,
            patterns: patternItems ?? [],
          ),
        );
      }

      return polylines;
    } catch (e, stack) {
      dev.log('❌ Error loading route data: $e\n$stack');
      return null;
    }
  }

  Future<Map<MarkerId, Marker>?> _loadMarkersData() async {
    try {
      final markersJson = await AppPreferences.getString(_keyDeliveryMarkers);
      if (markersJson == null || markersJson.isEmpty) return null;

      final markersData = jsonDecode(markersJson) as Map<String, dynamic>;
      final markersArray = markersData['markers'] as List<dynamic>?;

      if (markersArray == null) return null;

      final markers = <MarkerId, Marker>{};

      for (final markerData in markersArray) {
        final markerId = MarkerId(markerData['markerId'] as String);
        final position = LatLng(
          (markerData['position']['latitude'] as num).toDouble(),
          (markerData['position']['longitude'] as num).toDouble(),
        );

        BitmapDescriptor icon = BitmapDescriptor.defaultMarker;

        final markerIdValue = markerData['markerId'] as String;
        if (markerIdValue == 'pickup') {
          icon = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          );
        } else if (markerIdValue == 'delivery_destination') {
          icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        } else if (markerIdValue == 'delivery_driver') {
          icon = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          );
        }

        markers[markerId] = Marker(
          markerId: markerId,
          position: position,
          icon: icon,
          infoWindow: InfoWindow(
            title: markerData['infoWindow']['title'] as String?,
            snippet: markerData['infoWindow']['snippet'] as String?,
          ),
          rotation: (markerData['rotation'] as num?)?.toDouble() ?? 0.0,
          visible: markerData['visible'] as bool? ?? true,
          consumeTapEvents: markerData['consumeTapEvents'] as bool? ?? false,
        );
      }

      return markers;
    } catch (e) {
      dev.log('❌ Error loading markers data: $e');
      return null;
    }
  }

  Future<DeliveryModel?> _loadDeliveryRequest() async {
    try {
      final requestJson = await AppPreferences.getString(_keyDeliveryRequest);
      if (requestJson == null || requestJson.isEmpty) return null;

      final requestData = jsonDecode(requestJson) as Map<String, dynamic>;
      final deliveryRequestData =
          requestData['deliveryRequest'] as Map<String, dynamic>?;

      if (deliveryRequestData == null) return null;

      return DeliveryModel.fromJson(deliveryRequestData);
    } catch (e) {
      dev.log('❌ Error loading delivery request: $e');
      return null;
    }
  }

  Future<void> clearPersistedState() async {
    try {
      await Future.wait([
        AppPreferences.remove(_keyDeliveryState),
        AppPreferences.remove(_keyDeliveryRoute),
        AppPreferences.remove(_keyDeliveryMarkers),
        AppPreferences.remove(_keyDeliveryRequest),
        AppPreferences.remove(_keyDeliveryDriverInfo),
      ]);
      dev.log('🗑️ Cleared all persisted delivery state');
    } catch (e) {
      dev.log('❌ Error clearing persisted state: $e');
    }
  }

  Future<void> updateDeliveryDriverPosition(
    LatLng position,
    double rotation,
  ) async {
    try {
      final stateJson = await AppPreferences.getString(_keyDeliveryState);
      if (stateJson == null || stateJson.isEmpty) return;

      final stateData = jsonDecode(stateJson) as Map<String, dynamic>;
      stateData['currentDeliveryDriverPosition'] = {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
      stateData['lastDeliveryPositionUpdate'] =
          DateTime.now().toIso8601String();

      await AppPreferences.setString(_keyDeliveryState, jsonEncode(stateData));
    } catch (e) {
      dev.log('❌ Error updating driver position: $e');
    }
  }

  Future<bool> hasPersistedDeliveryState() async {
    try {
      final stateJson = await AppPreferences.getString(_keyDeliveryState);
      return stateJson != null && stateJson.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

class DistanceData {
  final String text;
  final int value;

  const DistanceData({required this.text, required this.value});

  factory DistanceData.fromJson(Map<String, dynamic> json) {
    return DistanceData(
      text: json['text'] as String? ?? '',
      value: json['value'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'text': text, 'value': value};
  }
}

class DurationData {
  final String text;
  final int value;

  const DurationData({required this.text, required this.value});

  factory DurationData.fromJson(Map<String, dynamic> json) {
    return DurationData(
      text: json['text'] as String? ?? '',
      value: json['value'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'text': text, 'value': value};
  }
}

class PersistedDeliveryData {
  final String deliveryId;
  final DeliveryStatus status;
  final bool riderFound;
  final bool deliveryInProgress;
  final bool deliveryDriverHasArrived;
  final bool isRealTimeDeliveryTrackingActive;
  final bool deliveryRouteDisplayed;
  final double currentDeliverySpeed;
  final DateTime? lastDeliveryPositionUpdate;
  final String? deliveryTrackingStatusMessage;
  final LatLng? currentDeliveryDriverPosition;
  final DeliveryData? deliveryData;
  final DeliveryManAcceptedModel? deliveryDriverAccepted;
  final DeliveryManStarted? deliveryDriverStarted;
  final Set<Polyline>? polylines;
  final Map<MarkerId, Marker>? markers;
  final DeliveryModel? deliveryRequest;
  final DeliveryStatusResponse? deliveryStatusResponse;

  const PersistedDeliveryData({
    required this.deliveryId,
    required this.status,
    required this.riderFound,
    required this.deliveryInProgress,
    required this.deliveryDriverHasArrived,
    required this.isRealTimeDeliveryTrackingActive,
    required this.deliveryRouteDisplayed,
    required this.currentDeliverySpeed,
    this.lastDeliveryPositionUpdate,
    this.deliveryTrackingStatusMessage,
    this.currentDeliveryDriverPosition,
    this.deliveryData,
    this.deliveryDriverAccepted,
    this.deliveryDriverStarted,
    this.polylines,
    this.markers,
    this.deliveryRequest,
    this.deliveryStatusResponse,
  });

  @override
  String toString() {
    return 'PersistedDeliveryData('
        'deliveryId: $deliveryId, '
        'status: $status, '
        'riderFound: $riderFound, '
        'deliveryInProgress: $deliveryInProgress, '
        'hasRoute: ${polylines?.isNotEmpty}, '
        'hasMarkers: ${markers?.isNotEmpty}'
        ')';
  }
}
