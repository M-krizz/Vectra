import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../models/signup_data.dart';
import 'preview_screen.dart';
import '../../utils/notification_overlay.dart';

class DocumentUploadScreen extends StatefulWidget {
  final SignUpData signUpData;

  const DocumentUploadScreen({super.key, required this.signUpData});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Sign Up'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            _buildProgressIndicator(3),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload Documents',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Step 3 of 4',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Please upload clear photos of your documents',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Driving License
                    _DocumentUploadCard(
                      title: 'Driving License',
                      subtitle: 'Upload front and back',
                      icon: Icons.credit_card,
                      imagePath: widget.signUpData.licensePath,
                      onUpload: () => _pickImage('license'),
                      onRemove: () => _removeImage('license'),
                      isRequired: true,
                    ),

                    const SizedBox(height: 16),

                    // RC Book
                    _DocumentUploadCard(
                      title: 'RC Book (Registration Certificate)',
                      subtitle: 'Vehicle registration document',
                      icon: Icons.description,
                      imagePath: widget.signUpData.rcBookPath,
                      onUpload: () => _pickImage('rc'),
                      onRemove: () => _removeImage('rc'),
                      isRequired: true,
                    ),

                    const SizedBox(height: 16),

                    // Aadhar Card
                    _DocumentUploadCard(
                      title: 'Aadhar Card',
                      subtitle: 'Government ID proof (Optional)',
                      icon: Icons.badge,
                      imagePath: widget.signUpData.aadharPath,
                      onUpload: () => _pickImage('aadhar'),
                      onRemove: () => _removeImage('aadhar'),
                      isRequired: false,
                    ),

                    const SizedBox(height: 16),

                    // PAN Card
                    _DocumentUploadCard(
                      title: 'PAN Card',
                      subtitle: 'For tax and payment purposes (Optional)',
                      icon: Icons.account_balance_wallet,
                      imagePath: widget.signUpData.panCardPath,
                      onUpload: () => _pickImage('pan'),
                      onRemove: () => _removeImage('pan'),
                      isRequired: false,
                    ),

                    const SizedBox(height: 24),

                    // Info Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.info,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Make sure all documents are clear and readable. Blurry or unclear images may delay verification.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Continue Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _continue,
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(String documentType) async {
    // Show bottom sheet to choose camera or gallery
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Image Source',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.primary,
                ),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          switch (documentType) {
            case 'license':
              widget.signUpData.licensePath = image.path;
              break;
            case 'rc':
              widget.signUpData.rcBookPath = image.path;
              break;
            case 'aadhar':
              widget.signUpData.aadharPath = image.path;
              break;
            case 'pan':
              widget.signUpData.panCardPath = image.path;
              break;
          }
        });

        if (mounted) {
          NotificationOverlay.showMessage(
            context,
            '${_getDocumentName(documentType)} uploaded successfully',
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationOverlay.showMessage(
          context,
          'Failed to pick image: $e',
          backgroundColor: AppColors.error,
        );
      }
    }
  }

  String _getDocumentName(String documentType) {
    switch (documentType) {
      case 'license':
        return 'Driving License';
      case 'rc':
        return 'RC Book';
      case 'aadhar':
        return 'Aadhar Card';
      case 'pan':
        return 'PAN Card';
      default:
        return 'Document';
    }
  }

  void _removeImage(String documentType) {
    setState(() {
      switch (documentType) {
        case 'license':
          widget.signUpData.licensePath = null;
          break;
        case 'rc':
          widget.signUpData.rcBookPath = null;
          break;
        case 'aadhar':
          widget.signUpData.aadharPath = null;
          break;
        case 'pan':
          widget.signUpData.panCardPath = null;
          break;
      }
    });
  }

  void _continue() {
    // Validate only required documents are uploaded (License and RC Book)
    if (widget.signUpData.licensePath == null ||
        widget.signUpData.rcBookPath == null) {
      NotificationOverlay.showMessage(
        context,
        'Please upload Driving License and RC Book',
        backgroundColor: AppColors.error,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewScreen(signUpData: widget.signUpData),
      ),
    );
  }

  Widget _buildProgressIndicator(int currentStep) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(4, (index) {
          final isCompleted = index < currentStep;
          final isCurrent = index == currentStep - 1;

          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? AppColors.primary
                    : AppColors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DocumentUploadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? imagePath;
  final VoidCallback onUpload;
  final VoidCallback onRemove;
  final bool isRequired;

  const _DocumentUploadCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.imagePath,
    required this.onUpload,
    required this.onRemove,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage = imagePath != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasImage ? AppColors.success : AppColors.grey,
          width: hasImage ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        children: [
                          if (isRequired)
                            const TextSpan(
                              text: ' *',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasImage)
                Icon(Icons.check_circle, color: AppColors.success, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onUpload,
                  icon: Icon(
                    hasImage ? Icons.refresh : Icons.upload_file,
                    size: 20,
                  ),
                  label: Text(hasImage ? 'Replace' : 'Upload'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (hasImage) ...[
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
