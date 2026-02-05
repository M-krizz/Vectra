import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../theme/app_colors.dart';

class ActiveEcoBackground extends StatefulWidget {
  const ActiveEcoBackground({super.key});

  @override
  State<ActiveEcoBackground> createState() => _ActiveEcoBackgroundState();
}

class _ActiveEcoBackgroundState extends State<ActiveEcoBackground>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _rayController;
  late Ticker _ticker;
  final List<Particle> _particles = [];
  final Random _random = Random();
  double _time = 0;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
        vsync: this, duration: const Duration(seconds: 15))
      ..repeat(reverse: true);
      
    _rayController = AnimationController(
        vsync: this, duration: const Duration(seconds: 20))
      ..repeat();

    // Create varied particles
    for (int i = 0; i < 20; i++) {
      _particles.add(Particle(_random));
    }

    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    setState(() {
      _time = elapsed.inMilliseconds / 1000.0;
      for (var particle in _particles) {
        particle.update(_time);
      }
    });
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _rayController.dispose();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Cinematic Blur & Vignette (Base Layer)
        Stack(
          children: [
             // Base
             Container(color: const Color(0xFF050A05)),
             
             // Blur
             BackdropFilter(
               filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
               child: Container(color: Colors.transparent),
             ),
             
             // Vignette
             Container(
               decoration: BoxDecoration(
                 gradient: RadialGradient(
                   center: Alignment.center,
                   radius: 1.2,
                   colors: const [
                     Color(0xFF0F1A0F), 
                     Color(0xFF000000), 
                   ],
                   stops: const [0.0, 1.0],
                 ),
               ),
             ),
          ],
        ),
        
        // 2. Neon Green Leaf Particles (ABOVE Vignette for Visibility)
        CustomPaint(
          painter: ParticlePainter(_particles),
          size: Size.infinite,
        ),

        // 3. Rotating God Rays (Top Atmosphere)
        AnimatedBuilder(
          animation: _rayController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rayController.value * 2 * pi,
              child: Container(
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    center: Alignment.center,
                    startAngle: 0,
                    endAngle: 2 * pi,
                    colors: [
                      Colors.transparent,
                      AppColors.hyperLime.withOpacity(0.02), // Very subtle
                      Colors.transparent,
                      AppColors.neonGreen.withOpacity(0.02),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.2, 0.4, 0.6, 1.0],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class Particle {
  late double x;
  late double y;
  late double speed;
  late double size;
  late double wobbleFreq;
  late double wobbleAmp;
  late double opacity;
  late Color color;
  late bool isLeaf;
  late double rotation;
  late double rotationSpeed;

  Particle(Random random) {
    reset(random, true);
  }

  void reset(Random random, bool initial) {
    x = random.nextDouble();
    y = initial ? random.nextDouble() : 1.1; // Start at bottom if not initial
    speed = 0.05 + random.nextDouble() * 0.10; // Speed 0.05 - 0.15 screen height/sec
    size = 4.0 + random.nextDouble() * 12.0;
    wobbleFreq = 1 + random.nextDouble() * 3;
    wobbleAmp = 0.02 + random.nextDouble() * 0.05;
    opacity = 0.2 + random.nextDouble() * 0.5;
    isLeaf = true; // Always a leaf for "Neon Green Leaf Animations"
    rotation = random.nextDouble() * 2 * pi;
    rotationSpeed = (random.nextDouble() - 0.5) * 2;
    
    final colors = [
      AppColors.hyperLime,
      AppColors.neonGreen,
      Color(0xFF44FF88),
      Colors.white,
    ];
    color = colors[random.nextInt(colors.length)];
  }

  void update(double time) {
    y -= speed * 0.016; // Assuming ~60fps for simple dt approximation, or just relative speed
    
    if (y < -0.1) {
      reset(Random(), false);
    }
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final double wobble = sin(particle.y * 10 + particle.wobbleFreq) * particle.wobbleAmp;
      final double x = (particle.x + wobble) * size.width;
      final double y = particle.y * size.height;
      
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      if (particle.isLeaf) {
        // Draw leaf shape (simplified as rotated oval/path)
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(particle.rotation + y * particle.rotationSpeed);
        
        final path = Path();
        path.moveTo(0, -particle.size);
        path.quadraticBezierTo(particle.size, 0, 0, particle.size);
        path.quadraticBezierTo(-particle.size, 0, 0, -particle.size);
        canvas.drawPath(path, paint..style = PaintingStyle.fill);
        
        // Glow
        canvas.drawPath(path, Paint()
          ..color = particle.color.withOpacity(particle.opacity * 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
          
        canvas.restore();
      } else {
        // Draw glow dot
        canvas.drawCircle(Offset(x, y), particle.size / 2, paint);
        // Glow
        canvas.drawCircle(Offset(x, y), particle.size, Paint()
          ..color = particle.color.withOpacity(particle.opacity * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
