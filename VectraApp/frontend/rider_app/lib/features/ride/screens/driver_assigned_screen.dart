import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/app_theme.dart';
import '../bloc/ride_bloc.dart';
import '../widgets/safety_fab.dart';
import 'driver_arriving_screen.dart';

class DriverAssignedScreen extends StatefulWidget {
  const DriverAssignedScreen({super.key});

  @override
  State<DriverAssignedScreen> createState() => _DriverAssignedScreenState();
}

class _DriverAssignedScreenState extends State<DriverAssignedScreen> {
  int _eta = 5;
  Timer? _etaTimer;

  @override
  void initState() {
    super.initState();
    // Countdown ETA and auto-advance to ARRIVING after etaTimer hits 0
    _etaTimer = Timer.periodic(const Duration(seconds: 4), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _eta = (_eta - 1).clamp(0, 99));
      if (_eta == 0) {
        t.cancel();
        context.read<RideBloc>().add(const RideDriverArrived());
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DriverArrivingScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RideBloc, RideState>(
      builder: (context, state) {
        final driver = state.driver;
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // Map placeholder
                _MapPlaceholder(
                  etaMinutes: _eta,
                  label: 'Driver is on the way',
                ),

                // Driver card
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _DriverCard(driver: driver),
                        const SizedBox(height: 16),
                        if (state.rideType == 'pool' &&
                            state.selectedPooledRequest != null)
                          _PoolMateCard(rider: state.selectedPooledRequest!),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: const SafetyFab(),
        );
      },
    );
  }

  @override
  void dispose() {
    _etaTimer?.cancel();
    super.dispose();
  }
}

// ─── Shared widgets ────────────────────────────────────────────────────────

class _MapPlaceholder extends StatelessWidget {
  final int etaMinutes;
  final String label;
  const _MapPlaceholder({required this.etaMinutes, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      color: const Color(0xFFE8F0FE),
      child: Stack(
        children: [
          // Mock map background
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.directions_car_rounded,
                    size: 48, color: AppColors.primary),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // ETA badge
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    etaMinutes == 0 ? 'Arriving now' : '$etaMinutes min',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
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
}

class _DriverCard extends StatelessWidget {
  final DriverInfo? driver;
  const _DriverCard({this.driver});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7FA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded,
                    size: 30, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver?.name ?? 'Driver',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: Color(0xFFFFA000)),
                        const SizedBox(width: 3),
                        Text(
                          driver?.rating.toString() ?? '—',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary),
                        ),
                        const Text('  •  ',
                            style: TextStyle(color: AppColors.textSecondary)),
                        Text(
                          driver?.vehicleModel ?? 'Vehicle',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${driver?.vehicleColor ?? ''} • ${driver?.vehicleNumber ?? ''}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              // Call button
              GestureDetector(
                onTap: () async {
                  final phone = driver?.phone ?? '';
                  final uri = Uri.parse('tel:$phone');
                  if (await canLaunchUrl(uri)) launchUrl(uri);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call_rounded,
                      size: 22, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PoolMateCard extends StatelessWidget {
  final PooledRiderRequest rider;
  const _PoolMateCard({required this.rider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_alt_rounded,
              size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(
            'You\'re pooling with ${rider.riderName}',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
