import 'dart:convert';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import '../models/place_model.dart';

/// Repository for Places/Location related operations
/// Uses Google Places API for real search
class PlacesRepository {
  // Google Maps API Key
  static const String _apiKey = 'AIzaSyAmkzwBHzhWbtKM61zsipsMFKhxjv3vyBg';

  final PolylinePoints _polylinePoints = PolylinePoints();

  // Mock places as fallback (Coimbatore area)
  static final List<PlaceModel> _mockPlaces = [
    const PlaceModel(
      placeId: 'mock_1',
      name: 'Brookefields Mall',
      address: 'Brookefields, Coimbatore, Tamil Nadu 641004',
      location: LatLng(11.0168, 76.9558),
    ),
    const PlaceModel(
      placeId: 'mock_2',
      name: 'Coimbatore Junction Railway Station',
      address: 'Railway Station Rd, Coimbatore, Tamil Nadu 641018',
      location: LatLng(11.0015, 76.9669),
    ),
    const PlaceModel(
      placeId: 'mock_3',
      name: 'PSG College of Technology',
      address: 'Avinashi Rd, Peelamedu, Coimbatore, Tamil Nadu 641004',
      location: LatLng(11.0242, 77.0022),
    ),
    const PlaceModel(
      placeId: 'mock_4',
      name: 'Coimbatore International Airport',
      address: 'Avinashi Rd, Peelamedu, Coimbatore, Tamil Nadu 641014',
      location: LatLng(11.0299, 77.0434),
    ),
    const PlaceModel(
      placeId: 'mock_5',
      name: 'Gandhipuram Bus Stand',
      address: 'Gandhipuram, Coimbatore, Tamil Nadu 641012',
      location: LatLng(11.0168, 76.9674),
    ),
  ];

  /// Search for places using Google Places Autocomplete API
  Future<List<PlaceModel>> searchPlaces(
    String query, {
    LatLng? nearLocation,
  }) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      // Build the API URL for Places Autocomplete
      String url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(query)}'
          '&key=$_apiKey'
          '&components=country:in'; // Restrict to India

      // Add location bias if provided
      if (nearLocation != null) {
        url +=
            '&location=${nearLocation.latitude},${nearLocation.longitude}'
            '&radius=50000'; // 50km radius
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          return predictions
              .map(
                (p) => PlaceModel(
                  placeId: p['place_id'] as String,
                  name:
                      p['structured_formatting']?['main_text'] as String? ??
                      p['description'] as String,
                  address: p['description'] as String,
                  location: null, // Will be fetched when selected
                ),
              )
              .toList();
        } else if (data['status'] == 'ZERO_RESULTS') {
          return [];
        }
      }

      // Fallback to mock data if API fails
      print('Places API returned non-OK status, using mock data');
      return _searchMockPlaces(query);
    } catch (e) {
      print('Places API error: $e');
      // Fallback to mock data
      return _searchMockPlaces(query);
    }
  }

  /// Fallback mock search
  List<PlaceModel> _searchMockPlaces(String query) {
    final queryLower = query.toLowerCase();
    final results = _mockPlaces.where((place) {
      return place.name.toLowerCase().contains(queryLower) ||
          place.address.toLowerCase().contains(queryLower);
    }).toList();

    results.sort((a, b) {
      final aNameMatch = a.name.toLowerCase().startsWith(queryLower) ? 0 : 1;
      final bNameMatch = b.name.toLowerCase().startsWith(queryLower) ? 0 : 1;
      return aNameMatch.compareTo(bNameMatch);
    });

    return results.take(5).toList();
  }

  /// Get place details (including lat/lng) from place_id using Google Places Details API
  Future<PlaceModel?> getPlaceDetails(String placeId) async {
    // Check if it's a mock place first
    if (placeId.startsWith('mock_')) {
      try {
        return _mockPlaces.firstWhere((p) => p.placeId == placeId);
      } catch (e) {
        return null;
      }
    }

    try {
      final url =
          'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$placeId'
          '&fields=name,formatted_address,geometry'
          '&key=$_apiKey';

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
      print('Place details error: $e');
      return null;
    }
  }

  /// Get route between two points (using real polyline when possible, mock fallback)
  Future<RouteModel> getRoute(PlaceModel pickup, PlaceModel destination) async {
    if (pickup.location == null || destination.location == null) {
      throw Exception('Pickup and destination must have locations');
    }

    List<LatLng> polylineCoordinates = [];

    try {
      // Try to get real route from Google Directions API
      PolylineResult result = await _polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: _apiKey,
        request: PolylineRequest(
          origin: PointLatLng(
            pickup.location!.latitude,
            pickup.location!.longitude,
          ),
          destination: PointLatLng(
            destination.location!.latitude,
            destination.location!.longitude,
          ),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        polylineCoordinates = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
      }
    } catch (e) {
      // Fallback to straight line if API fails
      print('Polyline API failed, using straight line: $e');
    }

    // If no polyline, create a simple straight line
    if (polylineCoordinates.isEmpty) {
      polylineCoordinates = _createStraightLine(
        pickup.location!,
        destination.location!,
      );
    }

    // Calculate distance and duration (mock estimates if API didn't provide)
    final distance = _calculateDistance(
      pickup.location!,
      destination.location!,
    );
    final distanceKm = distance / 1000;
    final durationMinutes = (distanceKm / 30 * 60)
        .round(); // Assume 30 km/h average

    return RouteModel(
      pickup: pickup,
      destination: destination,
      polylinePoints: polylineCoordinates,
      distanceMeters: distance,
      durationSeconds: durationMinutes * 60,
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
