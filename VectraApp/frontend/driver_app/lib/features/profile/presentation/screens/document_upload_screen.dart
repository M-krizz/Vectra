import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../theme/app_colors.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final Map<String, bool> _documents = {
    'Driving License': false,
    'RC Book': false,
    'PAN Card': false,
    'Aadhaar Card': false,
  };

  bool _isUploading = false;
  String? _uploadingDoc;

  Future<void> _uploadDocument(String docName) async {
    setState(() {
      _isUploading = true;
      _uploadingDoc = docName;
    });

    // Simulate upload delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _documents[docName] = true;
        _isUploading = false;
        _uploadingDoc = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$docName verified successfully!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  bool get _allUploaded => _documents.values.every((v) => v);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: AppColors.carbonGrey,
        title: Text('Driver Verification', style: GoogleFonts.outfit(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Required Documents',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please upload clear photos of the following documents to activate your account.',
              style: GoogleFonts.dmSans(color: AppColors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: _documents.keys.map((doc) => _buildDocItem(doc)).toList(),
              ),
            ),
            if (_allUploaded)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.successGreen),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.successGreen, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'All Documents Verified!',
                      style: GoogleFonts.outfit(
                        color: AppColors.successGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You can now go online.',
                      style: GoogleFonts.dmSans(color: Colors.white),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }

  Widget _buildDocItem(String docName) {
    final isUploaded = _documents[docName]!;
    final isUploadingThis = _isUploading && _uploadingDoc == docName;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUploaded ? AppColors.successGreen : AppColors.white10,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isUploaded ? AppColors.successGreen.withOpacity(0.2) : AppColors.white10,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUploaded ? Icons.check : Icons.description,
              color: isUploaded ? AppColors.successGreen : AppColors.white50,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  docName,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isUploaded ? 'Verified' : 'Pending Upload',
                  style: GoogleFonts.dmSans(
                    color: isUploaded ? AppColors.successGreen : AppColors.warningAmber,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isUploadingThis)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.hyperLime),
            )
          else if (!isUploaded)
            TextButton(
              onPressed: _isUploading ? null : () => _uploadDocument(docName),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.hyperLime.withOpacity(0.1),
                foregroundColor: AppColors.hyperLime,
              ),
              child: const Text('Upload'),
            ),
        ],
      ),
    );
  }
}
