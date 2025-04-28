class PlacePrediction {

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    required this.types,
    required this.iconType,
  });
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final List<String> types;
  final String iconType;
}