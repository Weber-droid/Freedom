class Location {

  Location({
    required this.id,
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.iconType,
    required this.isFavorite,
  });
  final String id;
  final String placeId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String iconType;
  final bool isFavorite;
}