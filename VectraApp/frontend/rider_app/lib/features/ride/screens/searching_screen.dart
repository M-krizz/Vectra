import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/app_theme.dart';
import '../bloc/ride_bloc.dart';

class SearchingScreen extends StatefulWidget {
  const SearchingScreen({super.key});

  @override
  State<SearchingScreen> createState() => _SearchingScreenState();
}

class _SearchingScreenState extends State<SearchingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _dots = 0;
  Timer? _dotsTimer;
  bool _cancelled = false;


  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Dots animation
    _dotsTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _dots = (_dots + 1) % 4);
    });

    // The actual driver search is handled by RideBloc when RideRequested
    // was dispatched from ride_options_screen. We just trigger the event if
    // the bloc is still in selectingVehicle state (i.e., user came here
    // directly without requesting yet).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<RideBloc>();
      if (bloc.state.status == RideStatus.selectingVehicle) {
        bloc.add(const RideRequested());
      }
    });
  }

  void _cancelRide() {
    _showCancelDialog();
  }

  void _showCancelDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CancelSheet(
        onCancel: (reason) {
          _cancelled = true;
          context.read<RideBloc>().add(RideCancelled(reason));
          // Pop sheet, then navigate home
          Navigator.of(context).pop();
          context.go('/home');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dots = '.' * _dots;
    return BlocListener<RideBloc, RideState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (ctx, state) {
        // noDriversFound is handled here (shell BlocListener handles other statuses)
        if (state.status == RideStatus.noDriversFound) {
          _showNoDriversDialog(ctx);
        }
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with route info
            BlocBuilder<RideBloc, RideState>(
              builder: (_, state) => _RouteBar(state: state),
            ),

            const Spacer(),

            // Pulse animation
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) {
                final scale = 1.0 + (_pulseController.value * 0.12);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(
                          alpha: 0.12 + _pulseController.value * 0.08),
                    ),
                    child: Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                        child: const Icon(Icons.search_rounded,
                            size: 36, color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            Text(
              'Finding a driver$dots',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please wait while we match you\nwith the nearest driver.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            // Tips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded,
                        size: 18, color: AppColors.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tip: Please be at the pickup point when the driver arrives.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Cancel button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _cancelRide,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Cancel Request',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),  // Scaffold
    );  // BlocListener
  }

  void _showNoDriversDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('No Drivers Found', textAlign: TextAlign.center),
        content: const Text(
          'We couldn\'t find a driver nearby right now. Please try again in a moment.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ctx.read<RideBloc>().add(const RideCleared());
              ctx.go('/home');
            },
            child: const Text('Back to Home'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ctx.read<RideBloc>().add(const RideRequested());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Try Again', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _dotsTimer?.cancel();
    super.dispose();
  }
}

// ─── Route bar ────────────────────────────────────────────────────────────

class _RouteBar extends StatelessWidget {
  final RideState state;
  const _RouteBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FA),
        border:
            Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32), shape: BoxShape.circle)),
              Container(
                  width: 1, height: 28, color: Colors.grey.shade300),
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.pickup?.name ?? 'Current Location',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                Text(
                  state.destination?.name ?? 'Destination',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              state.rideType == 'pool' ? '🚌 Pool' : '🚗 Solo',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cancel bottom sheet ──────────────────────────────────────────────────

class _CancelSheet extends StatefulWidget {
  final Function(String reason) onCancel;
  const _CancelSheet({required this.onCancel});

  @override
  State<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<_CancelSheet> {
  String? _reason;

  static const _reasons = [
    'Driver is too far away',
    'Changed my mind',
    'Entering wrong location',
    'Found another option',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Why are you cancelling?',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'This helps us improve our service.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ..._reasons.map((r) => RadioListTile<String>(
                value: r,
                groupValue: _reason,
                onChanged: (v) => setState(() => _reason = v),
                title: Text(r,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textPrimary)),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _reason == null
                  ? null
                  : () => widget.onCancel(_reason!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Confirm Cancel',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
