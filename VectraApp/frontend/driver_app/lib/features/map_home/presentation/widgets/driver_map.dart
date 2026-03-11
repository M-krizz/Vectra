import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../config/maps_config.dart';
import '../../../../theme/app_colors.dart';
import '../providers/map_home_providers.dart';
import 'heatmap_hexagon.dart';

/// Driver map widget with heatmap overlay
class DriverMap extends ConsumerStatefulWidget {
  final bool showHeatmap;
  final LatLng? initialCenter;
  final double initialZoom;
  final Function(LatLng)? onLocationChanged;

  const DriverMap({
    super.key,
    this.showHeatmap = true,
    this.initialCenter,
    this.initialZoom = 14.0,
    this.onLocationChanged,
  });

  @override
  ConsumerState<DriverMap> createState() => _DriverMapState();
}

class _DriverMapState extends ConsumerState<DriverMap>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapHomeProvider);
    final currentLocation = mapState.currentLocation ??
        widget.initialCenter ??
        LatLng(12.9716, 77.5946);

    List<Polygon> heatmapPolygons = [];
    if (widget.showHeatmap && mapState.heatmapData.isNotEmpty) {
      heatmapPolygons = buildHeatmapPolygons(
        hexagons: mapState.heatmapData,
        showDemand: mapState.showDemandLayer,
        showSurge: mapState.showSurgeLayer,
        hexagonRadius: 500,
      );
    }

    List<Marker> markers = [
      Marker(
        point: currentLocation,
        width: 40,
        height: 40,
        child: const Icon(Icons.my_location, color: Colors.green, size: 40),
      ),
    ];

    if (mapState.gotoDestination != null) {
      markers.add(
        Marker(
          point: mapState.gotoDestination!,
          width: 40,
          height: 40,
          child: const Icon(Icons.flag, color: Colors.orange, size: 40),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: currentLocation,
            initialZoom: widget.initialZoom,
            minZoom: 10,
            maxZoom: 18,
            onPositionChanged: (position, hasGesture) {
              if (hasGesture) {
                widget.onLocationChanged?.call(position.center);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: MapsConfig.tileUrlTemplate,
              userAgentPackageName: 'com.vectra.driver',
            ),
            if (heatmapPolygons.isNotEmpty)
              PolygonLayer(polygons: heatmapPolygons),
            MarkerLayer(markers: markers),
          ],
        ),

        // Map controls
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
            children: [
              _buildMapControl(
                icon: Icons.add,
                onTap: () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildMapControl(
                icon: Icons.remove,
                onTap: () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildMapControl(
                icon: Icons.my_location,
                onTap: () {
                  if (mapState.currentLocation != null) {
                    _mapController.move(mapState.currentLocation!, _mapController.camera.zoom);
                  }
                },
              ),
            ],
          ),
        ),

        // Heatmap layer toggles
        if (widget.showHeatmap)
          Positioned(
            left: 16,
            bottom: 100,
            child: Column(
              children: [
                _buildLayerToggle(
                  icon: Icons.local_fire_department,
                  label: 'Demand',
                  isActive: mapState.showDemandLayer,
                  color: AppColors.warningOrange,
                  onTap: () => ref.read(mapHomeProvider.notifier).toggleDemandLayer(),
                ),
                const SizedBox(height: 8),
                _buildLayerToggle(
                  icon: Icons.bolt,
                  label: 'Surge',
                  isActive: mapState.showSurgeLayer,
                  color: AppColors.errorRed,
                  onTap: () => ref.read(mapHomeProvider.notifier).toggleSurgeLayer(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMapControl({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black87, size: 22),
      ),
    );
  }

  Widget _buildLayerToggle({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.2) : AppColors.carbonGrey,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : AppColors.white20,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? color : AppColors.white70,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? color : AppColors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
