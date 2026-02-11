import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../bloc/ride_bloc.dart';
import '../models/place_model.dart';
import '../repository/places_repository.dart';

/// Enum to track which field is being edited
enum SearchField { pickup, destination }

/// Screen for searching and selecting pickup/destination locations
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

  PlaceModel? _selectedPickup;
  PlaceModel? _selectedDestination;

  @override
  void initState() {
    super.initState();

    _selectedPickup = widget.initialPickup;
    _selectedDestination = widget.initialDestination;

    _pickupController = TextEditingController(
      text: widget.initialPickup?.name ?? '',
    );
    _destinationController = TextEditingController(
      text: widget.initialDestination?.name ?? '',
    );

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

    // Focus appropriate field after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.focusField == SearchField.destination) {
        _destinationFocusNode.requestFocus();
      } else {
        _pickupFocusNode.requestFocus();
      }
    });
  }

  void _search(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (query.isEmpty) {
        setState(() => _searchResults = []);
        return;
      }

      setState(() => _isLoading = true);

      try {
        final results = await _placesRepository.searchPlaces(query);
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _onPlaceSelected(PlaceModel place) async {
    setState(() => _isLoading = true);

    // Fetch full place details with lat/lng if not already present
    PlaceModel placeWithLocation = place;
    if (place.location == null) {
      final details = await _placesRepository.getPlaceDetails(place.placeId);
      if (details != null) {
        placeWithLocation = details;
      } else {
        // Show error if we couldn't get location
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
      // Move focus to destination if empty
      if (_selectedDestination == null) {
        _destinationFocusNode.requestFocus();
      } else {
        _confirmSelection();
      }
    } else {
      setState(() {
        _selectedDestination = placeWithLocation;
        _destinationController.text = placeWithLocation.name;
        _searchResults = [];
        _isLoading = false;
      });
      // Confirm if both are selected
      if (_selectedPickup != null) {
        _confirmSelection();
      } else {
        _pickupFocusNode.requestFocus();
      }
    }
  }

  void _confirmSelection() {
    if (_selectedPickup != null && _selectedDestination != null) {
      // Update the Ride BLoC
      final rideBloc = context.read<RideBloc>();
      rideBloc.add(RidePickupSet(_selectedPickup!));
      rideBloc.add(RideDestinationSet(_selectedDestination!));

      // Pop back to home screen
      Navigator.of(context).pop();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Set your route',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // Search fields
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Location indicators
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
                      width: 2,
                      height: 30,
                      color: Colors.grey.shade300,
                    ),
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
                // Text fields
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
                            _searchResults = [];
                          });
                        },
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
                            _searchResults = [];
                          });
                        },
                      ),
                    ],
                  ),
                ),
                // Swap button
                IconButton(
                  icon: const Icon(Icons.swap_vert),
                  onPressed: _swapLocations,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),

          // Loading indicator
          if (_isLoading) const LinearProgressIndicator(),

          // Search results or saved places
          Expanded(
            child: _searchResults.isNotEmpty
                ? _buildSearchResults()
                : _buildSavedPlaces(),
          ),

          // Confirm button
          if (_selectedPickup != null && _selectedDestination != null)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _confirmSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Confirm Route',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? Colors.grey.shade100 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.blue : Colors.grey.shade200,
          width: isActive ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: onClear,
                )
              : null,
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
      itemBuilder: (context, index) {
        final place = _searchResults[index];
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on, color: Colors.grey),
          ),
          title: Text(
            place.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            place.address,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => _onPlaceSelected(place),
        );
      },
    );
  }

  Widget _buildSavedPlaces() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Current location option (only for pickup)
        if (_activeField == SearchField.pickup)
          _buildQuickOption(
            icon: Icons.my_location,
            iconColor: Colors.blue,
            title: 'Use current location',
            subtitle: 'Your GPS location',
            onTap: () {
              // We'll use the pickup from the home screen which has current location
              if (widget.initialPickup != null) {
                _onPlaceSelected(widget.initialPickup!);
              }
            },
          ),

        const SizedBox(height: 16),
        Text(
          'Saved Places',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        _buildQuickOption(
          icon: Icons.home,
          iconColor: Colors.orange,
          title: 'Home',
          subtitle: 'Add home address',
          onTap: () {
            // In real app, this would open address setting
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Home address not set')),
            );
          },
        ),
        _buildQuickOption(
          icon: Icons.work,
          iconColor: Colors.purple,
          title: 'Work',
          subtitle: 'Add work address',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Work address not set')),
            );
          },
        ),

        const SizedBox(height: 16),
        Text(
          'Recent Places',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        // Show some mock recent places
        _buildQuickOption(
          icon: Icons.history,
          iconColor: Colors.grey,
          title: 'Brookefields Mall',
          subtitle: 'Brookefields, Coimbatore',
          onTap: () => _search('Brookefields'),
        ),
        _buildQuickOption(
          icon: Icons.history,
          iconColor: Colors.grey,
          title: 'Coimbatore Junction',
          subtitle: 'Railway Station Rd, Coimbatore',
          onTap: () => _search('Junction'),
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
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      onTap: onTap,
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _pickupController.dispose();
    _destinationController.dispose();
    _pickupFocusNode.dispose();
    _destinationFocusNode.dispose();
    super.dispose();
  }
}
