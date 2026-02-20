import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../config/app_theme.dart';
import '../models/ride_history_model.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  String _selectedFilter = 'All';
  bool _isLoading = true;
  List<RideHistoryModel> _allRides = [];

  final List<String> _filters = ['All', 'Auto', 'Bike', 'Cab Economy', 'Cab Premium'];

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides() async {
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() {
      _allRides = [
        RideHistoryModel(
          id: 'ride_001',
          pickupAddress: 'RS Puram, Coimbatore',
          destinationAddress: 'Brookefields Mall',
          pickupLat: 11.0123, pickupLng: 76.9456,
          destinationLat: 11.0234, destinationLng: 76.9567,
          vehicleType: 'auto',
          fare: 0.0,
          status: 'cancelled',
          rideDate: DateTime(2026, 2, 19, 9, 18),
          driverName: 'Cancelled',
          driverPhone: '',
          vehicleNumber: '',
          distance: 3.2,
          durationMinutes: 0,
          paymentMethod: 'cash',
        ),
        RideHistoryModel(
          id: 'ride_002',
          pickupAddress: 'Gandhipuram',
          destinationAddress: '256, Race Course Rd',
          pickupLat: 11.0178, pickupLng: 76.9678,
          destinationLat: 11.0145, destinationLng: 76.9712,
          vehicleType: 'bike',
          fare: 35.0,
          status: 'completed',
          rideDate: DateTime(2026, 2, 15, 11, 59),
          driverName: 'Suresh M',
          driverPhone: '+91 98765 11111',
          vehicleNumber: 'TN-38-CD-5678',
          rating: 4.0,
          distance: 2.1,
          durationMinutes: 12,
          paymentMethod: 'upi',
        ),
        RideHistoryModel(
          id: 'ride_003',
          pickupAddress: 'Coimbatore Junction',
          destinationAddress: 'East, 11',
          pickupLat: 11.0017, pickupLng: 76.9669,
          destinationLat: 11.0089, destinationLng: 76.9723,
          vehicleType: 'auto',
          fare: 33.0,
          status: 'completed',
          rideDate: DateTime(2025, 12, 7, 17, 33),
          driverName: 'Karthik R',
          driverPhone: '+91 98765 22222',
          vehicleNumber: 'TN-38-EF-9012',
          rating: 5.0,
          distance: 1.8,
          durationMinutes: 10,
          paymentMethod: 'cash',
        ),
        RideHistoryModel(
          id: 'ride_004',
          pickupAddress: 'PSG College of Technology',
          destinationAddress: 'Coimbatore Junction',
          pickupLat: 11.0245, pickupLng: 77.0028,
          destinationLat: 11.0017, destinationLng: 76.9669,
          vehicleType: 'auto',
          fare: 0.0,
          status: 'cancelled',
          rideDate: DateTime(2025, 12, 7, 17, 20),
          driverName: 'Cancelled',
          driverPhone: '',
          vehicleNumber: '',
          distance: 6.8,
          durationMinutes: 0,
          paymentMethod: 'cash',
        ),
        RideHistoryModel(
          id: 'ride_005',
          pickupAddress: 'Gandhipuram Bus Stand',
          destinationAddress: 'H, 12/20, South Road',
          pickupLat: 11.0178, pickupLng: 76.9678,
          destinationLat: 11.0112, destinationLng: 76.9634,
          vehicleType: 'bike',
          fare: 36.0,
          status: 'completed',
          rideDate: DateTime(2025, 12, 7, 10, 27),
          driverName: 'Vijay S',
          driverPhone: '+91 98765 33333',
          vehicleNumber: 'TN-38-GH-3456',
          rating: 5.0,
          distance: 2.4,
          durationMinutes: 14,
          paymentMethod: 'cash',
        ),
      ];
      _isLoading = false;
    });
  }

  List<RideHistoryModel> get _filteredRides {
    if (_selectedFilter == 'All') return _allRides;
    return _allRides.where((r) =>
        r.vehicleType.toLowerCase().replaceAll(' ', '_') ==
        _selectedFilter.toLowerCase().replaceAll(' ', '_')).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Ride History',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter chips
                SizedBox(
                  height: 52,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                              color: selected ? AppColors.primary : AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Ride list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadRides,
                    color: AppColors.primary,
                    child: _filteredRides.isEmpty
                        ? _EmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _filteredRides.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, color: AppColors.divider),
                            itemBuilder: (_, i) => _RideHistoryTile(
                              ride: _filteredRides[i],
                              onTap: () => context.push(
                                '/trips/${_filteredRides[i].id}',
                                extra: _filteredRides[i],
                              ),
                            ),
                          ),
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
                      const Icon(Icons.help_outline_rounded, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Looking for rides older than 90 days?',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.border),
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
            Icon(_vehicleIcon, size: 30, color: AppColors.textPrimary),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ride.destinationAddress,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '₹${ride.fare.toStringAsFixed(1)}  •  ${isCompleted ? 'Completed' : 'Cancelled'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isCompleted ? AppColors.textSecondary : AppColors.error,
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
