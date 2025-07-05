// Extension methods for easy conversion
import 'package:geodesy/geodesy.dart' as ll;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

extension LatLngConversion on gmaps.LatLng {
  ll.LatLng toLatLong2() {
    return ll.LatLng(latitude, longitude);
  }
}

extension LatLong2Conversion on ll.LatLng {
  gmaps.LatLng toGoogleMaps() {
    return gmaps.LatLng(latitude, longitude);
  }
}
