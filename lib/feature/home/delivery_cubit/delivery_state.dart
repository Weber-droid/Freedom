part of 'delivery_cubit.dart';

enum DeliveryStatus { initial, loading, success, failure }

class DeliveryState extends Equatable {
  const DeliveryState({
    this.deliveryControllers = const [],
    this.isMultipleDestination = false,
    this.status = DeliveryStatus.initial,
    this.errorMessage,
    this.deliveryData,
    this.pickupPredictions = const [],
    this.destinationPredictions = const [],
    this.showPickupPredictions = false,
    this.showDestinationPredictions = false,
    this.isPickUpLocation = false,
    this.isDestinationLocation = false,
    this.recentLocations = const [],
    this.showRecentPickUpLocations = false,
    this.showRecentDestinationLocations = false,
    this.isLoadingPredictions = false,
    this.activeDestinationIndex = 0,
    this.islocationSelected = false,
    this.showDeliverySearchSheet = false,
    this.searchTimeElapsed = 0,
    this.isSearching = false,
    this.riderFound = false,
  });

  final List<TextEditingController> deliveryControllers;
  final bool isMultipleDestination;
  final DeliveryStatus status;
  final String? errorMessage;
  final DeliveryData? deliveryData;

  // Location search related state
  final List<PlacePrediction> pickupPredictions;
  final List<PlacePrediction> destinationPredictions;
  final bool showPickupPredictions;
  final bool showDestinationPredictions;

  // Additional state properties from SearchSheet
  final bool isPickUpLocation;
  final bool isDestinationLocation;
  final List<Location> recentLocations;
  final bool showRecentPickUpLocations;
  final bool showRecentDestinationLocations;
  final bool isLoadingPredictions;
  final int activeDestinationIndex;
  final bool islocationSelected;
  final bool showDeliverySearchSheet;
  final int searchTimeElapsed;
  final bool isSearching;
  final bool riderFound;

  DeliveryState copyWith({
    List<TextEditingController>? deliveryControllers,
    bool? isMultipleDestination,
    DeliveryStatus? status,
    String? errorMessage,
    DeliveryData? deliveryData,
    List<PlacePrediction>? pickupPredictions,
    List<PlacePrediction>? destinationPredictions,
    bool? showPickupPredictions,
    bool? showDestinationPredictions,
    bool? isPickUpLocation,
    bool? isDestinationLocation,
    List<Location>? recentLocations,
    bool? showRecentPickUpLocations,
    bool? showRecentDestinationLocations,
    bool? isLoadingPredictions,
    int? activeDestinationIndex,
    bool? islocationSelected,
    bool? showDeliverySearchSheet,
    int? searchTimeElapsed,
    bool? isSearching,
    bool? riderFound,
  }) {
    return DeliveryState(
      deliveryControllers: deliveryControllers ?? this.deliveryControllers,
      isMultipleDestination:
          isMultipleDestination ?? this.isMultipleDestination,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      deliveryData: deliveryData ?? this.deliveryData,
      pickupPredictions: pickupPredictions ?? this.pickupPredictions,
      destinationPredictions:
          destinationPredictions ?? this.destinationPredictions,
      showPickupPredictions:
          showPickupPredictions ?? this.showPickupPredictions,
      showDestinationPredictions:
          showDestinationPredictions ?? this.showDestinationPredictions,
      isPickUpLocation: isPickUpLocation ?? this.isPickUpLocation,
      isDestinationLocation:
          isDestinationLocation ?? this.isDestinationLocation,
      recentLocations: recentLocations ?? this.recentLocations,
      showRecentPickUpLocations:
          showRecentPickUpLocations ?? this.showRecentPickUpLocations,
      showRecentDestinationLocations:
          showRecentDestinationLocations ?? this.showRecentDestinationLocations,
      isLoadingPredictions: isLoadingPredictions ?? this.isLoadingPredictions,
      activeDestinationIndex:
          activeDestinationIndex ?? this.activeDestinationIndex,
      islocationSelected: islocationSelected ?? this.islocationSelected,
      showDeliverySearchSheet:
          showDeliverySearchSheet ?? this.showDeliverySearchSheet,
      searchTimeElapsed: searchTimeElapsed ?? this.searchTimeElapsed,
      isSearching: isSearching ?? this.isSearching,
      riderFound: riderFound ?? this.riderFound,
    );
  }

  @override
  List<Object?> get props => [
    deliveryControllers,
    isMultipleDestination,
    status,
    errorMessage,
    deliveryData,
    pickupPredictions,
    destinationPredictions,
    showPickupPredictions,
    showDestinationPredictions,
    isPickUpLocation,
    isDestinationLocation,
    recentLocations,
    showRecentPickUpLocations,
    showRecentDestinationLocations,
    isLoadingPredictions,
    activeDestinationIndex,
    islocationSelected,
    showDeliverySearchSheet,
    searchTimeElapsed,
    isSearching,
    riderFound,
  ];
}
