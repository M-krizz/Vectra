import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../shared/widgets/active_eco_background.dart';

/// Driver Earnings Dashboard
/// Shows earnings breakdown, statistics, and payout information
class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Mock data
  final double _todayEarnings = 2847.50;
  final double _weekEarnings = 18234.75;
  final double _monthEarnings = 67890.25;
  final int _todayTrips = 12;
  final int _weekTrips = 87;
  final int _monthTrips = 342;
  final double _averageFare = 237.08;
  final double _totalCo2Saved = 145.6;

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
      body: Stack(
        children: [
          const ActiveEcoBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEarningsTab('Today', _todayEarnings, _todayTrips),
                      _buildEarningsTab('This Week', _weekEarnings, _weekTrips),
                      _buildEarningsTab('This Month', _monthEarnings, _monthTrips),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.white10,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Earnings',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              // Download report
            },
            icon: const Icon(Icons.download_outlined, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.white10,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white10),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.hyperLime, AppColors.neonGreen],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.black,
        unselectedLabelColor: AppColors.white70,
        labelStyle: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        tabs: const [
          Tab(text: 'Today'),
          Tab(text: 'Week'),
          Tab(text: 'Month'),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms);
  }

  Widget _buildEarningsTab(String period, double earnings, int trips) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTotalEarningsCard(earnings, trips),
          const SizedBox(height: 24),
          _buildStatsGrid(),
          const SizedBox(height: 24),
          _buildEarningsBreakdown(),
          const SizedBox(height: 24),
          _buildPayoutInfo(),
        ],
      ),
    );
  }

  Widget _buildTotalEarningsCard(double earnings, int trips) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.hyperLime.withOpacity(0.2),
            AppColors.neonGreen.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.hyperLime.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.hyperLime.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  color: AppColors.hyperLime, size: 28),
              const SizedBox(width: 12),
              Text(
                'Total Earnings',
                style: GoogleFonts.dmSans(
                  color: AppColors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '₹${earnings.toStringAsFixed(2)}',
            style: GoogleFonts.outfit(
              color: AppColors.hyperLime,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$trips trips completed',
            style: GoogleFonts.dmSans(
              color: AppColors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.trending_up,
                label: 'Avg Fare',
                value: '₹${_averageFare.toStringAsFixed(0)}',
                color: AppColors.neonGreen,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.eco_outlined,
                label: 'CO₂ Saved',
                value: '${_totalCo2Saved.toStringAsFixed(1)} kg',
                color: AppColors.successGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.access_time,
                label: 'Online Hours',
                value: '8.5 hrs',
                color: AppColors.hyperLime,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.star_rounded,
                label: 'Rating',
                value: '4.8',
                color: AppColors.neonGreen,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 600.ms);
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: AppColors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Breakdown',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.carbonGrey.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.white10),
          ),
          child: Column(
            children: [
              _buildBreakdownRow('Base Fare', 2450.00),
              const SizedBox(height: 12),
              _buildBreakdownRow('Surge Pricing', 320.50),
              const SizedBox(height: 12),
              _buildBreakdownRow('Tips', 150.00),
              const SizedBox(height: 12),
              _buildBreakdownRow('Bonuses', 200.00),
              const SizedBox(height: 16),
              Divider(color: AppColors.white10),
              const SizedBox(height: 16),
              _buildBreakdownRow('Platform Fee', -273.00, isDeduction: true),
              const SizedBox(height: 16),
              Divider(color: AppColors.white10),
              const SizedBox(height: 16),
              _buildBreakdownRow('Net Earnings', _todayEarnings, isTotal: true),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms, duration: 600.ms);
  }

  Widget _buildBreakdownRow(String label, double amount,
      {bool isDeduction = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: isTotal ? Colors.white : AppColors.white70,
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '${isDeduction ? '-' : ''}₹${amount.abs().toStringAsFixed(2)}',
          style: GoogleFonts.outfit(
            color: isDeduction
                ? AppColors.errorRed
                : (isTotal ? AppColors.hyperLime : Colors.white),
            fontSize: isTotal ? 20 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPayoutInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payout Information',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.carbonGrey.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.white10),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.hyperLime, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Payouts are processed weekly on Mondays',
                      style: GoogleFonts.dmSans(
                        color: AppColors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildPayoutDetail('Next Payout', 'Monday, Feb 10'),
              const SizedBox(height: 12),
              _buildPayoutDetail('Pending Amount', '₹18,234.75'),
              const SizedBox(height: 12),
              _buildPayoutDetail('Bank Account', '****1234'),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms, duration: 600.ms);
  }

  Widget _buildPayoutDetail(String label, String value) {
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
          value,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
