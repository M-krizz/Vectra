import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../shared/widgets/active_eco_background.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/driver_status/presentation/providers/driver_status_providers.dart';
import 'driver_settings_screen.dart';
import 'driver_help_screen.dart';

class DriverProfileScreen extends ConsumerStatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  ConsumerState<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends ConsumerState<DriverProfileScreen> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final profile = ref.watch(driverProfileProvider);

    final driverName = profile?.name ?? 'Driver';
    final phoneNumber = profile?.phone ?? '';
    final email = profile?.email ?? '';
    final rating = profile?.rating ?? 0.0;
    final totalTrips = profile?.totalTrips ?? 0;
    final vehicleType = profile?.vehicleType ?? 'Vehicle';
    final status = profile?.documentsVerified == true ? 'APPROVED' : 'PENDING';

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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildProfileCard(colors, isDark, driverName, phoneNumber, email, rating, status),
                        const SizedBox(height: 24),
                        _buildStatsGrid(colors, isDark, totalTrips),
                        const SizedBox(height: 24),
                        _buildVehicleInfo(colors, isDark, vehicleType),
                        const SizedBox(height: 24),
                        _buildDocumentsSection(colors, isDark),
                        const SizedBox(height: 24),
                        _buildSettingsSection(colors, isDark),
                      ],
                    ),
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
          Text(
            'My Profile',
            style: GoogleFonts.outfit(color: colors.onSurface, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildProfileCard(ColorScheme colors, bool isDark, String driverName, String phoneNumber, String email, double rating, String status) {
    final accentColor = isDark ? AppColors.hyperLime : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.hyperLime.withValues(alpha: 0.2), AppColors.neonGreen.withValues(alpha: 0.1)]
              : [AppColors.primary.withValues(alpha: 0.08), AppColors.primaryLight.withValues(alpha: 0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [AppColors.hyperLime, AppColors.neonGreen]),
              border: Border.all(color: isDark ? Colors.white24 : Colors.black12, width: 3),
            ),
            child: const Icon(Icons.person, color: Colors.black, size: 48),
          ),
          const SizedBox(height: 20),
          Text(driverName, style: GoogleFonts.outfit(color: colors.onSurface, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: accentColor, size: 20),
              const SizedBox(width: 6),
              Text(rating.toStringAsFixed(1), style: GoogleFonts.dmSans(color: colors.onSurfaceVariant, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.5)),
                ),
                child: Text(status, style: GoogleFonts.dmSans(color: AppColors.successGreen, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: colors.outline.withValues(alpha: 0.2)),
          const SizedBox(height: 20),
          _buildProfileDetail(Icons.phone_outlined, phoneNumber, colors, isDark),
          if (email.isNotEmpty) ...[const SizedBox(height: 12),
          _buildProfileDetail(Icons.email_outlined, email, colors, isDark),],
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildProfileDetail(IconData icon, String value, ColorScheme colors, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: isDark ? AppColors.hyperLime : AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(value, style: GoogleFonts.dmSans(color: colors.onSurfaceVariant, fontSize: 14))),
      ],
    );
  }

  Widget _buildStatsGrid(ColorScheme colors, bool isDark, int totalTrips) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(icon: Icons.local_taxi, label: 'Total Trips', value: totalTrips.toString(), color: isDark ? AppColors.hyperLime : AppColors.primary, colors: colors, isDark: isDark)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard(icon: Icons.star, label: 'Rating', value: (ref.watch(driverProfileProvider)?.rating ?? 0.0).toStringAsFixed(1), color: isDark ? AppColors.neonGreen : AppColors.primaryDark, colors: colors, isDark: isDark)),
      ],
    ).animate().fadeIn(delay: 300.ms, duration: 600.ms);
  }

  Widget _buildStatCard({required IconData icon, required String label, required String value, required Color color, required ColorScheme colors, required bool isDark}) {
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
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.outfit(color: colors.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.dmSans(color: colors.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildVehicleInfo(ColorScheme colors, bool isDark, String vehicleType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vehicle Information', style: GoogleFonts.outfit(color: colors.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.carbonGrey.withValues(alpha: 0.6) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.directions_car, color: isDark ? AppColors.hyperLime : AppColors.primary, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vehicleType, style: GoogleFonts.outfit(color: colors.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Registered Vehicle', style: GoogleFonts.dmSans(color: colors.onSurfaceVariant, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: colors.outline.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              _buildVehicleDetail('Type', vehicleType, colors),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 600.ms);
  }

  Widget _buildVehicleDetail(String label, String value, ColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.dmSans(color: colors.onSurfaceVariant, fontSize: 14)),
        Text(value, style: GoogleFonts.dmSans(color: colors.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildDocumentsSection(ColorScheme colors, bool isDark) {
    final profile = ref.watch(driverProfileProvider);
    final docsVerified = profile?.documentsVerified ?? false;
    final docStatus = docsVerified ? 'Verified' : 'Pending Verification';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Documents', style: GoogleFonts.outfit(color: colors.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildDocumentCard('Driving License', docStatus, Icons.badge_outlined, docsVerified, colors, isDark),
        const SizedBox(height: 12),
        _buildDocumentCard('Vehicle RC', docStatus, Icons.description_outlined, docsVerified, colors, isDark),
        const SizedBox(height: 12),
        _buildDocumentCard('Insurance', docStatus, Icons.shield_outlined, docsVerified, colors, isDark),
      ],
    ).animate().fadeIn(delay: 500.ms, duration: 600.ms);
  }

  Widget _buildDocumentCard(String title, String status, IconData icon, bool isVerified, ColorScheme colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.carbonGrey.withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Icon(icon, color: isDark ? AppColors.hyperLime : AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.dmSans(color: colors.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
                Text(status, style: GoogleFonts.dmSans(color: colors.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
          Icon(
            isVerified ? Icons.check_circle : Icons.pending,
            color: isVerified ? AppColors.successGreen : (isDark ? AppColors.neonGreen : AppColors.primary),
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(ColorScheme colors, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Settings', style: GoogleFonts.outfit(color: colors.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildSettingItem(Icons.settings_outlined, 'Settings', () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverSettingsScreen()));
        }, colors: colors, isDark: isDark),
        const SizedBox(height: 12),
        _buildSettingItem(Icons.help_outline, 'Help & Support', () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverHelpScreen()));
        }, colors: colors, isDark: isDark),
        const SizedBox(height: 12),
        _buildSettingItem(Icons.info_outline, 'About', () {
          showAboutDialog(
            context: context,
            applicationName: 'Vectra Driver',
            applicationVersion: '1.0.0',
            applicationLegalese: '\u00a9 2024 Vectra Technologies',
          );
        }, colors: colors, isDark: isDark),
        const SizedBox(height: 12),
        _buildSettingItem(Icons.logout, 'Logout', () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(authProvider.notifier).logout();
                  },
                  child: Text('Logout', style: TextStyle(color: colors.error)),
                ),
              ],
            ),
          );
        }, colors: colors, isDark: isDark, isDestructive: true),
      ],
    ).animate().fadeIn(delay: 600.ms, duration: 600.ms);
  }

  Widget _buildSettingItem(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false, required ColorScheme colors, required bool isDark}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.carbonGrey.withValues(alpha: 0.6) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? colors.error : (isDark ? AppColors.hyperLime : AppColors.primary), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label, style: GoogleFonts.dmSans(color: isDestructive ? colors.error : colors.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.arrow_forward_ios, color: colors.onSurfaceVariant, size: 16),
          ],
        ),
      ),
    );
  }
}
