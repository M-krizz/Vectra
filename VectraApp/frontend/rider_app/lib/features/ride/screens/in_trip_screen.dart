import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/app_theme.dart';
import '../../../../config/maps_config.dart';
import '../bloc/ride_bloc.dart';
import '../services/trip_socket_service.dart';
import '../widgets/safety_fab.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class InTripScreen extends StatefulWidget {
  const InTripScreen({super.key});

  @override
  State<InTripScreen> createState() => _InTripScreenState();
}

class _InTripScreenState extends State<InTripScreen> {
  int _elapsedSeconds = 0;
  Timer? _timer;
  StreamSubscription<bool>? _connectionSubscription;
  bool _showReconnecting = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _elapsedSeconds++);
    });

    final tripSocketService = context.read<TripSocketService>();
    _showReconnecting = !tripSocketService.isConnected;
    _connectionSubscription = tripSocketService.connectionStream.listen((connected) {
      if (!mounted) return;
      setState(() => _showReconnecting = !connected);
    });
  }

  String get _elapsed {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RideBloc, RideState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        final tripId = state.rideId ?? 'current';
        if (state.status == RideStatus.completed) {
          context.go('/trip/$tripId/completed');
        } else if (state.status == RideStatus.cancelled) {
          context.go('/trip/$tripId/cancelled');
        }
      },
      child: BlocBuilder<RideBloc, RideState>(
        builder: (context, state) {
          return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Column(
              children: [
                // Reconnecting banner
                if (_showReconnecting) const _ReconnectingBanner(),

                // Map placeholder
                // Google Map
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.35,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        state.driver?.location?.latitude ?? state.pickup?.location?.latitude ?? 11.0168,
                        state.driver?.location?.longitude ?? state.pickup?.location?.longitude ?? 76.9558,
                      ),
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: Theme.of(context).brightness == Brightness.dark
                            ? MapsConfig.darkTileUrlTemplate
                            : MapsConfig.tileUrlTemplate,
                        userAgentPackageName: 'com.vectra.rider',
                      ),
                      if (state.route?.polylinePoints != null &&
                          state.route!.polylinePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: state.route!.polylinePoints,
                              color: AppColors.primary,
                              strokeWidth: 4,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          if (state.driver?.location != null)
                            Marker(
                              point: LatLng(
                                state.driver!.location!.latitude,
                                state.driver!.location!.longitude,
                              ),
                              width: 36,
                              height: 36,
                              child: const Icon(Icons.local_taxi, color: Colors.orange, size: 28),
                            ),
                          if (state.destination?.location != null)
                            Marker(
                              point: LatLng(
                                state.destination!.location!.latitude,
                                state.destination!.location!.longitude,
                              ),
                              width: 36,
                              height: 36,
                              child: const Icon(Icons.location_on, color: Colors.red, size: 32),
                            ),
                        ],
                      ),
                    ],
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
                              color: AppColors.success.withValues(alpha: 0.1),
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
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _connectionSubscription?.cancel();
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
      color: AppColors.warning.withValues(alpha: 0.1),
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
        color: AppColors.primary.withValues(alpha: 0.1),
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
        color: Theme.of(context).colorScheme.surface,
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
        color: Theme.of(context).colorScheme.surface,
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
