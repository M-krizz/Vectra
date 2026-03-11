import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../shared/widgets/active_eco_background.dart';

class DriverHelpScreen extends StatelessWidget {
  const DriverHelpScreen({super.key});

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
                _buildHeader(context, colors, isDark),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildFAQSection(colors, isDark),
                      const SizedBox(height: 24),
                      _buildContactSection(context, colors, isDark),
                      const SizedBox(height: 24),
                      _buildEmergencySection(context, colors, isDark),
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

  Widget _buildHeader(BuildContext context, ColorScheme colors, bool isDark) {
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
          Text('Help & Support', style: GoogleFonts.outfit(color: colors.onSurface, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildFAQSection(ColorScheme colors, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Frequently Asked Questions', style: GoogleFonts.outfit(color: colors.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildFAQItem('How do I go online?', 'Tap the online/offline toggle on your home screen. Make sure your GPS is enabled.', colors, isDark),
        const SizedBox(height: 12),
        _buildFAQItem('How are earnings calculated?', 'Earnings = Base fare + Distance charges + Time charges + Surge (if applicable) - Platform fee', colors, isDark),
        const SizedBox(height: 12),
        _buildFAQItem('When do I get paid?', 'Earnings are transferred to your bank account weekly, every Monday.', colors, isDark),
        const SizedBox(height: 12),
        _buildFAQItem('What if rider doesn\'t show up?', 'Wait for 5 minutes, then you can cancel with a cancellation fee.', colors, isDark),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms);
  }

  Widget _buildFAQItem(String question, String answer, ColorScheme colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.carbonGrey.withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.help_outline, color: isDark ? AppColors.hyperLime : AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(question, style: GoogleFonts.dmSans(color: colors.onSurface, fontSize: 16, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 12),
          Text(answer, style: GoogleFonts.dmSans(color: colors.onSurfaceVariant, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context, ColorScheme colors, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contact Support', style: GoogleFonts.outfit(color: colors.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildContactButton(icon: Icons.phone_outlined, label: 'Call Support', subtitle: '1800-XXX-XXXX', onTap: () => launchUrl(Uri.parse('tel:1800XXXXXXX')), colors: colors, isDark: isDark),
        const SizedBox(height: 12),
        _buildContactButton(icon: Icons.email_outlined, label: 'Email Support', subtitle: 'support@vectra.com', onTap: () => launchUrl(Uri.parse('mailto:support@vectra.com?subject=Driver%20Support%20Request')), colors: colors, isDark: isDark),
        const SizedBox(height: 12),
        _buildContactButton(icon: Icons.chat_outlined, label: 'Live Chat', subtitle: 'Chat with our team', onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Live chat coming soon'))), colors: colors, isDark: isDark),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 600.ms);
  }

  Widget _buildContactButton({required IconData icon, required String label, required String subtitle, required VoidCallback onTap, required ColorScheme colors, required bool isDark}) {
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isDark ? AppColors.hyperLime : AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: GoogleFonts.dmSans(color: colors.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
                Text(subtitle, style: GoogleFonts.dmSans(color: colors.onSurfaceVariant, fontSize: 13)),
              ]),
            ),
            Icon(Icons.arrow_forward_ios, color: colors.onSurfaceVariant, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencySection(BuildContext context, ColorScheme colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors.error.withValues(alpha: 0.2), colors.error.withValues(alpha: 0.1)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.error.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        children: [
          Icon(Icons.emergency, color: colors.error, size: 48),
          const SizedBox(height: 16),
          Text('Emergency Hotline', style: GoogleFonts.outfit(color: colors.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('24/7 Emergency Support', style: GoogleFonts.dmSans(color: colors.onSurfaceVariant, fontSize: 14)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => launchUrl(Uri.parse('tel:112')),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(color: colors.error, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone, color: colors.onError, size: 20),
                  const SizedBox(width: 12),
                  Text('Call Emergency', style: GoogleFonts.dmSans(color: colors.onError, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 600.ms);
  }
}
