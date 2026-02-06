import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DriversApi {
  // Use localhost for Web/Windows, 10.0.2.2 for Android Emulator
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    try {
      if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000';
    } catch (_) {}
    return 'http://localhost:3000';
  } 

  Future<void> updateLocation(double lat, double lng) async {
    final url = Uri.parse('$baseUrl/drivers/location');
    
    // Mock token
    final headers = {
      'Content-Type': 'application/json',
      // 'Authorization': 'Bearer <token>'
    };

    final body = jsonEncode({
      'lat': lat,
      'lng': lng,
    });

    try {
      await http.put(url, headers: headers, body: body);
    } catch (e) {
      print('Location Update Error: $e');
    }
  }

  Future<List<dynamic>> getNearbyRequests(double lat, double lng) async {
    final url = Uri.parse('$baseUrl/drivers/nearby-requests?lat=$lat&lng=$lng');
    
    final headers = {
      'Content-Type': 'application/json',
       // 'Authorization': 'Bearer <token>'
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch requests: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
