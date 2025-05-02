class Location {
  // Constructor that requires all fields
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

  // Empty constructor with default values
  Location.empty()
      : id = '',
        placeId = '',
        name = '',
        address = '',
        latitude = 0.0,
        longitude = 0.0,
        iconType = '',
        isFavorite = false;

  // Factory constructor from another location
  factory Location.from(Location other) {
    return Location(
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
  Location copyWith({
    String? id,
    String? placeId,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? iconType,
    bool? isFavorite,
  }) {
    return Location(
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
}
