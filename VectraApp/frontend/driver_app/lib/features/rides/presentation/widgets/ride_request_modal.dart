import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';
import '../../data/models/ride_request.dart';

class RideRequestModal extends StatefulWidget {
  final RideRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const RideRequestModal({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<RideRequestModal> createState() => _RideRequestModalState();
}

class _RideRequestModalState extends State<RideRequestModal> {
  static const int _timeoutSeconds = 15;
  int _remainingSeconds = _timeoutSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        widget.onReject(); // Auto-reject after timeout
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.carbonGrey,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _remainingSeconds <= 5
                  ? AppColors.errorRed
                  : AppColors.hyperLime,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (_remainingSeconds <= 5
                        ? AppColors.errorRed
                        : AppColors.hyperLime)
                    .withOpacity(0.3),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Timer
              _buildTimer(),
              const SizedBox(height: 24),

              // Title
              Text(
                'New Ride Request',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Rider info
              _buildRiderInfo(),
              const SizedBox(height: 20),

              // Pickup location
              _buildLocationCard(
                icon: Icons.my_location,
                label: 'Pickup',
                address: widget.request.pickupAddress,
                color: AppColors.neonGreen,
              ),
              const SizedBox(height: 12),

              // Dropoff location
              _buildLocationCard(
                icon: Icons.location_on,
                label: 'Dropoff',
                address: widget.request.dropoffAddress,
                color: AppColors.errorRed,
              ),
              const SizedBox(height: 20),

              // Trip details
              _buildTripDetails(),
              const SizedBox(height: 24),

              // Action buttons
              _buildActionButtons(),
            ],
          ),
        ).animate().scale(duration: 300.ms).fadeIn(),
      ),
    );
  }

  Widget _buildTimer() {
    final progress = _remainingSeconds / _timeoutSeconds;
    final isUrgent = _remainingSeconds <= 5;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 6,
            backgroundColor: AppColors.white10,
            valueColor: AlwaysStoppedAnimation(
              isUrgent ? AppColors.errorRed : AppColors.hyperLime,
            ),
          ),
        ),
        Text(
          '$_remainingSeconds',
          style: GoogleFonts.outfit(
            color: isUrgent ? AppColors.errorRed : AppColors.hyperLime,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).scale(
      duration: 1000.ms,
      begin: const Offset(1, 1),
      end: const Offset(1.1, 1.1),
    );
  }

  Widget _buildRiderInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.hyperLime, AppColors.neonGreen],
              ),
            ),
            child: const Icon(Icons.person, color: Colors.black, size: 28),
          ),
          const SizedBox(width: 16),
          // Name and rating
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.request.riderName,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.request.riderRating != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppColors.neonGreen,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.request.riderRating!.toStringAsFixed(1),
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
          // Vehicle type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.hyperLime.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.hyperLime),
            ),
            child: Text(
              widget.request.vehicleType.toUpperCase(),
              style: GoogleFonts.dmSans(
                color: AppColors.hyperLime,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
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
        color: AppColors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
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

  Widget _buildTripDetails() {
    return Row(
      children: [
        Expanded(
          child: _buildDetailCard(
            icon: Icons.route,
            label: 'Distance',
            value: '${widget.request.estimatedDistance.toStringAsFixed(1)} km',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDetailCard(
            icon: Icons.access_time,
            label: 'Duration',
            value: '${widget.request.estimatedDuration} min',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDetailCard(
            icon: Icons.currency_rupee,
            label: 'Fare',
            value: '₹${widget.request.estimatedFare.toStringAsFixed(0)}',
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.hyperLime, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: AppColors.white50,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Reject button
        Expanded(
          child: GestureDetector(
            onTap: widget.onReject,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.errorRed),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.close, color: AppColors.errorRed, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Reject',
                    style: GoogleFonts.outfit(
                      color: AppColors.errorRed,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Accept button
        Expanded(
          child: GestureDetector(
            onTap: widget.onAccept,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.hyperLime, AppColors.neonGreen],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.hyperLime.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check, color: Colors.black, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Accept',
                    style: GoogleFonts.outfit(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
