import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class FareBreakdown extends StatelessWidget {
  final double baseFare;
  final double distanceFare;
  final double? surgeFare;
  final double? discount;
  final double total;
  final String currency;

  const FareBreakdown({
    super.key,
    required this.baseFare,
    required this.distanceFare,
    this.surgeFare,
    this.discount,
    required this.total,
    this.currency = '₹',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fare Breakdown',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildFareRow('Base Fare', baseFare),
          const SizedBox(height: 12),
          _buildFareRow('Distance Fare', distanceFare),
          if (surgeFare != null) ...[
            const SizedBox(height: 12),
            _buildFareRow('Surge Charge', surgeFare!, color: Colors.orange),
          ],
          if (discount != null) ...[
            const SizedBox(height: 12),
            _buildFareRow('Discount', -discount!, color: AppColors.hyperLime),
          ],
          const SizedBox(height: 16),
          Divider(color: AppColors.white10),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.hyperLime, AppColors.neonGreen],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$currency${total.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFareRow(String label, double amount, {Color? color}) {
    final isNegative = amount < 0;
    final displayAmount = amount.abs();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: AppColors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          '${isNegative ? '-' : ''}$currency${displayAmount.toStringAsFixed(0)}',
          style: GoogleFonts.dmSans(
            color: color ?? Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// Compact fare display
class FareDisplay extends StatelessWidget {
  final double amount;
  final String currency;
  final String? label;

  const FareDisplay({
    super.key,
    required this.amount,
    this.currency = '₹',
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.hyperLime.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hyperLime),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: GoogleFonts.dmSans(
                color: AppColors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            '$currency${amount.toStringAsFixed(0)}',
            style: GoogleFonts.dmSans(
              color: AppColors.hyperLime,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
