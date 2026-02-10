import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NotificationOverlay {
  static OverlayEntry? _overlayEntry;

  static void show(BuildContext context, Widget child, {Duration? duration}) {
    hide();

    _overlayEntry = OverlayEntry(
      builder: (context) =>
          _SlideFromTopAnimation(onDismiss: hide, child: child),
    );

    Overlay.of(context).insert(_overlayEntry!);

    if (duration != null) {
      Future.delayed(duration, hide);
    }
  }

  static void showMessage(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      duration: duration,
    );
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _SlideFromTopAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback onDismiss;

  const _SlideFromTopAnimation({required this.child, required this.onDismiss});

  @override
  State<_SlideFromTopAnimation> createState() => _SlideFromTopAnimationState();
}

class _SlideFromTopAnimationState extends State<_SlideFromTopAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1.2, -1.0), // Start from top-right corner
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          type: MaterialType.transparency,
          child: Dismissible(
            key: const ValueKey('notification'),
            direction: DismissDirection.up,
            onDismissed: (_) => widget.onDismiss(),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
