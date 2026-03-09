import 'package:flutter/material.dart';
import '../../../../config/app_theme.dart';
import 'sos_screen.dart';
import 'incident_report_screen.dart';
import 'emergency_contacts_screen.dart';

class SafetyCenterScreen extends StatelessWidget {
  const SafetyCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Safety Center',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // SOS card - prominent
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SosScreen()),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SOS Emergency',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                    SizedBox(height: 4),
                    Text('Tap to call emergency services',
                        style: TextStyle(fontSize: 13, color: Colors.white70)),
                  ],
                ),
                Spacer(),
                Icon(Icons.emergency_share_rounded, size: 40, color: Colors.white),
              ]),
            ),
          ),

          const SizedBox(height: 20),

          const Text('During Your Ride',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 12),

          _SafetyTile(
            icon: Icons.report_problem_rounded,
            iconColor: const Color(0xFFE65100),
            iconBg: const Color(0xFFFFF3E0),
            title: 'Report an Issue',
            subtitle: 'Report unsafe driver behaviour or route concerns',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IncidentReportScreen()),
            ),
          ),

          _SafetyTile(
            icon: Icons.share_location_rounded,
            iconColor: AppColors.primary,
            iconBg: const Color(0xFFE8F0FE),
            title: 'Share My Trip',
            subtitle: 'Send live location to a trusted contact',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Trip share link copied to clipboard!')),
              );
            },
          ),

          _SafetyTile(
            icon: Icons.contacts_rounded,
            iconColor: const Color(0xFF6A1B9A),
            iconBg: const Color(0xFFEDE7F6),
            title: 'Emergency Contacts',
            subtitle: 'Manage your trusted emergency contacts',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()),
            ),
          ),

          const SizedBox(height: 20),

          const Text('Safety Tips',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Tip('Verify the driver\'s name and vehicle plate before getting in.'),
                SizedBox(height: 8),
                _Tip('Always ride in the backseat.'),
                SizedBox(height: 8),
                _Tip('Share your trip status with a friend or family member.'),
                SizedBox(height: 8),
                _Tip('Keep your phone charged during the trip.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SafetyTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 22, color: iconColor),
        ),
        title: Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 22),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final String text;
  const _Tip(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('•', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
      const SizedBox(width: 8),
      Expanded(child: Text(text,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
    ]);
  }
}
