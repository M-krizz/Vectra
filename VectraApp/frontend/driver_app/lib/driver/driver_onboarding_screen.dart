import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/driver_status/presentation/providers/driver_status_providers.dart';
import '../features/map_home/presentation/screens/driver_dashboard_screen.dart';
import '../features/profile/repository/driver_profile_repository.dart';
import '../shared/widgets/active_eco_background.dart';
import '../shared/widgets/document_upload_zone.dart';
import '../shared/widgets/premium_text_field.dart';
import '../theme/app_colors.dart';

class DriverOnboardingScreen extends ConsumerStatefulWidget {
  const DriverOnboardingScreen({super.key});

  @override
  ConsumerState<DriverOnboardingScreen> createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends ConsumerState<DriverOnboardingScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _vehiclePlateController = TextEditingController();
  final TextEditingController _vehicleColorController = TextEditingController();
  String _selectedVehicleType = 'Sedan';

  final Map<String, bool> _uploadingDocs = {
    'DRIVING_LICENSE': false,
    'VEHICLE_RC': false,
    'INSURANCE': false,
  };

  final Map<String, bool> _uploadedDocs = {
    'DRIVING_LICENSE': false,
    'VEHICLE_RC': false,
    'INSURANCE': false,
  };

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _licenseController.dispose();
    _vehicleModelController.dispose();
    _vehiclePlateController.dispose();
    _vehicleColorController.dispose();
    super.dispose();
  }

  void _nextStep() {
    final validationError = _validateCurrentStep();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _submitOnboarding();
    }
  }

  String? _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_nameController.text.trim().isEmpty) return 'Please enter your full name';
        if (_phoneController.text.trim().isEmpty) return 'Please enter your phone number';
        if (_licenseController.text.trim().isEmpty) return 'Please enter your license number';
        return null;
      case 1:
        if (_vehicleModelController.text.trim().isEmpty) return 'Please enter your vehicle model';
        if (_vehiclePlateController.text.trim().isEmpty) return 'Please enter your license plate';
        if (_vehicleColorController.text.trim().isEmpty) return 'Please enter your vehicle color';
        return null;
      case 2:
        return null; // Docs optional for now
      default:
        return null;
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _submitOnboarding() {
    ref.read(authProvider.notifier).completeOnboarding();
    showDialog(context: context, builder: (context) => _buildSuccessDialog());
  }

  Future<void> _pickAndUpload(String docType, String title) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _uploadingDocs[docType] = true);
    try {
      await ref.read(driverProfileRepositoryProvider).uploadDocument(
            File(picked.path),
            docType,
          );
      if (mounted) {
        setState(() => _uploadedDocs[docType] = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title uploaded successfully')),
        );
      }
      await ref.read(driverStatusProvider.notifier).loadProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingDocs[docType] = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.hyperLime : AppColors.primary;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          if (isDark) const ActiveEcoBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(colors, isDark),
                _buildProgressIndicator(colors, isDark, accent),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildProfileStep(colors, isDark),
                      _buildVehicleStep(colors, isDark, accent),
                      _buildDocumentsStep(colors, isDark, accent),
                    ],
                  ),
                ),
                _buildNavigationButtons(colors, isDark, accent),
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
          if (_currentStep > 0)
            IconButton(
              onPressed: _previousStep,
              icon: Icon(Icons.arrow_back_ios_new, color: colors.onSurface),
              style: IconButton.styleFrom(
                backgroundColor: isDark
                  ? AppColors.white10
                  : colors.outline.withValues(alpha: 0.1),
                padding: const EdgeInsets.all(12),
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Driver Onboarding',
                  style: GoogleFonts.outfit(
                    color: colors.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Step ${_currentStep + 1} of 3',
                  style: GoogleFonts.dmSans(
                    color: colors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildProgressIndicator(ColorScheme colors, bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
              decoration: BoxDecoration(
                color: isActive
                  ? accent
                  : (isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(2),
              ),
            ).animate(target: isActive ? 1 : 0).scaleX(
                  begin: 0,
                  alignment: Alignment.centerLeft,
                  duration: 300.ms,
                ),
          );
        }),
      ),
    );
  }

  Widget _buildProfileStep(ColorScheme colors, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Details',
            style: GoogleFonts.outfit(
              color: colors.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
          const SizedBox(height: 8),
          Text(
            'Tell us about you',
            style: GoogleFonts.dmSans(
              color: colors.onSurfaceVariant,
              fontSize: 16,
            ),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
          const SizedBox(height: 24),
          PremiumTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'e.g., Alex Rider',
            prefixIcon: Icon(Icons.person_outline, color: colors.onSurfaceVariant, size: 20),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
          const SizedBox(height: 20),
          PremiumTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: '+91 98765 43210',
            prefixIcon: Icon(Icons.phone_outlined, color: colors.onSurfaceVariant, size: 20),
            keyboardType: TextInputType.phone,
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
          const SizedBox(height: 20),
          PremiumTextField(
            controller: _emailController,
            label: 'Email (optional)',
            hint: 'you@example.com',
            prefixIcon: Icon(Icons.email_outlined, color: colors.onSurfaceVariant, size: 20),
            keyboardType: TextInputType.emailAddress,
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
          const SizedBox(height: 20),
          PremiumTextField(
            controller: _licenseController,
            label: 'Driving License Number',
            hint: 'DL-XXXXXXXX',
            prefixIcon: Icon(Icons.badge_outlined, color: colors.onSurfaceVariant, size: 20),
          ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildVehicleStep(ColorScheme colors, bool isDark, Color accent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Details',
            style: GoogleFonts.outfit(
              color: colors.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
          const SizedBox(height: 8),
          Text(
            'Your primary ride',
            style: GoogleFonts.dmSans(
              color: colors.onSurfaceVariant,
              fontSize: 16,
            ),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildVehicleTypeChip('Sedan', colors, isDark, accent),
              _buildVehicleTypeChip('SUV', colors, isDark, accent),
              _buildVehicleTypeChip('Hatchback', colors, isDark, accent),
              _buildVehicleTypeChip('Auto', colors, isDark, accent),
            ],
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
          const SizedBox(height: 24),
          PremiumTextField(
            controller: _vehicleModelController,
            label: 'Vehicle Model',
            hint: 'e.g., Honda City',
            prefixIcon: Icon(Icons.directions_car_outlined, color: colors.onSurfaceVariant, size: 20),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
          const SizedBox(height: 20),
          PremiumTextField(
            controller: _vehiclePlateController,
            label: 'License Plate',
            hint: 'KA-01-AB-1234',
            prefixIcon: Icon(Icons.pin_outlined, color: colors.onSurfaceVariant, size: 20),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
          const SizedBox(height: 20),
          PremiumTextField(
            controller: _vehicleColorController,
            label: 'Vehicle Color',
            hint: 'e.g., White',
            prefixIcon: Icon(Icons.palette_outlined, color: colors.onSurfaceVariant, size: 20),
          ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildVehicleTypeChip(String type, ColorScheme colors, bool isDark, Color accent) {
    final isSelected = _selectedVehicleType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedVehicleType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected && isDark
              ? const LinearGradient(colors: [AppColors.hyperLime, AppColors.neonGreen])
              : null,
            color: isSelected
              ? (isDark ? null : accent)
              : (isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? AppColors.white20 : colors.outline.withValues(alpha: 0.3)),
          ),
        ),
        child: Text(
          type,
          style: GoogleFonts.dmSans(
            color: isSelected ? (isDark ? Colors.black : Colors.white) : colors.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentsStep(ColorScheme colors, bool isDark, Color accent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Documents',
            style: GoogleFonts.outfit(
              color: colors.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
          const SizedBox(height: 8),
          Text(
            'Required for verification',
            style: GoogleFonts.dmSans(
              color: colors.onSurfaceVariant,
              fontSize: 16,
            ),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
          const SizedBox(height: 32),
          DocumentUploadZone(
            title: 'Driving License',
            subtitle: _uploadedDocs['DRIVING_LICENSE'] == true
                ? 'Uploaded'
                : 'Upload a clear photo of your license',
            isUploading: _uploadingDocs['DRIVING_LICENSE'] ?? false,
            onUpload: () => _pickAndUpload('DRIVING_LICENSE', 'Driving License'),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
          const SizedBox(height: 20),
          DocumentUploadZone(
            title: 'Vehicle RC',
            subtitle: _uploadedDocs['VEHICLE_RC'] == true
                ? 'Uploaded'
                : 'Registration certificate',
            isUploading: _uploadingDocs['VEHICLE_RC'] ?? false,
            onUpload: () => _pickAndUpload('VEHICLE_RC', 'Vehicle RC'),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
          const SizedBox(height: 20),
          DocumentUploadZone(
            title: 'Insurance',
            subtitle: _uploadedDocs['INSURANCE'] == true
                ? 'Uploaded'
                : 'Valid vehicle insurance',
            isUploading: _uploadingDocs['INSURANCE'] ?? false,
            onUpload: () => _pickAndUpload('INSURANCE', 'Insurance'),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(ColorScheme colors, bool isDark, Color accent) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: _buildButton(
                label: 'Back',
                onTap: _previousStep,
                isPrimary: false,
                colors: colors,
                isDark: isDark,
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _buildButton(
              label: _currentStep == 2 ? 'Submit' : 'Continue',
              onTap: _nextStep,
              isPrimary: true,
              colors: colors,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
    required ColorScheme colors,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: isPrimary ? const LinearGradient(colors: [AppColors.hyperLime, AppColors.neonGreen]) : null,
          color: isPrimary ? null : (isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimary ? Colors.transparent : (isDark ? AppColors.white20 : colors.outline.withValues(alpha: 0.3)),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              color: isPrimary ? Colors.black : colors.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessDialog() {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.hyperLime : AppColors.primary;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? AppColors.carbonGrey.withValues(alpha: 0.95) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent,
              ),
              child: Icon(
                Icons.check,
                color: isDark ? Colors.black : Colors.white,
                size: 48,
              ),
            ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
            const SizedBox(height: 24),
            Text(
              'Application Submitted!',
              style: GoogleFonts.outfit(
                color: colors.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Your application is under review. We'll notify you once approved.",
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: colors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const DriverDashboardScreen()),
                  (route) => false,
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.hyperLime, AppColors.neonGreen]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Done',
                    style: GoogleFonts.dmSans(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ).animate().scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
    );
  }
}
