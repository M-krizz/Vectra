import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../shared/widgets/active_eco_background.dart';
import '../features/rides/data/models/trip.dart';
import '../features/rides/presentation/providers/ride_request_providers.dart';

/// FutureProvider that fetches trip history from the repository
final tripHistoryProvider = FutureProvider<List<Trip>>((ref) async {
  final repository = ref.watch(ridesRepositoryProvider);
  return repository.getTripHistory();
});

class DriverTripHistoryScreen extends ConsumerStatefulWidget {
  const DriverTripHistoryScreen({super.key});

  @override
  ConsumerState<DriverTripHistoryScreen> createState() => _DriverTripHistoryScreenState();
}

class _DriverTripHistoryScreenState extends ConsumerState<DriverTripHistoryScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final tripsAsync = ref.watch(tripHistoryProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          if (isDark) const ActiveEcoBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(colors, isDark, tripsAsync),
                _buildFilterChips(colors, isDark),
                Expanded(
                  child: tripsAsync.when(
                    data: (trips) => trips.isEmpty
                        ? Center(child: Text('No trips yet', style: GoogleFonts.dmSans(color: colors.onSurfaceVariant, fontSize: 16)))
                        : _buildTripsList(trips, colors, isDark),
                    loading: () => Center(child: CircularProgressIndicator(color: isDark ? AppColors.hyperLime : colors.primary)),
                    error: (e, _) => Center(child: Text('Failed to load trips', style: GoogleFonts.dmSans(color: colors.error))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors, bool isDark, AsyncValue<List<Trip>> tripsAsync) {
    final count = tripsAsync.valueOrNull?.length ?? 0;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new, color: colors.onSurface),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Trip History', style: GoogleFonts.outfit(color: colors.onSurface, fontSize: 28, fontWeight: FontWeight.bold)),
              Text('$count trips', style: GoogleFonts.dmSans(color: colors.onSurfaceVariant, fontSize: 14)),
            ]),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildFilterChips(ColorScheme colors, bool isDark) {
    final filters = ['All', 'Today', 'This Week', 'This Month'];
    final activeColor = isDark ? AppColors.hyperLime : AppColors.primary;
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
              onTap: () => setState(() => _selectedFilter = filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected && isDark ? const LinearGradient(colors: [AppColors.hyperLime, AppColors.neonGreen]) : null,
                  color: isSelected ? (isDark ? null : activeColor) : (isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? Colors.transparent : (isDark ? AppColors.white20 : colors.outline.withValues(alpha: 0.3))),
                ),
                child: Text(
                  filter,
                  style: GoogleFonts.dmSans(
                    color: isSelected ? (isDark ? Colors.black : Colors.white) : colors.onSurface,
                    fontSize: 14, fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms);
  }

  Widget _buildTripsList(List<Trip> trips, ColorScheme colors, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: trips.length,
      itemBuilder: (context, index) => _buildTripCard(trips[index], index, colors, isDark),
    );
  }

  Widget _buildTripCard(Trip trip, int index, ColorScheme colors, bool isDark) {
    final accentColor = isDark ? AppColors.hyperLime : AppColors.primary;
    final dateStr = trip.completedAt != null ? DateFormat('yyyy-MM-dd').format(trip.completedAt!) : '';
    final timeStr = trip.completedAt != null ? DateFormat('HH:mm').format(trip.completedAt!) : '';
    final ratingInt = (trip.riderRating ?? 5).round();
    final co2Saved = (trip.distance * 0.45).toStringAsFixed(1);

    return GestureDetector(
      onTap: () => _showTripDetails(trip, colors, isDark),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.carbonGrey.withValues(alpha: 0.6) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.hyperLime, AppColors.neonGreen])),
                child: const Icon(Icons.person, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(trip.riderName, style: GoogleFonts.outfit(color: colors.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
                Row(children: [
                  ...List.generate(ratingInt, (i) => Icon(Icons.star, color: isDark ? AppColors.neonGreen : AppColors.primary, size: 14)),
                  const SizedBox(width: 8),
                  Text('$dateStr \u2022 $timeStr', style: GoogleFonts.dmSans(color: colors.onSurfaceVariant, fontSize: 12)),
                ]),
              ])),
              Text('\u20B9${trip.fare.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: accentColor, fontSize: 20, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),
            Divider(color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _buildTripLocation(Icons.my_location, trip.pickupAddress, colors, isDark)),
              Container(width: 40, height: 2, margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.hyperLime, AppColors.neonGreen]), borderRadius: BorderRadius.circular(1))),
              Expanded(child: _buildTripLocation(Icons.location_on, trip.dropoffAddress, colors, isDark)),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              _buildTripStat(Icons.route, '${trip.distance} km', colors),
              const SizedBox(width: 16),
              _buildTripStat(Icons.eco_outlined, '$co2Saved kg CO\u2082', colors),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.successGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.5))),
                child: Text(trip.status.name.toUpperCase(), style: GoogleFonts.dmSans(color: AppColors.successGreen, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ]),
          ],
        ),
      ).animate().fadeIn(delay: (300 + index * 100).ms, duration: 600.ms).slideX(begin: 0.2),
    );
  }

  Widget _buildTripLocation(IconData icon, String location, ColorScheme colors, bool isDark) {
    return Row(children: [
      Icon(icon, color: isDark ? AppColors.hyperLime : AppColors.primary, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(location, style: GoogleFonts.dmSans(color: colors.onSurface, fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]);
  }

  Widget _buildTripStat(IconData icon, String value, ColorScheme colors) {
    return Row(children: [
      Icon(icon, color: colors.onSurfaceVariant, size: 16),
      const SizedBox(width: 6),
      Text(value, style: GoogleFonts.dmSans(color: colors.onSurfaceVariant, fontSize: 12)),
    ]);
  }

  void _showTripDetails(Trip trip, ColorScheme colors, bool isDark) {
    final dateStr = trip.completedAt != null ? DateFormat('yyyy-MM-dd').format(trip.completedAt!) : 'N/A';
    final timeStr = trip.completedAt != null ? DateFormat('HH:mm').format(trip.completedAt!) : '';
    final co2Saved = (trip.distance * 0.45).toStringAsFixed(1);
    final ratingInt = (trip.riderRating ?? 5).round();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? AppColors.carbonGrey.withValues(alpha: 0.98) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? AppColors.white20 : colors.outline.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(children: [
                Text('Trip Details', style: GoogleFonts.outfit(color: colors.onSurface, fontSize: 24, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: colors.onSurface),
                  style: IconButton.styleFrom(backgroundColor: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.1)),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildDetailRow('Trip ID', trip.id, colors, isDark),
                  const SizedBox(height: 16),
                  _buildDetailRow('Rider', trip.riderName, colors, isDark),
                  const SizedBox(height: 16),
                  _buildDetailRow('Date & Time', '$dateStr at $timeStr', colors, isDark),
                  const SizedBox(height: 24),
                  Divider(color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
                  const SizedBox(height: 24),
                  _buildDetailRow('Pickup', trip.pickupAddress, colors, isDark),
                  const SizedBox(height: 16),
                  _buildDetailRow('Drop', trip.dropoffAddress, colors, isDark),
                  const SizedBox(height: 16),
                  _buildDetailRow('Distance', '${trip.distance.toStringAsFixed(1)} km', colors, isDark),
                  const SizedBox(height: 24),
                  Divider(color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
                  const SizedBox(height: 24),
                  _buildDetailRow('Base Fare', '\u20B9${(trip.fare * 0.85).toStringAsFixed(2)}', colors, isDark),
                  const SizedBox(height: 16),
                  _buildDetailRow('Platform Fee', '-\u20B9${(trip.fare * 0.15).toStringAsFixed(2)}', colors, isDark),
                  const SizedBox(height: 16),
                  _buildDetailRow('Total Earned', '\u20B9${trip.fare.toStringAsFixed(2)}', colors, isDark, isHighlight: true),
                  const SizedBox(height: 24),
                  Divider(color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
                  const SizedBox(height: 24),
                  _buildDetailRow('CO\u2082 Saved', '$co2Saved kg', colors, isDark, isEco: true),
                  const SizedBox(height: 16),
                  _buildDetailRow('Rating', '$ratingInt stars', colors, isDark),
                ]),
              ),
            ),
          ],
        ),
      ).animate().slideY(begin: 0.3, curve: Curves.easeOutCubic),
    );
  }

  Widget _buildDetailRow(String label, String value, ColorScheme colors, bool isDark, {bool isHighlight = false, bool isEco = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.dmSans(color: colors.onSurfaceVariant, fontSize: 14)),
        Text(
          value,
          style: GoogleFonts.dmSans(
            color: isEco ? AppColors.successGreen : (isHighlight ? (isDark ? AppColors.hyperLime : AppColors.primary) : colors.onSurface),
            fontSize: isHighlight ? 18 : 14,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
