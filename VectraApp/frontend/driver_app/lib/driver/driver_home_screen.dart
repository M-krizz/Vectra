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
import 'driver_trip_history_screen.dart';
import 'driver_profile_screen.dart';
import 'driver_help_screen.dart';
import 'driver_active_trip_screen.dart';


/// Driver Home Screen - Main hub for drivers
/// Shows online/offline status, earnings, and incoming ride requests
class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with TickerProviderStateMixin {
  bool _isOnline = false;
  bool _hasIncomingRequest = false;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  List<latlong.LatLng> _previewRoutePoints = [];

  // Mock data
  final double _todayEarnings = 2847.50;
  final int _tripsToday = 12;
  final double _rating = 4.8;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }
  
  Future<void> _fetchPreviewRoute() async {
    try {
      final pickupLatLng = latlong.LatLng(12.9716, 77.5946);
      final dropLatLng = latlong.LatLng(12.9352, 77.6245);
      
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${pickupLatLng.longitude},${pickupLatLng.latitude};'
        '${dropLatLng.longitude},${dropLatLng.latitude}'
        '?overview=full&geometries=geojson'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
        
        setState(() {
          _previewRoutePoints = coordinates.map((coord) {
            return latlong.LatLng(coord[1] as double, coord[0] as double);
          }).toList();
        });
      }
    } catch (e) {
      print('Preview route fetch failed: $e');
    }
  }


  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _toggleOnlineStatus() {
    setState(() {
      _isOnline = !_isOnline;
    });
    
    // Simulate incoming request after going online
    if (_isOnline) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isOnline) {
          setState(() {
            _hasIncomingRequest = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          const ActiveEcoBackground(),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOnlineToggle(),
                        const SizedBox(height: 32),
                        _buildEarningsCard(),
                        const SizedBox(height: 24),
                        _buildStatsGrid(),
                        const SizedBox(height: 24),
                        _buildQuickActions(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Incoming Request Overlay
          if (_hasIncomingRequest) _buildIncomingRequestOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Profile Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.hyperLime, AppColors.neonGreen],
              ),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: const Icon(Icons.person, color: Colors.black, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: GoogleFonts.dmSans(
                    color: AppColors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Driver Name',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Notifications
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_outlined, color: Colors.white),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2);
  }

  Widget _buildOnlineToggle() {
    return GestureDetector(
      onTap: _toggleOnlineStatus,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: _isOnline
              ? const LinearGradient(
                  colors: [AppColors.hyperLime, AppColors.neonGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: _isOnline ? null : AppColors.carbonGrey.withOpacity(0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isOnline ? Colors.transparent : AppColors.white10,
            width: 2,
          ),
          boxShadow: _isOnline
              ? [
                  BoxShadow(
                    color: AppColors.hyperLime.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 0,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isOnline
                        ? Colors.black.withOpacity(0.2)
                        : AppColors.white10,
                    boxShadow: _isOnline
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                  0.3 * _pulseController.value),
                              blurRadius: 20 * _pulseController.value,
                              spreadRadius: 5 * _pulseController.value,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    _isOnline ? Icons.power_settings_new : Icons.power_off,
                    size: 40,
                    color: _isOnline ? Colors.black : AppColors.white70,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              _isOnline ? 'You\'re Online' : 'You\'re Offline',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _isOnline ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isOnline
                  ? 'Ready to accept rides'
                  : 'Tap to go online and start earning',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: _isOnline
                    ? Colors.black.withOpacity(0.7)
                    : AppColors.white70,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildEarningsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.carbonGrey.withOpacity(0.8),
            AppColors.carbonGrey.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  color: AppColors.hyperLime, size: 24),
              const SizedBox(width: 12),
              Text(
                'Today\'s Earnings',
                style: GoogleFonts.dmSans(
                  color: AppColors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '₹${_todayEarnings.toStringAsFixed(2)}',
            style: GoogleFonts.outfit(
              color: AppColors.hyperLime,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_tripsToday trips completed',
            style: GoogleFonts.dmSans(
              color: AppColors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideX(begin: -0.2);
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.star_rounded,
            label: 'Rating',
            value: _rating.toString(),
            color: AppColors.neonGreen,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.eco_outlined,
            label: 'CO₂ Saved',
            value: '24kg',
            color: AppColors.successGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: AppColors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 600.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          icon: Icons.history,
          label: 'Trip History',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DriverTripHistoryScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.account_circle_outlined,
          label: 'My Profile',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DriverProfileScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.help_outline,
          label: 'Help & Support',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DriverHelpScreen()),
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 800.ms, duration: 600.ms);
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.carbonGrey.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.hyperLime, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: AppColors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingRequestOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.carbonGrey.withOpacity(0.95),
                AppColors.voidBlack.withOpacity(0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.hyperLime, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.hyperLime.withOpacity(0.3),
                blurRadius: 40,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing Icon
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.hyperLime.withOpacity(0.2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.hyperLime
                              .withOpacity(0.5 * _glowController.value),
                          blurRadius: 30 * _glowController.value,
                          spreadRadius: 10 * _glowController.value,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      color: AppColors.hyperLime,
                      size: 48,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'New Ride Request!',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Map Preview
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.hyperLime.withOpacity(0.3), width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: latlong.LatLng(12.9534, 77.6100), // Center between pickup and drop
                    initialZoom: 12.5,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none, // Disable interaction in preview
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.vectra.app',
                      // Clear, Google Maps-like appearance
                    ),
                    PolylineLayer(
                      polylines: _previewRoutePoints.isNotEmpty ? [
                        Polyline(
                          points: _previewRoutePoints,
                          color: const Color(0xFF4285F4), // Google Maps blue
                          strokeWidth: 5.0,
                        ),
                      ] : [
                        Polyline(
                          points: [
                            latlong.LatLng(12.9716, 77.5946), // Pickup
                            latlong.LatLng(12.9352, 77.6245), // Drop
                          ],
                          color: const Color(0xFF4285F4),
                          strokeWidth: 4.0,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: latlong.LatLng(12.9716, 77.5946),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: AppColors.hyperLime, size: 40),
                        ),
                        Marker(
                          point: latlong.LatLng(12.9352, 77.6245),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.flag, color: AppColors.errorRed, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildRequestDetail(Icons.location_on, 'Pickup', 'MG Road Metro'),
              const SizedBox(height: 12),
              _buildRequestDetail(Icons.flag, 'Drop', 'Koramangala'),
              const SizedBox(height: 12),
              _buildRequestDetail(Icons.route, 'Distance', '5.2 km'),
              const SizedBox(height: 12),
              _buildRequestDetail(Icons.access_time, 'ETA', '12 mins'),
              const SizedBox(height: 12),
              _buildRequestDetail(Icons.currency_rupee, 'Fare', '₹185'),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _buildResponseButton(
                      label: 'Decline',
                      color: AppColors.errorRed,
                      onTap: () {
                        setState(() {
                          _hasIncomingRequest = false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: _buildResponseButton(
                      label: 'Accept',
                      color: AppColors.hyperLime,
                      onTap: () {
                        setState(() {
                          _hasIncomingRequest = false;
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DriverActiveTripScreen()),
                        );
                      },
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

  Widget _buildRequestDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.hyperLime, size: 20),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: GoogleFonts.dmSans(
            color: AppColors.white70,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildResponseButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
