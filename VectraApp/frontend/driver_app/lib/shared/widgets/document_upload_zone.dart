import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

/// Document upload zone with scanning animation effect
class DocumentUploadZone extends StatefulWidget {
  final VoidCallback onUpload;
  final bool isUploading;
  final double progress;

  const DocumentUploadZone({
    super.key,
    required this.onUpload,
    this.isUploading = false,
    this.progress = 0.0,
  });

  @override
  State<DocumentUploadZone> createState() => _DocumentUploadZoneState();
}

class _DocumentUploadZoneState extends State<DocumentUploadZone>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isUploading ? null : widget.onUpload,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.carbonGrey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isUploading
                ? AppColors.hyperLime
                : AppColors.white10,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // Dashed border effect
              if (!widget.isUploading)
                CustomPaint(
                  size: Size.infinite,
                  painter: DashedBorderPainter(),
                ),

              // Scanning line animation
              if (widget.isUploading)
                AnimatedBuilder(
                  animation: _scanController,
                  builder: (context, child) {
                    return Positioned(
                      top: _scanController.value * 200,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.hyperLime,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.hyperLime.withOpacity(0.6),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // Content
              Center(
                child: widget.isUploading
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.document_scanner,
                            color: AppColors.hyperLime,
                            size: 48,
                          ).animate(onPlay: (controller) => controller.repeat())
                              .shimmer(duration: 1500.ms),
                          const SizedBox(height: 16),
                          Text(
                            'Scanning Document...',
                            style: TextStyle(
                              color: AppColors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: 150,
                            child: LinearProgressIndicator(
                              value: widget.progress,
                              backgroundColor: AppColors.white10,
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.hyperLime,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.upload_file,
                            color: AppColors.white70,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Upload Driver License',
                            style: TextStyle(
                              color: AppColors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to select file',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white10
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 10.0;
    const dashSpace = 8.0;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }

    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width, startY),
        Offset(size.width, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }

    startX = size.width;
    while (startX > 0) {
      canvas.drawLine(
        Offset(startX, size.height),
        Offset(startX - dashWidth, size.height),
        paint,
      );
      startX -= dashWidth + dashSpace;
    }

    startY = size.height;
    while (startY > 0) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY - dashWidth),
        paint,
      );
      startY -= dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
