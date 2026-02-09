import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../theme/app_colors.dart';
import 'driver_active_trip_screen.dart';

class DriverRequestListScreen extends StatefulWidget {
  const DriverRequestListScreen({super.key});

  @override
  State<DriverRequestListScreen> createState() => _DriverRequestListScreenState();
}

class _DriverRequestListScreenState extends State<DriverRequestListScreen> {
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  
  // Mock current location (Bangalore)
  final latlong.LatLng _currentLocation = latlong.LatLng(12.9716, 77.5946);
  
  // Mock ride requests
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _loadRequests();
      }
    });
  }

  void _loadRequests() {
    setState(() => _isRefreshing = true);
    
    // Simulate API call
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      setState(() {
        _requests = _generateMockRequests();
        _isRefreshing = false;
      });
    });
  }

  List<Map<String, dynamic>> _generateMockRequests() {
    final mockData = [
      {
        'id': '1',
        'riderName': 'Priya Sharma',
        'rating': 4.9,
        'pickup': 'MG Road Metro Station',
        'pickupLat': 12.9716,
        'pickupLng': 77.5946,
        'drop': 'Koramangala 5th Block',
        'dropLat': 12.9352,
        'dropLng': 77.6245,
        'distance': 4.2,
        'fare': 120.0,
        'vehicleType': 'Sedan',
        'timeAgo': '2 min ago',
      },
      {
        'id': '2',
        'riderName': 'Amit Kumar',
        'rating': 4.7,
        'pickup': 'Indiranagar 100 Feet Road',
        'pickupLat': 12.9784,
        'pickupLng': 77.6408,
        'drop': 'Whitefield ITPL',
        'dropLat': 12.9698,
        'dropLng': 77.7499,
        'distance': 8.5,
        'fare': 210.0,
        'vehicleType': 'Sedan',
        'timeAgo': '5 min ago',
      },
      {
        'id': '3',
        'riderName': 'Sneha Reddy',
        'rating': 5.0,
        'pickup': 'HSR Layout',
        'pickupLat': 12.9121,
        'pickupLng': 77.6446,
        'drop': 'Electronic City',
        'dropLat': 12.8456,
        'dropLng': 77.6603,
        'distance': 6.8,
        'fare': 165.0,
        'vehicleType': 'Sedan',
        'timeAgo': '8 min ago',
      },
      {
        'id': '4',
        'riderName': 'Rahul Verma',
        'rating': 4.6,
        'pickup': 'Jayanagar 4th Block',
        'pickupLat': 12.9250,
        'pickupLng': 77.5838,
        'drop': 'Malleshwaram',
        'dropLat': 13.0067,
        'dropLng': 77.5703,
        'distance': 5.3,
        'fare': 145.0,
        'vehicleType': 'Sedan',
        'timeAgo': '12 min ago',
      },
    ];
    
    // Randomly show 2-4 requests
    mockData.shuffle();
    return mockData.take(2 + (DateTime.now().second % 3)).toList();
  }

  double _calculateDistanceFromDriver(double lat, double lng) {
    return const latlong.Distance().as(
      latlong.LengthUnit.Kilometer,
      _currentLocation,
      latlong.LatLng(lat, lng),
    );
  }

  void _handleAcceptRequest(Map<String, dynamic> request) {
    // Remove from list
    setState(() {
      _requests.removeWhere((r) => r['id'] == request['id']);
    });
    
    // Navigate to active trip
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DriverActiveTripScreen(
          pickupLatLng: latlong.LatLng(request['pickupLat'], request['pickupLng']),
          dropLatLng: latlong.LatLng(request['dropLat'], request['dropLng']),
          pickupAddress: request['pickup'],
          dropAddress: request['drop'],
          riderName: request['riderName'],
          fare: request['fare'],
        ),
      ),
    );
  }

  void _handleDeclineRequest(Map<String, dynamic> request) {
    setState(() {
      _requests.removeWhere((r) => r['id'] == request['id']);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request from ${request['riderName']} declined'),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_requests.isEmpty)
              _buildEmptyState()
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _loadRequests();
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  color: AppColors.hyperLime,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      return _buildRequestCard(_requests[index], index);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(color: AppColors.white10),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.white10,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nearby Requests',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_requests.length} available',
                  style: GoogleFonts.dmSans(
                    color: AppColors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (_isRefreshing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.hyperLime,
              ),
            )
          else
            IconButton(
              onPressed: _loadRequests,
              icon: const Icon(Icons.refresh, color: AppColors.hyperLime),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.hyperLime.withOpacity(0.2),
                padding: const EdgeInsets.all(12),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white10,
              ),
              child: const Icon(
                Icons.search_off,
                color: AppColors.white30,
                size: 60,
              ),
            ).animate(onPlay: (controller) => controller.repeat())
                .fadeIn(duration: 1000.ms)
                .then()
                .fadeOut(duration: 1000.ms),
            const SizedBox(height: 24),
            Text(
              'No requests nearby',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Checking for new requests...',
              style: GoogleFonts.dmSans(
                color: AppColors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, int index) {
    final distanceFromDriver = _calculateDistanceFromDriver(
      request['pickupLat'],
      request['pickupLng'],
    );
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.carbonGrey,
            AppColors.carbonGrey.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.hyperLime.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.hyperLime, AppColors.neonGreen],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      request['riderName'].split(' ').map((e) => e[0]).join(),
                      style: GoogleFonts.outfit(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['riderName'],
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.hyperLime, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${request['rating']}',
                            style: GoogleFonts.dmSans(
                              color: AppColors.hyperLime,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            request['timeAgo'],
                            style: GoogleFonts.dmSans(
                              color: AppColors.white50,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.hyperLime.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.hyperLime),
                  ),
                  child: Text(
                    '₹${request['fare'].toStringAsFixed(0)}',
                    style: GoogleFonts.dmSans(
                      color: AppColors.hyperLime,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Route info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.hyperLime.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: AppColors.hyperLime,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pickup',
                            style: GoogleFonts.dmSans(
                              color: AppColors.white50,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            request['pickup'],
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${distanceFromDriver.toStringAsFixed(1)} km away',
                      style: GoogleFonts.dmSans(
                        color: AppColors.skyBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(width: 16),
                    Container(
                      width: 2,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.hyperLime,
                            AppColors.errorRed,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.errorRed,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Drop',
                            style: GoogleFonts.dmSans(
                              color: AppColors.white50,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            request['drop'],
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${request['distance']} km',
                      style: GoogleFonts.dmSans(
                        color: AppColors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.deepBlack.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _handleDeclineRequest(request),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.errorRed),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.close, color: AppColors.errorRed, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Decline',
                            style: GoogleFonts.dmSans(
                              color: AppColors.errorRed,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () => _handleAcceptRequest(request),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.hyperLime, AppColors.neonGreen],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.hyperLime.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.black, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Accept Request',
                            style: GoogleFonts.dmSans(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms, duration: 400.ms).slideX(begin: 0.2);
  }
}
