import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../../theme/app_colors.dart';
import '../providers/map_home_providers.dart';

class GotoButton extends ConsumerStatefulWidget {
  const GotoButton({super.key});

  @override
  ConsumerState<GotoButton> createState() => _GotoButtonState();
}

class _GotoButtonState extends ConsumerState<GotoButton> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.hyperLime : colors.primary;
    final border = isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2);
    final mapState = ref.watch(mapHomeProvider);
    final hasDestination = mapState.gotoDestination != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () {
            if (hasDestination) { ref.read(mapHomeProvider.notifier).clearGotoDestination(); }
            else { setState(() => _isExpanded = !_isExpanded); }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(horizontal: hasDestination ? 16 : 12, vertical: 12),
            decoration: BoxDecoration(
              color: hasDestination ? accent : (isDark ? AppColors.carbonGrey : Colors.white),
              borderRadius: BorderRadius.circular(hasDestination ? 30 : 12),
              border: Border.all(color: hasDestination ? accent : border),
              boxShadow: [BoxShadow(color: hasDestination ? accent.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(hasDestination ? Icons.close : Icons.near_me, color: hasDestination ? (isDark ? Colors.black : Colors.white) : colors.onSurface, size: 20),
              if (hasDestination) ...[
                const SizedBox(width: 8),
                Text('Go To Active', style: GoogleFonts.dmSans(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ]),
          ),
        ),
        if (_isExpanded)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.carbonGrey : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Go To Destination', style: GoogleFonts.outfit(color: colors.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Only show rides heading towards:', style: GoogleFonts.dmSans(color: colors.onSurfaceVariant, fontSize: 12)),
              const SizedBox(height: 12),
              _buildDestinationOption('Koramangala', LatLng(12.9352, 77.6245), colors, isDark, accent),
              _buildDestinationOption('Indiranagar', LatLng(12.9784, 77.6408), colors, isDark, accent),
              _buildDestinationOption('Marathahalli', LatLng(12.9569, 77.7011), colors, isDark, accent),
              _buildDestinationOption('Whitefield', LatLng(12.9698, 77.7500), colors, isDark, accent),
              const SizedBox(height: 8),
              _buildCustomDestinationButton(colors, isDark, accent),
            ]),
          ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1),
      ],
    );
  }

  Widget _buildDestinationOption(String name, LatLng location, ColorScheme colors, bool isDark, Color accent) {
    return GestureDetector(
      onTap: () { ref.read(mapHomeProvider.notifier).setGotoDestination(location); setState(() => _isExpanded = false); },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.white10 : colors.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(Icons.location_on_outlined, color: accent, size: 18),
          const SizedBox(width: 8),
          Text(name, style: GoogleFonts.dmSans(color: colors.onSurface, fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _buildCustomDestinationButton(ColorScheme colors, bool isDark, Color accent) {
    return GestureDetector(
      onTap: () { setState(() => _isExpanded = false); _showCustomDestinationDialog(colors, isDark, accent); },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(border: Border.all(color: accent.withValues(alpha: 0.5)), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_location_alt, color: accent, size: 18),
          const SizedBox(width: 8),
          Text('Custom Location', style: GoogleFonts.dmSans(color: accent, fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  void _showCustomDestinationDialog(ColorScheme colors, bool isDark, Color accent) {
    final border = isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.carbonGrey : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
            boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Enter Destination', style: GoogleFonts.outfit(color: colors.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              style: GoogleFonts.dmSans(color: colors.onSurface),
              decoration: InputDecoration(
                hintText: 'Search location...',
                hintStyle: GoogleFonts.dmSans(color: colors.onSurfaceVariant),
                prefixIcon: Icon(Icons.search, color: colors.onSurfaceVariant),
                filled: true,
                fillColor: isDark ? AppColors.voidBlack : colors.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accent)),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.dmSans(color: colors.onSurfaceVariant)))),
              Expanded(child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: isDark ? Colors.black : Colors.white),
                child: Text('Set', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }
}
