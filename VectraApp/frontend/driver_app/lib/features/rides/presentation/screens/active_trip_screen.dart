import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _arrivedAtPickup = false;
  bool _generatingOtp = false;

  Future<void> _launchPhoneDialer(String number, String errorMessage) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage)),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(activeTripProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Show error snackbar when OTP is wrong or action fails
    ref.listen<ActiveTripState>(activeTripProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!, style: GoogleFonts.dmSans()),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    if (tripState.trip == null) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: Center(
          child: Text(
            'No active trip',
            style: GoogleFonts.outfit(color: colors.onSurface, fontSize: 18),
          ),
        ),
      );
    }

    final trip = tripState.trip!;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.carbonGrey : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Active Trip',
          style: GoogleFonts.outfit(
            color: colors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: colors.onSurface),
        actions: [
          IconButton(
            onPressed: () async {
              await _launchPhoneDialer('112', 'Unable to open emergency dialer');
            },
            icon: const Icon(Icons.emergency, color: AppColors.errorRed),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.errorRed.withValues(alpha: 0.2),
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
            _buildStatusIndicator(trip.status),
            const SizedBox(height: 24),
            _buildRiderInfo(trip, colors, isDark),
            const SizedBox(height: 20),
            _buildLocationCard(
              icon: Icons.my_location,
              label: 'Pickup',
              address: trip.pickupAddress,
              color: AppColors.neonGreen,
              colors: colors,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildLocationCard(
              icon: Icons.location_on,
              label: 'Dropoff',
              address: trip.dropoffAddress,
              color: AppColors.errorRed,
              colors: colors,
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            _buildTripDetails(trip, colors, isDark),
            const SizedBox(height: 24),
            if (trip.status == TripStatus.arriving && _arrivedAtPickup) ...[
              _buildOtpSection(trip, colors, isDark),
              const SizedBox(height: 24),
            ],
            _buildActionButton(trip, colors, isDark),
            if (trip.status == TripStatus.assigned || trip.status == TripStatus.arriving) ...[            
              const SizedBox(height: 12),
              _buildCancelButton(trip, colors, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(TripStatus status) {
    String statusText;
    Color statusColor;

    switch (status) {
      case TripStatus.requested:
        statusText = 'Ride Requested';
        statusColor = AppColors.warningAmber;
        break;
      case TripStatus.assigned:
        statusText = 'Ride Assigned';
        statusColor = AppColors.warningAmber;
        break;
      case TripStatus.arriving:
        statusText = _arrivedAtPickup ? 'Arrived at Pickup' : 'En Route to Pickup';
        statusColor = _arrivedAtPickup ? AppColors.neonGreen : AppColors.hyperLime;
        break;
      case TripStatus.inProgress:
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
        color: statusColor.withValues(alpha: 0.2),
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

  Widget _buildRiderInfo(Trip trip, ColorScheme colors, bool isDark) {
    final accent = isDark ? AppColors.hyperLime : colors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.carbonGrey : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.hyperLime, AppColors.neonGreen]
                    : [colors.primary, colors.primary.withValues(alpha: 0.7)],
              ),
            ),
            child: Icon(Icons.person, color: isDark ? Colors.black : Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.riderName,
                  style: GoogleFonts.outfit(
                    color: colors.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (trip.riderRating != null)
                  Row(
                    children: [
                      Icon(Icons.star, color: accent, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        trip.riderRating!.toStringAsFixed(1),
                        style: GoogleFonts.dmSans(
                          color: colors.onSurfaceVariant,
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
              onPressed: () async {
                await _launchPhoneDialer(trip.riderPhone!, 'Unable to open rider call');
              },
              icon: Icon(Icons.phone, color: accent),
              style: IconButton.styleFrom(
                backgroundColor: accent.withValues(alpha: 0.2),
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
    required ColorScheme colors,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.carbonGrey : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
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
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: GoogleFonts.dmSans(
                    color: colors.onSurface,
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

  Widget _buildTripDetails(Trip trip, ColorScheme colors, bool isDark) {
    final accent = isDark ? AppColors.hyperLime : colors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.carbonGrey : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDetailItem(
            icon: Icons.route,
            label: 'Distance',
            value: '${trip.distance.toStringAsFixed(1)} km',
            colors: colors,
            accent: accent,
          ),
          Container(width: 1, height: 40, color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
          _buildDetailItem(
            icon: Icons.currency_rupee,
            label: 'Fare',
            value: '\u20B9${trip.fare.toStringAsFixed(0)}',
            colors: colors,
            accent: accent,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colors,
    required Color accent,
  }) {
    return Column(
      children: [
        Icon(icon, color: accent, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: colors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.dmSans(
            color: colors.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpSection(Trip trip, ColorScheme colors, bool isDark) {
    final accent = isDark ? AppColors.hyperLime : colors.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.carbonGrey : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter OTP to Start Trip',
            style: GoogleFonts.outfit(
              color: colors.onSurface,
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

  Widget _buildActionButton(Trip trip, ColorScheme colors, bool isDark) {
    String buttonText;
    VoidCallback? onPressed;
    Color buttonColor = isDark ? AppColors.hyperLime : colors.primary;

    switch (trip.status) {
      case TripStatus.requested:
        buttonText = 'Waiting for Assignment...';
        onPressed = null;
        buttonColor = colors.onSurfaceVariant;
        break;
      case TripStatus.assigned:
        buttonText = 'Start Navigation';
        onPressed = () {
          ref.read(activeTripProvider.notifier).updateStatus(TripStatus.arriving);
        };
        break;
      case TripStatus.arriving:
        if (!_arrivedAtPickup) {
          buttonText = _generatingOtp ? 'Generating OTP...' : "I've Arrived";
          onPressed = _generatingOtp
              ? null
              : () async {
                  setState(() => _generatingOtp = true);
                  try {
                    await ref
                        .read(activeTripProvider.notifier)
                        .generateOtp();
                    setState(() {
                      _arrivedAtPickup = true;
                      _generatingOtp = false;
                    });
                  } catch (e) {
                    setState(() => _generatingOtp = false);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to generate OTP: $e')),
                    );
                  }
                };
        } else {
          buttonText = 'Waiting for OTP...';
          onPressed = null;
          buttonColor = colors.onSurfaceVariant;
        }
        break;
      case TripStatus.inProgress:
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
          color: onPressed != null ? buttonColor : buttonColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: onPressed != null
              ? [
                  BoxShadow(
                    color: buttonColor.withValues(alpha: 0.4),
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
            color: onPressed != null
                ? (isDark ? Colors.black : Colors.white)
                : colors.onSurfaceVariant,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton(Trip trip, ColorScheme colors, bool isDark) {
    return GestureDetector(
      onTap: () => _showCancelDialog(trip, colors, isDark),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.5)),
        ),
        child: Text(
          'Cancel Trip',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: AppColors.errorRed,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(Trip trip, ColorScheme colors, bool isDark) {
    final reasons = [
      'Rider no-show',
      'Rider requested cancellation',
      'Wrong pickup location',
      'Vehicle issue',
      'Safety concern',
      'Traffic or road blocked',
    ];
    String selectedReason = reasons.first;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Cancel Trip', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select a reason:', style: GoogleFonts.dmSans(color: colors.onSurfaceVariant)),
              const SizedBox(height: 12),
              ...reasons.map((reason) => GestureDetector(
                onTap: () => setDialogState(() => selectedReason = reason),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedReason == reason ? AppColors.errorRed : colors.outline,
                            width: 2,
                          ),
                        ),
                        child: selectedReason == reason
                            ? Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.errorRed,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(reason, style: GoogleFonts.dmSans(fontSize: 14))),
                    ],
                  ),
                ),
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ref.read(activeTripProvider.notifier).cancelTrip(selectedReason);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
              child: Text('Confirm Cancel', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}