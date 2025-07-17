class FreedomLocation {
  FreedomLocation({
    required this.id,
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.iconType,
    required this.isFavorite,
  });

  factory FreedomLocation.fromJson(Map<String, dynamic> json) {
    return FreedomLocation(
      id: json['id'] as String,
      placeId: json['place_id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      iconType: json['icon_type'] as String,
      isFavorite: json['is_favorite'] as bool,
    );
  }

  // Empty constructor with default values
  FreedomLocation.empty()
    : id = '',
      placeId = '',
      name = '',
      address = '',
      latitude = 0.0,
      longitude = 0.0,
      iconType = '',
      isFavorite = false;

  factory FreedomLocation.from(FreedomLocation other) {
    return FreedomLocation(
      id: other.id,
      placeId: other.placeId,
      name: other.name,
      address: other.address,
      latitude: other.latitude,
      longitude: other.longitude,
      iconType: other.iconType,
      isFavorite: other.isFavorite,
    );
  }
  String id;
  String placeId;
  String name;
  String address;
  double latitude;
  double longitude;
  String iconType;
  bool isFavorite;

  // Update method to modify specific fields
  void update({
    String? id,
    String? placeId,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? iconType,
    bool? isFavorite,
  }) {
    if (id != null) this.id = id;
    if (placeId != null) this.placeId = placeId;
    if (name != null) this.name = name;
    if (address != null) this.address = address;
    if (latitude != null) this.latitude = latitude;
    if (longitude != null) this.longitude = longitude;
    if (iconType != null) this.iconType = iconType;
    if (isFavorite != null) this.isFavorite = isFavorite;
  }

  // Keep the immutable copyWith method for when you need it
  FreedomLocation copyWith({
    String? id,
    String? placeId,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? iconType,
    bool? isFavorite,
  }) {
    return FreedomLocation(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      iconType: iconType ?? this.iconType,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

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
