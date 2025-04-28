import 'dart:async';
import 'dart:developer' as dev;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:freedom/feature/location_search/repository/location_repository.dart';
import 'package:freedom/feature/location_search/repository/models/PlacePrediction.dart';
import 'package:freedom/feature/location_search/repository/models/location.dart';
import 'package:freedom/shared/enums/enums.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({required LocationRepository repository})
      : _repository = repository,
        super(const HomeState());
  Timer? _debounce;
  final LocationRepository _repository;
  void addDestination() {
    emit(
      state.copyWith(
        locations: [...state.locations, generateNewDestinationString()],
      ),
    );
  }

  void removeLastDestination() {
    emit(state.copyWith(locations: List.from(state.locations)..removeLast()));
  }

  String generateNewDestinationString() {
    return 'Destination ${state.locations.length}';
  }

  set fieldIndex(int index) {
    dev.log('index: $index');
    emit(state.copyWith(fieldIndexSetter: index));
  }

  int get fieldIndex => state.fieldIndexSetter ?? 0;

  Future<void> onSearchQueryChanged(
    String query,
  ) async {
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
