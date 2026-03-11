import 'package:latlong2/latlong.dart';

/// Centralized Mapbox configuration for the Rider App.
class MapsConfig {
  MapsConfig._();

  /// Mapbox public access token (safe for client-side usage).
  static const String accessToken =
      'YOUR_MAPBOX_ACCESS_TOKEN';

  // Default map center (Coimbatore, India)
  static const double defaultLat = 11.0168;
  static const double defaultLng = 76.9558;
  static const double defaultZoom = 14.0;

  /// Convenience getter for LatLng.
  static final LatLng defaultLatLng = LatLng(defaultLat, defaultLng);

  /// Mapbox tile URL for raster tiles (used by flutter_map).
  static String get tileUrlTemplate =>
      'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}@2x?access_token=$accessToken';

  /// Dark-mode tile URL.
  static String get darkTileUrlTemplate =>
      'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/{z}/{x}/{y}@2x?access_token=$accessToken';
}
