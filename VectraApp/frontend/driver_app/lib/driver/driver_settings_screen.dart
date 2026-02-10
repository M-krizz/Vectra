import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../shared/widgets/active_eco_background.dart';

/// Settings Screen for driver preferences
class DriverSettingsScreen extends StatefulWidget {
  const DriverSettingsScreen({super.key});

  @override
  State<DriverSettingsScreen> createState() => _DriverSettingsScreenState();
}

class _DriverSettingsScreenState extends State<DriverSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = true;
  bool _soundEffects = true;
  bool _vibration = true;
  bool _darkMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const ActiveEcoBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildNotificationSettings(),
                      const SizedBox(height: 24),
                      _buildAppSettings(),
                      const SizedBox(height: 24),
                      _buildPrivacySettings(),
                      const SizedBox(height: 24),
                      _buildAboutSection(),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.white10,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Settings',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildNotificationSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notifications',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingToggle(
          'Push Notifications',
          'Receive ride requests and updates',
          _pushNotifications,
          (value) => setState(() => _pushNotifications = value),
        ),
        const SizedBox(height: 12),
        _buildSettingToggle(
          'Email Notifications',
          'Weekly earnings and updates',
          _emailNotifications,
          (value) => setState(() => _emailNotifications = value),
        ),
        const SizedBox(height: 12),
        _buildSettingToggle(
          'SMS Notifications',
          'Important alerts via SMS',
          _smsNotifications,
          (value) => setState(() => _smsNotifications = value),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms);
  }

  Widget _buildAppSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'App Preferences',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingToggle(
          'Sound Effects',
          'Play sounds for notifications',
          _soundEffects,
          (value) => setState(() => _soundEffects = value),
        ),
        const SizedBox(height: 12),
        _buildSettingToggle(
          'Vibration',
          'Vibrate on notifications',
          _vibration,
          (value) => setState(() => _vibration = value),
        ),
        const SizedBox(height: 12),
        _buildSettingToggle(
          'Dark Mode',
          'Use dark theme',
          _darkMode,
          (value) => setState(() => _darkMode = value),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 600.ms);
  }

  Widget _buildPrivacySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy & Security',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingItem(
          Icons.lock_outline,
          'Change Password',
          'Update your account password',
          () {},
        ),
        const SizedBox(height: 12),
        _buildSettingItem(
          Icons.privacy_tip_outlined,
          'Privacy Policy',
          'Read our privacy policy',
          () {},
        ),
        const SizedBox(height: 12),
        _buildSettingItem(
          Icons.description_outlined,
          'Terms of Service',
          'View terms and conditions',
          () {},
        ),
      ],
    ).animate().fadeIn(delay: 600.ms, duration: 600.ms);
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingItem(
          Icons.info_outline,
          'App Version',
          'v1.0.0',
          null,
        ),
        const SizedBox(height: 12),
        _buildSettingItem(
          Icons.update_outlined,
          'Check for Updates',
          'You\'re up to date',
          () {},
        ),
      ],
    ).animate().fadeIn(delay: 800.ms, duration: 600.ms);
  }

  Widget _buildSettingToggle(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    color: AppColors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.hyperLime,
            activeTrackColor: AppColors.neonGreen.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.carbonGrey.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.hyperLime, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      color: AppColors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios, color: AppColors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}
