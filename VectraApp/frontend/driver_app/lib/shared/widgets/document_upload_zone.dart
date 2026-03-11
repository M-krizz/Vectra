import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';

/// Document upload zone with scanning animation effect
class DocumentUploadZone extends StatefulWidget {
  final VoidCallback onUpload;
  final bool isUploading;
  final double progress;
  final String title;
  final String subtitle;

  const DocumentUploadZone({
    super.key,
    required this.onUpload,
    this.isUploading = false,
    this.progress = 0.0,
    this.title = 'Upload Driver License',
    this.subtitle = 'Tap to select file',
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.hyperLime : colors.primary;

    return GestureDetector(
      onTap: widget.isUploading ? null : widget.onUpload,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? AppColors.carbonGrey.withValues(alpha: 0.3) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isUploading
                ? accent
                : (isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          boxShadow: isDark
              ? null
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              if (!widget.isUploading)
                CustomPaint(
                  size: Size.infinite,
                  painter: DashedBorderPainter(
                    color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2),
                  ),
                ),
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
                          color: accent,
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.6),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              Center(
                child: widget.isUploading
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.document_scanner,
                            color: accent,
                            size: 48,
                          ).animate(onPlay: (controller) => controller.repeat())
                              .shimmer(duration: 1500.ms),
                          const SizedBox(height: 16),
                          Text(
                            'Scanning Document...',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: 150,
                            child: LinearProgressIndicator(
                              value: widget.progress,
                              backgroundColor: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation(accent),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.upload_file,
                            color: colors.onSurfaceVariant,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.title,
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
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
  final Color color;

  DashedBorderPainter({this.color = const Color(0x1AFFFFFF)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 10.0;
    const dashSpace = 8.0;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }

    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(size.width, startY), Offset(size.width, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }

    startX = size.width;
    while (startX > 0) {
      canvas.drawLine(Offset(startX, size.height), Offset(startX - dashWidth, size.height), paint);
      startX -= dashWidth + dashSpace;
    }

    startY = size.height;
    while (startY > 0) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY - dashWidth), paint);
      startY -= dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) => oldDelegate.color != color;
}