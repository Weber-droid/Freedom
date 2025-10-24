// Google Places API Response Models

class PlacesAutocompleteResponse {
  final String status;
  final List<AutocompletePrediction> predictions;
  final String? errorMessage;

  PlacesAutocompleteResponse({
    required this.status,
    required this.predictions,
    this.errorMessage,
  });

  factory PlacesAutocompleteResponse.fromJson(Map<String, dynamic> json) {
    return PlacesAutocompleteResponse(
      status: json['status'] as String,
      predictions:
          (json['predictions'] as List<dynamic>?)
              ?.map(
                (e) =>
                    AutocompletePrediction.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      errorMessage: json['error_message'] as String?,
    );
  }

  bool get isOk => status == 'OK';
  bool get hasResults => predictions.isNotEmpty;
}

class AutocompletePrediction {
  final String description;
  final String placeId;
  final List<String> types;
  final StructuredFormatting? structuredFormatting;
  final String? reference;
  final int? distanceMeters;

  AutocompletePrediction({
    required this.description,
    required this.placeId,
    required this.types,
    this.structuredFormatting,
    this.reference,
    this.distanceMeters,
  });

  factory AutocompletePrediction.fromJson(Map<String, dynamic> json) {
    return AutocompletePrediction(
      description: json['description'] as String,
      placeId: json['place_id'] as String,
      types:
          (json['types'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      structuredFormatting:
          json['structured_formatting'] != null
              ? StructuredFormatting.fromJson(
                json['structured_formatting'] as Map<String, dynamic>,
              )
              : null,
      reference: json['reference'] as String?,
      distanceMeters: json['distance_meters'] as int?,
    );
  }
}

class StructuredFormatting {
  final String mainText;
  final String? secondaryText;
  final List<MatchedSubstring>? mainTextMatchedSubstrings;

  StructuredFormatting({
    required this.mainText,
    this.secondaryText,
    this.mainTextMatchedSubstrings,
  });

  factory StructuredFormatting.fromJson(Map<String, dynamic> json) {
    return StructuredFormatting(
      mainText: json['main_text'] as String,
      secondaryText: json['secondary_text'] as String?,
      mainTextMatchedSubstrings:
          (json['main_text_matched_substrings'] as List<dynamic>?)
              ?.map((e) => MatchedSubstring.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

class MatchedSubstring {
  final int length;
  final int offset;

  MatchedSubstring({required this.length, required this.offset});

  factory MatchedSubstring.fromJson(Map<String, dynamic> json) {
    return MatchedSubstring(
      length: json['length'] as int,
      offset: json['offset'] as int,
    );
  }
}

class PlaceDetailsResponse {
  final String status;
  final PlaceDetails? result;
  final String? errorMessage;

  PlaceDetailsResponse({required this.status, this.result, this.errorMessage});

  factory PlaceDetailsResponse.fromJson(Map<String, dynamic> json) {
    return PlaceDetailsResponse(
      status: json['status'] as String,
      result:
          json['result'] != null
              ? PlaceDetails.fromJson(json['result'] as Map<String, dynamic>)
              : null,
      errorMessage: json['error_message'] as String?,
    );
  }

  bool get isOk => status == 'OK';
}

class PlaceDetails {
  final String placeId;
  final String name;
  final String? formattedAddress;
  final String? formattedPhoneNumber;
  final String? internationalPhoneNumber;
  final Geometry? geometry;
  final List<String> types;
  final String? website;
  final double? rating;
  final int? userRatingsTotal;
  final List<Photo>? photos;
  final OpeningHours? openingHours;
  final List<AddressComponent>? addressComponents;
  final PlusCode? plusCode;
  final String? url;
  final int? utcOffset;
  final String? vicinity;

  PlaceDetails({
    required this.placeId,
    required this.name,
    this.formattedAddress,
    this.formattedPhoneNumber,
    this.internationalPhoneNumber,
    this.geometry,
    required this.types,
    this.website,
    this.rating,
    this.userRatingsTotal,
    this.photos,
    this.openingHours,
    this.addressComponents,
    this.plusCode,
    this.url,
    this.utcOffset,
    this.vicinity,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    return PlaceDetails(
      placeId: json['place_id'] as String,
      name: json['name'] as String,
      formattedAddress: json['formatted_address'] as String?,
      formattedPhoneNumber: json['formatted_phone_number'] as String?,
      internationalPhoneNumber: json['international_phone_number'] as String?,
      geometry:
          json['geometry'] != null
              ? Geometry.fromJson(json['geometry'] as Map<String, dynamic>)
              : null,
      types:
          (json['types'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      website: json['website'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: json['user_ratings_total'] as int?,
      photos:
          (json['photos'] as List<dynamic>?)
              ?.map((e) => Photo.fromJson(e as Map<String, dynamic>))
              .toList(),
      openingHours:
          json['opening_hours'] != null
              ? OpeningHours.fromJson(
                json['opening_hours'] as Map<String, dynamic>,
              )
              : null,
      addressComponents:
          (json['address_components'] as List<dynamic>?)
              ?.map((e) => AddressComponent.fromJson(e as Map<String, dynamic>))
              .toList(),
      plusCode:
          json['plus_code'] != null
              ? PlusCode.fromJson(json['plus_code'] as Map<String, dynamic>)
              : null,
      url: json['url'] as String?,
      utcOffset: json['utc_offset'] as int?,
      vicinity: json['vicinity'] as String?,
    );
  }
}

class Geometry {
  final Location location;
  final Viewport? viewport;

  Geometry({required this.location, this.viewport});

  factory Geometry.fromJson(Map<String, dynamic> json) {
    return Geometry(
      location: Location.fromJson(json['location'] as Map<String, dynamic>),
      viewport:
          json['viewport'] != null
              ? Viewport.fromJson(json['viewport'] as Map<String, dynamic>)
              : null,
    );
  }
}

class Location {
  final double lat;
  final double lng;

  Location({required this.lat, required this.lng});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}

class Viewport {
  final Location northeast;
  final Location southwest;

  Viewport({required this.northeast, required this.southwest});

  factory Viewport.fromJson(Map<String, dynamic> json) {
    return Viewport(
      northeast: Location.fromJson(json['northeast'] as Map<String, dynamic>),
      southwest: Location.fromJson(json['southwest'] as Map<String, dynamic>),
    );
  }
}

class Photo {
  final int height;
  final int width;
  final String photoReference;
  final List<String> htmlAttributions;

  Photo({
    required this.height,
    required this.width,
    required this.photoReference,
    required this.htmlAttributions,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      height: json['height'] as int,
      width: json['width'] as int,
      photoReference: json['photo_reference'] as String,
      htmlAttributions:
          (json['html_attributions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

class OpeningHours {
  final bool? openNow;
  final List<Period>? periods;
  final List<String>? weekdayText;

  OpeningHours({this.openNow, this.periods, this.weekdayText});

  factory OpeningHours.fromJson(Map<String, dynamic> json) {
    return OpeningHours(
      openNow: json['open_now'] as bool?,
      periods:
          (json['periods'] as List<dynamic>?)
              ?.map((e) => Period.fromJson(e as Map<String, dynamic>))
              .toList(),
      weekdayText:
          (json['weekday_text'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
    );
  }
}

class Period {
  final TimeInfo open;
  final TimeInfo? close;

  Period({required this.open, this.close});

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      open: TimeInfo.fromJson(json['open'] as Map<String, dynamic>),
      close:
          json['close'] != null
              ? TimeInfo.fromJson(json['close'] as Map<String, dynamic>)
              : null,
    );
  }
}

class TimeInfo {
  final int day;
  final String time;

  TimeInfo({required this.day, required this.time});

  factory TimeInfo.fromJson(Map<String, dynamic> json) {
    return TimeInfo(day: json['day'] as int, time: json['time'] as String);
  }
}

class AddressComponent {
  final String longName;
  final String shortName;
  final List<String> types;

  AddressComponent({
    required this.longName,
    required this.shortName,
    required this.types,
  });

  factory AddressComponent.fromJson(Map<String, dynamic> json) {
    return AddressComponent(
      longName: json['long_name'] as String,
      shortName: json['short_name'] as String,
      types:
          (json['types'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
    );
  }
}

class PlusCode {
  final String compoundCode;
  final String globalCode;

  PlusCode({required this.compoundCode, required this.globalCode});

  factory PlusCode.fromJson(Map<String, dynamic> json) {
    return PlusCode(
      compoundCode: json['compound_code'] as String,
      globalCode: json['global_code'] as String,
    );
  }
}

// Exception class for API errors
class PlacesApiException implements Exception {
  final String message;
  final String? details;

  PlacesApiException(this.message, [this.details]);

  @override
  String toString() =>
      'PlacesApiException: $message${details != null ? '\nDetails: $details' : ''}';
}
