import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/theme_mode_provider.dart';
import '../shared/widgets/active_eco_background.dart';

class DriverSettingsScreen extends ConsumerStatefulWidget {
  const DriverSettingsScreen({super.key});

  @override
  ConsumerState<DriverSettingsScreen> createState() => _DriverSettingsScreenState();
}

class _DriverSettingsScreenState extends ConsumerState<DriverSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = true;
  bool _soundEffects = true;
  bool _vibration = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          if (isDark) const ActiveEcoBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(colors, isDark),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildNotificationSettings(colors, isDark),
                      const SizedBox(height: 24),
                      _buildAppSettings(colors, isDark),
                      const SizedBox(height: 24),
                      _buildAboutSection(colors, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new, color: colors.onSurface),
            style: IconButton.styleFrom(
                backgroundColor: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.1),
                padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          Text('Settings', style: GoogleFonts.outfit(color: colors.onSurface, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildNotificationSettings(ColorScheme colors, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notifications', style: GoogleFonts.outfit(color: colors.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildSettingToggle('Push Notifications', 'Receive ride requests and updates', _pushNotifications, (v) => setState(() => _pushNotifications = v), colors, isDark),
        const SizedBox(height: 12),
        _buildSettingToggle('Email Notifications', 'Weekly earnings and updates', _emailNotifications, (v) => setState(() => _emailNotifications = v), colors, isDark),
        const SizedBox(height: 12),
        _buildSettingToggle('SMS Notifications', 'Important alerts via SMS', _smsNotifications, (v) => setState(() => _smsNotifications = v), colors, isDark),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms);
  }

  Widget _buildAppSettings(ColorScheme colors, bool isDark) {
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('App Preferences', style: GoogleFonts.outfit(color: colors.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildSettingToggle('Sound Effects', 'Play sounds for notifications', _soundEffects, (v) => setState(() => _soundEffects = v), colors, isDark),
        const SizedBox(height: 12),
        _buildSettingToggle('Vibration', 'Vibrate on notifications', _vibration, (v) => setState(() => _vibration = v), colors, isDark),
        const SizedBox(height: 12),
        _buildSettingToggle('Dark Mode', 'Use dark theme', isDarkMode, (v) {
          ref.read(themeModeProvider.notifier).state = v ? ThemeMode.dark : ThemeMode.light;
        }, colors, isDark),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 600.ms);
  }

  Widget _buildAboutSection(ColorScheme colors, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About', style: GoogleFonts.outfit(color: colors.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildSettingItem(Icons.info_outline, 'App Version', 'v1.0.0', null, colors, isDark),
      ],
    ).animate().fadeIn(delay: 600.ms, duration: 600.ms);
  }

  Widget _buildSettingToggle(String title, String subtitle, bool value, Function(bool) onChanged, ColorScheme colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
            color: isDark ? AppColors.carbonGrey.withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.dmSans(color: colors.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle, style: GoogleFonts.dmSans(color: colors.onSurfaceVariant, fontSize: 13)),
            ]),
          ),
            Switch(
              value: value,
              onChanged: onChanged,
              thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? (isDark ? AppColors.hyperLime : AppColors.primary) : null),
              trackColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? (isDark ? AppColors.neonGreen : colors.primary).withValues(alpha: 0.5)
                    : null,
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle, VoidCallback? onTap, ColorScheme colors, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
              color: isDark ? AppColors.carbonGrey.withValues(alpha: 0.6) : Colors.white,
          borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
              boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Icon(icon, color: isDark ? AppColors.hyperLime : AppColors.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: GoogleFonts.dmSans(color: colors.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.dmSans(color: colors.onSurfaceVariant, fontSize: 13)),
              ]),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios, color: colors.onSurfaceVariant, size: 16),
          ],
        ),
      ),
    );
  }
}
