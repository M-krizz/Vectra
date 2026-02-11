import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';
import '../providers/map_home_providers.dart';

/// Today's earnings card widget
class EarningsCard extends ConsumerWidget {
  final VoidCallback? onTap;

  const EarningsCard({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnings = ref.watch(todayEarningsProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.carbonGrey.withOpacity(0.9),
              AppColors.carbonGrey.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.hyperLime,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  "Today's Earnings",
                  style: GoogleFonts.dmSans(
                    color: AppColors.white70,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.white50,
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '\u{20B9}${earnings.totalAmount.toStringAsFixed(2)}',
              style: GoogleFonts.outfit(
                color: AppColors.hyperLime,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${earnings.tripCount} trips completed',
              style: GoogleFonts.dmSans(
                color: AppColors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildMiniStat(
                  icon: Icons.access_time,
                  value: '${earnings.onlineHours.toStringAsFixed(1)}h',
                  label: 'Online',
                ),
                const SizedBox(width: 24),
                _buildMiniStat(
                  icon: Icons.eco_outlined,
                  value: '${earnings.co2Saved.toStringAsFixed(1)}kg',
                  label: 'CO\u{2082} Saved',
                  valueColor: AppColors.successGreen,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideX(begin: -0.1);
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String value,
    required String label,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.white50, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.dmSans(
                color: valueColor ?? Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: AppColors.white50,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Compact earnings chip for map overlay
class EarningsChip extends ConsumerWidget {
  final VoidCallback? onTap;

  const EarningsChip({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnings = ref.watch(todayEarningsProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.carbonGrey.withOpacity(0.95),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet,
              color: AppColors.hyperLime,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '\u{20B9}${earnings.totalAmount.toStringAsFixed(0)}',
              style: GoogleFonts.outfit(
                color: AppColors.hyperLime,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              width: 1,
              height: 20,
              color: AppColors.white20,
            ),
            Text(
              '${earnings.tripCount}',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'trips',
              style: GoogleFonts.dmSans(
                color: AppColors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
