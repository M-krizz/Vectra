import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'registration_wizard.dart';
import 'theme/app_colors.dart';
import 'widgets/active_eco_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathController;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Cinematic Background (Persistent)
          const ActiveEcoBackground(),
          
          // 2. Responsive Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Mobile Breakpoint < 600px width
                final isMobile = constraints.maxWidth < 600;
                
                if (isMobile) {
                  return _buildMobileLayout(context, constraints);
                } else {
                  return _buildHeroLayout(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Mobile Layout: Column Structure (Text -> Phone -> Button)
  Widget _buildMobileLayout(BuildContext context, BoxConstraints constraints) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        
        // 1. Tagline (Visible ABOVE phone)
        _buildTagline(context),
        
        const SizedBox(height: 20),
        
        // 2. Phone Mockup (Hero Size)
        SizedBox(
          height: screenHeight * 0.6, // 60% of screen height
          width: screenWidth * 0.85,  // 85% of screen width
          child: FittedBox(
            fit: BoxFit.contain,
            child: _HyperRealisticPhone(),
          ),
        ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.8, 0.8)),
        
        const Spacer(),
        
        // 3. Button
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 30),
          child: _buildFloatingPill(context),
        ),
      ],
    );
  }

  // Desktop/Hero Layout: Stack Structure (Text Behind Phone)
  Widget _buildHeroLayout(BuildContext context) {
    return Stack(
      children: [
        // Layer A: Massive Text Behind Phone
        Positioned(
          top: 100,
          left: 0,
          right: 0,
          child: _buildTagline(context),
        ),

        // Layer B: Phone Hero (Centered)
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: _HyperRealisticPhone(), 
          ),
        )
          .animate()
          .fadeIn(delay: 400.ms, duration: 800.ms)
          .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),

        // Layer C: Floating Island Action Button
        Positioned(
          bottom: 30,
          left: 24,
          right: 24,
          child: _buildFloatingPill(context),
        ),
      ],
    );
  }

  Widget _buildTagline(BuildContext context) {
    return Column(
       children: [
         Text(
           "Smarter rides",
           textAlign: TextAlign.center,
           style: Theme.of(context).textTheme.displayLarge?.copyWith(
             color: Colors.white.withOpacity(0.9),
             height: 0.9,
             fontSize: 48, // Slightly adjusted for safety
           ),
         ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0),
         Text(
           "start here.",
           textAlign: TextAlign.center,
           style: Theme.of(context).textTheme.displayLarge?.copyWith(
             color: AppColors.hyperLime,
             height: 0.9,
             fontSize: 48,
           ),
         ).animate().fadeIn(delay: 200.ms, duration: 800.ms).slideY(begin: 0.2, end: 0),
       ],
    );
  }

  Widget _buildFloatingPill(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const RegistrationWizard(userRole: 'rider'),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      },
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.hyperLime,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
             BoxShadow(
               color: AppColors.hyperLime.withOpacity(0.4),
               blurRadius: 30,
               spreadRadius: 0,
               offset: const Offset(0, 10),
             ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Get Started",
              style: GoogleFonts.dmSans(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 24),
          ],
        ),
      )
      .animate(onPlay: (c) => c.repeat(reverse: true))
      .moveY(begin: 0, end: -5, duration: 1500.ms, curve: Curves.easeInOutSine), // Breath animation
    );
  }
}

class _HyperRealisticPhone extends StatefulWidget {
  @override
  State<_HyperRealisticPhone> createState() => _HyperRealisticPhoneState();
}

class _HyperRealisticPhoneState extends State<_HyperRealisticPhone> 
    with SingleTickerProviderStateMixin {
  Offset _mousePos = Offset.zero;
  bool _isHovering = false;
  late AnimationController _idleController;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() {
        _isHovering = false;
        _mousePos = Offset.zero;
      }),
      onHover: (event) {
        // Calculate normalized position (-1 to 1) from center
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPos = box.globalToLocal(event.position);
        final center = box.size.center(Offset.zero);
        
        setState(() {
          _mousePos = Offset(
            (localPos.dx - center.dx) / (box.size.width / 2),
            (localPos.dy - center.dy) / (box.size.height / 2),
          );
        });
      },
      child: TweenAnimationBuilder<Offset>(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        tween: Tween<Offset>(
          begin: Offset.zero,
          end: _isHovering ? _mousePos : Offset.zero,
        ),
        builder: (context, mouseOffset, child) {
          return AnimatedBuilder(
            animation: _idleController,
            builder: (context, child) {
              // Idle Sway Logic (Figure-8ish or Gentle Circular)
              final t = _idleController.value;
              // Gentle smooth wave
              final idleX = sin(t * pi * 2) * 0.05; 
              final idleY = cos(t * pi * 2) * 0.05;

              // Combined Tilt
              final double maxTilt = 0.15;
              final double totalTiltX = (-mouseOffset.dy * maxTilt) + idleX;
              final double totalTiltY = (mouseOffset.dx * maxTilt) + idleY;
              
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // Perspective
                  ..rotateX(totalTiltX)
                  ..rotateY(totalTiltY),
                child: child,
              );
            },
            child: child,
          );
        },
        child: SizedBox(
          height: 480,
          width: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Outer Frame Shadow (Dynamic)
              // Shadow moves opposite to the tilt direction
              TweenAnimationBuilder<Offset>(
                duration: const Duration(milliseconds: 200),
                tween: Tween<Offset>(
                  begin: Offset.zero, 
                  end: _isHovering ? _mousePos : Offset.zero
                ),
                builder: (context, offset, _) {
                  return Container(
                    height: 470,
                    width: 230,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(45),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.hyperLime.withOpacity(0.15),
                          blurRadius: 50,
                          spreadRadius: 5,
                          // Shadow moves opposite to phone tilt
                          offset: Offset(-offset.dx * 20, 20 + -offset.dy * 20),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.8),
                          blurRadius: 30,
                          spreadRadius: 10,
                          offset: Offset(-offset.dx * 10, 30 + -offset.dy * 10),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              // 2. Metallic Frame (Dark Titanium look)
              Container(
                height: 470,
                width: 230,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(45),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4A4A4A),
                      Color(0xFF2A2A2A),
                      Color(0xFF1A1A1A),
                      Color(0xFF333333),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 0.4, 0.6, 1.0],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),

              // 3. Black Bezel
              Container(
                height: 462,
                width: 222,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(41),
                ),
              ),

              // 4. Active Screen Area
              Container(
                height: 450,
                width: 210,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1a1a1a),
                      Color(0xFF0D1F0D), // Deep Green tint
                      Colors.black,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Screen Content (Abstract UI)
                    _buildScreenContent(),
                    
                    // Screen Reflection (Glass effect)
                    // Reflection moves slightly to simulate surface depth
                    LayoutBuilder(
                       builder: (context, constraints) {
                         // We can use the same TweenAnimationBuilder from parent if we pass builder down
                         // or just rebuild a lightweight tween here or rely on the parent transform
                         // For simplicity, static reflection within the transformed parent works well,
                         // BUT animated reflection is "chefs kiss".
                         // Let's use a simpler static gradient for now as the parent 3D rotation does most of the work.
                         return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(36),
                            gradient: LinearGradient(
                              begin: Alignment(0.8, -0.8),
                              end: Alignment(-0.8, 0.8),
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.transparent,
                                Colors.transparent,
                                Colors.white.withOpacity(0.05),
                              ],
                              stops: const [0.0, 0.3, 0.7, 1.0],
                            ),
                          ),
                        );
                       }
                    ),
                  ],
                ),
              ),

              // 5. Dynamic Island / Notch
              Positioned(
                top: 22,
                child: Container(
                  height: 24,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              // 6. Side Buttons
              Positioned(
                left: -2,
                top: 100,
                child: Container(
                  height: 25,
                  width: 3,
                  decoration: BoxDecoration(
                    color: Color(0xFF333333),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(2),
                      bottomLeft: Radius.circular(2),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -2,
                top: 135,
                child: Container(
                  height: 45,
                  width: 3,
                  decoration: BoxDecoration(
                    color: Color(0xFF333333),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(2),
                      bottomLeft: Radius.circular(2),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -2,
                top: 120,
                child: Container(
                  height: 60,
                  width: 3,
                  decoration: BoxDecoration(
                    color: Color(0xFF333333),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(2),
                      bottomRight: Radius.circular(2),
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
  
  // Helper to rebuild screen content without rewriting it all
  Widget _buildScreenContent() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: Stack(
        children: [
          // 1. Dark Map Base
          Container(
             color: const Color(0xFF151515),
          ),
          
          // 2. Map Elements (Mock Roads)
          // Vertical Avenues
          ...List.generate(6, (i) => Positioned(
            left: i * 40.0 + 10,
            top: 0,
            bottom: 0,
            child: Container(width: i % 2 == 0 ? 4 : 2, color: Colors.white.withOpacity(0.03)),
          )),
          // Horizontal Streets
          ...List.generate(10, (i) => Positioned(
            top: i * 50.0 + 20,
            left: 0,
            right: 0,
            child: Container(height: i % 2 == 0 ? 4 : 2, color: Colors.white.withOpacity(0.03)),
          )),
          
          // 3. Lime Green Route Line (Path)
          Center(
            child: CustomPaint(
               size: const Size(200, 400),
               painter: RoutePainter(),
            ),
          ),

          // 4. Car Pin (Current Location)
          Align(
            alignment: const Alignment(0, 0.4),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.hyperLime, width: 3),
                boxShadow: [
                  BoxShadow(color: AppColors.hyperLime.withOpacity(0.5), blurRadius: 15),
                ],
              ),
              child: const Center(child: Icon(Icons.navigation, color: AppColors.hyperLime, size: 12)),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 2.seconds),
          ),
          
          // 5. Pickup Pin (Destination)
          const Align(
            alignment: Alignment(0.3, -0.3),
            child: Icon(Icons.location_on, color: AppColors.errorRed, size: 32),
          ),

          // 6. Branding Inside Phone (Professional & Stylized)
          Positioned(
            top: 50, // Move down to avoid notch overlap
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.hyperLime.withOpacity(0.1), 
                      blurRadius: 10, 
                      spreadRadius: 1
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Stylized Icon
                    Icon(Icons.bolt, color: AppColors.hyperLime, size: 20)
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 2.seconds, color: Colors.white),
                    const SizedBox(width: 8),
                    // Brand Text
                    Text(
                      "VECTRA",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: -0.5, end: 0),


        ],
      ),
    );
  }
}

class RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.hyperLime
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2); // Soft neon glow

    final path = Path();
    // Simplified route
    path.moveTo(size.width * 0.5, size.height * 0.7); // Start near bottom (car)
    path.cubicTo(
      size.width * 0.5, size.height * 0.6,
      size.width * 0.8, size.height * 0.5,
      size.width * 0.65, size.height * 0.35, // Mid point 
    );
    path.lineTo(size.width * 0.65, size.height * 0.35); // Dest
    
    // Draw route
    canvas.drawPath(path, paint);
    
    // Draw route shadow/glow
    final glowPaint = Paint()
      ..color = AppColors.hyperLime.withOpacity(0.4)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      
    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}





