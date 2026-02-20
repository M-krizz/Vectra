import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/saved_places_bloc_exports.dart';
import '../models/saved_place_model.dart';
import 'saved_place_form_screen.dart';

/// Screen for managing saved places (Home, Work, Favorites)
class SavedPlacesScreen extends StatelessWidget {
  const SavedPlacesScreen({super.key});

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
      body: BlocBuilder<SavedPlacesBloc, SavedPlacesState>(
        builder: (context, state) {
          if (state is SavedPlacesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SavedPlacesError) {
            return Center(child: Text(state.message));
          }

          if (state is SavedPlacesLoaded) {
            final places = state.places;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Home & Work sections
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildPlaceTile(
                        context,
                        icon: Icons.home,
                        iconColor: Colors.blue,
                        title: 'Home',
                        placeType: PlaceType.home,
                        places: places,
                      ),
                      const Divider(height: 1),
                      _buildPlaceTile(
                        context,
                        icon: Icons.work,
                        iconColor: Colors.orange,
                        title: 'Work',
                        placeType: PlaceType.work,
                        places: places,
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
                      onPressed: () => _navigateToForm(context),
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
                      places
                              .where((p) => p.type == PlaceType.favorite)
                              .isEmpty
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
                            children: places
                                .where((p) => p.type == PlaceType.favorite)
                                .map(
                                  (place) => _buildFavoriteTile(context, place),
                                )
                                .toList(),
                          ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _navigateToForm(BuildContext context, {SavedPlace? place, PlaceType? initialType}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SavedPlaceFormScreen(place: place, initialType: initialType),
      ),
    );
  }

  Widget _buildPlaceTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required PlaceType placeType,
    required List<SavedPlace> places,
  }) {
    final place = places.where((p) => p.type == placeType).firstOrNull;
    final subtitle = place?.address ?? 'Tap to add';

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
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
      onTap: () {
        if (place != null) {
          _navigateToForm(context, place: place);
        } else {
          _navigateToForm(context, initialType: placeType);
        }
      },
    );
  }

  Widget _buildFavoriteTile(BuildContext context, SavedPlace place) {
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
        context.read<SavedPlacesBloc>().add(DeleteSavedPlace(place.id));
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
        onTap: () => _navigateToForm(context, place: place),
      ),
    );
  }
}
