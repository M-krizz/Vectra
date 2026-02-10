import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';
import '../../../../shared/widgets/otp_input.dart';
import '../../data/models/trip.dart';
import '../providers/ride_request_providers.dart';

class ActiveTripScreen extends ConsumerStatefulWidget {
  const ActiveTripScreen({super.key});

  @override
  ConsumerState<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends ConsumerState<ActiveTripScreen> {
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(activeTripProvider);

    if (tripState.trip == null) {
      return Scaffold(
        backgroundColor: AppColors.voidBlack,
        body: Center(
          child: Text(
            'No active trip',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    final trip = tripState.trip!;

    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: AppColors.carbonGrey,
        title: Text(
          'Active Trip',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // SOS Button
          IconButton(
            onPressed: () {
              // TODO: Implement SOS functionality
            },
            icon: const Icon(Icons.emergency, color: AppColors.errorRed),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.errorRed.withOpacity(0.2),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator
            _buildStatusIndicator(trip.status),
            const SizedBox(height: 24),

            // Rider info
            _buildRiderInfo(trip),
            const SizedBox(height: 20),

            // Locations
            _buildLocationCard(
              icon: Icons.my_location,
              label: 'Pickup',
              address: trip.pickupAddress,
              color: AppColors.neonGreen,
            ),
            const SizedBox(height: 12),
            _buildLocationCard(
              icon: Icons.location_on,
              label: 'Dropoff',
              address: trip.dropoffAddress,
              color: AppColors.errorRed,
            ),
            const SizedBox(height: 24),

            // Trip details
            _buildTripDetails(trip),
            const SizedBox(height: 24),

            // OTP input (if status is ARRIVED)
            if (trip.status == TripStatus.arrived) ...[
              _buildOtpSection(trip),
              const SizedBox(height: 24),
            ],

            // Action button
            _buildActionButton(trip),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(TripStatus status) {
    String statusText;
    Color statusColor;

    switch (status) {
      case TripStatus.assigned:
        statusText = 'Ride Assigned';
        statusColor = AppColors.warningAmber;
        break;
      case TripStatus.enRoute:
        statusText = 'En Route to Pickup';
        statusColor = AppColors.hyperLime;
        break;
      case TripStatus.arrived:
        statusText = 'Arrived at Pickup';
        statusColor = AppColors.neonGreen;
        break;
      case TripStatus.started:
        statusText = 'Trip in Progress';
        statusColor = AppColors.successGreen;
        break;
      case TripStatus.completed:
        statusText = 'Trip Completed';
        statusColor = AppColors.successGreen;
        break;
      case TripStatus.cancelled:
        statusText = 'Trip Cancelled';
        statusColor = AppColors.errorRed;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
            ),
          ).animate(onPlay: (controller) => controller.repeat()).fadeIn(
                duration: 1000.ms,
              ).fadeOut(duration: 1000.ms),
          const SizedBox(width: 12),
          Text(
            statusText,
            style: GoogleFonts.outfit(
              color: statusColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderInfo(Trip trip) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.hyperLime, AppColors.neonGreen],
              ),
            ),
            child: const Icon(Icons.person, color: Colors.black, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.riderName,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (trip.riderRating != null)
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.neonGreen, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        trip.riderRating!.toStringAsFixed(1),
                        style: GoogleFonts.dmSans(
                          color: AppColors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (trip.riderPhone != null)
            IconButton(
              onPressed: () {
                // TODO: Implement call functionality
              },
              icon: const Icon(Icons.phone, color: AppColors.hyperLime),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.hyperLime.withOpacity(0.2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationCard({
    required IconData icon,
    required String label,
    required String address,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    color: AppColors.white50,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetails(Trip trip) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDetailItem(
            icon: Icons.route,
            label: 'Distance',
            value: '${trip.distance.toStringAsFixed(1)} km',
          ),
          Container(width: 1, height: 40, color: AppColors.white10),
          _buildDetailItem(
            icon: Icons.currency_rupee,
            label: 'Fare',
            value: '₹${trip.fare.toStringAsFixed(0)}',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.hyperLime, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: AppColors.white50,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpSection(Trip trip) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hyperLime.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter OTP to Start Trip',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          OtpInput(
            length: 4,
            onCompleted: (otp) {
              ref.read(activeTripProvider.notifier).startTrip(otp);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(Trip trip) {
    String buttonText;
    VoidCallback? onPressed;
    Color buttonColor = AppColors.hyperLime;

    switch (trip.status) {
      case TripStatus.assigned:
        buttonText = 'Start Navigation';
        onPressed = () {
          ref.read(activeTripProvider.notifier).updateStatus(TripStatus.enRoute);
        };
        break;
      case TripStatus.enRoute:
        buttonText = 'Mark as Arrived';
        onPressed = () {
          ref.read(activeTripProvider.notifier).updateStatus(TripStatus.arrived);
        };
        break;
      case TripStatus.arrived:
        buttonText = 'Waiting for OTP...';
        onPressed = null;
        buttonColor = AppColors.white50;
        break;
      case TripStatus.started:
        buttonText = 'Complete Trip';
        onPressed = () {
          ref.read(activeTripProvider.notifier).completeTrip();
        };
        buttonColor = AppColors.successGreen;
        break;
      case TripStatus.completed:
        buttonText = 'Trip Completed';
        onPressed = null;
        buttonColor = AppColors.successGreen;
        break;
      case TripStatus.cancelled:
        buttonText = 'Trip Cancelled';
        onPressed = null;
        buttonColor = AppColors.errorRed;
        break;
    }

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: onPressed != null ? buttonColor : buttonColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: onPressed != null
              ? [
                  BoxShadow(
                    color: buttonColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          buttonText,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: onPressed != null ? Colors.black : AppColors.white50,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
