import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

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
    this.currency = '\u20B9',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.hyperLime : colors.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.carbonGrey : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fare Breakdown',
            style: GoogleFonts.outfit(
              color: colors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildFareRow('Base Fare', baseFare, colors),
          const SizedBox(height: 12),
          _buildFareRow('Distance Fare', distanceFare, colors),
          if (surgeFare != null) ...[
            const SizedBox(height: 12),
            _buildFareRow('Surge Charge', surgeFare!, colors, color: Colors.orange),
          ],
          if (discount != null) ...[
            const SizedBox(height: 12),
            _buildFareRow('Discount', -discount!, colors, color: accent),
          ],
          const SizedBox(height: 16),
          Divider(color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.outfit(
                  color: colors.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppColors.hyperLime, AppColors.neonGreen]
                        : [colors.primary, colors.primary.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$currency${total.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                    color: isDark ? Colors.black : Colors.white,
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

  Widget _buildFareRow(String label, double amount, ColorScheme colors, {Color? color}) {
    final isNegative = amount < 0;
    final displayAmount = amount.abs();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: colors.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        Text(
          '${isNegative ? '-' : ''}$currency${displayAmount.toStringAsFixed(0)}',
          style: GoogleFonts.dmSans(
            color: color ?? colors.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class FareDisplay extends StatelessWidget {
  final double amount;
  final String currency;
  final String? label;

  const FareDisplay({
    super.key,
    required this.amount,
    this.currency = '\u20B9',
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.hyperLime : colors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: GoogleFonts.dmSans(
                color: colors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            '$currency${amount.toStringAsFixed(0)}',
            style: GoogleFonts.dmSans(
              color: accent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}