import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_colors.dart';
import '../../data/models/incentive.dart';
import '../providers/incentives_providers.dart';

class IncentivesScreen extends ConsumerWidget {
  const IncentivesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeIncentivesAsync = ref.watch(activeIncentivesProvider);
    final completedIncentivesAsync = ref.watch(completedIncentivesProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.carbonGrey : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text('Incentives', style: GoogleFonts.outfit(color: colors.onSurface, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: colors.onSurface),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeIncentivesProvider);
          ref.invalidate(completedIncentivesProvider);
        },
        color: isDark ? AppColors.hyperLime : colors.primary,
        backgroundColor: isDark ? AppColors.carbonGrey : Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Active Incentives', style: GoogleFonts.outfit(color: colors.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              activeIncentivesAsync.when(
                data: (incentives) => incentives.isEmpty
                    ? _buildEmptyState('No active incentives', colors)
                    : Column(children: incentives.map((i) => _buildIncentiveCard(i, true, colors, isDark)).toList()),
                loading: () => Center(child: CircularProgressIndicator(color: isDark ? AppColors.hyperLime : colors.primary)),
                error: (e, s) => _buildErrorState(),
              ),
              const SizedBox(height: 24),
              Text('Completed', style: GoogleFonts.outfit(color: colors.onSurfaceVariant, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              completedIncentivesAsync.when(
                data: (incentives) => incentives.isEmpty
                    ? _buildEmptyState('No completed incentives', colors)
                    : Column(children: incentives.map((i) => _buildIncentiveCard(i, false, colors, isDark)).toList()),
                loading: () => const SizedBox(),
                error: (e, s) => const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncentiveCard(Incentive incentive, bool isActive, ColorScheme colors, bool isDark) {
    final accent = isDark ? AppColors.hyperLime : colors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.carbonGrey : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? accent.withValues(alpha: 0.3) : (isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
        ),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(incentive.title, style: GoogleFonts.outfit(color: colors.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent),
                ),
                child: Text('\u20B9${incentive.rewardAmount.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: accent, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(incentive.description, style: GoogleFonts.dmSans(color: colors.onSurfaceVariant, fontSize: 14)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: incentive.progressPercentage,
                    minHeight: 8,
                    backgroundColor: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(isActive ? accent : AppColors.successGreen),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${incentive.currentProgress}/${incentive.targetProgress}', style: GoogleFonts.dmSans(color: colors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          if (incentive.expiresAt != null && isActive) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, color: AppColors.warningAmber, size: 16),
                const SizedBox(width: 6),
                Text('Expires ${DateFormat('MMM dd, yyyy').format(incentive.expiresAt!)}', style: GoogleFonts.dmSans(color: AppColors.warningAmber, fontSize: 12)),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1);
  }

  Widget _buildEmptyState(String message, ColorScheme colors) {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(message, style: GoogleFonts.dmSans(color: colors.onSurfaceVariant))));
  }

  Widget _buildErrorState() {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('Failed to load incentives', style: GoogleFonts.dmSans(color: AppColors.errorRed))));
  }
}