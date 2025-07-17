import 'dart:convert';
import 'dart:ui' as ui;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PersistenceSerializationHelper {
  
  static Set<Polyline> deserializePolylines(List<dynamic>? polylinesJson) {
    if (polylinesJson == null || polylinesJson.isEmpty) {
      return const {};
    }

    final polylines = <Polyline>{};
    
    try {
      for (final polylineData in polylinesJson) {
        if (polylineData is Map<String, dynamic>) {
          final polylineId = polylineData['polylineId'] as String?;
          final pointsData = polylineData['points'] as List<dynamic>?;
          final colorValue = polylineData['color'] as int?;
          final width = polylineData['width'] as int?;

          if (polylineId != null && pointsData != null) {
            final points = <LatLng>[];
            
            for (final pointData in pointsData) {
              if (pointData is Map<String, dynamic>) {
                final lat = pointData['latitude'] as double?;
                final lng = pointData['longitude'] as double?;
                
                if (lat != null && lng != null) {
                  points.add(LatLng(lat, lng));
                }
              }
            }

            if (points.isNotEmpty) {
              polylines.add(Polyline(
                polylineId: PolylineId(polylineId),
                points: points,
                color: colorValue != null ? ui.Color(colorValue) : ui.Color(0xFF0000FF),
                width: width ?? 5,
              ));
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error deserializing polylines: $e');
    }

    return polylines;
  }

  /// Deserialize markers from JSON data
  static Map<MarkerId, Marker> deserializeMarkers(List<dynamic>? markersJson) {
    if (markersJson == null || markersJson.isEmpty) {
      return const {};
    }

    final markers = <MarkerId, Marker>{};
    
    try {
      for (final markerData in markersJson) {
        if (markerData is Map<String, dynamic>) {
          final markerIdValue = markerData['markerId'] as String?;
          final latitude = markerData['latitude'] as double?;
          final longitude = markerData['longitude'] as double?;
          final infoWindowTitle = markerData['infoWindowTitle'] as String?;
          final infoWindowSnippet = markerData['infoWindowSnippet'] as String?;
          final rotation = markerData['rotation'] as double?;

          if (markerIdValue != null && latitude != null && longitude != null) {
            final markerId = MarkerId(markerIdValue);
            
            // Determine the appropriate icon based on marker ID
            BitmapDescriptor icon;
            switch (markerIdValue.toLowerCase()) {
              case 'driver':
                icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
                break;
              case 'pickup':
              case 'origin':
                icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
                break;
              case 'destination':
              case 'dropoff':
                icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
                break;
              default:
                icon = BitmapDescriptor.defaultMarker;
            }

            markers[markerId] = Marker(
              markerId: markerId,
              position: LatLng(latitude, longitude),
              icon: icon,
              infoWindow: InfoWindow(
                title: infoWindowTitle,
                snippet: infoWindowSnippet,
              ),
              rotation: rotation ?? 0.0,
            );
          }
        }
      }
    } catch (e) {
      print('❌ Error deserializing markers: $e');
    }

    return markers;
  }

  /// Serialize polylines to JSON
  static List<Map<String, dynamic>> serializePolylines(Set<Polyline> polylines) {
    return polylines.map((polyline) => {
      'polylineId': polyline.polylineId.value,
      'points': polyline.points.map((point) => {
        'latitude': point.latitude,
        'longitude': point.longitude,
      }).toList(),
      'color': polyline.color.value,
      'width': polyline.width,
    }).toList();
  }

  /// Serialize markers to JSON
  static List<Map<String, dynamic>> serializeMarkers(Map<MarkerId, Marker> markers) {
    return markers.values.map((marker) => {
      'markerId': marker.markerId.value,
      'latitude': marker.position.latitude,
      'longitude': marker.position.longitude,
      'infoWindowTitle': marker.infoWindow.title,
      'infoWindowSnippet': marker.infoWindow.snippet,
      'rotation': marker.rotation,
    }).toList();
  }
}