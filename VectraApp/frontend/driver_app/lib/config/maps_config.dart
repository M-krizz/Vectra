import 'package:latlong2/latlong.dart';

/// Centralized Mapbox configuration for the Driver App.
class MapsConfig {
  MapsConfig._();

  static const String accessToken =
      'YOUR_MAPBOX_ACCESS_TOKEN';

  // Default map center (Coimbatore, India)
  static const double defaultLat = 11.0168;
  static const double defaultLng = 76.9558;
  static const double defaultZoom = 14.0;
  static final LatLng defaultCenter = LatLng(defaultLat, defaultLng);

  // Mapbox tile URLs
  static String get tileUrlTemplate =>
      'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}@2x?access_token=$accessToken';
  static String get darkTileUrlTemplate =>
      'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/{z}/{x}/{y}@2x?access_token=$accessToken';
}
