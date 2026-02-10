import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../shared/widgets/active_eco_background.dart';
import 'driver_settings_screen.dart';
import 'driver_help_screen.dart';


/// Driver Profile Screen
/// Shows driver information, stats, and settings
class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  // Mock driver data
  final String _driverName = 'Rajesh Kumar';
  final String _phoneNumber = '+91 98765 43210';
  final String _email = 'rajesh.kumar@example.com';
  final String _licenseNumber = 'DL-1420110012345';
  final String _vehicleModel = 'Honda City';
  final String _vehiclePlate = 'KA-01-AB-1234';
  final double _rating = 4.8;
  final int _totalTrips = 1247;
  final String _memberSince = 'Jan 2024';
  final String _status = 'APPROVED';

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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildProfileCard(),
                        const SizedBox(height: 24),
                        _buildStatsGrid(),
                        const SizedBox(height: 24),
                        _buildVehicleInfo(),
                        const SizedBox(height: 24),
                        _buildDocumentsSection(),
                        const SizedBox(height: 24),
                        _buildSettingsSection(),
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
            'My Profile',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              // Edit profile
            },
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.white10,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.hyperLime.withOpacity(0.2),
            AppColors.neonGreen.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.hyperLime.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.hyperLime, AppColors.neonGreen],
              ),
              border: Border.all(color: Colors.white24, width: 3),
            ),
            child: const Icon(Icons.person, color: Colors.black, size: 48),
          ),
          const SizedBox(height: 20),
          Text(
            _driverName,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: AppColors.neonGreen, size: 20),
              const SizedBox(width: 6),
              Text(
                _rating.toString(),
                style: GoogleFonts.dmSans(
                  color: AppColors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.successGreen.withOpacity(0.5)),
                ),
                child: Text(
                  _status,
                  style: GoogleFonts.dmSans(
                    color: AppColors.successGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: AppColors.white10),
          const SizedBox(height: 20),
          _buildProfileDetail(Icons.phone_outlined, _phoneNumber),
          const SizedBox(height: 12),
          _buildProfileDetail(Icons.email_outlined, _email),
          const SizedBox(height: 12),
          _buildProfileDetail(Icons.badge_outlined, _licenseNumber),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildProfileDetail(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.hyperLime, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.dmSans(
              color: AppColors.white70,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_taxi,
            label: 'Total Trips',
            value: _totalTrips.toString(),
            color: AppColors.hyperLime,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.calendar_today,
            label: 'Member Since',
            value: _memberSince,
            color: AppColors.neonGreen,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms, duration: 600.ms);
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: AppColors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Information',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.carbonGrey.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.white10),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      color: AppColors.hyperLime,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _vehicleModel,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _vehiclePlate,
                          style: GoogleFonts.dmSans(
                            color: AppColors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: AppColors.white10),
              const SizedBox(height: 16),
              _buildVehicleDetail('Type', 'Sedan'),
              const SizedBox(height: 12),
              _buildVehicleDetail('Color', 'White'),
              const SizedBox(height: 12),
              _buildVehicleDetail('Year', '2022'),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 600.ms);
  }

  Widget _buildVehicleDetail(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: AppColors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documents',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildDocumentCard('Driving License', 'Verified', Icons.badge_outlined, true),
        const SizedBox(height: 12),
        _buildDocumentCard('Vehicle RC', 'Verified', Icons.description_outlined, true),
        const SizedBox(height: 12),
        _buildDocumentCard('Insurance', 'Expires: Dec 2026', Icons.shield_outlined, true),
      ],
    ).animate().fadeIn(delay: 500.ms, duration: 600.ms);
  }

  Widget _buildDocumentCard(String title, String status, IconData icon, bool isVerified) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  status,
                  style: GoogleFonts.dmSans(
                    color: AppColors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isVerified ? Icons.check_circle : Icons.pending,
            color: isVerified ? AppColors.successGreen : AppColors.neonGreen,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingItem(Icons.notifications_outlined, 'Notifications', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DriverSettingsScreen()),
          );
        }),
        const SizedBox(height: 12),
        _buildSettingItem(Icons.lock_outline, 'Privacy & Security', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DriverSettingsScreen()),
          );
        }),
        const SizedBox(height: 12),
        _buildSettingItem(Icons.help_outline, 'Help & Support', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DriverHelpScreen()),
          );
        }),
        const SizedBox(height: 12),
        _buildSettingItem(Icons.info_outline, 'About', () {}),
        const SizedBox(height: 12),
        _buildSettingItem(Icons.logout, 'Logout', () {
          // Navigate back to login and clear stack
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }, isDestructive: true),
      ],
    ).animate().fadeIn(delay: 600.ms, duration: 600.ms);
  }

  Widget _buildSettingItem(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.carbonGrey.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.white10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? AppColors.errorRed : AppColors.hyperLime,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  color: isDestructive ? AppColors.errorRed : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
