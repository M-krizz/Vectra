import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/app_theme.dart';
import '../bloc/ride_bloc.dart';

class TripCompletedScreen extends StatelessWidget {
  const TripCompletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RideBloc, RideState>(
      builder: (context, state) {
        final fare = state.finalFare ?? state.selectedVehicle?.fare ?? 85.0;
        final isPool = state.rideType == 'pool';
        final vehicle = state.selectedVehicle;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // Checkmark
                        Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_rounded,
                              size: 60, color: Color(0xFF2E7D32)),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Ride Completed!',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'You\'ve arrived at ${state.destination?.name ?? 'destination'}',
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 32),

                        // Fare card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total Fare',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textSecondary)),
                                  Text(
                                    '₹${fare.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              if (isPool) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Pool discount',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF2E7D32))),
                                    const Text('-30%',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF2E7D32))),
                                  ],
                                ),
                              ],
                              if (vehicle != null) ...[
                                const SizedBox(height: 12),
                                const Divider(height: 1, color: AppColors.border),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(vehicle.name,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary)),
                                    const Text('4.2 km • 14 min',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Route summary
                        _RouteRow(
                          pickup: state.pickup?.name ?? 'Pickup',
                          destination: state.destination?.name ?? 'Destination',
                        ),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final tripId = state.rideId ?? 'current';
                            context.push('/trip/$tripId/fare');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: const Text('View Fare Breakdown',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            context.read<RideBloc>().add(const RideCleared());
                            context.go('/home');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.border),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Back to Home',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RouteRow extends StatelessWidget {
  final String pickup;
  final String destination;
  const _RouteRow({required this.pickup, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Column(children: [
            Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle)),
            Container(width: 1, height: 28, color: Colors.grey.shade200),
            Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pickup,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 22),
              Text(destination,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ],
      ),
    );
  }
}
