import 'dart:io';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/signup_data.dart';
import '../../utils/notification_overlay.dart';

class DocumentInfoScreen extends StatelessWidget {
  final SignUpData? signUpData;
  const DocumentInfoScreen({super.key, this.signUpData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Documents',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildDocumentCard(
              context,
              title: 'Driving License',
              status: _getDocumentStatus(signUpData?.licensePath),
              icon: Icons.credit_card,
              expiryDate: 'Expires on 12/2028', // Dummy date for now
              filePath: signUpData?.licensePath,
            ),
            const SizedBox(height: 16),
            _buildDocumentCard(
              context,
              title: 'RC Book (Vehicle Registration)',
              status: _getDocumentStatus(signUpData?.rcBookPath),
              icon: Icons.description,
              expiryDate: 'Expires on 05/2030', // Dummy date for now
              filePath: signUpData?.rcBookPath,
            ),
            const SizedBox(height: 16),
            if (signUpData != null) ...[
              _buildDocumentCard(
                context,
                title: 'Aadhar Card',
                status: _getDocumentStatus(signUpData?.aadharPath),
                icon: Icons.badge,
                filePath: signUpData?.aadharPath,
              ),
              const SizedBox(height: 16),
              _buildDocumentCard(
                context,
                title: 'PAN Card',
                status: _getDocumentStatus(signUpData?.panCardPath),
                icon: Icons.account_balance_wallet,
                filePath: signUpData?.panCardPath,
              ),
            ] else ...[
              // Fallback dummy cards if no signup data provided (e.g. dev testing)
              _buildDocumentCard(
                context,
                title: 'Aadhar Card',
                status: 'Verified',
                icon: Icons.badge,
              ),
              const SizedBox(height: 16),
              _buildDocumentCard(
                context,
                title: 'PAN Card',
                status: 'Pending Verification',
                icon: Icons.account_balance_wallet,
                isPending: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDocumentStatus(String? path) {
    if (path != null && path.isNotEmpty) {
      return 'Uploaded';
    }
    return 'Not Uploaded';
  }

  Widget _buildDocumentCard(
    BuildContext context, {
    required String title,
    required String status,
    required IconData icon,
    String? expiryDate,
    bool isPending = false,
    String? filePath,
  }) {
    // If we have a file path, we consider it "Uploaded" essentially,
    // regardless of the verified/pending status text passed in unless explicitly handled.
    // For now we trust the status passed in or derive it.

    // If explicitly marked pending OR it's uploaded but not verified (just uploaded state)
    // we can colour code differently. Let's keep it simple:
    // Uploaded -> Success color (Green)
    // Not Uploaded -> Grey or Error
    // Pending -> Warning (Orange)

    Color statusColor;
    if (status == 'Verified' || status == 'Uploaded') {
      statusColor = AppColors.success;
    } else if (status == 'Pending Verification') {
      statusColor = AppColors.warning;
    } else {
      statusColor = AppColors.textSecondary;
    }

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
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (expiryDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    expiryDate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (filePath != null)
            IconButton(
              icon: const Icon(
                Icons.visibility_outlined,
                color: AppColors.primary,
              ),
              onPressed: () => _viewDocument(context, title, filePath),
            )
          else
            IconButton(
              icon: Icon(
                Icons.visibility_off_outlined,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              onPressed: () {
                NotificationOverlay.showMessage(
                  context,
                  'No document uploaded for $title',
                  duration: const Duration(seconds: 1),
                );
              },
            ),
        ],
      ),
    );
  }

  void _viewDocument(BuildContext context, String title, String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              AppBar(
                title: Text(title),
                backgroundColor: Colors.black87,
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.file(
                      File(path),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.white,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Failed to load image',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
