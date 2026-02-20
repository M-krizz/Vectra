import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/app_theme.dart';
import '../bloc/ride_bloc.dart';
import '../widgets/safety_fab.dart';
import 'trip_completed_screen.dart';

class InTripScreen extends StatefulWidget {
  const InTripScreen({super.key});

  @override
  State<InTripScreen> createState() => _InTripScreenState();
}

class _InTripScreenState extends State<InTripScreen> {
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _showReconnecting = false;

  // Mock: trip auto-completes after 30s
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _elapsedSeconds++);

      // Brief connectivity blip at 10s (demo)
      if (_elapsedSeconds == 10) {
        setState(() => _showReconnecting = true);
        Future.delayed(const Duration(seconds: 3),
            () { if (mounted) setState(() => _showReconnecting = false); });
      }

      if (_elapsedSeconds >= 30) {
        t.cancel();
        final state = context.read<RideBloc>().state;
        final fare = state.selectedVehicle?.fare ?? 85.0;
        context.read<RideBloc>().add(RideCompleted(fare));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TripCompletedScreen()),
        );
      }
    });
  }

  String get _elapsed {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RideBloc, RideState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // Reconnecting banner
                if (_showReconnecting) const _ReconnectingBanner(),

                // Map placeholder
                Container(
                  height: 200,
                  color: const Color(0xFFE3F2FD),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.navigation_rounded,
                            size: 44, color: AppColors.primary),
                        const SizedBox(height: 8),
                        Text(
                          'En route to ${state.destination?.name ?? 'destination'}',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),

                // Trip phase progress
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _TripPhaseBar(elapsed: _elapsed),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Driver info (compact)
                        _CompactDriverBar(driver: state.driver),
                        const SizedBox(height: 16),

                        // Route card
                        _RouteCard(
                          pickup: state.pickup?.name ?? 'Pickup',
                          destination:
                              state.destination?.name ?? 'Destination',
                        ),

                        if (state.rideType == 'pool' &&
                            state.selectedPooledRequest != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.people_alt_rounded,
                                    size: 18, color: Color(0xFF2E7D32)),
                                const SizedBox(width: 8),
                                Text(
                                  'Pooling with ${state.selectedPooledRequest!.riderName}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF2E7D32),
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
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
    _timer?.cancel();
    super.dispose();
  }
}

// ─── Reconnecting banner ──────────────────────────────────────────────────

class _ReconnectingBanner extends StatelessWidget {
  const _ReconnectingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF3E0),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFE65100),
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Reconnecting…',
            style:
                TextStyle(fontSize: 13, color: Color(0xFFE65100), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Trip phase bar ────────────────────────────────────────────────────────

class _TripPhaseBar extends StatelessWidget {
  final String elapsed;
  const _TripPhaseBar({required this.elapsed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.circle, size: 10, color: AppColors.primary),
              SizedBox(width: 6),
              Text('IN PROGRESS',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.8)),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.timer_outlined,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                elapsed,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Compact driver bar ────────────────────────────────────────────────────

class _CompactDriverBar extends StatelessWidget {
  final DriverInfo? driver;
  const _CompactDriverBar({this.driver});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_rounded,
              size: 26, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              driver?.name ?? 'Driver',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
          ),
          Text(
            driver?.vehicleNumber ?? '',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Route card ────────────────────────────────────────────────────────────

class _RouteCard extends StatelessWidget {
  final String pickup;
  final String destination;
  const _RouteCard({required this.pickup, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32), shape: BoxShape.circle)),
              Container(width: 1, height: 36, color: Colors.grey.shade200),
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pickup,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 24),
                Text(destination,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
