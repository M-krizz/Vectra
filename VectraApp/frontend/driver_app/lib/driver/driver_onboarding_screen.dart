import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../shared/widgets/active_eco_background.dart';
import '../shared/widgets/document_upload_zone.dart';
import '../shared/widgets/premium_text_field.dart';
import 'driver_home_screen.dart';


/// Driver Onboarding Flow
/// Collects driver profile, vehicle details, and documents
class DriverOnboardingScreen extends StatefulWidget {
  const DriverOnboardingScreen({super.key});

  @override
  State<DriverOnboardingScreen> createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends State<DriverOnboardingScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _vehiclePlateController = TextEditingController();
  final TextEditingController _vehicleColorController = TextEditingController();
  
  String _selectedVehicleType = 'Sedan';
  File? _licenseDocument;
  File? _rcDocument;
  File? _insuranceDocument;

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
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      // Submit onboarding
      _submitOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _submitOnboarding() {
    // Show success dialog
    showDialog(
      context: context,
      builder: (context) => _buildSuccessDialog(),
    );
  }

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
                _buildProgressIndicator(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildProfileStep(),
                      _buildVehicleStep(),
                      _buildDocumentsStep(),
                    ],
                  ),
                ),
                _buildNavigationButtons(),
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
          if (_currentStep > 0)
            IconButton(
              onPressed: _previousStep,
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.white10,
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
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Step ${_currentStep + 1} of 3',
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
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildProgressIndicator() {
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
                color: isActive ? AppColors.hyperLime : AppColors.white10,
                borderRadius: BorderRadius.circular(2),
              ),
            ).animate(target: isActive ? 1 : 0).scaleX(
                  begin: 0,
                  alignment: Alignment.centerLeft,
                  duration: 400.ms,
                ),
          );
        }),
      ),
    );
  }

  Widget _buildProfileStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
          const SizedBox(height: 8),
          Text(
            'Tell us about yourself',
            style: GoogleFonts.dmSans(
              color: AppColors.white70,
              fontSize: 16,
            ),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
          const SizedBox(height: 32),
          PremiumTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Enter your full name',
            prefixIcon: Icons.person_outline,
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
          const SizedBox(height: 20),
          PremiumTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: '+91 XXXXX XXXXX',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
          const SizedBox(height: 20),
          PremiumTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'your.email@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
          const SizedBox(height: 20),
          PremiumTextField(
            controller: _licenseController,
            label: 'License Number',
            hint: 'DL-XXXXXXXXXX',
            prefixIcon: Icons.badge_outlined,
          ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildVehicleStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Details',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
          const SizedBox(height: 8),
          Text(
            'Add your vehicle information',
            style: GoogleFonts.dmSans(
              color: AppColors.white70,
              fontSize: 16,
            ),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
          const SizedBox(height: 32),
          
          // Vehicle Type Selector
          Text(
            'Vehicle Type',
            style: GoogleFonts.dmSans(
              color: AppColors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildVehicleTypeChip('Sedan'),
              const SizedBox(width: 12),
              _buildVehicleTypeChip('SUV'),
              const SizedBox(width: 12),
              _buildVehicleTypeChip('Hatchback'),
            ],
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
          const SizedBox(height: 24),
          
          PremiumTextField(
            controller: _vehicleModelController,
            label: 'Vehicle Model',
            hint: 'e.g., Honda City',
            prefixIcon: Icons.directions_car_outlined,
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
          const SizedBox(height: 20),
          PremiumTextField(
            controller: _vehiclePlateController,
            label: 'License Plate',
            hint: 'KA-01-AB-1234',
            prefixIcon: Icons.pin_outlined,
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
          const SizedBox(height: 20),
          PremiumTextField(
            controller: _vehicleColorController,
            label: 'Vehicle Color',
            hint: 'e.g., White',
            prefixIcon: Icons.palette_outlined,
          ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildVehicleTypeChip(String type) {
    final isSelected = _selectedVehicleType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVehicleType = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.hyperLime, AppColors.neonGreen],
                )
              : null,
          color: isSelected ? null : AppColors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.white20,
          ),
        ),
        child: Text(
          type,
          style: GoogleFonts.dmSans(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Documents',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
          const SizedBox(height: 8),
          Text(
            'Required for verification',
            style: GoogleFonts.dmSans(
              color: AppColors.white70,
              fontSize: 16,
            ),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
          const SizedBox(height: 32),
          
          _buildDocumentUploadCard(
            title: 'Driving License',
            subtitle: 'Upload a clear photo of your license',
            icon: Icons.badge_outlined,
            file: _licenseDocument,
            onUpload: (file) {
              setState(() {
                _licenseDocument = file;
              });
            },
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
          const SizedBox(height: 20),
          
          _buildDocumentUploadCard(
            title: 'Vehicle RC',
            subtitle: 'Registration certificate',
            icon: Icons.description_outlined,
            file: _rcDocument,
            onUpload: (file) {
              setState(() {
                _rcDocument = file;
              });
            },
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
          const SizedBox(height: 20),
          
          _buildDocumentUploadCard(
            title: 'Insurance',
            subtitle: 'Valid vehicle insurance',
            icon: Icons.shield_outlined,
            file: _insuranceDocument,
            onUpload: (file) {
              setState(() {
                _insuranceDocument = file;
              });
            },
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required File? file,
    required Function(File) onUpload,
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
          Row(
            children: [
              Icon(icon, color: AppColors.hyperLime, size: 24),
              const SizedBox(width: 12),
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
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        color: AppColors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              // Mock file selection
              // In real app, use image_picker package
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: file != null ? AppColors.hyperLime : AppColors.white20,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    file != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                    color: file != null ? AppColors.hyperLime : AppColors.white70,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    file != null ? 'Uploaded' : 'Tap to upload',
                    style: GoogleFonts.dmSans(
                      color: file != null ? AppColors.hyperLime : AppColors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppColors.voidBlack.withOpacity(0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: _buildButton(
                label: 'Back',
                onTap: _previousStep,
                isPrimary: false,
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _buildButton(
              label: _currentStep == 2 ? 'Submit' : 'Continue',
              onTap: _nextStep,
              isPrimary: true,
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [AppColors.hyperLime, AppColors.neonGreen],
                )
              : null,
          color: isPrimary ? null : AppColors.white10,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimary ? Colors.transparent : AppColors.white20,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              color: isPrimary ? Colors.black : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.carbonGrey.withOpacity(0.95),
              AppColors.voidBlack.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.hyperLime, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.hyperLime,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.black,
                size: 48,
              ),
            ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
            const SizedBox(height: 24),
            Text(
              'Application Submitted!',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your application is under review. We\'ll notify you once approved.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: AppColors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                // Close dialog
                Navigator.of(context).pop();
                // Navigate to driver home screen and clear all previous routes
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
                  (route) => false,
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.hyperLime, AppColors.neonGreen],
                  ),
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
