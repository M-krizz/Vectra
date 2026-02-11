import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class DriverDocumentManagerScreen extends StatefulWidget {
  const DriverDocumentManagerScreen({super.key});

  @override
  State<DriverDocumentManagerScreen> createState() => _DriverDocumentManagerScreenState();
}

class _DriverDocumentManagerScreenState extends State<DriverDocumentManagerScreen> {
  // Mock document data
  final List<Map<String, dynamic>> _documents = [
    {
      'name': 'Driver License',
      'status': 'verified',
      'expiryDate': DateTime(2026, 12, 15),
      'uploadedDate': DateTime(2024, 1, 10),
      'icon': Icons.credit_card,
    },
    {
      'name': 'Vehicle Registration',
      'status': 'verified',
      'expiryDate': DateTime(2025, 8, 20),
      'uploadedDate': DateTime(2024, 1, 10),
      'icon': Icons.description,
    },
    {
      'name': 'Insurance Certificate',
      'status': 'expiring_soon',
      'expiryDate': DateTime(2025, 3, 5),
      'uploadedDate': DateTime(2024, 1, 10),
      'icon': Icons.shield,
    },
    {
      'name': 'PUC Certificate',
      'status': 'expired',
      'expiryDate': DateTime(2025, 1, 15),
      'uploadedDate': DateTime(2024, 1, 10),
      'icon': Icons.eco,
    },
    {
      'name': 'Background Verification',
      'status': 'pending',
      'expiryDate': null,
      'uploadedDate': DateTime(2025, 2, 1),
      'icon': Icons.verified_user,
    },
  ];

  int _getDaysUntilExpiry(DateTime? expiryDate) {
    if (expiryDate == null) return 999;
    return expiryDate.difference(DateTime.now()).inDays;
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'verified':
        return 'Verified';
      case 'pending':
        return 'Under Review';
      case 'expiring_soon':
        return 'Expiring Soon';
      case 'expired':
        return 'Expired';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'verified':
        return AppColors.hyperLime;
      case 'pending':
        return AppColors.skyBlue;
      case 'expiring_soon':
        return Colors.orange;
      case 'expired':
        return AppColors.errorRed;
      default:
        return AppColors.white50;
    }
  }

  void _handleUploadDocument(Map<String, dynamic> doc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.carbonGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Upload ${doc['name']}',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.hyperLime),
              title: Text(
                'Take Photo',
                style: GoogleFonts.dmSans(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Camera feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.hyperLime),
              title: Text(
                'Choose from Gallery',
                style: GoogleFonts.dmSans(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gallery feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: AppColors.hyperLime),
              title: Text(
                'Choose PDF',
                style: GoogleFonts.dmSans(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File picker coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expiringDocs = _documents.where((doc) {
      final daysLeft = _getDaysUntilExpiry(doc['expiryDate']);
      return daysLeft >= 0 && daysLeft <= 30;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (expiringDocs.isNotEmpty)
              _buildExpiryReminder(expiringDocs),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _documents.length,
                itemBuilder: (context, index) {
                  return _buildDocumentCard(_documents[index], index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey.withOpacity(0.8),
        border: const Border(
          bottom: BorderSide(color: AppColors.white10),
        ),
      ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Document Manager',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_documents.length} documents',
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
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildExpiryReminder(List<Map<String, dynamic>> expiringDocs) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.2),
            AppColors.errorRed.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Documents Expiring Soon',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${expiringDocs.length} document(s) need renewal',
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
    ).animate().shake(duration: 600.ms);
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc, int index) {
    final daysLeft = _getDaysUntilExpiry(doc['expiryDate']);
    final status = doc['status'] as String;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'expired' || status == 'expiring_soon'
              ? _getStatusColor(status)
              : AppColors.white10,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    doc['icon'],
                    color: _getStatusColor(status),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc['name'],
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _getStatusColor(status)),
                            ),
                            child: Text(
                              _getStatusText(status),
                              style: GoogleFonts.dmSans(
                                color: _getStatusColor(status),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (doc['expiryDate'] != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              daysLeft < 0
                                  ? 'Expired ${-daysLeft} days ago'
                                  : 'Expires in $daysLeft days',
                              style: GoogleFonts.dmSans(
                                color: AppColors.white50,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _handleUploadDocument(doc),
                  icon: Icon(
                    status == 'verified' ? Icons.refresh : Icons.upload_file,
                    color: AppColors.hyperLime,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.hyperLime.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
          if (doc['expiryDate'] != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.deepBlack.withOpacity(0.3),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: AppColors.white50,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Uploaded: ${_formatDate(doc['uploadedDate'])}',
                        style: GoogleFonts.dmSans(
                          color: AppColors.white50,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.event,
                        color: AppColors.white50,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Expires: ${_formatDate(doc['expiryDate'])}',
                        style: GoogleFonts.dmSans(
                          color: AppColors.white50,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms, duration: 400.ms).slideX(begin: 0.2);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
