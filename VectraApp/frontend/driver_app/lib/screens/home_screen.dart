import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/app_colors.dart';
import '../../models/signup_data.dart';
import '../../models/ride_request.dart';
import 'profile_screen.dart';
import '../utils/notification_overlay.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final SignUpData? signUpData;

  const HomeScreen({super.key, required this.userName, this.signUpData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isOnline = false;
  RideStatus _rideStatus = RideStatus.idle;
  RideRequest? _currentRide;
  Timer? _searchTimer;
  Timer? _requestTimer;
  double _requestProgress = 1.0;
  int _requestCounter = 0; // For toggling ride types

  // Map Controller
  final MapController _mapController = MapController();

  // Dummy Location Data (Bangalore coordinates for demo)
  final LatLng _currentLocation = const LatLng(12.9716, 77.5946);

  // Analytics State
  double _totalEarnings = 0.0;
  int _totalRides = 0;
  final List<RideRequest> _completedRides = [];

  @override
  void dispose() {
    _searchTimer?.cancel();
    _requestTimer?.cancel();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  void _toggleOnlineStatus() {
    setState(() {
      _isOnline = !_isOnline;
      if (_isOnline) {
        _rideStatus = RideStatus.searching;
        _startSearching();
      } else {
        _rideStatus = RideStatus.idle;
        _searchTimer?.cancel();
        _requestTimer?.cancel();
        NotificationOverlay.hide();
        _currentRide = null;
      }
    });
  }

  void _startSearching() {
    if (!_isOnline) return;

    // Simulate finding a ride after 5 seconds
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _isOnline && _rideStatus == RideStatus.searching) {
        _handleNewRequest();
      }
    });
  }

  void _handleNewRequest() {
    // Generate dummy request
    final random = Random();
    final request = RideRequest(
      id: 'RIDE-${random.nextInt(10000)}',
      passengerName: 'Passenger ${random.nextInt(100)}',
      passengerRating: '4.${random.nextInt(9)}',
      pickupLocation: const LatLng(
        12.9716,
        77.5946,
      ), // Current location roughly
      pickupAddress: 'MG Road, Bangalore',
      dropLocation: const LatLng(12.9352, 77.6245), // Koramangala
      dropAddress: 'Koramangala 5th Block',
      fare: 150.0 + random.nextInt(100),
      otp: '${random.nextInt(9000) + 1000}', // 4 digit OTP
      distance: 4.5,
      duration: '25 min',
      isPooling: (_requestCounter++ % 2 != 0), // Alternate
    );

    setState(() {
      _rideStatus = RideStatus.requestReceived;
      _currentRide = request;
      _requestProgress = 1.0;
    });

    _showRequestBottomSheet(request);
  }

  void _showRequestBottomSheet(RideRequest request) {
    // 30 Seconds Timer
    int timeLeft = 30;
    _requestTimer?.cancel();
    _requestTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        timeLeft--;
        _requestProgress = timeLeft / 30.0;
      });

      if (timeLeft <= 0) {
        timer.cancel();
        NotificationOverlay.hide();
        _rejectRide();
      }
    });

    NotificationOverlay.show(
      context,
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: AppColors.grey.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NEW RIDE REQUEST',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.passengerName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (request.isPooling)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.group, size: 14, color: Colors.purple),
                        SizedBox(width: 4),
                        Text(
                          'Pooling',
                          style: TextStyle(
                            color: Colors.purple,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person, size: 14, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Normal',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    size: 14,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    request.pickupAddress,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    size: 14,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    request.dropAddress,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Progress Bar
            Stack(
              children: [
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(seconds: 1),
                  height: 4,
                  width:
                      (MediaQuery.of(context).size.width - 64) *
                      _requestProgress,
                  decoration: BoxDecoration(
                    color: _requestProgress > 0.3
                        ? AppColors.primary
                        : AppColors.error,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _requestTimer?.cancel();
                      NotificationOverlay.hide();
                      _rejectRide();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.error),
                      foregroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _requestTimer?.cancel();
                      NotificationOverlay.hide();
                      _acceptRide();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _acceptRide() {
    _requestTimer?.cancel();
    setState(() {
      _rideStatus = RideStatus.goingToPickup;
    });
  }

  void _rejectRide() {
    _requestTimer?.cancel();
    setState(() {
      _rideStatus = RideStatus.searching;
      _currentRide = null;
    });
    _startSearching(); // Search for next
  }

  void _arrivedAtPickup() {
    setState(() {
      _rideStatus = RideStatus.arrivedAtPickup;
    });
    _showOTPDialog();
  }

  void _showOTPDialog() {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ask ${_currentRide?.passengerName} for the OTP to start the ride.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                hintText: 'Enter 4-digit OTP',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (otpController.text.isNotEmpty) {
                Navigator.pop(context);
                _startRide();
              } else {
                NotificationOverlay.showMessage(
                  context,
                  'Please enter OTP',
                  backgroundColor: AppColors.error,
                );
              }
            },
            child: const Text('Start Ride'),
          ),
        ],
      ),
    );
  }

  void _startRide() {
    setState(() {
      _rideStatus = RideStatus.inProgress;
    });
  }

  void _completeRide() {
    setState(() {
      _rideStatus = RideStatus.completed;
      if (_currentRide != null) {
        _totalEarnings += _currentRide!.fare;
        _totalRides += 1;
        _completedRides.insert(0, _currentRide!);
      }
    });

    // Show Summary
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Ride Completed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 64),
            const SizedBox(height: 16),
            Text(
              'You earned ₹${_currentRide?.fare.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _rideStatus = RideStatus.searching; // Back to online
                _currentRide = null;
              });
              _startSearching();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If in ride flow (not idle/searching/request), show Map
    if (_rideStatus == RideStatus.goingToPickup ||
        _rideStatus == RideStatus.arrivedAtPickup ||
        _rideStatus == RideStatus.inProgress) {
      return _buildRideMapScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _selectedIndex == 0 ? _buildHomeBody() : _buildProfileBody(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildRideMapScreen() {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.driver_app',
              ),
              MarkerLayer(
                markers: [
                  // Pickup Marker
                  Marker(
                    point: _currentRide!.pickupLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.green,
                      size: 40,
                    ),
                  ),
                  // Drop Marker (Only show if in progress or map view shows both)
                  Marker(
                    point: _currentRide!.dropLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                  // Driver (Current) Marker - Simulated
                  Marker(
                    point: _currentLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.directions_car,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Bottom Status Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_rideStatus == RideStatus.goingToPickup) ...[
                    const Text(
                      'Picking up',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    Text(
                      _currentRide!.passengerName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentRide!.pickupAddress,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _arrivedAtPickup,
                        child: const Text('Arrived at Location'),
                      ),
                    ),
                  ] else if (_rideStatus == RideStatus.arrivedAtPickup) ...[
                    const Text(
                      'Waiting for passenger...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ask passenger for OTP',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _showOTPDialog,
                        child: const Text('Enter OTP'),
                      ),
                    ),
                  ] else if (_rideStatus == RideStatus.inProgress) ...[
                    const Text(
                      'Heading to Destination',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentRide!.dropAddress,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _completeRide,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: const Text('End Ride'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          InkWell(
            onTap: () => setState(() => _selectedIndex = 0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.home,
                    color: _selectedIndex == 0
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Home',
                    style: TextStyle(
                      color: _selectedIndex == 0
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Online/Offline Button (Center)
          GestureDetector(
            onTap: _toggleOnlineStatus,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color:
                    _rideStatus != RideStatus.idle &&
                        _rideStatus != RideStatus.searching
                    ? AppColors
                          .grey // Disable if in ride
                    : (_isOnline ? AppColors.success : AppColors.grey),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: (_isOnline ? AppColors.success : AppColors.grey)
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_rideStatus == RideStatus.searching)
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  Icon(
                    Icons.power_settings_new,
                    color: _isOnline ? Colors.white : AppColors.textPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isOnline
                        ? (_rideStatus == RideStatus.searching
                              ? 'SEARCHING'
                              : 'ONLINE')
                        : 'OFFLINE',
                    style: TextStyle(
                      color: _isOnline ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          InkWell(
            onTap: () => setState(() => _selectedIndex = 1),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person,
                    color: _selectedIndex == 1
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Profile',
                    style: TextStyle(
                      color: _selectedIndex == 1
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeBody() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, size: 28),
                      onPressed: () {},
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Status Message based on Online State
            if (!_isOnline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'You are currently Offline. Go Online to start receiving rides.',
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 24),

            // Analytics
            const Text(
              'Today\'s Analytics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildAnalyticsCard(
                  'Earnings',
                  '₹${_totalEarnings.toStringAsFixed(0)}',
                  Icons.account_balance_wallet,
                  AppColors.primary,
                ),
                const SizedBox(width: 16),
                _buildAnalyticsCard(
                  'Rides',
                  '$_totalRides',
                  Icons.directions_car,
                  AppColors.warning,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Ride History
            const Text(
              'Recent Rides',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            if (_completedRides.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No recent rides',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _completedRides.length,
                itemBuilder: (context, index) {
                  return _buildRideHistoryItem(_completedRides[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideHistoryItem(RideRequest ride) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.grey.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trip to ${ride.dropAddress}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Completed just now', // Timestamp could be added to RideRequest
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${ride.fare.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Completed',
                style: TextStyle(fontSize: 12, color: AppColors.success),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileBody() {
    return ProfileScreen(
      userName: widget.userName,
      signUpData: widget.signUpData,
    );
  }
}
