// ignore_for_file: avoid_bool_literals_in_conditional_expressions

import 'dart:async';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freedom/feature/home/models/delivery_model.dart';
import 'package:freedom/feature/home/models/delivery_request_response.dart';
import 'package:freedom/feature/home/repository/delivery_repository.dart';
import 'package:freedom/feature/home/repository/location_repository.dart';
import 'package:freedom/feature/home/repository/models/location.dart';
import 'package:freedom/feature/home/repository/models/place_prediction.dart';

part 'delivery_state.dart';

class DeliveryCubit extends Cubit<DeliveryState> {
  DeliveryCubit(this.deliveryRepository, this.locationRepository)
    : super(const DeliveryState());

  final DeliveryRepositoryImpl deliveryRepository;
  final LocationRepository locationRepository;

  Timer? _debounceTimer;
  Timer? _timer;
  static const int maxSearchTime = 60;

  set searchTimeElapsed(int searchTimeElapsed) =>
      emit(state.copyWith(searchTimeElapsed: searchTimeElapsed));

  int get searchTimeElapsed => state.searchTimeElapsed;

  void _startTimer() {
    _timer?.cancel();
    emit(state.copyWith(searchTimeElapsed: 0));

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (searchTimeElapsed < maxSearchTime) {
        searchTimeElapsed++;
        emit(state.copyWith(searchTimeElapsed: searchTimeElapsed));
      } else {
        emit(
          state.copyWith(
            isSearching: false,
            searchTimeElapsed: 0,
            status: DeliveryStatus.initial,
            riderFound: false,
          ),
        );
        _timer?.cancel();
        _timer = null;
      }
    });
  }

  Future<void> requestDelivery(DeliveryModel deliveryRequestModel) async {
    emit(state.copyWith(status: DeliveryStatus.loading));
    try {
      final response = await deliveryRepository.requestDelivery(
        deliveryRequestModel,
      );
      response.fold(
        (isLeft) {
          emit(
            state.copyWith(
              status: DeliveryStatus.failure,
              errorMessage: isLeft.message,
            ),
          );
        },
        (right) {
          if (right.success) {
            emit(
              state.copyWith(
                status: DeliveryStatus.success,
                deliveryData: right.data,
                showDeliverySearchSheet: true,
              ),
            );
            _startTimer();
          } else {
            emit(
              state.copyWith(
                status: DeliveryStatus.failure,
                errorMessage: right.message,
              ),
            );
          }
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DeliveryStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void addDeliveryDestination(TextEditingController controller) {
    final newController = TextEditingController();

    final currentControllers = List<TextEditingController>.from(
      state.deliveryControllers.isEmpty
          ? [controller]
          : state.deliveryControllers,
    )..add(newController);

    emit(
      state.copyWith(
        deliveryControllers: currentControllers,
        isMultipleDestination: true,
      ),
    );
  }

  void removeDestination(int index) {
    if (state.deliveryControllers.isEmpty ||
        index <= 0 ||
        index >= state.deliveryControllers.length) {
      return;
    }

    final newControllers = List<TextEditingController>.from(
      state.deliveryControllers,
    );

    newControllers[index].clear();

    newControllers.removeAt(index);
    emit(
      state.copyWith(
        deliveryControllers: newControllers,
        isMultipleDestination: newControllers.length > 1,
        activeDestinationIndex:
            index == state.activeDestinationIndex
                ? 0
                : (state.activeDestinationIndex > index
                    ? state.activeDestinationIndex - 1
                    : state.activeDestinationIndex),
      ),
    );
  }

  void setSingleDestination() {
    if (state.deliveryControllers.isEmpty) return;

    for (var i = 1; i < state.deliveryControllers.length; i++) {
      state.deliveryControllers[i].clear();
    }

    emit(
      state.copyWith(
        deliveryControllers:
            state.deliveryControllers.isNotEmpty
                ? [state.deliveryControllers.first]
                : [],
        isMultipleDestination: false,
        activeDestinationIndex: 0,
      ),
    );
  }

  List<String> getAllDestinationValues() {
    return state.deliveryControllers
        .map((controller) => controller.text)
        .toList();
  }

  void clearControllers() {
    final controllers = state.deliveryControllers;
    for (final controller in controllers) {
      controller.clear();
    }
  }

  void searchLocationDebounced(String query, {required bool isPickup}) {
    _debounceTimer?.cancel();
    if (query.isEmpty) {
      if (isPickup) {
        emit(
          state.copyWith(
            showPickupPredictions: false,
            showRecentPickUpLocations: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            showDestinationPredictions: false,
            showRecentDestinationLocations: true,
          ),
        );
      }
      return;
    }
    emit(state.copyWith(isLoadingPredictions: true));
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!state.islocationSelected) {
        log(
          'Debounce timer fired, executing search for "$query" (isPickup: $isPickup, activeIndex: ${state.activeDestinationIndex})',
        );
        searchLocations(query, isPickup: isPickup);
      } else {
        emit(state.copyWith(islocationSelected: false));
      }
    });
  }

  // In your searchLocations method of DeliveryCubit
  Future<void> searchLocations(String query, {required bool isPickup}) async {
    try {
      log(
        'Executing search for "$query" (isPickup: $isPickup, activeIndex: ${state.activeDestinationIndex})',
      );

      final predictions = await locationRepository.getPlacePredictions(query);

      log('Found ${predictions.length} predictions for $query');

      // Update the state based on whether there are any predictions
      emit(
        state.copyWith(
          // Only update the appropriate predictions list
          pickupPredictions: isPickup ? predictions : state.pickupPredictions,
          destinationPredictions:
              isPickup ? state.destinationPredictions : predictions,

          // Show predictions panels only if we have results and maintain the current active index
          showPickupPredictions:
              isPickup ? (predictions.isNotEmpty) : state.showPickupPredictions,
          showDestinationPredictions:
              isPickup
                  ? state.showDestinationPredictions
                  : (predictions.isNotEmpty),

          isLoadingPredictions: false,
        ),
      );
    } catch (e) {
      log('Error searching places: $e');
      emit(
        state.copyWith(
          errorMessage: 'Failed to search locations: ${e.toString()}',
          isLoadingPredictions: false,
        ),
      );
    }
  }

  void selectLocationAddress(
    PlacePrediction prediction, {
    required bool isPickup,
    required TextEditingController controller,
    required VoidCallback onBeforeTextChange,
    required VoidCallback onAfterTextChange,
    FocusNode? currentFocusNode,
    FocusNode? nextFocusNode,
  }) {
    log('Selecting location: ${prediction.description} (isPickup: $isPickup)');

    // Prevent search triggering by removing listener temporarily
    onBeforeTextChange();

    // Update text
    controller.text = prediction.description;

    // Clear predictions and prediction panels immediately
    // Also ensure loading indicator is hidden
    emit(
      state.copyWith(
        showPickupPredictions: false,
        showDestinationPredictions: false,
        showRecentPickUpLocations: false,
        showRecentDestinationLocations: false,
        isLoadingPredictions: false,
        islocationSelected: true,
      ),
    );

    // Re-add listener after updating state
    onAfterTextChange();

    // Only unfocus the current field without auto-focusing the next one
    // This removes the auto-focus functionality
    if (currentFocusNode != null) {
      currentFocusNode.unfocus();
    }
  }

  Future<void> handlePickUpLocation(
    PlacePrediction prediction,
    FocusNode pickUpNode,
    FocusNode destinationNode,
    TextEditingController pickUpController,
    TextEditingController destinationController,
    VoidCallback onBeforeTextChange,
    VoidCallback onAfterTextChange,
  ) async {
    emit(
      state.copyWith(
        isLoadingPredictions: false,
        showPickupPredictions: false,
        showDestinationPredictions: false,
        showRecentPickUpLocations: false,
        showRecentDestinationLocations: false,
      ),
    );

    selectLocationAddress(
      prediction,
      isPickup: true,
      controller: pickUpController,
      currentFocusNode: pickUpNode,
      nextFocusNode: null,
      onBeforeTextChange: onBeforeTextChange,
      onAfterTextChange: onAfterTextChange,
    );
  }

  Future<void> handleDestinationLocation(
    PlacePrediction prediction,
    FocusNode destinationNode,
    TextEditingController destinationController,
    VoidCallback onBeforeTextChange,
    VoidCallback onAfterTextChange,
  ) async {
    // First, immediately clear the loading state and prediction panels
    emit(
      state.copyWith(
        isLoadingPredictions: false,
        showPickupPredictions: false,
        showDestinationPredictions: false,
        showRecentPickUpLocations: false,
        showRecentDestinationLocations: false,
      ),
    );

    selectLocationAddress(
      prediction,
      isPickup: false,
      controller: destinationController,
      currentFocusNode: destinationNode,
      nextFocusNode: null,
      onBeforeTextChange: onBeforeTextChange,
      onAfterTextChange: onAfterTextChange,
    );
  }

  Future<void> handleAdditionalDestinationLocation(
    PlacePrediction prediction,
    FocusNode destinationNode,
    TextEditingController destinationController,
    int destinationIndex,
    VoidCallback onBeforeTextChange,
    VoidCallback onAfterTextChange,
  ) async {
    log(
      'Handling location selection for destination #${destinationIndex}: ${prediction.mainText}',
    );

    // First, immediately clear the loading state and prediction panels
    emit(
      state.copyWith(
        isLoadingPredictions: false,
        showPickupPredictions: false,
        showDestinationPredictions: false,
        showRecentPickUpLocations: false,
        showRecentDestinationLocations: false,
      ),
    );

    // Then select the location
    selectLocationAddress(
      prediction,
      isPickup: false,
      controller: destinationController,
      currentFocusNode: destinationNode,
      nextFocusNode: null,
      onBeforeTextChange: onBeforeTextChange,
      onAfterTextChange: onAfterTextChange,
    );
  }

  void hideAllPredictionPanels() {
    emit(
      state.copyWith(
        showPickupPredictions: false,
        showDestinationPredictions: false,
        isLoadingPredictions: false,
      ),
    );
  }

  void togglePredictionVisibility({
    required bool isPickup,
    required bool isVisible,
  }) {
    emit(
      state.copyWith(
        showPickupPredictions:
            isPickup ? isVisible : state.showPickupPredictions,
        showDestinationPredictions:
            isPickup ? state.showDestinationPredictions : isVisible,
        isPickUpLocation: isPickup ? isVisible : state.isPickUpLocation,
        isDestinationLocation:
            isPickup ? state.isDestinationLocation : isVisible,
      ),
    );
  }

  void isPickUpLocation({required bool isPickUpLocation}) {
    emit(
      state.copyWith(
        isPickUpLocation: isPickUpLocation,
        isDestinationLocation:
            isPickUpLocation ? false : state.isDestinationLocation,
      ),
    );
  }

  void isDestinationLocation({required bool isDestinationLocation}) {
    emit(
      state.copyWith(
        isDestinationLocation: isDestinationLocation,
        isPickUpLocation:
            isDestinationLocation ? false : state.isPickUpLocation,
      ),
    );
  }

  void showRecentPickUpLocations({
    required bool showRecentlySearchedLocations,
  }) {
    emit(
      state.copyWith(
        showRecentPickUpLocations: showRecentlySearchedLocations,
        showDestinationPredictions: false,
        showPickupPredictions: false,
        showRecentDestinationLocations: false,
      ),
    );

    if (showRecentlySearchedLocations) {
      fetchRecentLocations();
    }
  }

  void showDestinationRecentlySearchedLocations({
    required bool showDestinationRecentlySearchedLocations,
  }) {
    emit(
      state.copyWith(
        showRecentDestinationLocations:
            showDestinationRecentlySearchedLocations,
        showPickupPredictions: false,
        showDestinationPredictions: false,
        showRecentPickUpLocations: false,
      ),
    );

    if (showDestinationRecentlySearchedLocations) {
      fetchRecentLocations();
    }
  }

  Future<void> clearPredictions() async {
    emit(
      state.copyWith(
        pickupPredictions: [],
        destinationPredictions: [],
        showPickupPredictions: false,
        showDestinationPredictions: false,
      ),
    );
  }

  Future<void> fetchRecentLocations() async {
    try {
      final locations = await locationRepository.getRecentLocations();
      emit(state.copyWith(recentLocations: locations));
    } catch (e) {
      log('Error fetching recent locations: $e');
    }
  }

  Future<void> clearRecentLocations() async {
    try {
      await locationRepository.clearRecentLocations();
      emit(state.copyWith(recentLocations: []));
    } catch (e) {
      log('Error clearing recent locations: $e');
    }
  }

  void setActiveDestinationIndex(int index) {
    log('Setting active destination index to $index');

    // Update the active index and ensure the appropriate flag is set
    emit(
      state.copyWith(
        activeDestinationIndex: index,
        isDestinationLocation: true, // We're now working with a destination
        isPickUpLocation: false, // Not pickup anymore
      ),
    );
  }

  void _addToRecentLocations(Location location) {
    // Add to recent location via repository
    try {
      locationRepository.saveLocation(location);
      fetchRecentLocations(); // Refresh the list
    } catch (e) {
      log('Error saving location: $e');
    }
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
