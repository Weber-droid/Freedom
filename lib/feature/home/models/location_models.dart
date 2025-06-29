class LocationModel {

  LocationModel({
    required this.id,
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.iconType = 'location_on',
    this.isFavorite = false,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as String? ?? '',
      placeId: json['place_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: json['latitude'] as double? ?? 0.0,
      longitude: json['longitude'] as double? ?? 0.0,
      iconType: json['icon_type'] as String? ?? 'location_on',
      isFavorite: json['is_favorite'] as bool? ?? false,
    );
  }
  final String id;
  final String placeId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String iconType;
  final bool isFavorite;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'place_id': placeId,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'icon_type': iconType,
      'is_favorite': isFavorite,
    };
  }
}