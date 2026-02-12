import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../shared/widgets/active_eco_background.dart';

/// Driver Trip History Screen
/// Shows past trips with details and filters
class DriverTripHistoryScreen extends StatefulWidget {
  const DriverTripHistoryScreen({super.key});

  @override
  State<DriverTripHistoryScreen> createState() => _DriverTripHistoryScreenState();
}

class _DriverTripHistoryScreenState extends State<DriverTripHistoryScreen> {
  String _selectedFilter = 'All';
  
  // Mock trip data
  final List<Map<String, dynamic>> _trips = [
    {
      'id': 'TRIP001',
      'riderName': 'Priya Sharma',
      'pickup': 'MG Road Metro',
      'drop': 'Koramangala 5th Block',
      'date': '2026-02-07',
      'time': '14:30',
      'distance': 5.2,
      'fare': 185.0,
      'rating': 5,
      'status': 'completed',
      'co2Saved': 2.4,
    },
    {
      'id': 'TRIP002',
      'riderName': 'Rahul Verma',
      'pickup': 'Indiranagar',
      'drop': 'Whitefield',
      'date': '2026-02-07',
      'time': '12:15',
      'distance': 12.8,
      'fare': 420.0,
      'rating': 4,
      'status': 'completed',
      'co2Saved': 5.8,
    },
    {
      'id': 'TRIP003',
      'riderName': 'Anjali Reddy',
      'pickup': 'HSR Layout',
      'drop': 'Electronic City',
      'date': '2026-02-07',
      'time': '10:00',
      'distance': 8.5,
      'fare': 295.0,
      'rating': 5,
      'status': 'completed',
      'co2Saved': 3.9,
    },
    {
      'id': 'TRIP004',
      'riderName': 'Vikram Singh',
      'pickup': 'Jayanagar',
      'drop': 'Banashankari',
      'date': '2026-02-06',
      'time': '18:45',
      'distance': 4.2,
      'fare': 152.0,
      'rating': 4,
      'status': 'completed',
      'co2Saved': 1.9,
    },
    {
      'id': 'TRIP005',
      'riderName': 'Sneha Patel',
      'pickup': 'Marathahalli',
      'drop': 'Bellandur',
      'date': '2026-02-06',
      'time': '16:20',
      'distance': 3.8,
      'fare': 138.0,
      'rating': 5,
      'status': 'completed',
      'co2Saved': 1.7,
    },
  ];

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
                _buildFilterChips(),
                Expanded(
                  child: _buildTripsList(),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trip History',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_trips.length} trips',
                  style: GoogleFonts.dmSans(
                    color: AppColors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Search trips
            },
            icon: const Icon(Icons.search, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.white10,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Today', 'This Week', 'This Month'];
    
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          
          return Padding(
            padding: EdgeInsets.only(right: index < filters.length - 1 ? 12 : 0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [AppColors.hyperLime, AppColors.neonGreen],
                        )
                      : null,
                  color: isSelected ? null : AppColors.white10,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : AppColors.white20,
                  ),
                ),
                child: Text(
                  filter,
                  style: GoogleFonts.dmSans(
                    color: isSelected ? Colors.black : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms);
  }

  Widget _buildTripsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _trips.length,
      itemBuilder: (context, index) {
        final trip = _trips[index];
        return _buildTripCard(trip, index);
      },
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip, int index) {
    return GestureDetector(
      onTap: () {
        _showTripDetails(trip);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.carbonGrey.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.hyperLime, AppColors.neonGreen],
                    ),
                  ),
                  child: const Icon(Icons.person, color: Colors.black, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip['riderName'],
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          ...List.generate(
                            trip['rating'],
                            (i) => const Icon(
                              Icons.star,
                              color: AppColors.neonGreen,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${trip['date']} • ${trip['time']}',
                            style: GoogleFonts.dmSans(
                              color: AppColors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${trip['fare'].toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                    color: AppColors.hyperLime,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: AppColors.white10),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTripLocation(
                    Icons.my_location,
                    trip['pickup'],
                  ),
                ),
                Container(
                  width: 40,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.hyperLime, AppColors.neonGreen],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                Expanded(
                  child: _buildTripLocation(
                    Icons.location_on,
                    trip['drop'],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildTripStat(Icons.route, '${trip['distance']} km'),
                const SizedBox(width: 16),
                _buildTripStat(Icons.eco_outlined, '${trip['co2Saved']} kg CO₂'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.successGreen.withOpacity(0.5)),
                  ),
                  child: Text(
                    trip['status'].toUpperCase(),
                    style: GoogleFonts.dmSans(
                      color: AppColors.successGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(delay: (300 + index * 100).ms, duration: 600.ms).slideX(begin: 0.2),
    );
  }

  Widget _buildTripLocation(IconData icon, String location) {
    return Row(
      children: [
        Icon(icon, color: AppColors.hyperLime, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            location,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTripStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.white70, size: 16),
        const SizedBox(width: 6),
        Text(
          value,
          style: GoogleFonts.dmSans(
            color: AppColors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showTripDetails(Map<String, dynamic> trip) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.carbonGrey.withOpacity(0.95),
              AppColors.voidBlack.withOpacity(0.95),
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.white10),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.white20,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    'Trip Details',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.white10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Trip ID', trip['id']),
                    const SizedBox(height: 16),
                    _buildDetailRow('Rider', trip['riderName']),
                    const SizedBox(height: 16),
                    _buildDetailRow('Date & Time', '${trip['date']} at ${trip['time']}'),
                    const SizedBox(height: 24),
                    Divider(color: AppColors.white10),
                    const SizedBox(height: 24),
                    _buildDetailRow('Pickup', trip['pickup']),
                    const SizedBox(height: 16),
                    _buildDetailRow('Drop', trip['drop']),
                    const SizedBox(height: 16),
                    _buildDetailRow('Distance', '${trip['distance']} km'),
                    const SizedBox(height: 24),
                    Divider(color: AppColors.white10),
                    const SizedBox(height: 24),
                    _buildDetailRow('Base Fare', '₹${(trip['fare'] * 0.85).toStringAsFixed(2)}'),
                    const SizedBox(height: 16),
                    _buildDetailRow('Platform Fee', '-₹${(trip['fare'] * 0.15).toStringAsFixed(2)}'),
                    const SizedBox(height: 16),
                    _buildDetailRow('Total Earned', '₹${trip['fare'].toStringAsFixed(2)}', isHighlight: true),
                    const SizedBox(height: 24),
                    Divider(color: AppColors.white10),
                    const SizedBox(height: 24),
                    _buildDetailRow('CO₂ Saved', '${trip['co2Saved']} kg', isEco: true),
                    const SizedBox(height: 16),
                    _buildDetailRow('Rating', '${trip['rating']} stars'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate().slideY(begin: 0.3, curve: Curves.easeOutCubic),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false, bool isEco = false}) {
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
            color: isEco
                ? AppColors.successGreen
                : (isHighlight ? AppColors.hyperLime : Colors.white),
            fontSize: isHighlight ? 18 : 14,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
