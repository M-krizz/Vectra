import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/app_theme.dart';
import '../bloc/ride_bloc.dart';
import '../models/place_model.dart';
import 'driver_assigned_screen.dart';

class PoolPreviewScreen extends StatefulWidget {
  const PoolPreviewScreen({super.key});

  @override
  State<PoolPreviewScreen> createState() => _PoolPreviewScreenState();
}

class _PoolPreviewScreenState extends State<PoolPreviewScreen> {
  String? _selectedRequestId;

  static final _mockPooledRiders = [
    PooledRiderRequest(
      id: 'pr_001',
      riderId: 'r_001',
      riderName: 'Ananya S',
      riderPhone: '+91 98765 11111',
      rating: 4.7,
      photoUrl: '',
      pickup: const PlaceModel(
        placeId: 'p1',
        name: 'RS Puram',
        address: 'RS Puram, Coimbatore',
      ),
      destination: const PlaceModel(
        placeId: 'd1',
        name: 'Gandhipuram',
        address: 'Gandhipuram, Coimbatore',
      ),
    ),
    PooledRiderRequest(
      id: 'pr_002',
      riderId: 'r_002',
      riderName: 'Priya K',
      riderPhone: '+91 98765 22222',
      rating: 4.9,
      photoUrl: '',
      pickup: const PlaceModel(
        placeId: 'p2',
        name: 'Peelamedu',
        address: 'Peelamedu, Coimbatore',
      ),
      destination: const PlaceModel(
        placeId: 'd2',
        name: 'Town Hall',
        address: 'Town Hall, Coimbatore',
      ),
    ),
  ];

  void _confirmPool() {
    if (_selectedRequestId == null) {
      // Auto-select first
      setState(() => _selectedRequestId = _mockPooledRiders[0].id);
    }

    final rider = _mockPooledRiders
        .firstWhere((r) => r.id == (_selectedRequestId ?? _mockPooledRiders[0].id));

    context.read<RideBloc>()
      ..add(RidePooledRequestSelected(rider))
      ..add(const RideDriverFound(DriverInfo(
        id: 'drv_001',
        name: 'Karthik R',
        phone: '+91 98765 43210',
        vehicleNumber: 'TN-38-AB-1234',
        vehicleModel: 'TVS Jupiter',
        vehicleColor: 'Black',
        rating: 4.8,
      )));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DriverAssignedScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Pool Preview',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Pool benefit card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Text('💚', style: TextStyle(fontSize: 28)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You\'re saving 30%!',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Sharing a ride is better for your wallet and the environment.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF388E3C)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Detour info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFCC80)),
            ),
            child: const Row(
              children: [
                Icon(Icons.timer_outlined, size: 18, color: Color(0xFFE65100)),
                SizedBox(width: 10),
                Text(
                  'Estimated detour: +4 min for your pickup',
                  style:
                      TextStyle(fontSize: 13, color: Color(0xFFE65100)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Fellow Riders',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'ll be matched with one of these riders going your way.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          ..._mockPooledRiders.map((rider) => _RiderCard(
                rider: rider,
                selected: _selectedRequestId == rider.id,
                onTap: () =>
                    setState(() => _selectedRequestId = rider.id),
              )),

          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _confirmPool,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Confirm Pool Ride',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Rider card ───────────────────────────────────────────────────────────

class _RiderCard extends StatelessWidget {
  final PooledRiderRequest rider;
  final bool selected;
  final VoidCallback onTap;

  const _RiderCard({required this.rider, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F0FE) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FA),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded,
                  size: 26, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        rider.riderName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded,
                          size: 14, color: Color(0xFFFFA000)),
                      Text(
                        rider.rating.toString(),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.circle,
                          size: 8, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          rider.pickup.name,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.circle,
                          size: 8, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          rider.destination.name,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  size: 22, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
