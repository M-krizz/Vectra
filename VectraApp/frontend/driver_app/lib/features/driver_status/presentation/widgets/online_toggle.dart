import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';
import '../providers/driver_status_providers.dart';

/// Online/Offline toggle widget for driver dashboard
class OnlineToggle extends ConsumerStatefulWidget {
  final VoidCallback? onStatusChanged;

  const OnlineToggle({
    super.key,
    this.onStatusChanged,
  });

  @override
  ConsumerState<OnlineToggle> createState() => _OnlineToggleState();
}

class _OnlineToggleState extends ConsumerState<OnlineToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleToggle() async {
    final statusNotifier = ref.read(driverStatusProvider.notifier);
    final currentState = ref.read(driverStatusProvider);

    // Show restriction message if can't go online
    if (!currentState.isOnline && currentState.statusRestriction != null) {
      _showRestrictionDialog(currentState.statusRestriction!);
      return;
    }

    final success = await statusNotifier.toggleStatus();

    if (success) {
      widget.onStatusChanged?.call();
    } else {
      final newState = ref.read(driverStatusProvider);
      if (newState.statusRestriction != null) {
        _showRestrictionDialog(newState.statusRestriction!);
      } else if (newState.error != null) {
        _showErrorSnackbar(newState.error!);
      }
    }
  }

  void _showRestrictionDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.carbonGrey,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.warningOrange, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warningOrange,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Cannot Go Online',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: AppColors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Got it',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error,
          style: GoogleFonts.dmSans(),
        ),
        backgroundColor: AppColors.errorRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusState = ref.watch(driverStatusProvider);
    final isOnline = statusState.isOnline;
    final isToggling = statusState.isToggling;

    return GestureDetector(
      onTap: isToggling ? null : _handleToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: isOnline
              ? const LinearGradient(
                  colors: [AppColors.hyperLime, AppColors.neonGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isOnline ? null : AppColors.carbonGrey.withOpacity(0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isOnline ? Colors.transparent : AppColors.white10,
            width: 2,
          ),
          boxShadow: isOnline
              ? [
                  BoxShadow(
                    color: AppColors.hyperLime.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 0,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline
                        ? Colors.black.withOpacity(0.2)
                        : AppColors.white10,
                    boxShadow: isOnline
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                  0.3 * _pulseController.value),
                              blurRadius: 20 * _pulseController.value,
                              spreadRadius: 5 * _pulseController.value,
                            ),
                          ]
                        : [],
                  ),
                  child: isToggling
                      ? Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: isOnline ? Colors.black : AppColors.white70,
                            ),
                          ),
                        )
                      : Icon(
                          isOnline ? Icons.power_settings_new : Icons.power_off,
                          size: 40,
                          color: isOnline ? Colors.black : AppColors.white70,
                        ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              isOnline ? "You're Online" : "You're Offline",
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isOnline ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isOnline
                  ? 'Ready to accept rides'
                  : 'Tap to go online and start earning',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: isOnline
                    ? Colors.black.withOpacity(0.7)
                    : AppColors.white70,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms).scale(
          begin: const Offset(0.95, 0.95),
        );
  }
}
