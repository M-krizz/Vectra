import 'package:flutter/material.dart';
import '../../../../config/app_theme.dart';
import '../../ride/screens/location_search_screen.dart';

class AllServicesScreen extends StatelessWidget {
  const AllServicesScreen({super.key});

  static const List<_Service> _services = [
    _Service(id: 'auto', label: 'Auto', emoji: '🛺', color: Color(0xFFFEF3E2)),
    _Service(id: 'cab_economy', label: 'Cab Economy', emoji: '🚗', color: Color(0xFFE8F5E9)),
    _Service(id: 'bike', label: 'Bike', emoji: '🏍️', color: Color(0xFFE3F2FD)),
    _Service(id: 'bike_pink', label: 'Bike Pink', emoji: '🛵', color: Color(0xFFFCE4EC)),
    _Service(id: 'cab_premium', label: 'Cab Premium', emoji: '🚙', color: Color(0xFFEDE7F6)),
    _Service(id: 'shared_auto', label: 'Shared Auto', emoji: '🚐', color: Color(0xFFF3E5F5)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'All Services',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 20,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: _services.length,
          itemBuilder: (context, i) => _ServiceCard(service: _services[i]),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final _Service service;
  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LocationSearchScreen()),
        );
      },
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: service.color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(service.emoji, style: const TextStyle(fontSize: 38)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            service.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _Service {
  final String id;
  final String label;
  final String emoji;
  final Color color;
  const _Service({required this.id, required this.label, required this.emoji, required this.color});
}
