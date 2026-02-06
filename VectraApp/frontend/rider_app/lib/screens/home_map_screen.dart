import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/rides_api.dart';
import 'chat_screen.dart';

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  GoogleMapController? _mapController;
  final RidesApi _ridesApi = RidesApi();
  
  // Default to Bangalore
  static const CameraPosition _kDefaultPosition = CameraPosition(
    target: LatLng(12.9716, 77.5946),
    zoom: 14.4746,
  );

  LatLng? _pickupLocation;
  LatLng? _dropLocation;
  final Set<Marker> _markers = {};
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
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

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
    );
    
    setState(() {
      _pickupLocation = LatLng(position.latitude, position.longitude);
      _updateMarkers();
    });
  }

  void _updateMarkers() {
    _markers.clear();
    if (_pickupLocation != null) {
      _markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Pickup Point'),
      ));
    }
    if (_dropLocation != null) {
      _markers.add(Marker(
        markerId: const MarkerId('drop'),
        position: _dropLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Drop Point'),
      ));
    }
  }

  void _onMapTap(LatLng pos) {
    setState(() {
      if (_pickupLocation == null) {
        _pickupLocation = pos;
      } else if (_dropLocation == null) {
        _dropLocation = pos;
      } else {
        // Reset drop if tapping again
        _dropLocation = pos;
      }
      _updateMarkers();
    });
  }

  Future<void> _requestRide() async {
    if (_pickupLocation == null || _dropLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Pickup and Drop locations')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _ridesApi.createRideRequest(
        pickupLat: _pickupLocation!.latitude,
        pickupLng: _pickupLocation!.longitude,
        dropLat: _dropLocation!.latitude,
        dropLng: _dropLocation!.longitude,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride Requested Successfully! Finding drivers...')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _kDefaultPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            onTap: _onMapTap,
          ),
          if (_pickupLocation != null && _dropLocation != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _requestRide,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('REQUEST RIDE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'chat_btn',
              child: const Icon(Icons.chat),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChatScreen(
                      tripId: 'test-trip-123',
                      userId: 'rider-1',
                    ),
                  ),
                );
              },
            ),
          ),
           Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text(_pickupLocation != null ? "Pickup Set" : "Tap map to set Pickup"),
                    const Divider(),
                    Text(_dropLocation != null ? "Drop Set" : "Tap map to set Drop"),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
