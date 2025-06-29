class PlacePredictionModel {
  PlacePredictionModel({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    required this.types,
    this.iconType = 'location_on',
  });
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final List<String> types;
  final String iconType;

  static String getIconForPlaceType(List<String> types) {
    if (types.contains('airport')) return 'local_airport';
    if (types.contains('train_station')) return 'train';
    if (types.contains('lodging')) return 'hotel';
    if (types.contains('restaurant') || types.contains('food')) {
      return 'restaurant';
    }
    if (types.contains('shopping_mall')) return 'shopping_cart';
    if (types.contains('hospital')) return 'local_hospital';
    return 'location_on';
  }
}
