import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme_cubit.dart';

/// Content-first home/ride tab matching the reference app layout
class RideHomeScreen extends StatelessWidget {
  const RideHomeScreen({super.key});

  static final List<_ServiceItem> _quickServices = [
    _ServiceItem(id: 'auto', label: 'Auto', icon: Icons.electric_rickshaw, lightColor: Color(0xFFFEF3E2), darkColor: Color(0xFF3D2E14)),
    _ServiceItem(id: 'cab_economy', label: 'Cab\nEconomy', icon: Icons.local_taxi, lightColor: Color(0xFFE8F5E9), darkColor: Color(0xFF1B3D1E)),
    _ServiceItem(id: 'bike', label: 'Bike', icon: Icons.two_wheeler, lightColor: Color(0xFFE3F2FD), darkColor: Color(0xFF142838)),
    _ServiceItem(id: 'cab_premium', label: 'Cab\nPremium', icon: Icons.directions_car, lightColor: Color(0xFFF3E5F5), darkColor: Color(0xFF2D1A33)),
  ];

  static const List<_PromoItem> _promos = [
    _PromoItem(
      title: 'In a hurry?',
      subtitle: 'An auto will arrive in 5 mins.',
      cta: 'Book Now',
      lightBg: Color(0xFFE8F5E9),
      darkBg: Color(0xFF1A3D1E),
      accentColor: Color(0xFF00B248),
      icon: Icons.electric_rickshaw,
    ),
  ];

  static const List<_DestinationCard> _destinations = [
    _DestinationCard(title: 'Airport Rides', subtitle: 'Hassle-Free Airport\nDrops', icon: Icons.flight_takeoff, lightBg: Color(0xFFFFF8E1), darkBg: Color(0xFF3D3514)),
    _DestinationCard(title: 'Railway Station', subtitle: 'Quick Rides to\nRailway Station', icon: Icons.train, lightBg: Color(0xFFE8F5E9), darkBg: Color(0xFF1A3D1E)),
    _DestinationCard(title: 'Bus Terminal', subtitle: 'Ride to Your\nBus Terminal', icon: Icons.directions_bus, lightBg: Color(0xFFE3F2FD), darkBg: Color(0xFF142838)),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Search bar at top
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(child: _SearchBar()),
                    const SizedBox(width: 10),
                    _ThemeToggleButton(),
                  ],
                ),
              ),
            ),

            // Explore section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Explore', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.onSurface)),
                    GestureDetector(
                      onTap: () => context.push('/home/location-select'),
                      child: Row(children: [
                        Text('View All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.primary)),
                        const SizedBox(width: 2),
                        Icon(Icons.chevron_right, size: 16, color: colors.primary),
                      ]),
                    ),
                  ],
                ),
              ),
            ),

            // Quick service grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: _quickServices.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final s = entry.value;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: idx == _quickServices.length - 1 ? 0 : 10),
                        child: _ServiceTile(item: s),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Promo banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _PromoBanner(promo: _promos[0]),
              ),
            ),

            // Go Places section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Text('Go Places with Vectra', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.onSurface)),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 152,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  scrollDirection: Axis.horizontal,
                  itemCount: _destinations.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => _DestinationTile(item: _destinations[i]),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// Search bar widget
class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => context.push('/home/location-select'),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? colors.surfaceContainerHighest : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colors.outline.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Icon(Icons.search, color: colors.onSurfaceVariant, size: 22),
          const SizedBox(width: 10),
          Text('Enter pickup location', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 15)),
        ]),
      ),
    );
  }
}

// Service tile
class _ServiceTile extends StatelessWidget {
  final _ServiceItem item;
  const _ServiceTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => context.push('/home/location-select'),
      child: Column(
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              color: isDark ? item.darkColor : item.lightColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Icon(item.icon, size: 32, color: isDark ? Colors.white70 : Colors.black54)),
          ),
          const SizedBox(height: 6),
          Text(item.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.onSurface), textAlign: TextAlign.center, maxLines: 2),
        ],
      ),
    );
  }
}

// Promo banner
class _PromoBanner extends StatelessWidget {
  final _PromoItem promo;
  const _PromoBanner({required this.promo});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      decoration: BoxDecoration(
        color: isDark ? promo.darkBg : promo.lightBg,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(promo.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: promo.accentColor)),
                  const SizedBox(height: 2),
                  Text(promo.subtitle, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(promo.cta, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: promo.accentColor)),
                ],
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(12), child: Icon(promo.icon, size: 52, color: promo.accentColor.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}

// Destination card
class _DestinationTile extends StatelessWidget {
  final _DestinationCard item;
  const _DestinationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => context.push('/home/location-select'),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: isDark ? item.darkBg : item.lightBg,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(item.icon, size: 36, color: isDark ? Colors.white70 : Colors.black54),
            const Spacer(),
            Text(item.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.onSurface)),
            const SizedBox(height: 2),
            Text(item.subtitle, style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant), maxLines: 2),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: isDark ? colors.surfaceContainerHighest : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.read<ThemeCubit>().toggleTheme(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            size: 20,
            color: colors.primary,
          ),
        ),
      ),
    );
  }
}

// Data classes
class _ServiceItem {
  final String id, label;
  final IconData icon;
  final Color lightColor, darkColor;
  const _ServiceItem({required this.id, required this.label, required this.icon, required this.lightColor, required this.darkColor});
}

class _PromoItem {
  final String title, subtitle, cta;
  final IconData icon;
  final Color lightBg, darkBg, accentColor;
  const _PromoItem({required this.title, required this.subtitle, required this.cta, required this.lightBg, required this.darkBg, required this.accentColor, required this.icon});
}

class _DestinationCard {
  final String title, subtitle;
  final IconData icon;
  final Color lightBg, darkBg;
  const _DestinationCard({required this.title, required this.subtitle, required this.icon, required this.lightBg, required this.darkBg});
}
