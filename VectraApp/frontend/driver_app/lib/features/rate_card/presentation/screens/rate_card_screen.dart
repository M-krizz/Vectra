import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../theme/app_colors.dart';

/// Screen displaying the rate card for different service types
class RateCardScreen extends StatefulWidget {
  const RateCardScreen({super.key});

  @override
  State<RateCardScreen> createState() => _RateCardScreenState();
}

class _RateCardScreenState extends State<RateCardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: AppColors.voidBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Rate Card',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.help_outline, color: Colors.white, size: 18),
            label: Text(
              'Help',
              style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.white10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.hyperLime,
          unselectedLabelColor: AppColors.white50,
          indicatorColor: AppColors.hyperLime,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.dmSans(),
          tabs: const [
            Tab(text: 'Bike'),
            Tab(text: 'Parcel Delivery'),
            Tab(text: 'Scooty'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRateList('Bike'),
          _buildRateList('Parcel'), // Placeholder logic for now
          _buildRateList('Scooty'),
        ],
      ),
    );
  }

  Widget _buildRateList(String type) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Order Fare'),
          const SizedBox(height: 12),
          
          // Distance Fare Card
          Container(
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
                  'Distance Fare',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'For the kilometers travelled',
                  style: GoogleFonts.dmSans(color: AppColors.white50, fontSize: 12),
                ),
                const SizedBox(height: 16),
                _buildFareRow('0 to 5 km', '₹6.0', 'per km'), // Adjusted for premium pricing ;)
                _buildFareRow('5 to 10 km', '₹8.0', 'per km'),
                _buildFareRow('10 to 16 km', '₹10.0', 'per km'),
                _buildFareRow('16 to 100 km', '₹12.0', 'per km'),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

          const SizedBox(height: 16),

          // Time & Base Fare
          _buildSimpleFareCard('Time Fare', 'Time to complete the order', '₹1.0', 'per min'),
          const SizedBox(height: 12),
          _buildSimpleFareCard('Base Fare', 'For completing an order', '₹20', ''),

          const SizedBox(height: 24),
          _buildSectionHeader('Extra Fare'),
          const SizedBox(height: 12),

          // Extra Fares
          _buildSimpleFareCard('Long Pickup', 'After 2 km', '+ ₹3', 'per km'),
           const SizedBox(height: 12),
          _buildSimpleFareCard('Night Fare', '11:00pm - 6:00am', '+30%', 'on total fare'),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.hyperLime.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.hyperLime.withOpacity(0.3)),
      ),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: AppColors.hyperLime,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildFareRow(String label, String price, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(color: AppColors.white70, fontSize: 14),
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: price,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: GoogleFonts.dmSans(
                      color: AppColors.white50,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleFareCard(String title, String subtitle, String price, String unit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(color: AppColors.white50, fontSize: 12),
                ),
            ],
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: price,
                  style: GoogleFonts.outfit(
                    color: AppColors.hyperLime,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: GoogleFonts.dmSans(
                      color: AppColors.white50,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.1);
  }
}
