import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/app_theme.dart';
import '../models/ride_history_model.dart';
import '../bloc/history_bloc.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Auto', 'Bike', 'Cab Economy', 'Cab Premium'];

  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(LoadHistoryRequested());
  }

  Future<void> _loadRides() async {
    context.read<HistoryBloc>().add(LoadHistoryRequested());
  }

  List<RideHistoryModel> _filteredRides(List<RideHistoryModel> rides) {
    if (_selectedFilter == 'All') return rides;
    return rides.where((r) =>
        r.vehicleType.toLowerCase().replaceAll(' ', '_') ==
        _selectedFilter.toLowerCase().replaceAll(' ', '_') || r.vehicleType.toLowerCase() == _selectedFilter.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Ride History',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Theme.of(context).colorScheme.outline),
        ),
      ),
      body: Column(
              children: [
                // Filter chips
                SizedBox(
                  height: 52,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final f = _filters[i];
                      final selected = f == _selectedFilter;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedFilter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected ? AppColors.primary : Theme.of(context).colorScheme.outline,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Ride list
                Expanded(
                  child: BlocBuilder<HistoryBloc, HistoryState>(
                    builder: (context, state) {
                      if (state is HistoryLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is HistoryError) {
                        return Center(child: Text(state.message));
                      } else if (state is HistoryLoaded) {
                        final rides = _filteredRides(state.rides);
                        return RefreshIndicator(
                          onRefresh: _loadRides,
                          color: AppColors.primary,
                          child: rides.isEmpty
                              ? _EmptyState()
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: rides.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(height: 1, color: AppColors.divider),
                                  itemBuilder: (_, i) => _RideHistoryTile(
                                    ride: rides[i],
                                    onTap: () => context.push(
                                      '/trips/${rides[i].id}',
                                      extra: rides[i],
                                    ),
                                  ),
                                ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.help_outline_rounded, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Looking for rides older than 90 days?',
                          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurface,
                          side: BorderSide(color: Theme.of(context).colorScheme.outline),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Request Ride History'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Ride tile (matching reference — icon, destination, date, fare, status) ─

class _RideHistoryTile extends StatelessWidget {
  final RideHistoryModel ride;
  final VoidCallback onTap;
  const _RideHistoryTile({required this.ride, required this.onTap});

  IconData get _vehicleIcon {
    switch (ride.vehicleType.toLowerCase()) {
      case 'bike':
      case 'bike_pink':
        return Icons.two_wheeler_rounded;
      case 'auto':
      case 'shared_auto':
        return Icons.electric_rickshaw_rounded;
      default:
        return Icons.directions_car_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = ride.status == 'completed';
    final dateStr = DateFormat('dd MMM yyyy • hh:mm a').format(ride.rideDate);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Vehicle icon
            Icon(_vehicleIcon, size: 30, color: Theme.of(context).colorScheme.onSurface),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ride.destinationAddress,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dateStr,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '₹${ride.fare.toStringAsFixed(1)}  •  ${isCompleted ? 'Completed' : 'Cancelled'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isCompleted ? Theme.of(context).colorScheme.onSurfaceVariant : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No rides yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your ride history will appear here.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
