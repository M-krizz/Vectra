import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import 'saved_places_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.help_outline_rounded, size: 16),
              label: const Text('Help'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // ── GENERAL section ───────────────────────────────────────────
          _SectionHeader(label: 'GENERAL'),
          _SettingsGroup(
            items: [
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                title: 'Profile',
                subtitle: 'Edit your personal information',
                onTap: () => Navigator.pop(context),
              ),
              _SettingsTile(
                icon: Icons.favorite_outline_rounded,
                title: 'Favourites',
                subtitle: 'Manage favourite locations',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavedPlacesScreen()),
                ),
              ),
              _SettingsTile(
                icon: Icons.tune_rounded,
                title: 'Preferences',
                subtitle: 'Manage preferences',
                onTap: () => _showComingSoon(context),
              ),
              _SettingsTile(
                icon: Icons.add_to_home_screen_rounded,
                title: 'App shortcuts',
                subtitle: 'Create shortcuts on home launcher',
                onTap: () => _showComingSoon(context),
                showDivider: false,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── OTHERS section ────────────────────────────────────────────
          _SectionHeader(label: 'OTHERS'),
          _SettingsGroup(
            items: [
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About',
                subtitle: '1.0.0',
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'Vectra Rider',
                  applicationVersion: '1.0.0',
                ),
              ),
              _SettingsTile(
                icon: Icons.bug_report_outlined,
                title: 'Subscribe to Beta',
                subtitle: 'Get early access to latest features',
                onTap: () => _showComingSoon(context),
              ),
              _SettingsTile(
                icon: Icons.logout_rounded,
                title: 'Logout',
                onTap: () => _showLogoutDialog(context),
              ),
              _SettingsTile(
                icon: Icons.delete_outline_rounded,
                title: 'Delete Account',
                titleColor: AppColors.error,
                iconColor: AppColors.error,
                onTap: () => _showDeleteDialog(context),
                showDivider: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon!')),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account'),
        content: const Text(
          'This action is irreversible. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Section header ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 16, 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── Settings group (rounded card) ────────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsTile> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: items),
    );
  }
}

// ─── Individual tile ───────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? titleColor;
  final Color? iconColor;
  final bool showDivider;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.titleColor,
    this.iconColor,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 22),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: titleColor ?? AppColors.textPrimary,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                )
              : null,
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 52, endIndent: 0, color: AppColors.divider),
      ],
    );
  }
}
