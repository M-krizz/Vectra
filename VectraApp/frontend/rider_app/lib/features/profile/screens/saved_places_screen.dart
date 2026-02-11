import 'package:flutter/material.dart';

/// Screen for managing saved places (Home, Work, Favorites)
class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  final List<SavedPlace> _savedPlaces = [
    SavedPlace(
      id: '1',
      name: 'Home',
      address: 'RS Puram, Coimbatore',
      icon: Icons.home,
      type: PlaceType.home,
    ),
    SavedPlace(
      id: '2',
      name: 'Work',
      address: 'Tidel Park, Coimbatore',
      icon: Icons.work,
      type: PlaceType.work,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Saved Places'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Home & Work (special places)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildPlaceTile(
                  icon: Icons.home,
                  iconColor: Colors.blue,
                  title: 'Home',
                  subtitle: _getPlaceAddress(PlaceType.home),
                  onTap: () => _editPlace(PlaceType.home),
                ),
                const Divider(height: 1),
                _buildPlaceTile(
                  icon: Icons.work,
                  iconColor: Colors.orange,
                  title: 'Work',
                  subtitle: _getPlaceAddress(PlaceType.work),
                  onTap: () => _editPlace(PlaceType.work),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Favorites section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Favorites',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton.icon(
                onPressed: _addFavorite,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Favorite places list
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                _savedPlaces.where((p) => p.type == PlaceType.favorite).isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.bookmark_border,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No favorite places yet',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Save frequently visited places for quick access',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: _savedPlaces
                        .where((p) => p.type == PlaceType.favorite)
                        .map((place) => _buildFavoriteTile(place))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  String _getPlaceAddress(PlaceType type) {
    final place = _savedPlaces.where((p) => p.type == type).firstOrNull;
    return place?.address ?? 'Tap to add';
  }

  Widget _buildPlaceTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildFavoriteTile(SavedPlace place) {
    return Dismissible(
      key: Key(place.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        setState(() {
          _savedPlaces.removeWhere((p) => p.id == place.id);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${place.name} removed')));
      },
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.bookmark, color: Colors.grey),
        ),
        title: Text(
          place.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          place.address,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => _editFavorite(place),
      ),
    );
  }

  void _editPlace(PlaceType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _AddPlaceSheet(
        title: type == PlaceType.home ? 'Set Home' : 'Set Work',
        onSave: (name, address) {
          setState(() {
            _savedPlaces.removeWhere((p) => p.type == type);
            _savedPlaces.add(
              SavedPlace(
                id: DateTime.now().toString(),
                name: type == PlaceType.home ? 'Home' : 'Work',
                address: address,
                icon: type == PlaceType.home ? Icons.home : Icons.work,
                type: type,
              ),
            );
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _addFavorite() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _AddPlaceSheet(
        title: 'Add Favorite Place',
        showNameField: true,
        onSave: (name, address) {
          setState(() {
            _savedPlaces.add(
              SavedPlace(
                id: DateTime.now().toString(),
                name: name,
                address: address,
                icon: Icons.bookmark,
                type: PlaceType.favorite,
              ),
            );
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _editFavorite(SavedPlace place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _AddPlaceSheet(
        title: 'Edit ${place.name}',
        initialName: place.name,
        initialAddress: place.address,
        showNameField: true,
        onSave: (name, address) {
          setState(() {
            final index = _savedPlaces.indexWhere((p) => p.id == place.id);
            if (index != -1) {
              _savedPlaces[index] = SavedPlace(
                id: place.id,
                name: name,
                address: address,
                icon: Icons.bookmark,
                type: PlaceType.favorite,
              );
            }
          });
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _AddPlaceSheet extends StatefulWidget {
  final String title;
  final bool showNameField;
  final String? initialName;
  final String? initialAddress;
  final void Function(String name, String address) onSave;

  const _AddPlaceSheet({
    required this.title,
    this.showNameField = false,
    this.initialName,
    this.initialAddress,
    required this.onSave,
  });

  @override
  State<_AddPlaceSheet> createState() => _AddPlaceSheetState();
}

class _AddPlaceSheetState extends State<_AddPlaceSheet> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _addressController = TextEditingController(
      text: widget.initialAddress ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            if (widget.showNameField) ...[
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Place name (e.g., Gym)',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                hintText: 'Search for address',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final name = widget.showNameField
                      ? _nameController.text
                      : widget.title.replaceAll('Set ', '');
                  final address = _addressController.text;

                  if (address.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter an address')),
                    );
                    return;
                  }

                  widget.onSave(name, address);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum PlaceType { home, work, favorite }

class SavedPlace {
  final String id;
  final String name;
  final String address;
  final IconData icon;
  final PlaceType type;

  const SavedPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.icon,
    required this.type,
  });
}
