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

    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: AppColors.carbonGrey,
        title: Text('Incentives', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeIncentivesProvider);
          ref.invalidate(completedIncentivesProvider);
        },
        color: AppColors.hyperLime,
        backgroundColor: AppColors.carbonGrey,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Active Incentives', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              activeIncentivesAsync.when(
                data: (incentives) => incentives.isEmpty
                    ? _buildEmptyState('No active incentives')
                    : Column(children: incentives.map((i) => _buildIncentiveCard(i, true)).toList()),
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.hyperLime)),
                error: (e, s) => _buildErrorState(),
              ),
              const SizedBox(height: 24),
              Text('Completed', style: GoogleFonts.outfit(color: AppColors.white70, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              completedIncentivesAsync.when(
                data: (incentives) => incentives.isEmpty
                    ? _buildEmptyState('No completed incentives')
                    : Column(children: incentives.map((i) => _buildIncentiveCard(i, false)).toList()),
                loading: () => const SizedBox(),
                error: (e, s) => const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncentiveCard(Incentive incentive, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? AppColors.hyperLime.withOpacity(0.3) : AppColors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(incentive.title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.hyperLime.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.hyperLime),
                ),
                child: Text('₹${incentive.rewardAmount.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: AppColors.hyperLime, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(incentive.description, style: GoogleFonts.dmSans(color: AppColors.white70, fontSize: 14)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: incentive.progressPercentage,
                    minHeight: 8,
                    backgroundColor: AppColors.white10,
                    valueColor: AlwaysStoppedAnimation(isActive ? AppColors.hyperLime : AppColors.successGreen),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${incentive.currentProgress}/${incentive.targetProgress}', style: GoogleFonts.dmSans(color: AppColors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
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

  Widget _buildEmptyState(String message) {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(message, style: GoogleFonts.dmSans(color: AppColors.white50))));
  }

  Widget _buildErrorState() {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('Failed to load incentives', style: GoogleFonts.dmSans(color: AppColors.errorRed))));
  }
}
