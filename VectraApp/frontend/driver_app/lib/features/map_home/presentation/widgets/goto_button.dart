import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../../theme/app_colors.dart';
import '../providers/map_home_providers.dart';

/// "Go To" destination filter button and dialog
class GotoButton extends ConsumerStatefulWidget {
  const GotoButton({super.key});

  @override
  ConsumerState<GotoButton> createState() => _GotoButtonState();
}

class _GotoButtonState extends ConsumerState<GotoButton> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapHomeProvider);
    final hasDestination = mapState.gotoDestination != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Main button
        GestureDetector(
          onTap: () {
            if (hasDestination) {
              ref.read(mapHomeProvider.notifier).clearGotoDestination();
            } else {
              setState(() => _isExpanded = !_isExpanded);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(
              horizontal: hasDestination ? 16 : 12,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: hasDestination ? AppColors.hyperLime : AppColors.carbonGrey,
              borderRadius: BorderRadius.circular(hasDestination ? 30 : 12),
              border: Border.all(
                color: hasDestination ? AppColors.hyperLime : AppColors.white10,
              ),
              boxShadow: [
                BoxShadow(
                  color: hasDestination
                      ? AppColors.hyperLime.withOpacity(0.3)
                      : Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasDestination ? Icons.close : Icons.near_me,
                  color: hasDestination ? Colors.black : Colors.white,
                  size: 20,
                ),
                if (hasDestination) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Go To Active',
                    style: GoogleFonts.dmSans(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Destination options
        if (_isExpanded)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.carbonGrey,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.white10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Go To Destination',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Only show rides heading towards:',
                  style: GoogleFonts.dmSans(
                    color: AppColors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDestinationOption(
                  'Koramangala',
                  LatLng(12.9352, 77.6245),
                ),
                _buildDestinationOption(
                  'Indiranagar',
                  LatLng(12.9784, 77.6408),
                ),
                _buildDestinationOption(
                  'Marathahalli',
                  LatLng(12.9569, 77.7011),
                ),
                _buildDestinationOption(
                  'Whitefield',
                  LatLng(12.9698, 77.7500),
                ),
                const SizedBox(height: 8),
                _buildCustomDestinationButton(),
              ],
            ),
          ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1),
      ],
    );
  }

  Widget _buildDestinationOption(String name, LatLng location) {
    return GestureDetector(
      onTap: () {
        ref.read(mapHomeProvider.notifier).setGotoDestination(location);
        setState(() => _isExpanded = false);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: AppColors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: AppColors.hyperLime,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomDestinationButton() {
    return GestureDetector(
      onTap: () {
        // Open search/picker dialog
        setState(() => _isExpanded = false);
        _showCustomDestinationDialog();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.hyperLime.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_location_alt,
              color: AppColors.hyperLime,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Custom Location',
              style: GoogleFonts.dmSans(
                color: AppColors.hyperLime,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomDestinationDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.carbonGrey,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter Destination',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                style: GoogleFonts.dmSans(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search location...',
                  hintStyle: GoogleFonts.dmSans(color: AppColors.white50),
                  prefixIcon: Icon(Icons.search, color: AppColors.white70),
                  filled: true,
                  fillColor: AppColors.voidBlack,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.white10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.white10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.hyperLime),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.dmSans(color: AppColors.white70),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Set destination and close
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.hyperLime,
                        foregroundColor: Colors.black,
                      ),
                      child: Text(
                        'Set',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
