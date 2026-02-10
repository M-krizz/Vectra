import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';
import '../providers/driver_status_providers.dart';

/// Premium Swipe-to-Online Toggle
class OnlineToggle extends ConsumerStatefulWidget {
  final VoidCallback? onStatusChanged;

  const OnlineToggle({super.key, this.onStatusChanged});

  @override
  ConsumerState<OnlineToggle> createState() => _OnlineToggleState();
}

class _OnlineToggleState extends ConsumerState<OnlineToggle> with SingleTickerProviderStateMixin {
  double _dragValue = 0.0;
  bool _isDragging = false;
  static const double _height = 60.0;
  static const double _padding = 4.0;
  
  // For pulse animation when online
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details, double width) {
    if (ref.read(driverStatusProvider).isOnline) return; // Only swipe to go ONLINE. Tap to go OFFLINE.
    
    setState(() {
      _isDragging = true;
      _dragValue = (_dragValue + details.delta.dx).clamp(0.0, width - _height);
    });
  }

  void _handleDragEnd(DragEndDetails details, double width) {
    if (ref.read(driverStatusProvider).isOnline) return;

    final threshold = (width - _height) * 0.7;
    if (_dragValue > threshold) {
      _toggleStatus();
    }
    
    // Reset drag
    setState(() {
      _isDragging = false;
      _dragValue = 0.0;
    });
  }

  Future<void> _toggleStatus() async {
    final statusNotifier = ref.read(driverStatusProvider.notifier);
    final success = await statusNotifier.toggleStatus();
    if (success) {
      widget.onStatusChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusState = ref.watch(driverStatusProvider);
    final isOnline = statusState.isOnline; // True if Online
    final isToggling = statusState.isToggling;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final effectiveDrag = isOnline ? (width - _height) : _dragValue;
        
        return GestureDetector(
          onTap: isOnline ? _toggleStatus : null, // Tap to go Offline
          child: Container(
            height: _height,
            decoration: BoxDecoration(
              color: isOnline ? AppColors.voidBlack : AppColors.carbonGrey,
              borderRadius: BorderRadius.circular(_height / 2),
              border: Border.all(
                color: isOnline ? AppColors.hyperLime : AppColors.white10,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                 if (isOnline)
                  BoxShadow(
                    color: AppColors.hyperLime.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Stack(
              children: [
                // Background Text
                Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _isDragging || isOnline ? 0.0 : 1.0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'SWIPE TO GO ONLINE',
                          style: GoogleFonts.outfit(
                            color: AppColors.white50,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.white50),
                        Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.white30),
                      ],
                    ),
                  ),
                ),
                
                // Online Text
                Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isOnline ? 1.0 : 0.0,
                    child: Text(
                      'YOU ARE ONLINE',
                      style: GoogleFonts.outfit(
                        color: AppColors.hyperLime,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),

                // Knob
                AnimatedPositioned(
                  duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  left: effectiveDrag,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (d) => _handleDragUpdate(d, width),
                    onHorizontalDragEnd: (d) => _handleDragEnd(d, width),
                    child: Container(
                      width: _height, // Circle
                      margin: const EdgeInsets.all(_padding),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? AppColors.hyperLime : AppColors.white10,
                        gradient: isOnline 
                          ? const LinearGradient(colors: [AppColors.hyperLime, AppColors.neonGreen])
                          : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: isToggling
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : Icon(
                            isOnline ? Icons.power_settings_new : Icons.chevron_right,
                            color: isOnline ? Colors.black : Colors.white,
                            size: isOnline ? 24 : 32,
                          ),
                    ).animate(target: isOnline ? 1 : 0)
                     .scale(end: const Offset(1.1, 1.1), duration: 200.ms)
                     .then(delay: 200.ms), // Pulse handled by controller/shadow if needed
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
