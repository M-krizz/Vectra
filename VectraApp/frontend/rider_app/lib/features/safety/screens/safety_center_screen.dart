import 'package:flutter/material.dart';
import '../../../../config/app_theme.dart';
import 'sos_screen.dart';
import 'incident_report_screen.dart';
import 'emergency_contacts_screen.dart';

class SafetyCenterScreen extends StatelessWidget {
  const SafetyCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text('Safety Center',
            style: TextStyle(fontWeight: FontWeight.w700, color: colors.onSurface)),
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: colors.outline.withValues(alpha: 0.2)),
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
                color: colors.error,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SOS Emergency',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colors.onError)),
                    const SizedBox(height: 4),
                    Text('Tap to call emergency services',
                        style: TextStyle(fontSize: 13, color: colors.onError.withValues(alpha: 0.7))),
                  ],
                ),
                const Spacer(),
                Icon(Icons.emergency_share_rounded, size: 40, color: colors.onError),
              ]),
            ),
          ),

          const SizedBox(height: 20),

          Text('During Your Ride',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.onSurfaceVariant)),
          const SizedBox(height: 12),

          _SafetyTile(
            icon: Icons.report_problem_rounded,
            iconColor: AppColors.warning,
            iconBg: AppColors.warning.withValues(alpha: 0.1),
            title: 'Report an Issue',
            subtitle: 'Report unsafe driver behaviour or route concerns',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IncidentReportScreen()),
            ),
            colors: colors,
          ),

          _SafetyTile(
            icon: Icons.share_location_rounded,
            iconColor: colors.primary,
            iconBg: colors.primary.withValues(alpha: 0.1),
            title: 'Share My Trip',
            subtitle: 'Send live location to a trusted contact',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Trip share link copied to clipboard!')),
              );
            },
            colors: colors,
          ),

          _SafetyTile(
            icon: Icons.contacts_rounded,
            iconColor: AppColors.secondary,
            iconBg: AppColors.secondary.withValues(alpha: 0.1),
            title: 'Emergency Contacts',
            subtitle: 'Manage your trusted emergency contacts',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()),
            ),
            colors: colors,
          ),

          const SizedBox(height: 20),

          Text('Safety Tips',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.onSurfaceVariant)),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Tip('Verify the driver\'s name and vehicle plate before getting in.', colors: colors),
                const SizedBox(height: 8),
                _Tip('Always ride in the backseat.', colors: colors),
                const SizedBox(height: 8),
                _Tip('Share your trip status with a friend or family member.', colors: colors),
                const SizedBox(height: 8),
                _Tip('Keep your phone charged during the trip.', colors: colors),
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
  final ColorScheme colors;

  const _SafetyTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.colors,
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
          side: BorderSide(color: colors.outline.withValues(alpha: 0.3)),
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 22, color: iconColor),
        ),
        title: Text(title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.onSurface)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
        trailing: Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant, size: 22),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final String text;
  final ColorScheme colors;
  const _Tip(this.text, {required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('\u2022', style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700)),
      const SizedBox(width: 8),
      Expanded(child: Text(text,
          style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant))),
    ]);
  }
}
