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
  const RideRequestModal({super.key, required this.request, required this.onAccept, required this.onReject});

  @override
  State<RideRequestModal> createState() => _RideRequestModalState();
}

class _RideRequestModalState extends State<RideRequestModal> {
  static const int _timeoutSeconds = 15;
  int _remainingSeconds = _timeoutSeconds;
  Timer? _timer;

  @override
  void initState() { super.initState(); _startTimer(); }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        widget.onReject();
      }
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.hyperLime : colors.primary;
    final border = isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2);
    final cardBg = isDark ? AppColors.carbonGrey : Colors.white;
    final urgentColor = _remainingSeconds <= 5 ? AppColors.errorRed : accent;

    return Container(
      color: Colors.black54,
      child: Center(child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: urgentColor, width: 2),
          boxShadow: [BoxShadow(color: urgentColor.withValues(alpha: 0.3), blurRadius: 24, spreadRadius: 4)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _buildTimer(colors, isDark, accent),
          const SizedBox(height: 24),
          Text('New Ride Request', style: GoogleFonts.outfit(color: colors.onSurface, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildRiderInfo(colors, isDark, accent, border),
          const SizedBox(height: 20),
          _buildLocationCard(icon: Icons.my_location, label: 'Pickup', address: widget.request.pickupAddress, color: isDark ? AppColors.neonGreen : colors.primary, colors: colors, isDark: isDark, border: border),
          const SizedBox(height: 12),
          _buildLocationCard(icon: Icons.location_on, label: 'Dropoff', address: widget.request.dropoffAddress, color: AppColors.errorRed, colors: colors, isDark: isDark, border: border),
          const SizedBox(height: 20),
          _buildTripDetails(colors, isDark, accent),
          const SizedBox(height: 24),
          _buildActionButtons(colors, isDark, accent),
        ]),
      )).animate().scale(duration: 300.ms).fadeIn(),
    );
  }

  Widget _buildTimer(ColorScheme colors, bool isDark, Color accent) {
    final progress = _remainingSeconds / _timeoutSeconds;
    final isUrgent = _remainingSeconds <= 5;
    final timerColor = isUrgent ? AppColors.errorRed : accent;
    return Stack(alignment: Alignment.center, children: [
      SizedBox(width: 80, height: 80, child: CircularProgressIndicator(
        value: progress, strokeWidth: 6,
        backgroundColor: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.1),
        valueColor: AlwaysStoppedAnimation(timerColor),
      )),
      Text('$_remainingSeconds', style: GoogleFonts.outfit(color: timerColor, fontSize: 32, fontWeight: FontWeight.bold)),
    ]).animate(onPlay: (c) => c.repeat()).scale(duration: 1000.ms, begin: const Offset(1, 1), end: const Offset(1.1, 1.1));
  }

  Widget _buildRiderInfo(ColorScheme colors, bool isDark, Color accent, Color border) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.white10 : colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [accent, accent.withValues(alpha: 0.7)])),
          child: Icon(Icons.person, color: isDark ? Colors.black : Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.request.riderName, style: GoogleFonts.outfit(color: colors.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
          if (widget.request.riderRating != null) Row(children: [
            Icon(Icons.star, color: accent, size: 16),
            const SizedBox(width: 4),
            Text(widget.request.riderRating!.toStringAsFixed(1), style: GoogleFonts.dmSans(color: colors.onSurfaceVariant, fontSize: 14)),
          ]),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: accent)),
          child: Text((widget.request.vehicleType ?? 'STANDARD').toUpperCase(), style: GoogleFonts.dmSans(color: accent, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _buildLocationCard({required IconData icon, required String label, required String address, required Color color, required ColorScheme colors, required bool isDark, required Color border}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.white10 : colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.dmSans(color: colors.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 4),
          Text(address, style: GoogleFonts.dmSans(color: colors.onSurface, fontSize: 14, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  Widget _buildTripDetails(ColorScheme colors, bool isDark, Color accent) {
    return Row(children: [
      Expanded(child: _buildDetailCard(icon: Icons.route, label: 'Distance', value: '${widget.request.estimatedDistance.toStringAsFixed(1)} km', colors: colors, isDark: isDark, accent: accent)),
      const SizedBox(width: 12),
      Expanded(child: _buildDetailCard(icon: Icons.access_time, label: 'Duration', value: '${widget.request.estimatedDuration} min', colors: colors, isDark: isDark, accent: accent)),
      const SizedBox(width: 12),
      Expanded(child: _buildDetailCard(icon: Icons.currency_rupee, label: 'Fare', value: '\u20B9${widget.request.estimatedFare.toStringAsFixed(0)}', colors: colors, isDark: isDark, accent: accent)),
    ]);
  }

  Widget _buildDetailCard({required IconData icon, required String label, required String value, required ColorScheme colors, required bool isDark, required Color accent}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.white10 : colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Icon(icon, color: accent, size: 20),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.dmSans(color: colors.onSurfaceVariant, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.dmSans(color: colors.onSurface, fontSize: 14, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildActionButtons(ColorScheme colors, bool isDark, Color accent) {
    return Row(children: [
      Expanded(child: GestureDetector(
        onTap: widget.onReject,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(color: AppColors.errorRed.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.errorRed)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.close, color: AppColors.errorRed, size: 24),
            const SizedBox(width: 8),
            Text('Reject', style: GoogleFonts.outfit(color: AppColors.errorRed, fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
        ),
      )),
      const SizedBox(width: 16),
      Expanded(child: GestureDetector(
        onTap: widget.onAccept,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [accent, accent.withValues(alpha: 0.8)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.check, color: isDark ? Colors.black : Colors.white, size: 24),
            const SizedBox(width: 8),
            Text('Accept', style: GoogleFonts.outfit(color: isDark ? Colors.black : Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
        ),
      )),
    ]);
  }
}
