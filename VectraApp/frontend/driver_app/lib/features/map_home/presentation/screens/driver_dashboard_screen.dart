import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';
import '../../../driver_status/presentation/providers/driver_status_providers.dart';
import '../../../driver_status/presentation/widgets/online_toggle.dart';
import '../../../rides/presentation/providers/ride_request_providers.dart';
import '../../../rides/presentation/widgets/ride_request_modal.dart';
import '../../../wallet/presentation/screens/wallet_screen.dart';
import '../../../incentives/presentation/screens/incentives_screen.dart';
import '../../../rides/data/models/ride_request.dart';
import '../../../../core/socket/socket_service.dart';
import 'dart:async';
import '../widgets/driver_map.dart';
import '../widgets/earnings_card.dart';
import '../widgets/goto_button.dart';
import '../../../rides/presentation/screens/active_trip_screen.dart';

/// Main driver dashboard screen with map and controls
class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  ConsumerState<DriverDashboardScreen> createState() =>
      _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen> {
  bool _showFullDashboard = true;
  StreamSubscription? _rideOfferSubscription;
  StreamSubscription? _rideUpdateSubscription;
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    // Defer socket setup until after build to safely access ref
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupSocketListeners();
    });
  }

  void _setupSocketListeners() {
    final socketService = ref.read(socketServiceProvider);
    
    _rideOfferSubscription = socketService.rideOfferStream.listen((data) {
      if (mounted) {
        // Need to import RideRequest
        ref.read(rideRequestProvider.notifier).setRideRequest(RideRequest.fromJson(data));
      }
    });

    _rideUpdateSubscription = socketService.rideUpdateStream.listen((data) {
      // Handle updates if needed
    });
    
    // Ensure we are connected/simulating
    socketService.connect();
  }

  @override
  void dispose() {
    _rideOfferSubscription?.cancel();
    _rideUpdateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driverStatus = ref.watch(driverStatusProvider);
    final rideRequestState = ref.watch(rideRequestProvider);
    final activeTripState = ref.watch(activeTripProvider);

    // If there is an active trip, show the ActiveTripScreen
    if (activeTripState.hasActiveTrip) {
      return const ActiveTripScreen();
    }

    return Scaffold(
      body: Stack(
        children: [
          // Map background
          const DriverMap(showHeatmap: true),

          // Top bar
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(driverStatus),
                const Spacer(),
                if (_showFullDashboard) _buildBottomSheet(driverStatus),
              ],
            ),
          ),

          // Go To button
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 80,
            child: const GotoButton(),
          ),

          // Ride request modal
          if (rideRequestState.hasActiveRequest)
            RideRequestModal(
              request: rideRequestState.currentRequest!,
              onAccept: () async {
                await ref.read(rideRequestProvider.notifier).acceptCurrentRequest();
                // Refresh active trip provider to pick up the new trip
                ref.invalidate(activeTripProvider);
              },
              onReject: () {
                ref.read(rideRequestProvider.notifier).rejectCurrentRequest();
              },
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTopBar(DriverStatusState driverStatus) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile
          GestureDetector(
            onTap: () {
              // Navigate to profile
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.hyperLime, AppColors.neonGreen],
                ),
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: const Icon(Icons.person, color: Colors.black, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          // Name and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverStatus.profile?.name ?? 'Driver',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: driverStatus.isOnline
                            ? AppColors.successGreen
                            : AppColors.white50,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      driverStatus.isOnline ? 'Online' : 'Offline',
                      style: GoogleFonts.dmSans(
                        color: AppColors.white70,
                        fontSize: 12,
                      ),
                    ),
                    if (driverStatus.profile != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.star,
                        color: AppColors.neonGreen,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${driverStatus.profile!.rating}',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Notifications
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  // Show notifications
                },
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.white10,
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.errorRed,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2);
  }

  Widget _buildBottomSheet(DriverStatusState driverStatus) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Earnings card
          const EarningsCard(),
          const SizedBox(height: 16),
          // Online toggle
          const OnlineToggle(),
          const SizedBox(height: 16),
          // Quick actions
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickAction(
            icon: Icons.history,
            label: 'History',
            onTap: () {
              // Navigate to trip history
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickAction(
            icon: Icons.account_balance_wallet,
            label: 'Wallet',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WalletScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickAction(
            icon: Icons.emoji_events,
            label: 'Rewards',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IncentivesScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickAction(
            icon: Icons.help_outline,
            label: 'Help',
            onTap: () {
              // Navigate to help
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms, duration: 600.ms);
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.carbonGrey.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.hyperLime, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.voidBlack,
        border: Border(
          top: BorderSide(color: AppColors.white10),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_filled, 'Home'),
              _buildNavItem(1, Icons.directions_car, 'Trips'),
              _buildNavItem(2, Icons.account_balance_wallet, 'Wallet'),
              _buildNavItem(3, Icons.person_outline, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedNavIndex = index);
        _handleNavigation(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.hyperLime.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.hyperLime : AppColors.white50,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: isSelected ? AppColors.hyperLime : AppColors.white50,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        // Navigate to trips/history
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WalletScreen()),
        );
        break;
      case 3:
        // Navigate to profile
        break;
    }
  }
}
