import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _current = 0;

  static const _slides = [
    _Slide(
      emoji: '🚗',
      title: 'Ride Solo or Share',
      subtitle:
          'Book a ride just for you, or share with others heading the same way — save money, save the planet.',
      bg: Color(0xFFE8F0FE),
      accent: AppColors.primary,
    ),
    _Slide(
      emoji: '📍',
      title: 'Live Tracking',
      subtitle:
          'Watch your driver arrive in real-time. Share your trip status with family and friends.',
      bg: Color(0xFFE8F5E9),
      accent: Color(0xFF2E7D32),
    ),
    _Slide(
      emoji: '🛡️',
      title: 'Your Safety First',
      subtitle:
          'SOS button, emergency contacts, in-app incident reporting — we\'ve got you covered every ride.',
      bg: Color(0xFFFFF3E0),
      accent: Color(0xFFE65100),
    ),
    _Slide(
      emoji: '💳',
      title: 'Seamless Payments',
      subtitle:
          'Pay with UPI, cards, or cash. Get a detailed receipt after every ride. No surprises.',
      bg: Color(0xFFEDE7F6),
      accent: Color(0xFF6A1B9A),
    ),
  ];

  Future<void> _done() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
                child: TextButton(
                  onPressed: _done,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (_, i) => _SlideWidget(slide: _slides[i]),
              ),
            ),

            // Dots & button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _current == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _current == i
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_current < _slides.length - 1) {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _done();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _current == _slides.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _SlideWidget extends StatelessWidget {
  final _Slide slide;
  const _SlideWidget({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: slide.bg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(slide.emoji, style: const TextStyle(fontSize: 72)),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            slide.title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            slide.subtitle,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Slide {
  final String emoji;
  final String title;
  final String subtitle;
  final Color bg;
  final Color accent;
  const _Slide({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.bg,
    required this.accent,
  });
}
