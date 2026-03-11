import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:shared/shared.dart';
import '../models/place_model.dart';

class PlacesRepository {
  /// Search for places using Mapbox Geocoding API (via backend proxy)
  Future<List<PlaceModel>> searchPlaces(
    String query, {
    LatLng? nearLocation,
  }) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      // Build the API URL for our Backend Proxy
      String url = '${ApiConstants.baseUrl}${ApiConstants.placesAutocomplete}'
          '?input=${Uri.encodeComponent(query)}';

      // Add location bias if provided
      if (nearLocation != null) {
        url += '&location=${nearLocation.latitude},${nearLocation.longitude}'
               '&radius=50000'; // 50km radius
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          return predictions
              .map(
                (p) {
                  // Extract coordinates directly from autocomplete response
                  LatLng? location;
                  if (p['geometry'] != null && p['geometry']['location'] != null) {
                    final loc = p['geometry']['location'];
                    location = LatLng(
                      (loc['lat'] as num).toDouble(),
                      (loc['lng'] as num).toDouble(),
                    );
                  }
                  return PlaceModel(
                    placeId: p['place_id'] as String,
                    name:
                        p['structured_formatting']?['main_text'] as String? ??
                        p['description'] as String,
                    address: p['description'] as String,
                    location: location,
                  );
                },
              )
              .toList();
        } else if (data['status'] == 'ZERO_RESULTS') {
          return [];
        }
      }

      // API returned a non-OK status
      debugPrint('Places API returned non-OK status');
      return [];
    } catch (e) {
      debugPrint('Places API error: $e');
      return [];
    }
  }

  /// Get place details (including lat/lng) from place_id using backend proxy.
  /// With Mapbox, coordinates are already included in autocomplete results,
  /// so this is mainly a fallback.
  Future<PlaceModel?> getPlaceDetails(String placeId) async {
    try {
      String url = '${ApiConstants.baseUrl}${ApiConstants.placesDetails}'
          '?place_id=$placeId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final result = data['result'];
          final location = result['geometry']['location'];

          return PlaceModel(
            placeId: placeId,
            name: result['name'] as String,
            address: result['formatted_address'] as String,
            location: LatLng(
              (location['lat'] as num).toDouble(),
              (location['lng'] as num).toDouble(),
            ),
          );
        }
      }

      return null;
    } catch (e) {
      debugPrint('Place details error: $e');
      return null;
    }
  }

  /// Get route between two points using Mapbox Directions API (via backend proxy)
  Future<RouteModel> getRoute(PlaceModel pickup, PlaceModel destination) async {
    if (pickup.location == null || destination.location == null) {
      throw Exception('Pickup and destination must have locations');
    }

    List<LatLng> polylineCoordinates = [];
    double? routeDistanceMeters;
    double? routeDurationSeconds;

    try {
      // Fetch route from backend Mapbox directions endpoint
      final url = '${ApiConstants.baseUrl}${ApiConstants.directions}'
          '?origin_lat=${pickup.location!.latitude}'
          '&origin_lng=${pickup.location!.longitude}'
          '&dest_lat=${destination.location!.latitude}'
          '&dest_lng=${destination.location!.longitude}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extract GeoJSON coordinates from Mapbox Directions response
        if (data['geometry'] != null &&
            data['geometry']['coordinates'] != null) {
          final coords = data['geometry']['coordinates'] as List;
          polylineCoordinates = coords
              .map((c) => LatLng(
                    (c[1] as num).toDouble(), // lat
                    (c[0] as num).toDouble(), // lng
                  ))
              .toList();
        }

        // Extract distance and duration from Mapbox response
        if (data['distance'] != null) {
          routeDistanceMeters = (data['distance'] as num).toDouble();
        }
        if (data['duration'] != null) {
          routeDurationSeconds = (data['duration'] as num).toDouble();
        }
      }
    } catch (e) {
      debugPrint('Directions API failed, using straight line: $e');
    }

    // If no polyline, create a simple straight line
    if (polylineCoordinates.isEmpty) {
      polylineCoordinates = _createStraightLine(
        pickup.location!,
        destination.location!,
      );
    }

    // Calculate distance and duration
    final distance = routeDistanceMeters ??
        _calculateDistance(pickup.location!, destination.location!);
    final durationSeconds = routeDurationSeconds?.round() ??
        ((distance / 1000) / 30 * 60 * 60).round(); // 30 km/h fallback
    final distanceKm = distance / 1000;
    final durationMinutes = (durationSeconds / 60).round();

    return RouteModel(
      pickup: pickup,
      destination: destination,
      polylinePoints: polylineCoordinates,
      distanceMeters: distance,
      durationSeconds: durationSeconds,
      distanceText: distanceKm < 1
          ? '${distance.round()} m'
          : '${distanceKm.toStringAsFixed(1)} km',
      durationText: durationMinutes < 60
          ? '$durationMinutes min'
          : '${durationMinutes ~/ 60}h ${durationMinutes % 60}min',
    );
  }

  /// Create a straight line between two points with intermediate points
  List<LatLng> _createStraightLine(LatLng start, LatLng end) {
    const int numPoints = 10;
    final List<LatLng> points = [];

    for (int i = 0; i <= numPoints; i++) {
      final fraction = i / numPoints;
      final lat = start.latitude + (end.latitude - start.latitude) * fraction;
      final lng =
          start.longitude + (end.longitude - start.longitude) * fraction;
      points.add(LatLng(lat, lng));
    }

    return points;
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371000; // meters

    final double lat1Rad = start.latitude * pi / 180;
    final double lat2Rad = end.latitude * pi / 180;
    final double deltaLatRad = (end.latitude - start.latitude) * pi / 180;
    final double deltaLngRad = (end.longitude - start.longitude) * pi / 180;

    final double a =
        sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLngRad / 2) *
            sin(deltaLngRad / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Create a PlaceModel from current location
  PlaceModel createCurrentLocationPlace(LatLng location, {String? address}) {
    return PlaceModel(
      placeId: 'current_location',
      name: 'Current Location',
      address: address ?? 'Your current location',
      location: location,
    );
  }
}
