import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ride_history_model.dart';
import 'ride_detail_screen.dart';

/// Screen showing user's ride history
class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<RideHistoryModel> _allRides = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRideHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRideHistory() async {
    // Simulate loading - in production, fetch from API
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock ride history data
    setState(() {
      _allRides = [
        RideHistoryModel(
          id: 'ride_001',
          pickupAddress: 'RS Puram, Coimbatore',
          destinationAddress: 'Gandhipuram Bus Stand, Coimbatore',
          pickupLat: 11.0123,
          pickupLng: 76.9456,
          destinationLat: 11.0178,
          destinationLng: 76.9678,
          vehicleType: 'sedan',
          fare: 145.0,
          status: 'completed',
          rideDate: DateTime.now().subtract(const Duration(hours: 2)),
          driverName: 'Rajesh Kumar',
          driverPhone: '+91 98765 43210',
          vehicleNumber: 'TN-38-AB-1234',
          rating: 5.0,
          review: 'Great ride!',
          distance: 4.5,
          durationMinutes: 18,
          paymentMethod: 'cash',
        ),
        RideHistoryModel(
          id: 'ride_002',
          pickupAddress: 'Brookefields Mall, Coimbatore',
          destinationAddress: 'Coimbatore Junction Railway Station',
          pickupLat: 11.0234,
          pickupLng: 76.9567,
          destinationLat: 11.0017,
          destinationLng: 76.9669,
          vehicleType: 'mini',
          fare: 98.0,
          status: 'completed',
          rideDate: DateTime.now().subtract(const Duration(days: 1)),
          driverName: 'Suresh M',
          driverPhone: '+91 98765 11111',
          vehicleNumber: 'TN-38-CD-5678',
          rating: 4.0,
          distance: 3.2,
          durationMinutes: 14,
          paymentMethod: 'upi',
        ),
        RideHistoryModel(
          id: 'ride_003',
          pickupAddress: 'PSG College of Technology',
          destinationAddress: 'Ukkadam Bus Stand',
          pickupLat: 11.0245,
          pickupLng: 77.0028,
          destinationLat: 10.9925,
          destinationLng: 76.9614,
          vehicleType: 'xl',
          fare: 220.0,
          status: 'cancelled',
          rideDate: DateTime.now().subtract(const Duration(days: 2)),
          driverName: 'Karthik R',
          driverPhone: '+91 98765 22222',
          vehicleNumber: 'TN-38-EF-9012',
          distance: 6.8,
          durationMinutes: 25,
          paymentMethod: 'card',
        ),
        RideHistoryModel(
          id: 'ride_004',
          pickupAddress: 'Fun Mall, Coimbatore',
          destinationAddress: 'Coimbatore International Airport',
          pickupLat: 11.0156,
          pickupLng: 76.9789,
          destinationLat: 11.0300,
          destinationLng: 77.0434,
          vehicleType: 'sedan',
          fare: 380.0,
          status: 'completed',
          rideDate: DateTime.now().subtract(const Duration(days: 5)),
          driverName: 'Vijay S',
          driverPhone: '+91 98765 33333',
          vehicleNumber: 'TN-38-GH-3456',
          rating: 5.0,
          review: 'Very professional driver',
          distance: 12.5,
          durationMinutes: 35,
          paymentMethod: 'card',
        ),
      ];
      _isLoading = false;
    });
  }

  List<RideHistoryModel> get _completedRides =>
      _allRides.where((r) => r.status == 'completed').toList();

  List<RideHistoryModel> get _cancelledRides =>
      _allRides.where((r) => r.status == 'cancelled').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('My Rides'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          tabs: [
            Tab(text: 'Completed (${_completedRides.length})'),
            Tab(text: 'Cancelled (${_cancelledRides.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRideList(_completedRides),
                _buildRideList(_cancelledRides),
              ],
            ),
    );
  }

  Widget _buildRideList(List<RideHistoryModel> rides) {
    if (rides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No rides yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRideHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rides.length,
        itemBuilder: (context, index) {
          return _RideHistoryCard(
            ride: rides[index],
            onTap: () => _openRideDetail(rides[index]),
          );
        },
      ),
    );
  }

  void _openRideDetail(RideHistoryModel ride) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RideDetailScreen(ride: ride)),
    );
  }
}

class _RideHistoryCard extends StatelessWidget {
  final RideHistoryModel ride;
  final VoidCallback onTap;

  const _RideHistoryCard({required this.ride, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM, hh:mm a');
    final isCompleted = ride.status == 'completed';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and Status row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(ride.rideDate),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isCompleted ? 'Completed' : 'Cancelled',
                      style: TextStyle(
                        color: isCompleted
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Pickup
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ride.pickupAddress,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Dotted line
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Column(
                  children: List.generate(
                    3,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      width: 2,
                      height: 4,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ),

              // Destination
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ride.destinationAddress,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Bottom row - fare, vehicle, driver
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Fare
                  Row(
                    children: [
                      Text(
                        '₹${ride.fare.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _getVehicleIcon(ride.vehicleType),
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),

                  // Driver info
                  Row(
                    children: [
                      if (ride.rating != null) ...[
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ride.rating!.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        ride.driverName,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'mini':
        return Icons.directions_car;
      case 'xl':
        return Icons.airport_shuttle;
      default:
        return Icons.local_taxi;
    }
  }
}
