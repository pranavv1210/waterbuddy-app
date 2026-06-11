import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/premium_ui.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _minDurationPassed = false;
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() => _minDurationPassed = true);
      _checkAndNavigate();
    });
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  void _checkAndNavigate() {
    if (!_minDurationPassed) return;

    final authState = ref.read(authStateProvider);
    if (authState.isLoading) return;

    context.go(RouteNames.roleSelection);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      if (!next.isLoading) _checkAndNavigate();
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: WbColors.surface,
        body: Stack(
          children: [
            const AbstractWaterBackground(),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _motion,
                builder: (context, _) => CustomPaint(
                  painter: _SplashRayPainter(_motion.value),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Hero(
                      tag: 'waterbuddy-logo',
                      child: AnimatedBuilder(
                        animation: _motion,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1 + math.sin(_motion.value * math.pi * 2) * 0.035,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF38BDF8), Color(0xFF0369A1)],
                            ),
                            borderRadius: BorderRadius.circular(36),
                            boxShadow: WaterBuddyDesignSystem.premiumShadow(
                              WbColors.blue,
                            ),
                          ),
                          child: const Icon(
                            Icons.water_drop_rounded,
                            color: Colors.white,
                            size: 62,
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 450.ms)
                        .scale(begin: const Offset(0.86, 0.86)),
                    const SizedBox(height: 24),
                    const Text(
                      'WaterBuddy',
                      style: TextStyle(
                        color: WbColors.ink,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ).animate(delay: 900.ms).fadeIn().slideY(begin: 0.12),
                    const SizedBox(height: 8),
                    const Text(
                      'Water Delivered Fast',
                      style: TextStyle(
                        color: WbColors.muted,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ).animate(delay: 1200.ms).fadeIn(),
                    const SizedBox(height: 42),
                    const _SplashProgress()
                        .animate(delay: 1500.ms)
                        .fadeIn(duration: 320.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashProgress extends StatelessWidget {
  const _SplashProgress();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white),
      ),
      clipBehavior: Clip.antiAlias,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [WbColors.blue, WbColors.deepBlue],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SplashRayPainter extends CustomPainter {
  const _SplashRayPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.38);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.70),
          WbColors.blue.withOpacity(0.09),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.72));
    canvas.drawCircle(center, size.width * (0.56 + math.sin(t * math.pi * 2) * 0.02), paint);
  }

  @override
  bool shouldRepaint(covariant _SplashRayPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}

