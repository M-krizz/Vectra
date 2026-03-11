import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import 'profile_details_screen.dart';
import 'saved_places_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthAuthenticated ? authState.user : null;

        return Scaffold(
          backgroundColor: colors.surface,
          appBar: AppBar(
            title: Text('Settings', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: colors.onSurface)),
            backgroundColor: colors.surface,
            foregroundColor: colors.onSurface,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: colors.outline.withValues(alpha: 0.3)),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.help_outline_rounded, size: 16, color: colors.onSurface),
                  label: Text('Help', style: TextStyle(color: colors.onSurface)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.onSurface,
                    side: BorderSide(color: colors.outline.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            children: [
              _sectionLabel('GENERAL', colors),
              const SizedBox(height: 8),
              _SettingsCard(items: [
                _SettingsTile(icon: Icons.person_outline_rounded, title: 'Profile', subtitle: user?.phone ?? '', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileDetailsScreen()))),
                _SettingsTile(icon: Icons.favorite_outline_rounded, title: 'Favourites', subtitle: 'Manage favourite locations', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedPlacesScreen())), isLast: true),
              ]),

              const SizedBox(height: 20),
              _sectionLabel('OTHERS', colors),
              const SizedBox(height: 8),
              _SettingsCard(items: [
                _SettingsTile(icon: Icons.info_outline_rounded, title: 'About', subtitle: '1.0.0', onTap: () => showAboutDialog(context: context, applicationName: 'Vectra Rider', applicationVersion: '1.0.0', applicationLegalese: ' 2025 Vectra. All rights reserved.')),
                _SettingsTile(icon: Icons.logout_rounded, title: 'Logout', onTap: () => _showLogoutDialog(context)),
                _SettingsTile(icon: Icons.delete_outline_rounded, title: 'Delete Account', titleColor: colors.error, iconColor: colors.error, onTap: () => _showDeleteDialog(context), isLast: true),
              ]),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String label, ColorScheme colors) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.primary, letterSpacing: 0.8)),
  );

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
            onPressed: () { Navigator.pop(context); context.read<AuthBloc>().add(AuthLogoutRequested()); },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
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
        content: const Text('This action is irreversible. All your data will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<_SettingsTile> items;
  const _SettingsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: items),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? titleColor;
  final Color? iconColor;
  final bool isLast;

  const _SettingsTile({required this.icon, required this.title, this.subtitle, required this.onTap, this.titleColor, this.iconColor, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(16)) : BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 22, color: iconColor ?? colors.onSurfaceVariant),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: titleColor ?? colors.onSurface)),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[const SizedBox(height: 2), Text(subtitle!, style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant))],
                ])),
                Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant, size: 20),
              ],
            ),
          ),
        ),
        if (!isLast) Divider(height: 1, indent: 54, color: colors.outline.withValues(alpha: 0.2)),
      ],
    );
  }
}
