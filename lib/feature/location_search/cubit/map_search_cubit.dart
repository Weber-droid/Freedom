import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:freedom/feature/location_search/repository/location_repository.dart';
import 'package:freedom/feature/location_search/repository/models/PlacePrediction.dart';
import 'package:freedom/feature/location_search/repository/models/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

part 'map_search_state.dart';

class MapSearchCubit extends Cubit<MapSearchState> {
  MapSearchCubit({required LocationRepository repository})
      : _repository = repository,
        super(const MapSearchState());

  final LocationRepository _repository;

  Timer? _debounce;

  Future<void> onSearchQueryChanged(String query,) async {
    if (query.isEmpty) {
      emit(state.copyWith(predictions: [], status: MapSearchStatus.success));
      return;
    }

    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      emit(state.copyWith(predictions: [], status: MapSearchStatus.loading));

      try {
        final predictions = await _repository.getPlacePredictions(query);
        emit(state.copyWith(
            predictions: predictions, status: MapSearchStatus.success));
      } catch (e) {
        emit(state.copyWith(
            predictions: [],
            status: MapSearchStatus.error,
            locationSearchErrorMessage: 'Failed to fetch predictions: $e'));
      }
    });
  }

  void setSelectedPickUpLocation(Location location) {
    emit(state.copyWith(selectedPickUpLocation: location));
  }

  void setMarkers() {
    final markers = <Marker>{};

    if (state.selectedPickUpLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(
            state.selectedPickUpLocation!.latitude,
            state.selectedPickUpLocation!.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'Pickup',
            snippet: state.selectedPickUpLocation!.name,
          ),
          icon:
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    if (state.selectedDestinationLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(
            state.selectedDestinationLocation!.latitude,
            state.selectedDestinationLocation!.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: state.selectedDestinationLocation!.name,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
  }
}