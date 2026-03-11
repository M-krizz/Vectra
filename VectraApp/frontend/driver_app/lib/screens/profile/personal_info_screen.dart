import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/signup_data.dart';
import '../../utils/notification_overlay.dart';
import '../../services/legacy_driver_profile_service.dart';

class PersonalInfoScreen extends StatefulWidget {
  final SignUpData? signUpData;
  const PersonalInfoScreen({super.key, this.signUpData});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  bool _isEditing = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers for the fields
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.signUpData?.fullName ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.signUpData?.phoneNumber ?? '',
    );
    _emailController = TextEditingController(
      text: widget.signUpData?.email ?? '',
    );
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await LegacyDriverProfileService.fetchProfile();
      if (!mounted) return;

      _nameController.text = (profile['fullName'] ?? '').toString();
      _phoneController.text = (profile['phone'] ?? '').toString();
      _emailController.text = (profile['email'] ?? '').toString();
    } catch (_) {
      // Keep existing values if backend fetch fails.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    if (_isLoading) return;

    if (!_isEditing) {
      setState(() => _isEditing = true);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    LegacyDriverProfileService.updateFullName(_nameController.text.trim())
        .then((_) {
          if (!mounted) return;
          NotificationOverlay.showMessage(
            context,
            'Profile updated successfully',
            backgroundColor: AppColors.success,
          );
          setState(() => _isEditing = false);
        })
        .catchError((_) {
          if (!mounted) return;
          NotificationOverlay.showMessage(
            context,
            'Failed to update profile',
            backgroundColor: AppColors.error,
          );
        })
        .whenComplete(() {
          if (mounted) setState(() => _isLoading = false);
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Personal Information',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          TextButton(
            onPressed: _toggleEdit,
            child: Text(
              _isLoading ? 'Saving...' : (_isEditing ? 'Save' : 'Edit'),
              style: TextStyle(
                color: _isEditing ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildInfoCard(
                context,
                title: 'Full Name',
                controller: _nameController,
                icon: Icons.person_outline,
                isEditable: true,
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                context,
                title: 'Phone Number',
                controller: _phoneController,
                icon: Icons.phone_outlined,
                isEditable: false,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                context,
                title: 'Email Address',
                controller: _emailController,
                icon: Icons.email_outlined,
                isEditable: false,
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required TextEditingController controller,
    required IconData icon,
    bool isEditable = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                _isEditing && isEditable
                    ? TextFormField(
                        controller: controller,
                        keyboardType: keyboardType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                          border: InputBorder.none,
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Field cannot be empty';
                          }
                          return null;
                        },
                      )
                    : Text(
                        controller.text,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
