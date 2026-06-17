import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/route_names.dart';

class ConsumerAuthLandingScreen extends StatelessWidget {
  const ConsumerAuthLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go(RouteNames.roleSelection);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Stack(
            children: [
              const _AuthGradientBackground(),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // Icon
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0EA5E9)
                                  .withValues(alpha: 0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.water_drop_rounded,
                          color: Colors.white,
                          size: 52,
                        ),
                      ).animate().fadeIn(duration: 400.ms).scale(
                            begin: const Offset(0.8, 0.8),
                            curve: Curves.easeOutBack,
                          ),

                      const SizedBox(height: 28),

                      // Title
                      const Text(
                        'Welcome to WaterBuddy',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF08111F),
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                      const SizedBox(height: 10),

                      const Text(
                        'Fresh water delivered to your doorstep\nin minutes',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),

                      const Spacer(flex: 2),

                      // CTA Buttons
                      _PremiumCTAButton(
                        label: 'Login',
                        subtitle: 'Already have an account',
                        icon: Icons.login_rounded,
                        gradientColors: const [
                          Color(0xFF0EA5E9),
                          Color(0xFF0284C7)
                        ],
                        onTap: () => context.push(RouteNames.authConsumerLogin),
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.15),

                      const SizedBox(height: 14),

                      _PremiumCTAButton(
                        label: 'Create Account',
                        subtitle: 'New to WaterBuddy? Sign up',
                        icon: Icons.person_add_rounded,
                        gradientColors: const [
                          Color(0xFF08111F),
                          Color(0xFF1E293B)
                        ],
                        onTap: () =>
                            context.push(RouteNames.authConsumerSignup),
                      ).animate().fadeIn(delay: 650.ms).slideY(begin: 0.15),

                      const SizedBox(height: 24),

                      // Skip / back
                      TextButton(
                        onPressed: () => context.go(RouteNames.roleSelection),
                        child: const Text(
                          'Change role',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ).animate().fadeIn(delay: 800.ms),

                      const Spacer(flex: 1),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthGradientBackground extends StatelessWidget {
  const _AuthGradientBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF0F9FF),
            Color(0xFFE0F2FE),
            Color(0xFFF8FAFC),
          ],
        ),
      ),
    );
  }
}

class _PremiumCTAButton extends StatefulWidget {
  const _PremiumCTAButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  @override
  State<_PremiumCTAButton> createState() => _PremiumCTAButtonState();
}

class _PremiumCTAButtonState extends State<_PremiumCTAButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradientColors,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors.first.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white.withValues(alpha: 0.8),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
