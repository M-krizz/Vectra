import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';
import '../../data/models/rate_card.dart';
import '../providers/wallet_providers.dart';

class RateCardScreen extends ConsumerStatefulWidget {
  const RateCardScreen({super.key});

  @override
  ConsumerState<RateCardScreen> createState() => _RateCardScreenState();
}

class _RateCardScreenState extends ConsumerState<RateCardScreen> {
  VehicleType _selectedType = VehicleType.mini;

  @override
  Widget build(BuildContext context) {
    final rateCardsAsync = ref.watch(rateCardsProvider);

    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: AppColors.carbonGrey,
        title: Text(
          'Rate Card',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: rateCardsAsync.when(
        data: (rateCards) {
          final selectedCard = rateCards.firstWhere(
            (card) => card.vehicleType == _selectedType,
            orElse: () => rateCards.first,
          );
          return Column(
            children: [
              _buildVehicleTypeTabs(rateCards),
              Expanded(child: _buildRateCardContent(selectedCard)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.hyperLime)),
        error: (error, stack) => Center(
          child: Text('Failed to load rate cards', style: GoogleFonts.dmSans(color: AppColors.errorRed)),
        ),
      ),
    );
  }

  Widget _buildVehicleTypeTabs(List<RateCard> rateCards) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: rateCards.map((card) {
            final isSelected = card.vehicleType == _selectedType;
            return GestureDetector(
              onTap: () => setState(() => _selectedType = card.vehicleType),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.hyperLime : AppColors.carbonGrey,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? AppColors.hyperLime : AppColors.white10),
                ),
                child: Text(
                  card.vehicleType.name.toUpperCase(),
                  style: GoogleFonts.dmSans(
                    color: isSelected ? Colors.black : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRateCardContent(RateCard card) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard('Base Fare', '₹${card.baseFare.toStringAsFixed(0)}'),
          const SizedBox(height: 16),
          _buildDistanceSlabs(card.distanceSlabs),
          const SizedBox(height: 16),
          _buildInfoCard('Night Fare', '${((card.nightFareMultiplier - 1) * 100).toStringAsFixed(0)}% extra (${card.nightStartTime} - ${card.nightEndTime})'),
          const SizedBox(height: 16),
          _buildInfoCard('Waiting Charge', '₹${card.waitingChargePerMin.toStringAsFixed(0)}/min'),
          const SizedBox(height: 16),
          _buildInfoCard('Cancellation Fee', '₹${card.cancellationFee.toStringAsFixed(0)}'),
          if (card.surgeMultiplier != null) ...[
            const SizedBox(height: 16),
            _buildInfoCard('Current Surge', '${card.surgeMultiplier!.toStringAsFixed(1)}x', color: AppColors.warningAmber),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color?.withOpacity(0.3) ?? AppColors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.dmSans(color: AppColors.white70, fontSize: 14)),
          Text(value, style: GoogleFonts.outfit(color: color ?? Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDistanceSlabs(List<DistanceSlab> slabs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Distance Slabs', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...slabs.map((slab) {
            final range = slab.maxDistance != null
                ? '${slab.minDistance.toStringAsFixed(0)} - ${slab.maxDistance!.toStringAsFixed(0)} km'
                : '${slab.minDistance.toStringAsFixed(0)}+ km';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(range, style: GoogleFonts.dmSans(color: AppColors.white70, fontSize: 14)),
                  Text('₹${slab.ratePerKm.toStringAsFixed(1)}/km', style: GoogleFonts.dmSans(color: AppColors.hyperLime, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
