import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class RidesApi {
  // Use localhost for Web/Windows, 10.0.2.2 for Android Emulator
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    try {
      if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000';
    } catch (_) {}
    return 'http://localhost:3000';
  } 
  
  Future<Map<String, dynamic>> createRideRequest({
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
    String? pickupAddress,
    String? dropAddress,
    String rideType = 'SOLO',
  }) async {
    final url = Uri.parse('$baseUrl/ride-requests');
    print('POST Request to: $url');
    
    // TODO: Add proper Authorization header with Bearer token
    // For now, assuming endpoints might be open or we mock auth
    final headers = {
      'Content-Type': 'application/json',
      // 'Authorization': 'Bearer <token>' 
    };

    final body = jsonEncode({
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropLat': dropLat,
      'dropLng': dropLng,
      'pickupAddress': pickupAddress,
      'dropAddress': dropAddress,
      'rideType': rideType,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create ride request: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
