import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerConverter {
  static Future<Map<String, Marker>> convertRestoredMarkers(
    Map<MarkerId, Marker> restoredMarkers,
  ) async {
    final convertedMarkers = <String, Marker>{};

    for (final entry in restoredMarkers.entries) {
      final marker = entry.value;
      final markerId = entry.key.value;

      try {
        BitmapDescriptor icon = _getIconForMarkerType(
          markerId,
          marker.markerId.value,
        );

        final convertedMarker = Marker(
          markerId: marker.markerId,
          position: marker.position,
          infoWindow: marker.infoWindow,
          icon: icon,
          anchor: marker.anchor,
          consumeTapEvents: marker.consumeTapEvents,
          draggable: marker.draggable,
          flat: marker.flat,
          rotation: marker.rotation,
          visible: marker.visible,
          zIndex: marker.zIndex,
          onTap: marker.onTap,
        );

        convertedMarkers[markerId] = convertedMarker;
        dev.log(
          '✅ Converted marker: ${marker.markerId.value} with ${_getMarkerTypeDescription(markerId, marker.markerId.value)}',
        );
      } catch (e) {
        dev.log('❌ Failed to convert marker ${marker.markerId.value}: $e');

        final fallbackMarker = Marker(
          markerId: marker.markerId,
          position: marker.position,
          infoWindow: marker.infoWindow,
          icon: BitmapDescriptor.defaultMarker,
        );
        convertedMarkers[markerId] = fallbackMarker;
        dev.log('🔧 Created fallback marker for ${marker.markerId.value}');
      }
    }

    dev.log('🔄 Successfully converted ${convertedMarkers.length} markers');
    return convertedMarkers;
  }

  static BitmapDescriptor _getIconForMarkerType(
    String markerId,
    String markerIdValue,
  ) {
    final id = markerId.toLowerCase();
    final idValue = markerIdValue.toLowerCase();

    if (id.contains('pickup') || idValue.contains('pickup')) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    } else if (id.contains('driver') || idValue.contains('driver')) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    } else if (id.contains('destination') || idValue.contains('destination')) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    } else if (id.contains('delivery') || idValue.contains('delivery')) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    } else if (id.contains('waypoint') ||
        idValue.contains('waypoint') ||
        id.contains('stop') ||
        idValue.contains('stop')) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
    } else {
      return BitmapDescriptor.defaultMarker;
    }
  }

  static String _getMarkerTypeDescription(
    String markerId,
    String markerIdValue,
  ) {
    final id = markerId.toLowerCase();
    final idValue = markerIdValue.toLowerCase();

    if (id.contains('pickup') || idValue.contains('pickup')) {
      return 'green pickup marker';
    } else if (id.contains('driver') || idValue.contains('driver')) {
      return 'blue driver marker';
    } else if (id.contains('destination') || idValue.contains('destination')) {
      return 'red destination marker';
    } else if (id.contains('delivery') || idValue.contains('delivery')) {
      return 'orange delivery marker';
    } else if (id.contains('waypoint') ||
        idValue.contains('waypoint') ||
        id.contains('stop') ||
        idValue.contains('stop')) {
      return 'yellow waypoint marker';
    } else {
      return 'default red marker';
    }
  }

  static Marker createMarker({
    required String markerId,
    required LatLng position,
    String? markerType,
    InfoWindow infoWindow = InfoWindow.noText,
    Offset anchor = const Offset(0.5, 1.0),
    bool visible = true,
    double zIndex = 0.0,
    VoidCallback? onTap,
  }) {
    BitmapDescriptor icon;

    if (markerType != null) {
      icon = _getIconForMarkerType(markerType, markerType);
    } else {
      icon = _getIconForMarkerType(markerId, markerId);
    }

    return Marker(
      markerId: MarkerId(markerId),
      position: position,
      icon: icon,
      infoWindow: infoWindow,
      anchor: anchor,
      visible: visible,
      zIndex: zIndex,
      onTap: onTap,
    );
  }

  static bool validateMarkers(Set<Marker> markers) {
    for (final marker in markers) {
      if (marker.icon.toString().contains('null') ||
          marker.icon.toString().isEmpty) {
        dev.log('⚠️ Invalid icon found for marker: ${marker.markerId.value}');
        return false;
      }
    }
    return true;
  }
}
