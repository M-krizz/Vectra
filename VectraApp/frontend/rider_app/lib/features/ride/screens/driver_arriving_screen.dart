import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/app_theme.dart';
import '../../../../config/maps_config.dart';
import '../bloc/ride_bloc.dart';
import '../widgets/safety_fab.dart';
import 'pickup_verification_screen.dart';

class DriverArrivingScreen extends StatefulWidget {
  const DriverArrivingScreen({super.key});

  @override
  State<DriverArrivingScreen> createState() => _DriverArrivingScreenState();
}

class _DriverArrivingScreenState extends State<DriverArrivingScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<RideBloc, RideState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        final tripId = state.rideId ?? 'current';
        if (state.status == RideStatus.inProgress) {
          context.go('/trip/$tripId/in-progress');
        } else if (state.status == RideStatus.completed) {
          context.go('/trip/$tripId/completed');
        } else if (state.status == RideStatus.cancelled) {
          context.go('/trip/$tripId/cancelled');
        }
      },
      child: BlocBuilder<RideBloc, RideState>(
        builder: (context, state) {
          final driver = state.driver;
          return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Column(
              children: [
                // Map view - driver arrived
                _ArrivedMapPlaceholder(state: state),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Arrived banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFA5D6A7)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF2E7D32), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Your driver is at the pickup point!',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        _ArrivingDriverCard(driver: driver),
                        const SizedBox(height: 20),

                        // Verify OTP
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const PickupVerificationScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Verify & Start Trip',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
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
}

// ─── Local widgets ─────────────────────────────────────────────────────────

class _ArrivedMapPlaceholder extends StatelessWidget {
  final RideState state;
  const _ArrivedMapPlaceholder({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      color: AppColors.success.withValues(alpha: 0.1),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(
                state.driver?.location?.latitude ?? state.pickup?.location?.latitude ?? 11.0168,
                state.driver?.location?.longitude ?? state.pickup?.location?.longitude ?? 76.9558,
              ),
              initialZoom: 17.0,
            ),
            children: [
              TileLayer(
                urlTemplate: Theme.of(context).brightness == Brightness.dark
                    ? MapsConfig.darkTileUrlTemplate
                    : MapsConfig.tileUrlTemplate,
                userAgentPackageName: 'com.vectra.rider',
              ),
              if (state.route?.polylinePoints != null && state.route!.polylinePoints.isNotEmpty)
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
                  if (state.pickup?.location != null)
                    Marker(
                      point: LatLng(
                        state.pickup!.location!.latitude,
                        state.pickup!.location!.longitude,
                      ),
                      width: 36,
                      height: 36,
                      child: const Icon(Icons.circle, color: Colors.green, size: 16),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArrivingDriverCard extends StatelessWidget {
  final DriverInfo? driver;
  const _ArrivingDriverCard({this.driver});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
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
                        style:
                            TextStyle(color: AppColors.textSecondary)),
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
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call_rounded,
                  size: 22, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
