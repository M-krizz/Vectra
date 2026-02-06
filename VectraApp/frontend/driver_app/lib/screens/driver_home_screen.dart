import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator/geolocator.dart';
import '../services/drivers_api.dart';
import 'chat_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  GoogleMapController? _mapController;
  final DriversApi _driversApi = DriversApi();
  
  static const CameraPosition _kDefaultPosition = CameraPosition(
    target: LatLng(12.9716, 77.5946),
    zoom: 14.4746,
  );

  LatLng? _currentPosition;
  final Set<Marker> _markers = {};
  bool _isOnline = false;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(_currentPosition!),
    );
  }

  void _toggleOnline() {
    setState(() {
      _isOnline = !_isOnline;
    });

    if (_isOnline) {
      _startBackgroundUpdates();
    } else {
      _poller?.cancel();
    }
  }

  void _startBackgroundUpdates() {
    // Poll every 10 seconds for nearby requests & location update
    _poller = Timer.periodic(const Duration(seconds: 10), (timer) async {
       if (_currentPosition == null) return;

       // 1. Send Heartbeat
       await _driversApi.updateLocation(_currentPosition!.latitude, _currentPosition!.longitude);

       // 2. Fetch Nearby Requests
       try {
         final requests = await _driversApi.getNearbyRequests(_currentPosition!.latitude, _currentPosition!.longitude);
         
         setState(() {
           _markers.clear();
           for (var req in requests) {
             // Validate coordinates exist
              if (req['pickupPoint'] != null && req['pickupPoint']['coordinates'] != null) {
                 final coords = req['pickupPoint']['coordinates'];
                 final lat = coords[1]; // geojson is [lng, lat]
                 final lng = coords[0];
                 
                 _markers.add(Marker(
                   markerId: MarkerId(req['id']),
                   position: LatLng(lat, lng),
                   icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
                   infoWindow: InfoWindow(
                     title: 'Request: ${req['rideType']}',
                     snippet: 'Pickup here',
                   ),
                 ));
              }
           }
         });
       } catch (e) {
         print("Error fetching requests: $e");
       }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vectra Driver'),
        actions: [
          Switch(
            value: _isOnline, 
            onChanged: (val) => _toggleOnline(),
            activeColor: Colors.green,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: _kDefaultPosition,
        myLocationEnabled: true,
        onMapCreated: (controller) => _mapController = controller,
        markers: _markers,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'chat_btn',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChatScreen(
                    tripId: 'test-trip-123',
                    userId: 'driver-1',
                  ),
                ),
              );
            },
            child: const Icon(Icons.chat),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'loc_btn',
            onPressed: _determinePosition,
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
}
