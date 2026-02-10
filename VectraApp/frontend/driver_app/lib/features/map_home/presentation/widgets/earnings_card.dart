import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';
import '../providers/map_home_providers.dart';

/// Premium Compact Earnings Card
class EarningsCard extends ConsumerWidget {
  final VoidCallback? onTap;

  const EarningsCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnings = ref.watch(todayEarningsProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.carbonGrey.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
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
          children: [
            // Icon Background
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.hyperLime.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.hyperLime,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            
            // Text Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Earnings',
                  style: GoogleFonts.dmSans(
                    color: AppColors.white50,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '₹${earnings.totalAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const Spacer(),
            
            // Trip Count Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.white10,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.white10),
              ),
              child: Row(
                children: [
                  Icon(Icons.directions_car, size: 14, color: AppColors.white70),
                  const SizedBox(width: 6),
                  Text(
                    '${earnings.tripCount}',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1);
  }
}
