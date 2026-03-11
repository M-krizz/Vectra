import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../theme/app_colors.dart';
import '../providers/map_home_providers.dart';

List<Polygon> buildHeatmapPolygons({
  required List<HeatmapHexagon> hexagons,
  bool showDemand = true,
  bool showSurge = true,
  double hexagonRadius = 500,
}) {
  return hexagons.map((hex) => _buildHexagon(hex, showDemand, showSurge, hexagonRadius)).toList();
}

Polygon _buildHexagon(HeatmapHexagon hex, bool showDemand, bool showSurge, double hexagonRadius) {
  final points = _generateHexagonPoints(hex.center, hexagonRadius);

  Color fillColor;
  Color borderColor;

  if (showSurge && hex.hasSurge) {
    // Surge color (red-orange gradient based on multiplier)
    final surgeIntensity = ((hex.surgeMultiplier - 1.0) / 1.0).clamp(0.0, 1.0);
    fillColor = Color.lerp(
      AppColors.warningOrange,
      AppColors.errorRed,
      surgeIntensity,
    )!.withValues(alpha: 0.4);
    borderColor = AppColors.errorRed.withValues(alpha: 0.6);
  } else if (showDemand) {
    // Demand color (orange gradient based on demand level)
    fillColor = AppColors.warningOrange.withValues(alpha: 0.2 + hex.demandLevel * 0.4);
    borderColor = AppColors.warningOrange.withValues(alpha: 0.4 + hex.demandLevel * 0.4);
  } else {
    fillColor = Colors.transparent;
    borderColor = Colors.transparent;
  }

  return Polygon(
    points: points,
    color: fillColor,
    borderColor: borderColor,
    borderStrokeWidth: 2,
  );
}

List<LatLng> _generateHexagonPoints(LatLng center, double radiusMeters) {
  const int sides = 6;
  final points = <LatLng>[];

  // Convert radius from meters to approximate degrees
  // At equator: 1 degree ≈ 111km
  final latRadius = radiusMeters / 111000;
  final lngRadius = radiusMeters / (111000 * math.cos(center.latitude * math.pi / 180));

  for (int i = 0; i < sides; i++) {
    final angle = (math.pi / 3) * i + (math.pi / 6); // Flat-top hexagon
    final lat = center.latitude + latRadius * math.sin(angle);
    final lng = center.longitude + lngRadius * math.cos(angle);
    points.add(LatLng(lat, lng));
  }

  return points;
}

/// Single hexagon info card widget
class HexagonInfoCard extends StatelessWidget {
  final HeatmapHexagon hexagon;
  final VoidCallback? onTap;

  const HexagonInfoCard({
    super.key,
    required this.hexagon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.carbonGrey.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hexagon.hasSurge ? AppColors.errorRed : AppColors.warningOrange,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hexagon.zoneName != null)
              Text(
                hexagon.zoneName!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoChip(
                  icon: Icons.local_fire_department,
                  label: '${(hexagon.demandLevel * 100).toInt()}%',
                  color: AppColors.warningOrange,
                ),
                const SizedBox(width: 8),
                if (hexagon.hasSurge)
                  _buildInfoChip(
                    icon: Icons.bolt,
                    label: '${hexagon.surgeMultiplier}x',
                    color: AppColors.errorRed,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
