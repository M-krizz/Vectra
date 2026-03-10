import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';
import '../providers/map_home_providers.dart';

class EarningsCard extends ConsumerWidget {
  final VoidCallback? onTap;
  const EarningsCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.hyperLime : colors.primary;
    final earnings = ref.watch(todayEarningsProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.carbonGrey.withValues(alpha: 0.9) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
          boxShadow: isDark
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.account_balance_wallet_outlined, color: accent, size: 24),
            const SizedBox(width: 12),
            Text("Today's Earnings", style: GoogleFonts.dmSans(color: colors.onSurfaceVariant, fontSize: 14)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: colors.onSurfaceVariant.withValues(alpha: 0.5), size: 14),
          ]),
          const SizedBox(height: 12),
          Text('\u{20B9}${earnings.totalAmount.toStringAsFixed(2)}', style: GoogleFonts.outfit(color: accent, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${earnings.tripCount} trips completed', style: GoogleFonts.dmSans(color: colors.onSurfaceVariant, fontSize: 14)),
          const SizedBox(height: 16),
          Row(children: [
            _buildMiniStat(icon: Icons.access_time, value: '${earnings.onlineHours.toStringAsFixed(1)}h', label: 'Online', colors: colors),
            const SizedBox(width: 24),
            _buildMiniStat(icon: Icons.eco_outlined, value: '${earnings.co2Saved.toStringAsFixed(1)}kg', label: 'CO\u{2082} Saved', valueColor: AppColors.successGreen, colors: colors),
          ]),
        ]),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideX(begin: -0.1);
  }

  Widget _buildMiniStat({required IconData icon, required String value, required String label, Color? valueColor, required ColorScheme colors}) {
    return Row(children: [
      Icon(icon, color: colors.onSurfaceVariant, size: 16),
      const SizedBox(width: 6),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: GoogleFonts.dmSans(color: valueColor ?? colors.onSurface, fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.dmSans(color: colors.onSurfaceVariant, fontSize: 10)),
      ]),
    ]);
  }
}

class EarningsChip extends ConsumerWidget {
  final VoidCallback? onTap;
  const EarningsChip({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.hyperLime : colors.primary;
    final earnings = ref.watch(todayEarningsProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.carbonGrey.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.account_balance_wallet, color: accent, size: 20),
          const SizedBox(width: 8),
          Text('\u{20B9}${earnings.totalAmount.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: accent, fontSize: 18, fontWeight: FontWeight.bold)),
          Container(margin: const EdgeInsets.symmetric(horizontal: 12), width: 1, height: 20, color: isDark ? AppColors.white20 : colors.outline.withValues(alpha: 0.3)),
          Text('${earnings.tripCount}', style: GoogleFonts.dmSans(color: colors.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text('trips', style: GoogleFonts.dmSans(color: colors.onSurfaceVariant, fontSize: 12)),
        ]),
      ),
    );
  }
}
