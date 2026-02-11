import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

enum AlertType { info, success, warning, error }

class AlertBanner extends StatefulWidget {
  final AlertType type;
  final String message;
  final IconData? icon;
  final bool isCloseable;
  final VoidCallback? onClose;
  final Duration? autoDismissDuration;

  const AlertBanner({
    super.key,
    required this.type,
    required this.message,
    this.icon,
    this.isCloseable = true,
    this.onClose,
    this.autoDismissDuration,
  });

  @override
  State<AlertBanner> createState() => _AlertBannerState();
}

class _AlertBannerState extends State<AlertBanner> {
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    if (widget.autoDismissDuration != null) {
      Future.delayed(widget.autoDismissDuration!, () {
        if (mounted) {
          _dismiss();
        }
      });
    }
  }

  void _dismiss() {
    setState(() {
      _isVisible = false;
    });
    widget.onClose?.call();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case AlertType.info:
        return AppColors.skyBlue.withOpacity(0.2);
      case AlertType.success:
        return AppColors.hyperLime.withOpacity(0.2);
      case AlertType.warning:
        return Colors.orange.withOpacity(0.2);
      case AlertType.error:
        return AppColors.errorRed.withOpacity(0.2);
    }
  }

  Color _getBorderColor() {
    switch (widget.type) {
      case AlertType.info:
        return AppColors.skyBlue;
      case AlertType.success:
        return AppColors.hyperLime;
      case AlertType.warning:
        return Colors.orange;
      case AlertType.error:
        return AppColors.errorRed;
    }
  }

  IconData _getDefaultIcon() {
    switch (widget.type) {
      case AlertType.info:
        return Icons.info_outline;
      case AlertType.success:
        return Icons.check_circle_outline;
      case AlertType.warning:
        return Icons.warning_amber;
      case AlertType.error:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor()),
      ),
      child: Row(
        children: [
          Icon(
            widget.icon ?? _getDefaultIcon(),
            color: _getBorderColor(),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.message,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          if (widget.isCloseable) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _dismiss,
              child: Icon(
                Icons.close,
                color: AppColors.white70,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2);
  }
}

// Static helper methods for common use cases
class AlertBannerHelper {
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AlertBanner(
          type: AlertType.info,
          message: message,
          isCloseable: false,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AlertBanner(
          type: AlertType.success,
          message: message,
          isCloseable: false,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AlertBanner(
          type: AlertType.warning,
          message: message,
          isCloseable: false,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration ?? const Duration(seconds: 4),
      ),
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AlertBanner(
          type: AlertType.error,
          message: message,
          isCloseable: false,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration ?? const Duration(seconds: 4),
      ),
    );
  }
}
