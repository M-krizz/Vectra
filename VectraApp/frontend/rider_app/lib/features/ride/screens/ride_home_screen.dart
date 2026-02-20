import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/app_theme.dart';

/// Content-first home/ride tab matching the reference app layout
class RideHomeScreen extends StatelessWidget {
  const RideHomeScreen({super.key});

  static const List<_ServiceItem> _quickServices = [
    _ServiceItem(id: 'auto', label: 'Auto', emoji: '🛺', color: Color(0xFFFEF3E2)),
    _ServiceItem(id: 'cab_economy', label: 'Cab Economy', emoji: '🚗', color: Color(0xFFE8F5E9)),
    _ServiceItem(id: 'bike', label: 'Bike', emoji: '🏍️', color: Color(0xFFE3F2FD)),
    _ServiceItem(id: 'cab_premium', label: 'Cab Premium', emoji: '🚙', color: Color(0xFFEDE7F6)),
  ];

  static const List<_PromoItem> _promos = [
    _PromoItem(
      title: 'In a hurry?',
      subtitle: 'An auto will arrive in 5 mins.',
      cta: 'Book Now',
      bgColor: Color(0xFFE8F0FE),
      accentColor: AppColors.primary,
      emoji: '🛺',
    ),
    _PromoItem(
      title: 'Ride safe!',
      subtitle: 'SOS & live tracking on every ride.',
      cta: 'Learn More',
      bgColor: Color(0xFFE8F5E9),
      accentColor: Color(0xFF2E7D32),
      emoji: '🛡️',
    ),
  ];

  static const List<_DestinationCard> _destinations = [
    _DestinationCard(
      title: 'Airport Rides',
      subtitle: 'Hassle-Free Airport Drops',
      emoji: '✈️',
      bgColor: Color(0xFFFFF3E0),
    ),
    _DestinationCard(
      title: 'Railway Station',
      subtitle: 'Quick Rides to Railway Station',
      emoji: '🚆',
      bgColor: Color(0xFFE8F0FE),
    ),
    _DestinationCard(
      title: 'Bus Terminal',
      subtitle: 'Ride to Your Bus Terminal',
      emoji: '🚌',
      bgColor: Color(0xFFE8F5E9),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Search bar at top ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _SearchBar(),
              ),
            ),

            // ── Explore section ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Explore',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {}, // navigate to all services tab
                      child: const Row(
                        children: [
                          Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Quick service grid (2x2) ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: _quickServices.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final s = entry.value;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: idx == _quickServices.length - 1 ? 0 : 10,
                        ),
                        child: _ServiceTile(item: s),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // ── Promo banner ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _PromoBanner(promo: _promos[0]),
              ),
            ),

            // ── Go Places section ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Text(
                  'Go Places with Vectra',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 152,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  scrollDirection: Axis.horizontal,
                  itemCount: _destinations.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
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

// ─── Search bar widget ─────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/home/location-select'),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: AppColors.textSecondary, size: 22),
            SizedBox(width: 10),
            Text(
              'Enter pickup location',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Service tile ──────────────────────────────────────────────────────────

class _ServiceTile extends StatelessWidget {
  final _ServiceItem item;
  const _ServiceTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/home/location-select'),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(item.emoji, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

// ─── Promo banner ─────────────────────────────────────────────────────────

class _PromoBanner extends StatelessWidget {
  final _PromoItem promo;
  const _PromoBanner({required this.promo});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: promo.bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    promo.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: promo.accentColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    promo.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    promo.cta,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: promo.accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(promo.emoji, style: const TextStyle(fontSize: 52)),
          ),
        ],
      ),
    );
  }
}

// ─── Destination card ──────────────────────────────────────────────────────

class _DestinationTile extends StatelessWidget {
  final _DestinationCard item;
  const _DestinationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: item.bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 36)),
            const Spacer(),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data classes ──────────────────────────────────────────────────────────

class _ServiceItem {
  final String id;
  final String label;
  final String emoji;
  final Color color;
  const _ServiceItem({required this.id, required this.label, required this.emoji, required this.color});
}

class _PromoItem {
  final String title;
  final String subtitle;
  final String cta;
  final Color bgColor;
  final Color accentColor;
  final String emoji;
  const _PromoItem({required this.title, required this.subtitle, required this.cta, required this.bgColor, required this.accentColor, required this.emoji});
}

class _DestinationCard {
  final String title;
  final String subtitle;
  final String emoji;
  final Color bgColor;
  const _DestinationCard({required this.title, required this.subtitle, required this.emoji, required this.bgColor});
}
