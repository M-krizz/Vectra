import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_colors.dart';
import '../../data/models/incentive.dart';
import '../providers/incentives_providers.dart';

/// Premium Incentives Screen with Timeline and Tiers
class IncentivesScreen extends ConsumerStatefulWidget {
  const IncentivesScreen({super.key});

  @override
  ConsumerState<IncentivesScreen> createState() => _IncentivesScreenState();
}

class _IncentivesScreenState extends ConsumerState<IncentivesScreen> with SingleTickerProviderStateMixin {
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
        backgroundColor: AppColors.carbonGrey,
        elevation: 0,
        title: Text('Incentives', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.help_outline, color: Colors.white, size: 18),
            label: Text('Help', style: GoogleFonts.dmSans(color: Colors.white)),
            style: TextButton.styleFrom(backgroundColor: AppColors.white10),
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.hyperLime,
          unselectedLabelColor: AppColors.white50,
          indicatorColor: AppColors.hyperLime,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Bonus'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyIncentives(),
          _buildPlaceholder('Weekly Incentives coming soon'),
          _buildBonusTimeline(), // The reference Timeline View
        ],
      ),
    );
  }

  Widget _buildDailyIncentives() {
    final activeAsync = ref.watch(activeIncentivesProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.refresh(activeIncentivesProvider),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDateSelector(),
          const SizedBox(height: 24),
          activeAsync.when(
            data: (orders) => Column(children: orders.map((i) => _buildIncentiveCard(i)).toList()),
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.hyperLime)),
            error: (e, s) => Center(child: Text('Error loading', style: GoogleFonts.dmSans(color: AppColors.errorRed))),
          ),
        ],
      ),
    );
  }

  Widget _buildBonusTimeline() {
    // Mock data for the Premium Timeline View based on reference image
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Hero Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFA726), Color(0xFFFFCC80)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'Earn ₹5000 more',
                  style: GoogleFonts.outfit(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'by completing 550 rides',
                  style: GoogleFonts.dmSans(color: Colors.black87, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                  child: Text('Bike Taxi, Scooty', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 10)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Timeline Steps
          const SizedBox(height: 16),
          _buildTimelineStep(250, 1000, 50, true), // Active
          _buildTimelineStep(350, 1000, 0, false),
          _buildTimelineStep(450, 1000, 0, false),
          _buildTimelineStep(550, 2000, 0, false, isLast: true),

           const SizedBox(height: 32),
           // Cross-sell
           Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
               gradient: const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFFE040FB)]),
               borderRadius: BorderRadius.circular(16),
             ),
             child: Row(
               children: [
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text('Win cashback upto ₹400', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                       Text('by activating Food Delivery!', style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 12)),
                     ],
                   ),
                 ),
                 ElevatedButton(
                   onPressed: () {},
                   style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                   child: const Text('Start Now'),
                 ),
               ],
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(int rides, double prize, double progress, bool isActive, {bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Line
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? Colors.orange : AppColors.white10,
                  border: Border.all(color: isActive ? Colors.orangeAccent : Colors.transparent, width: 4),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.white10,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isActive ? AppColors.white10 : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isActive ? Border.all(color: Colors.orange.withOpacity(0.5)) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Complete $rides rides, and get',
                        style: GoogleFonts.dmSans(
                          color: isActive ? Colors.orange : AppColors.white50,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹ $prize',
                        style: GoogleFonts.outfit(
                          color: isActive ? Colors.orange : AppColors.white30,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                   Text(
                    'Target Date: 21-01-2026',
                    style: GoogleFonts.dmSans(color: AppColors.white30, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    // Current date logic would go here
    return SizedBox(
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           _buildDateItem('Jan', '11', false),
           const SizedBox(width: 12),
           _buildDateItem('Jan', '12', false),
           const SizedBox(width: 12),
           Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
               color: AppColors.white10,
               shape: BoxShape.circle,
               border: Border.all(color: AppColors.hyperLime),
             ),
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Text('Today', style: GoogleFonts.dmSans(color: AppColors.white70, fontSize: 10)),
                 Text('13', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
               ],
             ),
           ),
           const SizedBox(width: 12),
           _buildDateItem('Jan', '14', false),
        ],
      ),
    );
  }

  Widget _buildDateItem(String month, String day, bool isSelected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(month, style: GoogleFonts.dmSans(color: AppColors.white30, fontSize: 12)),
        Text(day, style: GoogleFonts.outfit(color: AppColors.white50, fontSize: 16)),
      ],
    );
  }

  Widget _buildIncentiveCard(Incentive incentive) {
    return Container(
      // ... Existing card logic
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
       decoration: BoxDecoration(
        color: AppColors.carbonGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(incentive.title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16)),
          Text(incentive.description, style: GoogleFonts.dmSans(color: AppColors.white50, fontSize: 12)),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: incentive.progressPercentage, color: AppColors.hyperLime, backgroundColor: AppColors.white10),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String text) {
    return Center(child: Text(text, style: GoogleFonts.dmSans(color: AppColors.white30)));
  }
}
