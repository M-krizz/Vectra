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

class DriverAssignedScreen extends StatefulWidget {
  const DriverAssignedScreen({super.key});

  @override
  State<DriverAssignedScreen> createState() => _DriverAssignedScreenState();
}

class _DriverAssignedScreenState extends State<DriverAssignedScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<RideBloc, RideState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        final tripId = state.rideId ?? 'current';
        if (state.status == RideStatus.arrived) {
          context.go('/trip/$tripId/arriving');
        } else if (state.status == RideStatus.inProgress) {
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
          final eta = (state.estimatedArrivalMinutes ?? state.tripDurationMinutes ?? 5).clamp(0, 99);
          return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Column(
              children: [
                // Map view
                _MapPlaceholder(
                  etaMinutes: eta,
                  label: 'Driver is on the way',
                  state: state,
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
      ),
    );
  }
}

// ─── Shared widgets ────────────────────────────────────────────────────────

class _MapPlaceholder extends StatelessWidget {
  final int etaMinutes;
  final String label;
  final RideState state;
  const _MapPlaceholder({required this.etaMinutes, required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Stack(
        children: [
          // Mapbox Map Background
          FlutterMap(
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
          // ETA badge
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_rounded,
                    size: 30, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        Text('  •  ',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        Text(
                          driver?.vehicleModel ?? 'Vehicle',
                          style: TextStyle(
                              fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${driver?.vehicleColor ?? ''} • ${driver?.vehicleNumber ?? ''}',
                      style: TextStyle(
                          fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                    color: AppColors.primary.withValues(alpha: 0.1),
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_alt_rounded,
              size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(
            'You\'re pooling with ${rider.riderName}',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}
