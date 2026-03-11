import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';
import '../providers/ride_request_providers.dart';
import '../../../../core/socket/socket_service.dart';
import '../../data/models/ride_request.dart';
import 'active_trip_screen.dart';

/// Dedicated screen displaying all incoming ride requests received via
/// WebSocket. Drivers can accept or decline each request individually.
class IncomingRidesScreen extends ConsumerStatefulWidget {
  const IncomingRidesScreen({super.key});

  @override
  ConsumerState<IncomingRidesScreen> createState() =>
      _IncomingRidesScreenState();
}

class _IncomingRidesScreenState extends ConsumerState<IncomingRidesScreen> {
  /// Local list of pending ride offers, newest first.
  final List<_RideOffer> _pendingOffers = [];
  StreamSubscription<Map<String, dynamic>>? _offerSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _listen());
  }

  void _listen() {
    final socketService = ref.read(socketServiceProvider);
    _offerSubscription = socketService.rideOfferStream.listen((data) {
      if (!mounted) return;
      final request = RideRequest.fromJson(data);
      setState(() {
        // Insert at front so newest rides appear at the top
        _pendingOffers.insert(0, _RideOffer(request: request));
      });
    });
  }

  @override
  void dispose() {
    _offerSubscription?.cancel();
    super.dispose();
  }

  void _accept(_RideOffer offer) async {
    // Push current request into Riverpod so DriverDashboardScreen handles it
    ref
        .read(rideRequestProvider.notifier)
        .setRideRequest(offer.request);

    final trip = await ref
        .read(rideRequestProvider.notifier)
        .acceptCurrentRequest();

    if (!mounted) return;

    setState(() => _pendingOffers.remove(offer));

    if (trip != null) {
      ref.read(activeTripProvider.notifier).setTrip(trip);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ActiveTripScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not accept the ride. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _decline(_RideOffer offer) async {
    await ref
        .read(ridesRepositoryProvider)
        .rejectRide(offer.request.id);
    if (mounted) setState(() => _pendingOffers.remove(offer));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.carbonGrey : AppColors.background;
    final cardBg = isDark ? const Color(0xFF263142) : AppColors.cardBackground;
    final textPrimary =
        isDark ? Colors.white : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.white70 : AppColors.textSecondary;
    final accent = isDark ? AppColors.hyperLime : AppColors.primary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(color: textPrimary),
        title: Text(
          'Available Rides',
          style: GoogleFonts.outfit(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_pendingOffers.isNotEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_pendingOffers.length}',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _pendingOffers.isEmpty
          ? _buildEmpty(textSecondary)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pendingOffers.length,
              itemBuilder: (context, index) {
                final offer = _pendingOffers[index];
                return _RideRequestCard(
                  key: ValueKey(offer.request.id),
                  offer: offer,
                  cardBg: cardBg,
                  accent: accent,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  isDark: isDark,
                  onAccept: () => _accept(offer),
                  onDecline: () => _decline(offer),
                );
              },
            ),
    );
  }

  Widget _buildEmpty(Color textSecondary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_car_outlined,
              size: 72, color: textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'No rides available right now',
            style: GoogleFonts.outfit(
              fontSize: 18,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New requests will appear here in real time',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Data wrapper (can hold expiry timer state)
// ─────────────────────────────────────────────

class _RideOffer {
  final RideRequest request;
  _RideOffer({required this.request});
}

// ─────────────────────────────────────────────
// Card widget for a single incoming ride offer
// ─────────────────────────────────────────────

class _RideRequestCard extends StatefulWidget {
  final _RideOffer offer;
  final Color cardBg;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _RideRequestCard({
    super.key,
    required this.offer,
    required this.cardBg,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<_RideRequestCard> createState() => _RideRequestCardState();
}

class _RideRequestCardState extends State<_RideRequestCard> {
  static const int _timeoutSeconds = 20;
  int _remaining = _timeoutSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_remaining <= 1) {
        t.cancel();
        widget.onDecline();
      } else {
        setState(() => _remaining--);
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
    final r = widget.offer.request;
    final isUrgent = _remaining <= 5;
    final timerColor = isUrgent ? AppColors.errorRed : widget.accent;
    final border = widget.isDark
        ? AppColors.white10
        : Colors.grey.withValues(alpha: 0.15);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: timerColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: timerColor.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: fare + timer ──────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${r.estimatedFare.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: widget.accent,
                      ),
                    ),
                    Text(
                      '${r.estimatedDistance.toStringAsFixed(1)} km • ${r.estimatedDuration} min',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: widget.textSecondary,
                      ),
                    ),
                  ],
                ),
                _CircularTimer(
                  remaining: _remaining,
                  total: _timeoutSeconds,
                  color: timerColor,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Rider info ────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      widget.accent.withValues(alpha: 0.15),
                  child: Icon(Icons.person,
                      size: 22, color: widget.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.riderName,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: widget.textPrimary,
                        ),
                      ),
                      if (r.riderRating != null)
                        Row(
                          children: [
                            Icon(Icons.star_rounded,
                                size: 14,
                                color: AppColors.warning),
                            const SizedBox(width: 2),
                            Text(
                              r.riderRating!.toStringAsFixed(1),
                              style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: widget.textSecondary),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (r.vehicleType != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      r.vehicleType!,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: widget.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Route ─────────────────────────────────────────────
            _LocationRow(
              icon: Icons.my_location_rounded,
              iconColor: widget.isDark ? AppColors.neonGreen : AppColors.primary,
              label: 'Pickup',
              address: r.pickupAddress,
              textPrimary: widget.textPrimary,
              textSecondary: widget.textSecondary,
              border: border,
              cardBg: widget.cardBg,
              isDark: widget.isDark,
            ),
            const SizedBox(height: 8),
            _LocationRow(
              icon: Icons.location_on_rounded,
              iconColor: AppColors.errorRed,
              label: 'Drop-off',
              address: r.dropoffAddress,
              textPrimary: widget.textPrimary,
              textSecondary: widget.textSecondary,
              border: border,
              cardBg: widget.cardBg,
              isDark: widget.isDark,
            ),

            const SizedBox(height: 20),

            // ── Action buttons ─────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onDecline,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.errorRed),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Decline',
                      style: GoogleFonts.outfit(
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: widget.onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Accept Ride',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}

// ─────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────

class _CircularTimer extends StatelessWidget {
  final int remaining;
  final int total;
  final Color color;

  const _CircularTimer({
    required this.remaining,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: remaining / total,
            strokeWidth: 5,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Text(
            '$remaining',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String address;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color cardBg;
  final bool isDark;

  const _LocationRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.address,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.cardBg,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  address.isNotEmpty ? address : '—',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
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
}
