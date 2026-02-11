import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:http/http.dart' as http;
import '../theme/app_colors.dart';
import '../shared/widgets/active_eco_background.dart';
import 'driver_incident_report_screen.dart';
import '../shared/widgets/otp_input.dart';


/// Active Trip Screen for Driver
/// Shows live navigation, trip details, and controls
class DriverActiveTripScreen extends StatefulWidget {
  const DriverActiveTripScreen({super.key});

  @override
  State<DriverActiveTripScreen> createState() => _DriverActiveTripScreenState();
}

class _DriverActiveTripScreenState extends State<DriverActiveTripScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  final MapController _mapController = MapController();
  
  String _tripStatus = 'going_to_pickup'; // going_to_pickup, waiting_for_rider, in_progress, completed
  bool _showOtpDialog = false;
  String _enteredOtp = '';
  
  // Mock trip data
  final String _riderName = 'Priya Sharma';
  final String _pickupLocation = 'MG Road Metro Station';
  final String _dropLocation = 'Koramangala 5th Block';
  final double _distance = 5.2;
  final double _estimatedFare = 185.0;
  final String _tripOtp = '4729';
  
  // Map coordinates (Bangalore)
  final latlong.LatLng _pickupLatLng = latlong.LatLng(12.9716, 77.5946); // MG Road
  final latlong.LatLng _dropLatLng = latlong.LatLng(12.9352, 77.6245); // Koramangala
  latlong.LatLng _currentLocation = latlong.LatLng(12.9500, 77.6100); // Current position (mutable)
  
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _setupMapMarkers();
  }
  
  void _setupMapMarkers() {
    _markers = [
      // Current location marker
      Marker(
        point: _currentLocation,
        width: 60,
        height: 60,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0xFF4285F4), width: 4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4285F4).withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.navigation,
            color: Color(0xFF4285F4),
            size: 28,
          ),
        ),
      ),
      // Pickup marker
      Marker(
        point: _pickupLatLng,
        width: 80,
        height: 80,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.hyperLime,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Pickup',
                style: GoogleFonts.dmSans(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(Icons.location_on, color: AppColors.hyperLime, size: 32),
          ],
        ),
      ),
      // Drop marker
      Marker(
        point: _dropLatLng,
        width: 80,
        height: 80,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.errorRed,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Drop',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(Icons.flag, color: AppColors.errorRed, size: 32),
          ],
        ),
      ),
    ];
    
    // Fetch real route from OSRM
    _fetchRoute();
  }
  
  Future<void> _fetchRoute() async {
    try {
      // Determine route based on trip status
      latlong.LatLng startPoint;
      latlong.LatLng endPoint;
      
      if (_tripStatus == 'going_to_pickup' || _tripStatus == 'waiting_for_rider') {
        // Route from current location to pickup (stay focused on pickup until rider boards)
        startPoint = _currentLocation;
        endPoint = _pickupLatLng;
      } else {
        // Route from current location to drop (during trip)
        startPoint = _currentLocation;
        endPoint = _dropLatLng;
      }
      
      // OSRM API endpoint (free public server)
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${startPoint.longitude},${startPoint.latitude};'
        '${endPoint.longitude},${endPoint.latitude}'
        '?overview=full&geometries=geojson&steps=true'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
        
        // Convert coordinates to LatLng
        List<latlong.LatLng> routePoints = coordinates.map((coord) {
          return latlong.LatLng(coord[1] as double, coord[0] as double);
        }).toList();
        
        setState(() {
          _polylines = [
            // Background/border line (darker, thicker)
            Polyline(
              points: routePoints,
              color: const Color(0xFF1967D2), // Google Maps blue
              strokeWidth: 8.0,
            ),
            // Main route line (brighter, on top)
            Polyline(
              points: routePoints,
              color: const Color(0xFF4285F4), // Bright Google Maps blue
              strokeWidth: 6.0,
            ),
          ];
        });
        
        // Zoom in and center on current location for turn-by-turn navigation
        if (_tripStatus == 'going_to_pickup' || _tripStatus == 'in_progress') {
          _mapController.move(_currentLocation, 16.0); // Zoomed in view
        } else {
          // Center map on the route
          _mapController.move(
            latlong.LatLng(
              (startPoint.latitude + endPoint.latitude) / 2,
              (startPoint.longitude + endPoint.longitude) / 2,
            ),
            13.0,
          );
        }
      }
    } catch (e) {
      // Fallback to simple route if API fails
      print('Route fetch failed: $e');
      latlong.LatLng startPoint = _currentLocation;
      latlong.LatLng endPoint = (_tripStatus == 'going_to_pickup' || _tripStatus == 'waiting_for_rider') 
          ? _pickupLatLng 
          : _dropLatLng;
      
      setState(() {
        _polylines = [
          Polyline(
            points: [startPoint, endPoint],
            color: const Color(0xFF4285F4),
            strokeWidth: 6.0,
          ),
        ];
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleStartTrip() {
    setState(() {
      _showOtpDialog = true;
    });
  }

  void _verifyOtp() {
    // Bypass OTP - accept any OTP
    setState(() {
      _showOtpDialog = false;
      _tripStatus = 'in_progress';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trip started! OTP verified'),
        backgroundColor: AppColors.hyperLime,
      ),
    );
  }

  void _handleEndTrip() {
    // Move driver to drop location
    setState(() {
      _currentLocation = _dropLatLng;
      _tripStatus = 'completed';
    });
    
    // Refresh route to show driver at destination
    _fetchRoute();
    
    // Show completion dialog
    Future.delayed(const Duration(milliseconds: 500), () {
      _showTripCompletedDialog();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map Background (Mock)
          _buildMapView(),
          
          // Top Info Card
          SafeArea(
            child: Column(
              children: [
                _buildTopInfoCard(),
                const Spacer(),
                _buildBottomSheet(),
              ],
            ),
          ),

          // OTP Dialog
          if (_showOtpDialog) _buildOtpDialog(),

          // SOS Button
          _buildSosButton(),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: latlong.LatLng(12.9534, 77.6100), // Center of route
            initialZoom: 13.5,
            minZoom: 11,
            maxZoom: 18,
            initialRotation: 0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.vectra.app',
              // Removed dark filter for clearer, Google Maps-like appearance
            ),
            PolylineLayer(
              polylines: _polylines,
            ),
            MarkerLayer(
              markers: _markers,
            ),
            // Current location marker during trip
            if (_tripStatus == 'in_progress')
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 60,
                    height: 60,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: AppColors.hyperLime, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.hyperLime.withOpacity(0.5 * _pulseController.value),
                                blurRadius: 20 * _pulseController.value,
                                spreadRadius: 5 * _pulseController.value,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.navigation,
                            color: AppColors.hyperLime,
                            size: 28,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
        // Zoom controls
        Positioned(
          right: 16,
          bottom: 120,
          child: Column(
            children: [
              _buildMapControl(Icons.add, () {
                _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
              }),
              const SizedBox(height: 8),
              _buildMapControl(Icons.remove, () {
                _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
              }),
              const SizedBox(height: 8),
              _buildMapControl(Icons.my_location, () {
                _mapController.move(_currentLocation, 15);
              }),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildMapControl(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black87, size: 24),
      ),
    );
  }

  Widget _buildTopInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.carbonGrey.withOpacity(0.95),
            AppColors.voidBlack.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.hyperLime, AppColors.neonGreen],
                  ),
                ),
                child: const Icon(Icons.person, color: Colors.black, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _riderName,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.neonGreen, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '4.9',
                          style: GoogleFonts.dmSans(
                            color: AppColors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  // Call rider
                },
                icon: const Icon(Icons.phone, color: AppColors.hyperLime),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.white10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.white10),
          const SizedBox(height: 16),
          _buildTripDetail(Icons.my_location, 'Pickup', _pickupLocation),
          const SizedBox(height: 12),
          _buildTripDetail(Icons.location_on, 'Drop', _dropLocation),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3);
  }

  Widget _buildTripDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.hyperLime, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: AppColors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppColors.voidBlack.withOpacity(0.9),
            AppColors.voidBlack,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.route,
                label: '${_distance} km',
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                icon: Icons.access_time,
                label: '12 mins',
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                icon: Icons.currency_rupee,
                label: '₹${_estimatedFare.toStringAsFixed(0)}',
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildActionButton(),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.3);
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.white20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.hyperLime, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    String buttonText;
    VoidCallback onTap;
    Color buttonColor = AppColors.hyperLime;
    
    switch (_tripStatus) {
      case 'going_to_pickup':
        buttonText = 'Start Navigation to Pickup';
        buttonColor = const Color(0xFF4285F4); // Google Maps blue
        onTap = () {
          // Fetch route from current location to pickup
          _fetchRoute();
          
          // Start navigation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.navigation, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text('Navigation started! Heading to pickup...'),
                ],
              ),
              backgroundColor: const Color(0xFF4285F4),
              duration: const Duration(seconds: 2),
            ),
          );
          // Move driver to pickup location and change status
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _currentLocation = _pickupLatLng; // Move driver to pickup
                _tripStatus = 'waiting_for_rider';
              });
              _fetchRoute(); // Refresh route
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Arrived at pickup! Waiting for rider...'),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          });
        };
        break;
      case 'waiting_for_rider':
        buttonText = 'Start Trip (Rider Onboard)';
        buttonColor = AppColors.hyperLime;
        onTap = () {
          setState(() {
            _tripStatus = 'in_progress';
          });
          // Fetch new route from current location to drop
          _fetchRoute();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.directions_car, color: Colors.black),
                  SizedBox(width: 12),
                  Text('Trip started! Navigate to destination'),
                ],
              ),
              backgroundColor: AppColors.hyperLime,
              duration: Duration(seconds: 2),
            ),
          );
        };
        break;
      case 'in_progress':
        buttonText = 'End Trip';
        onTap = _handleEndTrip;
        break;
      default:
        buttonText = 'Continue';
        onTap = () {};
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: buttonColor == const Color(0xFF4285F4)
                ? [const Color(0xFF4285F4), const Color(0xFF1967D2)]
                : [AppColors.hyperLime, AppColors.neonGreen],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: buttonColor.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_tripStatus == 'going_to_pickup')
              const Icon(Icons.navigation, color: Colors.white, size: 20),
            if (_tripStatus == 'going_to_pickup')
              const SizedBox(width: 8),
            if (_tripStatus == 'waiting_for_rider')
              const Icon(Icons.person_add, color: Colors.black, size: 20),
            if (_tripStatus == 'waiting_for_rider')
              const SizedBox(width: 8),
            Text(
              buttonText,
              style: GoogleFonts.dmSans(
                color: buttonColor == const Color(0xFF4285F4) ? Colors.white : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpDialog() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.carbonGrey.withOpacity(0.95),
                AppColors.voidBlack.withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.hyperLime, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, color: AppColors.hyperLime, size: 48),
              const SizedBox(height: 20),
              Text(
                'Enter Trip OTP',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ask the rider for the 4-digit OTP',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: AppColors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              OtpInput(
                length: 4,
                onCompleted: (otp) {
                  setState(() {
                    _enteredOtp = otp;
                  });
                },
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showOtpDialog = false;
                          _enteredOtp = '';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.white10,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.white20),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _verifyOtp,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.hyperLime, AppColors.neonGreen],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Verify & Start',
                            style: GoogleFonts.dmSans(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSosButton() {
    return Positioned(
      right: 20,
      top: MediaQuery.of(context).size.height * 0.5,
      child: GestureDetector(
        onTap: () {
          // Handle SOS
          _showSosDialog();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.errorRed,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.errorRed.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.emergency, color: Colors.white, size: 28),
        ),
      ).animate(onPlay: (c) => c.repeat()).scale(
        begin: const Offset(1, 1),
        end: const Offset(1.1, 1.1),
        duration: 1000.ms,
      ),
    );
  }

  void _showSosDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.voidBlack.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.errorRed, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 64),
              const SizedBox(height: 20),
              Text(
                'Emergency SOS',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This will alert our support team and emergency contacts immediately.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: AppColors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to incident report
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DriverIncidentReportScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Activate SOS',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.dmSans(color: AppColors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTripCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.carbonGrey.withOpacity(0.95),
                AppColors.voidBlack.withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.hyperLime, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.hyperLime,
                ),
                child: const Icon(Icons.check, color: Colors.black, size: 48),
              ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
              const SizedBox(height: 24),
              Text(
                'Trip Completed!',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildFareDetail('Distance', '${_distance} km'),
              const SizedBox(height: 12),
              _buildFareDetail('Duration', '18 mins'),
              const SizedBox(height: 12),
              Divider(color: AppColors.white10),
              const SizedBox(height: 12),
              _buildFareDetail('Total Fare', '₹${_estimatedFare.toStringAsFixed(2)}', isTotal: true),
              const SizedBox(height: 12),
              _buildFareDetail('CO₂ Saved', '2.4 kg', isEco: true),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.hyperLime, AppColors.neonGreen],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Done',
                      style: GoogleFonts.dmSans(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ).animate().scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
      ),
    );
  }

  Widget _buildFareDetail(String label, String value, {bool isTotal = false, bool isEco = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: isTotal || isEco ? Colors.white : AppColors.white70,
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: isEco ? AppColors.successGreen : (isTotal ? AppColors.hyperLime : Colors.white),
            fontSize: isTotal ? 24 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _RouteLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.hyperLime
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.3, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.4,
      size.width * 0.75,
      size.height * 0.6,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
