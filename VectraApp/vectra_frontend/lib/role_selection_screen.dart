import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'registration_wizard.dart';
import 'theme/app_colors.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Eco-friendly animated background
          const EcoBackground(),

          // Floating particles
          ...List.generate(15, (index) => _buildFloatingParticle(index)),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.white10,
                      padding: const EdgeInsets.all(12),
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2),

                  const Spacer(),

                  // Title section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Join the',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontSize: 36,
                              fontWeight: FontWeight.w300,
                              color: AppColors.white70,
                            ),
                      ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideX(begin: -0.2),
                      
                      Text(
                        'Green Revolution',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              foreground: Paint()
                                ..shader = const LinearGradient(
                                  colors: [AppColors.hyperLime, AppColors.neonGreen],
                                ).createShader(const Rect.fromLTWH(0, 0, 400, 70)),
                            ),
                      ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideX(begin: -0.2),
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        'Choose your role to get started',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.white70,
                              fontSize: 18,
                            ),
                      ).animate().fadeIn(delay: 600.ms, duration: 600.ms).slideX(begin: -0.2),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // Role cards
                  _buildRoleCard(
                    context,
                    role: 'rider',
                    title: 'I\'m a Rider',
                    subtitle: 'Book eco-friendly rides',
                    icon: Icons.person_outline,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00FF88), Color(0xFF00CC66)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    delay: 800,
                  ),

                  const SizedBox(height: 20),

                  _buildRoleCard(
                    context,
                    role: 'driver',
                    title: 'I\'m a Driver',
                    subtitle: 'Earn while going green',
                    icon: Icons.electric_car_outlined,
                    gradient: const LinearGradient(
                      colors: [AppColors.hyperLime, Color(0xFF99CC00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    delay: 1000,
                  ),

                  const Spacer(),

                  // Continue button
                  if (_selectedRole != null)
                    _buildContinueButton(context)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.3, curve: Curves.easeOutBack),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingParticle(int index) {
    final random = Random(index);
    final size = 4.0 + random.nextDouble() * 8;
    final startX = random.nextDouble();
    final startY = random.nextDouble();
    final duration = 10 + random.nextInt(15);

    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = (_particleController.value + (index * 0.1)) % 1.0;
        final x = startX * MediaQuery.of(context).size.width;
        final y = startY * MediaQuery.of(context).size.height -
            (progress * MediaQuery.of(context).size.height * 1.5);

        return Positioned(
          left: x + sin(progress * pi * 4) * 30,
          top: y,
          child: Opacity(
            opacity: (1 - progress) * 0.6,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index % 3 == 0
                    ? AppColors.hyperLime
                    : index % 3 == 1
                        ? AppColors.neonGreen
                        : AppColors.successGreen,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.hyperLime.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String role,
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required int delay,
  }) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected ? null : AppColors.carbonGrey.withOpacity(0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.white10,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.hyperLime.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 0,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.black.withOpacity(0.2)
                    : AppColors.white10,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isSelected ? Colors.black : AppColors.hyperLime,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: isSelected ? Colors.black : Colors.white,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? Colors.black.withOpacity(0.7)
                              : AppColors.white70,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Colors.black : AppColors.white20,
              size: 28,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms, duration: 600.ms).slideX(begin: 0.2);
  }

  Widget _buildContinueButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                RegistrationWizard(userRole: _selectedRole!),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.hyperLime, AppColors.neonGreen],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.hyperLime.withOpacity(0.5),
              blurRadius: 25,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Continue',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
          ),
        ),
      ),
    );
  }
}

/// Eco-friendly animated background
class EcoBackground extends StatefulWidget {
  const EcoBackground({super.key});

  @override
  State<EcoBackground> createState() => _EcoBackgroundState();
}

class _EcoBackgroundState extends State<EcoBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                0.5 * sin(_controller.value * 2 * pi),
                -0.3 + 0.4 * cos(_controller.value * 2 * pi),
              ),
              radius: 1.5 + 0.5 * sin(_controller.value * pi),
              colors: [
                AppColors.neonGreen.withOpacity(0.25),
                AppColors.hyperLime.withOpacity(0.15),
                const Color(0xFF004400).withOpacity(0.3),
                AppColors.voidBlack,
                AppColors.voidBlack,
              ],
              stops: const [0.0, 0.2, 0.4, 0.7, 1.0],
            ),
          ),
        );
      },
    );
  }
}
