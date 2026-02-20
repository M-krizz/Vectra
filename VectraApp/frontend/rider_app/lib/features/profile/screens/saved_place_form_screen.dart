import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../bloc/saved_places_bloc.dart';
import '../bloc/saved_places_event.dart';
import '../models/saved_place_model.dart';

class SavedPlaceFormScreen extends StatefulWidget {
  final SavedPlace? place;
  final PlaceType? initialType;

  const SavedPlaceFormScreen({super.key, this.place, this.initialType});

  @override
  State<SavedPlaceFormScreen> createState() => _SavedPlaceFormScreenState();
}

class _SavedPlaceFormScreenState extends State<SavedPlaceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late PlaceType _selectedType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.place?.name ?? '');
    _addressController = TextEditingController(text: widget.place?.address ?? '');
    _selectedType = widget.place?.type ?? widget.initialType ?? PlaceType.favorite;
    
    // Auto-fill name if initialType is Home or Work
    if (widget.place == null && (widget.initialType == PlaceType.home || widget.initialType == PlaceType.work)) {
       if (widget.initialType == PlaceType.home) _nameController.text = 'Home';
       if (widget.initialType == PlaceType.work) _nameController.text = 'Work';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _savePlace() {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      final address = _addressController.text.trim();

      if (widget.place == null) {
        // Create
        final newPlace = SavedPlace(
          id: const Uuid().v4(), // ID will be ignored/overwritten by repo if needed, but good to have
          name: name,
          address: address,
          type: _selectedType,
        );
        context.read<SavedPlacesBloc>().add(AddSavedPlace(newPlace));
      } else {
        // Update
        final updatedPlace = widget.place!.copyWith(
          name: name,
          address: address,
          type: _selectedType,
        );
        context.read<SavedPlacesBloc>().add(UpdateSavedPlace(updatedPlace));
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.place != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Place' : 'Add New Place'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type Selector
              Text(
                'Place Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildTypeChip(PlaceType.home, 'Home', Icons.home),
                  const SizedBox(width: 12),
                  _buildTypeChip(PlaceType.work, 'Work', Icons.work),
                  const SizedBox(width: 12),
                  _buildTypeChip(PlaceType.favorite, 'Favorite', Icons.bookmark),
                ],
              ),
              const SizedBox(height: 24),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g., Gym, Mom\'s House',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address Field
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  hintText: 'Search or enter address',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _savePlace,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isEditing ? 'Update Place' : 'Save Place',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(PlaceType type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            // Auto-fill name for Home/Work if empty
            if (_nameController.text.isEmpty) {
              if (type == PlaceType.home) _nameController.text = 'Home';
              if (type == PlaceType.work) _nameController.text = 'Work';
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.black : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
