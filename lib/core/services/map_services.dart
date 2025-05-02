import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapService {
  final Completer<GoogleMapController> _controllerCompleter =
      Completer<GoogleMapController>();
  GoogleMapController? _mapController;

  GoogleMapController? get controller => _mapController;

  Future<GoogleMapController> get controllerFuture =>
      _controllerCompleter.future;

  void setController(GoogleMapController controller) {
    if (!_controllerCompleter.isCompleted) {
      _mapController = controller;
      _controllerCompleter.complete(controller);
    }
  }

  bool get isReady => _mapController != null;

  Future<void> animateToLocation(LatLng location) async {
    final controller = await controllerFuture;
    await controller.animateCamera(
      CameraUpdate.newLatLng(location),
    );
  }
}
