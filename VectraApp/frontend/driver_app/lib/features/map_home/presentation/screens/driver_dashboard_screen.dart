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
import '../../../rate_card/presentation/screens/rate_card_screen.dart';
import '../../../rides/data/models/ride_request.dart';
import '../../../../core/socket/socket_service.dart';
import '../../../profile/presentation/screens/document_upload_screen.dart';
import 'dart:async';
import '../widgets/driver_map.dart';
import '../widgets/earnings_card.dart';
import '../../../rides/presentation/screens/active_trip_screen.dart';

/// Main driver dashboard screen with premium Rapido-like UI
class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  ConsumerState<DriverDashboardScreen> createState() =>
      _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen> {
  StreamSubscription? _rideOfferSubscription;
  StreamSubscription? _rideUpdateSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupSocketListeners();
    });
  }

  void _setupSocketListeners() {
    final socketService = ref.read(socketServiceProvider);
    
    _rideOfferSubscription = socketService.rideOfferStream.listen((data) {
      if (mounted) {
        ref.read(rideRequestProvider.notifier).setRideRequest(RideRequest.fromJson(data));
      }
    });

    _rideUpdateSubscription = socketService.rideUpdateStream.listen((data) {
      // Handle updates
    });
    
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

    if (activeTripState.hasActiveTrip) {
      return const ActiveTripScreen();
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(), // Placeholder for now
      body: Stack(
        children: [
          // 1. Map Background
          const DriverMap(showHeatmap: true),

          // 2. Top Area (Menu, Earnings)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 8),
                  // Earnings Strip
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: EarningsCard(onTap: () {
                         Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WalletScreen()),
                        );
                    }),
                  ),
                ],
              ),
            ),
          ),

          // 3. Bottom Area (Filters, Toggle)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                    Colors.black,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Filter Pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterPill(Icons.bolt, 'Surge Area', isActive: false),
                          const SizedBox(width: 12),
                          _buildFilterPill(Icons.trending_up, 'High Demand', isActive: true),
                          const SizedBox(width: 12),
                          _buildFilterPill(Icons.near_me, 'Go To Area', isActive: false, onTap: () {
                             // Show GoTo Sheet
                          }),
                          const SizedBox(width: 16), // End padding
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Online Toggle Slider
                    const OnlineToggle(),
                  ],
                ),
              ),
            ),
          ),

          // 4. Ride Request Modal (Overlay)
          if (rideRequestState.hasActiveRequest)
            RideRequestModal(
              request: rideRequestState.currentRequest!,
              onAccept: () async {
                await ref.read(rideRequestProvider.notifier).acceptCurrentRequest();
                ref.invalidate(activeTripProvider);
              },
              onReject: () {
                ref.read(rideRequestProvider.notifier).rejectCurrentRequest();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Menu Button
          Builder(
            builder: (context) => GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.carbonGrey,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.menu, color: Colors.white, size: 24),
              ),
            ),
          ),
          
          // Notification Bell
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.carbonGrey,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.errorRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(IconData icon, String label, {bool isActive = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.white10 : AppColors.carbonGrey,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isActive ? AppColors.hyperLime : AppColors.white10,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.hyperLime : AppColors.white50,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: isActive ? Colors.white : AppColors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
     // Simple Drawer for navigation
     return Drawer(
      backgroundColor: AppColors.voidBlack,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.carbonGrey,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white10,
                    border: Border.all(color: AppColors.hyperLime),
                  ),
                  child: const Icon(Icons.person, size: 30, color: Colors.white),
                 ),
                 const SizedBox(height: 12),
                 Text(
                   'Captain Info',
                   style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                 ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events, color: AppColors.hyperLime),
            title: Text('Incentives', style: GoogleFonts.dmSans(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const IncentivesScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.price_change, color: AppColors.hyperLime),
            title: Text('Rate Card', style: GoogleFonts.dmSans(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
               Navigator.push(context, MaterialPageRoute(builder: (_) => const RateCardScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.verified_user, color: AppColors.hyperLime),
            title: Text('Verify Documents', style: GoogleFonts.dmSans(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentUploadScreen()));
            },
          ),
          Divider(color: AppColors.white10),
          ListTile(
            leading: const Icon(Icons.bug_report, color: AppColors.warningAmber),
            title: Text('Simulate Ride Request', style: GoogleFonts.dmSans(color: AppColors.warningAmber)),
            onTap: () {
              Navigator.pop(context);
              ref.read(socketServiceProvider).simulateIncomingRequest();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Simulating Incoming Ride...')),
              );
            },
          ),
           ListTile(
            leading: const Icon(Icons.account_balance_wallet, color: AppColors.hyperLime),
            title: Text('Wallet', style: GoogleFonts.dmSans(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
               Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
            },
          ),
        ],
      ),
     );
  }
}
