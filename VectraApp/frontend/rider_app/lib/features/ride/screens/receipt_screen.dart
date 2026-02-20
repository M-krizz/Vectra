import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../config/app_theme.dart';
import '../bloc/ride_bloc.dart';

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RideBloc, RideState>(
      builder: (context, state) {
        final total =
            (state.finalFare ?? state.selectedVehicle?.fare ?? 85.0) + 8.5;
        final now = DateTime.now();
        final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(now);

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: const Text('Receipt',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Receipt sharing coming soon!')),
                  );
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppColors.border),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Receipt card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(children: [
                      const Text('Trip Receipt',
                          style: TextStyle(fontSize: 14, color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text('₹${total.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Paid · $dateStr',
                          style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    ]),
                  ),

                  // Dashed divider
                  _DashedDivider(),

                  // Details
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      _ReceiptRow('From', state.pickup?.name ?? '—'),
                      const SizedBox(height: 12),
                      _ReceiptRow('To', state.destination?.name ?? '—'),
                      const SizedBox(height: 12),
                      _ReceiptRow('Vehicle', state.selectedVehicle?.name ?? '—'),
                      if (state.driver != null) ...[
                        const SizedBox(height: 12),
                        _ReceiptRow('Driver', state.driver!.name),
                        const SizedBox(height: 12),
                        _ReceiptRow('Vehicle No.', state.driver!.vehicleNumber),
                      ],
                      const SizedBox(height: 12),
                      _ReceiptRow('Distance', '4.2 km'),
                      const SizedBox(height: 12),
                      _ReceiptRow('Duration', '14 min'),
                      const SizedBox(height: 12),
                      _ReceiptRow('Ride Type',
                          state.rideType == 'pool' ? 'Pool (-30%)' : 'Solo'),
                    ]),
                  ),

                  // Dashed divider
                  _DashedDivider(),

                  // Fare breakdown summary
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Paid',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        Text('₹${total.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary)),
                      ],
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              // Rate your ride
              GestureDetector(
                onTap: () {
                  final tripId = context.read<RideBloc>().state.rideId ?? 'current';
                  context.push('/trip/$tripId/rating');
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(children: [
                    Text('⭐', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Rate your ride',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        Text('Help us improve with your feedback',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ]),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  ]),
                ),
              ),

              const SizedBox(height: 16),

              // Back to home
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Back to Home',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReceiptRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              textAlign: TextAlign.right,
              maxLines: 2),
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: CustomPaint(
        painter: _DashPainter(),
        size: const Size(double.infinity, 2),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.5;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 8, 0), paint);
      x += 14;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
