import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';
import '../../../driver_status/presentation/providers/driver_status_providers.dart';
import '../../../rides/presentation/providers/ride_request_providers.dart';
import '../../../rides/presentation/widgets/ride_request_modal.dart';
import '../../../wallet/presentation/screens/wallet_screen.dart';
import '../../../incentives/presentation/screens/incentives_screen.dart';
import '../../../rides/data/models/ride_request.dart';
import '../../../rides/data/models/trip.dart';
import '../../../../core/socket/socket_service.dart';
import 'dart:async';
import '../providers/map_home_providers.dart';
import '../widgets/driver_map.dart';
import '../widgets/goto_button.dart';
import '../../../rides/presentation/screens/active_trip_screen.dart';
import '../../../rides/presentation/screens/incoming_rides_screen.dart';
import '../../../../driver/driver_profile_screen.dart';
import '../../../../driver/driver_trip_history_screen.dart';
import '../../../../driver/driver_help_screen.dart';
import '../../../../services/legacy_safety_service.dart';
import '../../../../screens/profile/emergency_contacts_screen.dart';

class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  ConsumerState<DriverDashboardScreen> createState() =>
      _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen> {
  StreamSubscription? _rideOfferSubscription;
  StreamSubscription? _rideUpdateSubscription;
  int _selectedNavIndex = 0;

  // Filter chip active state
  bool _surgeActive = false;
  bool _highDemandActive = false;

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
      if (mounted) {
        _handleRideUpdate(Map<String, dynamic>.from(data));
      }
    });
    socketService.connect();
  }

  void _handleRideUpdate(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final payloadRaw = data['data'] ?? data;
    final payload = payloadRaw is Map<String, dynamic>
        ? Map<String, dynamic>.from(payloadRaw)
        : <String, dynamic>{};

    final rideRequestNotifier = ref.read(rideRequestProvider.notifier);
    final activeTripNotifier = ref.read(activeTripProvider.notifier);

    if (type == 'expired') {
      rideRequestNotifier.clearRequest();
      return;
    }

    if (type == 'accepted') {
      rideRequestNotifier.clearRequest();
    }

    if (payload.isNotEmpty) {
      try {
        final trip = Trip.fromJson(payload);
        activeTripNotifier.setTrip(trip);
      } catch (_) {
        // ignore parse errors and continue with type handling
      }
    }

    if (type == 'cancelled') {
      activeTripNotifier.clearTrip();
      rideRequestNotifier.clearRequest();
    }

    if (type == 'completed') {
      activeTripNotifier.clearTrip();
    }
  }

  @override
  void dispose() {
    _rideOfferSubscription?.cancel();
    _rideUpdateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleToggle() async {
    final driverStatus = ref.read(driverStatusProvider);
    if (driverStatus.isToggling) return;
    final restriction = driverStatus.statusRestriction;
    if (!driverStatus.isOnline && restriction != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(restriction, style: GoogleFonts.dmSans()),
        backgroundColor: AppColors.warningOrange,
      ));
      return;
    }
    final success = await ref.read(driverStatusProvider.notifier).toggleStatus();
    if (!success && mounted) {
      final error = ref.read(driverStatusProvider).error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error, style: GoogleFonts.dmSans()),
          backgroundColor: AppColors.errorRed,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverStatus = ref.watch(driverStatusProvider);
    final rideRequestState = ref.watch(rideRequestProvider);
    final activeTripState = ref.watch(activeTripProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (activeTripState.hasActiveTrip) {
      return const ActiveTripScreen();
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen map as background
          const DriverMap(showHeatmap: true),

          // Top floating app bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(driverStatus, colors, isDark),
          ),

          // Right-side floating map controls
          Positioned(
            right: 12,
            bottom: MediaQuery.of(context).size.height * 0.40 + 16,
            child: _buildRightMapControls(colors, isDark),
          ),

          // Bottom draggable sheet
          DraggableScrollableSheet(
            initialChildSize: 0.40,
            minChildSize: 0.22,
            maxChildSize: 0.82,
            snap: true,
            snapSizes: const [0.22, 0.40, 0.82],
            builder: (context, scrollController) {
              return _buildBottomSheet(scrollController, driverStatus, colors, isDark);
            },
          ),

          // Ride request modal overlays everything
          if (rideRequestState.hasActiveRequest)
            RideRequestModal(
              request: rideRequestState.currentRequest!,
              onAccept: () async {
                final currentRequest = ref.read(rideRequestProvider).currentRequest;
                if (currentRequest != null) {
                  ref.read(socketServiceProvider).acceptRide(currentRequest.id);
                }
                final trip = await ref.read(rideRequestProvider.notifier).acceptCurrentRequest();
                if (trip != null) {
                  ref.read(activeTripProvider.notifier).setTrip(trip);
                } else {
                  ref.invalidate(activeTripProvider);
                }
              },
              onReject: () {
                final currentRequest = ref.read(rideRequestProvider).currentRequest;
                if (currentRequest != null) {
                  ref.read(socketServiceProvider).rejectRide(currentRequest.id);
                }
                ref.read(rideRequestProvider.notifier).rejectCurrentRequest();
              },
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(colors, isDark),
    );
  }

  // ─── Top App Bar ───────────────────────────────────────────────────────────

  Widget _buildTopBar(DriverStatusState driverStatus, ColorScheme colors, bool isDark) {
    final barBg = isDark ? AppColors.voidBlack : Colors.white;
    return SafeArea(
      bottom: false,
      child: Container(
        color: barBg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Hamburger / profile
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DriverProfileScreen()),
              ),
              child: Icon(Icons.menu, color: colors.onSurface, size: 28),
            ),

            // Centered ON DUTY toggle pill
            Expanded(
              child: Center(
                child: _buildOnDutyPill(driverStatus, isDark),
              ),
            ),

            // Location pin icon
            Icon(
              Icons.location_on,
              color: isDark ? AppColors.hyperLime : AppColors.primary,
              size: 26,
            ),
            const SizedBox(width: 16),

            // Notification bell
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IncomingRidesScreen()),
              ),
              child: Icon(Icons.notifications_none, color: colors.onSurface, size: 26),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnDutyPill(DriverStatusState driverStatus, bool isDark) {
    final isOnline = driverStatus.isOnline;
    final isToggling = driverStatus.isToggling;
    final borderColor = isOnline ? Colors.green.shade400 : Colors.grey.shade300;
    final labelColor = isOnline ? Colors.green.shade700 : Colors.grey.shade600;

    return GestureDetector(
      onTap: isToggling ? null : _handleToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.carbonGrey : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ON DUTY',
              style: GoogleFonts.outfit(
                color: labelColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: 4),
            if (isToggling)
              Padding(
                padding: const EdgeInsets.all(8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isOnline ? Colors.green : Colors.grey,
                  ),
                ),
              )
            else
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: isOnline,
                  onChanged: isToggling ? null : (_) => _handleToggle(),
                  activeThumbColor: Colors.white,
                  activeTrackColor: Colors.green,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Right-side floating map controls ─────────────────────────────────────

  Widget _buildRightMapControls(ColorScheme colors, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _circularMapButton(
          icon: Icons.bar_chart_rounded,
          color: AppColors.successGreen,
          isDark: isDark,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const IncentivesScreen()),
          ),
        ),
        const SizedBox(height: 8),
        const GotoButton(),
        const SizedBox(height: 8),
        _circularMapButton(
          icon: Icons.security,
          color: Colors.red.shade400,
          isDark: isDark,
          onTap: () => _showSafetyActionsSheet(),
        ),
      ],
    );
  }

  Widget _circularMapButton({
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? AppColors.carbonGrey : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  // ─── Bottom Draggable Sheet ─────────────────────────────────────────────────

  Widget _buildBottomSheet(
    ScrollController scrollController,
    DriverStatusState driverStatus,
    ColorScheme colors,
    bool isDark,
  ) {
    final earnings = ref.watch(todayEarningsProvider);
    final panelBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 2),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Earnings header row
          _buildEarningsHeaderRow(earnings, colors, isDark),

          // Performance / incentive card
          _buildPerformanceCard(colors, isDark),

          const SizedBox(height: 12),

          // Filter chips (Surge / High Demand / Go to)
          _buildFilterChips(isDark),

          // Up chevrons
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.keyboard_arrow_up, color: Colors.grey.shade400, size: 20),
                Icon(Icons.keyboard_arrow_up, color: Colors.grey.shade400, size: 20),
              ],
            ),
          ),

          // Take Action Now section
          _buildTakeActionNow(colors, isDark),

          const SizedBox(height: 12),

          // Quick action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildQuickActions(colors, isDark),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEarningsHeaderRow(TodayEarnings earnings, ColorScheme colors, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          Text(
            "Today's Earnings",
            style: GoogleFonts.outfit(
              color: colors.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          Text(
            '\u20B9${earnings.totalAmount.toStringAsFixed(0)}',
            style: GoogleFonts.outfit(
              color: colors.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down, color: colors.onSurface, size: 22),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(ColorScheme colors, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade700,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Best Performance!',
                    style: GoogleFonts.dmSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '17/20 Completed Orders',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const IncentivesScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Know more',
                          style: GoogleFonts.dmSans(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 14, color: Colors.green.shade700),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              color: Colors.green.shade600,
            ),
            child: const Icon(Icons.person, size: 36, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _filterChip(
            Icons.trending_up, 'Surge', Colors.red, isDark,
            isActive: _surgeActive,
            onTap: () => setState(() => _surgeActive = !_surgeActive),
          ),
          const SizedBox(width: 8),
          _filterChip(
            Icons.flash_on, 'High Demand', Colors.orange, isDark,
            isActive: _highDemandActive,
            onTap: () => setState(() => _highDemandActive = !_highDemandActive),
          ),
          const SizedBox(width: 8),
          _filterChip(
            Icons.location_on, 'Go to', Colors.pink, isDark,
            isActive: false,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IncomingRidesScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(IconData icon, String label, Color iconColor, bool isDark, {
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final activeColor = iconColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: isDark ? 0.3 : 0.12)
              : (isDark ? const Color(0xFF2C2C2E) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? activeColor
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  )
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isActive ? activeColor : iconColor.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive ? activeColor : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTakeActionNow(ColorScheme colors, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Take Action Now',
                style: GoogleFonts.outfit(
                  color: colors.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Low balance warning card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Low Balance- Orders will be blocked',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Wallet balance is low',
                        style: GoogleFonts.dmSans(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WalletScreen()),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Pay Now',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ColorScheme colors, bool isDark) {
    return Row(
      children: [
        Expanded(child: _buildQuickAction(icon: Icons.directions_car_outlined, label: 'Rides', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const IncomingRidesScreen()));
        }, colors: colors, isDark: isDark)),
        const SizedBox(width: 12),
        Expanded(child: _buildQuickAction(icon: Icons.history, label: 'History', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverTripHistoryScreen()));
        }, colors: colors, isDark: isDark)),
        const SizedBox(width: 12),
        Expanded(child: _buildQuickAction(icon: Icons.account_balance_wallet, label: 'Wallet', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
        }, colors: colors, isDark: isDark)),
        const SizedBox(width: 12),
        Expanded(child: _buildQuickAction(icon: Icons.emoji_events, label: 'Rewards', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const IncentivesScreen()));
        }, colors: colors, isDark: isDark)),
        const SizedBox(width: 12),
        Expanded(child: _buildQuickAction(icon: Icons.help_outline, label: 'Help', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverHelpScreen()));
        }, colors: colors, isDark: isDark)),
      ],
    ).animate().fadeIn(delay: 600.ms, duration: 600.ms);
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colors,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.carbonGrey.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Icon(icon, color: isDark ? AppColors.hyperLime : AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.dmSans(color: colors.onSurface, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(ColorScheme colors, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.voidBlack : Colors.white,
        border: Border(top: BorderSide(color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_filled, 'Home', colors, isDark),
              _buildNavItem(1, Icons.directions_car, 'Trips', colors, isDark),
              _buildNavItem(2, Icons.person_outline, 'Profile', colors, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, ColorScheme colors, bool isDark) {
    final isSelected = _selectedNavIndex == index;
    final activeColor = isDark ? AppColors.hyperLime : AppColors.primary;
    final inactiveColor = isDark ? AppColors.white50 : const Color(0xFF9CA3AF);
    return GestureDetector(
      onTap: () {
        setState(() => _selectedNavIndex = index);
        _handleNavigation(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? activeColor : inactiveColor, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: isSelected ? activeColor : inactiveColor,
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
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverTripHistoryScreen()));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverProfileScreen()));
        break;
    }
  }

  // ─── Safety helpers ─────────────────────────────────────────────────────────

  void _showSafetyActionsSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.sos, color: AppColors.errorRed),
                  title: Text('Trigger SOS', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                  subtitle: Text('Alerts admins immediately', style: GoogleFonts.dmSans()),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _triggerSos();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.report_problem, color: AppColors.warningOrange),
                  title: Text('Report Incident', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                  subtitle: Text('Send details to safety team', style: GoogleFonts.dmSans()),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showIncidentReportDialog();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.contacts, color: AppColors.primary),
                  title: Text('Emergency Contacts', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                  subtitle: Text('View and manage SOS contacts', style: GoogleFonts.dmSans()),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _triggerSos() async {
    try {
      await LegacySafetyService.triggerSos(
        tripId: ref.read(activeTripProvider).trip?.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SOS alert sent to safety team.', style: GoogleFonts.dmSans()),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to send SOS. Please retry.', style: GoogleFonts.dmSans()),
          backgroundColor: AppColors.warningOrange,
        ),
      );
    }
  }

  void _showIncidentReportDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Report Safety Incident', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Describe what happened',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final description = controller.text.trim();
              if (description.isEmpty) return;
              Navigator.of(dialogContext).pop();
              try {
                await LegacySafetyService.reportIncident(
                  description: description,
                  rideId: ref.read(activeTripProvider).trip?.id,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Incident reported successfully.', style: GoogleFonts.dmSans()),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to report incident.', style: GoogleFonts.dmSans()),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
