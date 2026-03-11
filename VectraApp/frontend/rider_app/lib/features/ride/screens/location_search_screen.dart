import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../../config/maps_config.dart';
import '../bloc/ride_bloc.dart';
import '../models/place_model.dart';
import '../repository/places_repository.dart';

enum SearchField { pickup, destination }

class LocationSearchScreen extends StatefulWidget {
  final PlaceModel? initialPickup;
  final PlaceModel? initialDestination;
  final SearchField focusField;

  const LocationSearchScreen({
    super.key,
    this.initialPickup,
    this.initialDestination,
    this.focusField = SearchField.destination,
  });

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  late TextEditingController _pickupController;
  late TextEditingController _destinationController;
  late FocusNode _pickupFocusNode;
  late FocusNode _destinationFocusNode;

  final PlacesRepository _placesRepository = PlacesRepository();

  SearchField _activeField = SearchField.destination;
  List<PlaceModel> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounceTimer;
  final MapController _mapController = MapController();
  RouteModel? _previewRoute;

  PlaceModel? _selectedPickup;
  PlaceModel? _selectedDestination;

  /// Current device location used to centre the map initially.
  LatLng _currentLatLng = MapsConfig.defaultLatLng;
  bool _gotCurrentLocation = false;

  @override
  void initState() {
    super.initState();
    _selectedPickup = widget.initialPickup;
    _selectedDestination = widget.initialDestination;

    _pickupController =
        TextEditingController(text: widget.initialPickup?.name ?? '');
    _destinationController =
        TextEditingController(text: widget.initialDestination?.name ?? '');
    _pickupFocusNode = FocusNode();
    _destinationFocusNode = FocusNode();
    _activeField = widget.focusField;

    _pickupFocusNode.addListener(() {
      if (_pickupFocusNode.hasFocus) {
        setState(() => _activeField = SearchField.pickup);
        _search(_pickupController.text);
      }
    });
    _destinationFocusNode.addListener(() {
      if (_destinationFocusNode.hasFocus) {
        setState(() => _activeField = SearchField.destination);
        _search(_destinationController.text);
      }
    });

    // Grab the device location so we can centre the map.
    _fetchCurrentLocation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.focusField == SearchField.destination) {
        _destinationFocusNode.requestFocus();
      } else {
        _pickupFocusNode.requestFocus();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Location helpers
  // ---------------------------------------------------------------------------

  Future<void> _fetchCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return; // keep default
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      setState(() {
        _currentLatLng = LatLng(pos.latitude, pos.longitude);
        _gotCurrentLocation = true;
      });
      // If no pickup/destination yet, move the camera to current location.
      if (_selectedPickup?.location == null &&
          _selectedDestination?.location == null) {
        _mapController.move(_currentLatLng, 15);
      }
    } catch (_) {
      // silently keep default position
    }
  }

  // ---------------------------------------------------------------------------
  // Search — calls the Mapbox Geocoding API via backend proxy
  // ---------------------------------------------------------------------------

  void _search(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      if (query.trim().isEmpty) {
        setState(() => _searchResults = []);
        return;
      }
      setState(() => _isLoading = true);
      try {
        final results = await _placesRepository.searchPlaces(
          query,
          nearLocation: _gotCurrentLocation ? _currentLatLng : null,
        );
        if (!mounted) return;
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Place selection / route preview
  // ---------------------------------------------------------------------------

  Future<void> _onPlaceSelected(PlaceModel place) async {
    setState(() => _isLoading = true);
    PlaceModel placeWithLocation = place;
    if (place.location == null) {
      final details = await _placesRepository.getPlaceDetails(place.placeId);
      if (details != null) {
        placeWithLocation = details;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not get location details')),
          );
          setState(() => _isLoading = false);
        }
        return;
      }
    }

    if (_activeField == SearchField.pickup) {
      setState(() {
        _selectedPickup = placeWithLocation;
        _pickupController.text = placeWithLocation.name;
        _searchResults = [];
        _isLoading = false;
      });
      _mapController.move(placeWithLocation.location!, 15);
      if (_selectedDestination == null) {
        _destinationFocusNode.requestFocus();
      } else {
        await _refreshRoutePreview();
      }
    } else {
      setState(() {
        _selectedDestination = placeWithLocation;
        _destinationController.text = placeWithLocation.name;
        _searchResults = [];
        _isLoading = false;
      });
      _mapController.move(placeWithLocation.location!, 15);
      if (_selectedPickup != null) {
        await _refreshRoutePreview();
      } else {
        _pickupFocusNode.requestFocus();
      }
    }
  }

  Future<void> _refreshRoutePreview() async {
    if (_selectedPickup?.location == null ||
        _selectedDestination?.location == null) {
      setState(() => _previewRoute = null);
      return;
    }
    try {
      final route = await _placesRepository.getRoute(
          _selectedPickup!, _selectedDestination!);
      setState(() => _previewRoute = route);

      final pickup = _selectedPickup!.location!;
      final destination = _selectedDestination!.location!;
      final bounds = LatLngBounds.fromPoints([pickup, destination]);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(56)),
      );
    } catch (_) {
      setState(() => _previewRoute = null);
    }
  }

  void _confirmSelection() {
    if (_selectedPickup != null && _selectedDestination != null) {
      final rideBloc = context.read<RideBloc>();
      rideBloc.add(RidePickupSet(_selectedPickup!));
      rideBloc.add(RideDestinationSet(_selectedDestination!));
      context.go('/home/ride-options');
    }
  }

  void _swapLocations() {
    setState(() {
      final tempPlace = _selectedPickup;
      final tempText = _pickupController.text;
      _selectedPickup = _selectedDestination;
      _pickupController.text = _destinationController.text;
      _selectedDestination = tempPlace;
      _destinationController.text = tempText;
    });
    _refreshRoutePreview();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location permissions permanently denied. Enable in Settings.'),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final place = _placesRepository.createCurrentLocationPlace(
          LatLng(position.latitude, position.longitude));
      _onPlaceSelected(place);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not get location: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Column(
        children: [
          // ── Map (always visible) ───────────────────────────────────
          _buildMapPreview(colors, isDark),

          // ── Search fields ──────────────────────────────────────────
          _buildSearchPanel(colors, isDark),

          if (_isLoading) LinearProgressIndicator(color: colors.primary),

          // ── Search results or quick actions ────────────────────────
          Expanded(
            child: _searchResults.isNotEmpty
                ? _buildSearchResults(colors, isDark)
                : _buildQuickActions(colors, isDark),
          ),

          // ── Route info + confirm button ────────────────────────────
          if (_selectedPickup != null && _selectedDestination != null)
            _buildConfirmBar(colors, isDark),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Map (always visible – centres on current location fallback)
  // ---------------------------------------------------------------------------

  Widget _buildMapPreview(ColorScheme colors, bool isDark) {
    final LatLng target = _selectedPickup?.location ??
        _selectedDestination?.location ??
        _currentLatLng;

    final markers = <Marker>[];
    if (_selectedPickup?.location != null) {
      markers.add(Marker(
        point: _selectedPickup!.location!,
        width: 36,
        height: 36,
        child: const Icon(Icons.circle, color: Colors.green, size: 16),
      ));
    }
    if (_selectedDestination?.location != null) {
      markers.add(Marker(
        point: _selectedDestination!.location!,
        width: 36,
        height: 36,
        child: const Icon(Icons.location_on, color: Colors.red, size: 32),
      ));
    }

    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: target,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: isDark
                    ? MapsConfig.darkTileUrlTemplate
                    : MapsConfig.tileUrlTemplate,
                userAgentPackageName: 'com.vectra.rider',
              ),
              if (_previewRoute != null &&
                  _previewRoute!.polylinePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _previewRoute!.polylinePoints,
                      color: const Color(0xFF1E88E5),
                      strokeWidth: 5,
                    ),
                  ],
                ),
              if (markers.isNotEmpty) MarkerLayer(markers: markers),
            ],
          ),
          // Back button floating over the map
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: CircleAvatar(
              backgroundColor: colors.surface.withAlpha(220),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: colors.onSurface),
                onPressed: () => context.pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Search panel (pickup + destination text fields)
  // ---------------------------------------------------------------------------

  Widget _buildSearchPanel(ColorScheme colors, bool isDark) {
    return Container(
      color: colors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _activeField == SearchField.pickup
                      ? Colors.green
                      : Colors.green.shade200,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green, width: 2),
                ),
              ),
              Container(
                  width: 2, height: 30, color: colors.outline.withAlpha(77)),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _activeField == SearchField.destination
                      ? Colors.red
                      : Colors.red.shade200,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red, width: 2),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                _buildSearchField(
                  controller: _pickupController,
                  focusNode: _pickupFocusNode,
                  hint: 'Pickup location',
                  isActive: _activeField == SearchField.pickup,
                  onChanged: _search,
                  onClear: () {
                    _pickupController.clear();
                    setState(() {
                      _selectedPickup = null;
                      _previewRoute = null;
                      _searchResults = [];
                    });
                  },
                  colors: colors,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildSearchField(
                  controller: _destinationController,
                  focusNode: _destinationFocusNode,
                  hint: 'Where to?',
                  isActive: _activeField == SearchField.destination,
                  onChanged: _search,
                  onClear: () {
                    _destinationController.clear();
                    setState(() {
                      _selectedDestination = null;
                      _previewRoute = null;
                      _searchResults = [];
                    });
                  },
                  colors: colors,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.swap_vert, color: colors.onSurfaceVariant),
            onPressed: _swapLocations,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required bool isActive,
    required Function(String) onChanged,
    required VoidCallback onClear,
    required ColorScheme colors,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? colors.surfaceContainerHighest
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? colors.primary : colors.outline.withAlpha(102),
          width: isActive ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: TextStyle(color: colors.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: colors.onSurfaceVariant),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          prefixIcon:
              Icon(Icons.search, size: 20, color: colors.onSurfaceVariant),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear,
                      size: 20, color: colors.onSurfaceVariant),
                  onPressed: onClear,
                )
              : null,
        ),
        onChanged: onChanged,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Autocomplete results dropdown
  // ---------------------------------------------------------------------------

  Widget _buildSearchResults(ColorScheme colors, bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, indent: 56, color: colors.outline.withAlpha(51)),
      itemBuilder: (context, index) {
        final place = _searchResults[index];
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? colors.surfaceContainerHighest
                  : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_on, color: colors.onSurfaceVariant),
          ),
          title: Text(
            place.name,
            style: TextStyle(
                fontWeight: FontWeight.w500, color: colors.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            place.address,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => _onPlaceSelected(place),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Quick actions (shown when search field is empty)
  // ---------------------------------------------------------------------------

  Widget _buildQuickActions(ColorScheme colors, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_activeField == SearchField.pickup)
          _buildQuickOption(
            icon: Icons.my_location,
            iconColor: Colors.blue,
            title: 'Use current location',
            subtitle: 'Your GPS location',
            onTap: _useCurrentLocation,
            colors: colors,
            isDark: isDark,
          ),

        const SizedBox(height: 16),
        Text(
          'Saved Places',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        _buildQuickOption(
          icon: Icons.home,
          iconColor: Colors.orange,
          title: 'Home',
          subtitle: 'Add home address',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Home address not set')),
          ),
          colors: colors,
          isDark: isDark,
        ),
        _buildQuickOption(
          icon: Icons.work,
          iconColor: isDark ? const Color(0xFFCE93D8) : Colors.purple,
          title: 'Work',
          subtitle: 'Add work address',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Work address not set')),
          ),
          colors: colors,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildQuickOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ColorScheme colors,
    required bool isDark,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: iconColor.withAlpha(25), shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style:
              TextStyle(fontWeight: FontWeight.w500, color: colors.onSurface)),
      subtitle: Text(subtitle,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
      onTap: onTap,
    );
  }

  // ---------------------------------------------------------------------------
  // Confirm bar (route info + button)
  // ---------------------------------------------------------------------------

  Widget _buildConfirmBar(ColorScheme colors, bool isDark) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          border:
              Border(top: BorderSide(color: colors.outline.withAlpha(51))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_previewRoute != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_car,
                        size: 16, color: colors.primary),
                    const SizedBox(width: 6),
                    Text(_previewRoute!.distanceText,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface)),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time,
                        size: 16, color: colors.primary),
                    const SizedBox(width: 6),
                    Text(_previewRoute!.durationText,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface)),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirm Route',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController.dispose();
    _pickupController.dispose();
    _destinationController.dispose();
    _pickupFocusNode.dispose();
    _destinationFocusNode.dispose();
    super.dispose();
  }
}
