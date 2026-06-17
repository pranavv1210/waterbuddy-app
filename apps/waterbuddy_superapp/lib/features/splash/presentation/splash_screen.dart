import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

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
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 2400), () {
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
            // Premium animated water background
            const _PremiumSplashBackground(),

            // Floating particles layer
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _motion,
                builder: (context, _) => CustomPaint(
                  painter: _FloatingParticlePainter(_motion.value),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Spacer(flex: 3),

                    // Premium logo with glass effect
                    Hero(
                      tag: 'waterbuddy-logo',
                      child: AnimatedBuilder(
                        animation: _motion,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1 +
                                math.sin(_motion.value * math.pi * 2) * 0.025,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(36),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0EA5E9)
                                    .withValues(alpha: 0.35),
                                blurRadius: 40,
                                offset: const Offset(0, 16),
                              ),
                              BoxShadow(
                                color: const Color(0xFF0EA5E9)
                                    .withValues(alpha: 0.15),
                                blurRadius: 80,
                                offset: const Offset(0, 40),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Inner glass effect
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(36),
                                  child: BackdropFilter(
                                    filter:
                                        ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withValues(alpha: 0.2),
                                            Colors.transparent,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.water_drop_rounded,
                                color: Colors.white,
                                size: 64,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 500.ms).scale(
                        begin: const Offset(0.8, 0.8),
                        curve: Curves.easeOutBack),

                    const SizedBox(height: 28),

                    // Brand name
                    const Text(
                      'WaterBuddy',
                      style: TextStyle(
                        color: WbColors.ink,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        height: 1.1,
                      ),
                    )
                        .animate(delay: 700.ms)
                        .fadeIn()
                        .slideY(begin: 0.12, curve: Curves.easeOutCubic),

                    const SizedBox(height: 10),

                    // Tagline
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Water Delivered Fast',
                        style: TextStyle(
                          color: Color(0xFF0284C7),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    )
                        .animate(delay: 1000.ms)
                        .fadeIn()
                        .slideY(begin: 0.12, curve: Curves.easeOutCubic),

                    const Spacer(flex: 2),

                    // Premium loading indicator
                    const _PremiumLoadingBar()
                        .animate(delay: 1300.ms)
                        .fadeIn(duration: 400.ms),

                    const Spacer(flex: 1),
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

class _PremiumSplashBackground extends StatefulWidget {
  const _PremiumSplashBackground();

  @override
  State<_PremiumSplashBackground> createState() =>
      _PremiumSplashBackgroundState();
}

class _PremiumSplashBackgroundState extends State<_PremiumSplashBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
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
      builder: (context, _) {
        return CustomPaint(
          painter: _PremiumBackgroundPainter(_controller.value),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _PremiumBackgroundPainter extends CustomPainter {
  const _PremiumBackgroundPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Base gradient
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF0F9FF),
          Color(0xFFE0F2FE),
          Color(0xFFF8FAFC),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    // Soft radial glow at center
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF0EA5E9).withValues(
              alpha: 0.08 * (0.8 + math.sin(t * math.pi * 2) * 0.2)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.35),
        radius: size.width * 0.5,
      ));
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.35),
      size.width * 0.5,
      glowPaint,
    );

    // Animated wave at bottom
    final wavePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.5);

    final wavePath = Path();
    final baseY = size.height * 0.82;
    wavePath.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 2) {
      final y = baseY +
          math.sin((x / size.width * math.pi * 3) + t * math.pi * 2) * 18 +
          math.sin((x / size.width * math.pi * 5) + t * math.pi * 3) * 8;
      wavePath.lineTo(x, y);
    }
    wavePath.lineTo(size.width, size.height);
    wavePath.close();
    canvas.drawPath(wavePath, wavePaint);

    // Second wave layer
    final wavePaint2 = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF0EA5E9).withValues(alpha: 0.04);

    final wavePath2 = Path();
    final baseY2 = size.height * 0.78;
    wavePath2.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 2) {
      final y = baseY2 +
          math.sin((x / size.width * math.pi * 2.5) + t * math.pi * 2 + 1) *
              22 +
          math.sin((x / size.width * math.pi * 4) + t * math.pi * 3) * 10;
      wavePath2.lineTo(x, y);
    }
    wavePath2.lineTo(size.width, size.height);
    wavePath2.close();
    canvas.drawPath(wavePath2, wavePaint2);
  }

  @override
  bool shouldRepaint(covariant _PremiumBackgroundPainter oldDelegate) =>
      oldDelegate.t != t;
}

class _FloatingParticlePainter extends CustomPainter {
  const _FloatingParticlePainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < 12; i++) {
      final progress = (t + i * 0.085) % 1;
      final x = size.width *
          ((i * 0.19 + math.sin(progress * math.pi * 2) * 0.06) % 1);
      final y = size.height * (0.05 + ((i * 0.11 + progress * 0.4) % 0.7));
      final radius = 4.0 + (i % 4) * 6;

      paint.color =
          const Color(0xFF0EA5E9).withValues(alpha: 0.04 + (i % 3) * 0.015);
      canvas.drawCircle(Offset(x, y), radius, paint);

      // Soft ripple
      final ripplePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color =
            const Color(0xFF0EA5E9).withValues(alpha: 0.06 * (1 - progress));
      canvas.drawCircle(
        Offset(x, y),
        radius * (1.5 + progress * 2),
        ripplePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingParticlePainter oldDelegate) =>
      oldDelegate.t != t;
}

class _PremiumLoadingBar extends StatefulWidget {
  const _PremiumLoadingBar();

  @override
  State<_PremiumLoadingBar> createState() => _PremiumLoadingBarState();
}

class _PremiumLoadingBarState extends State<_PremiumLoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Container(
              width: 160,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(999),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 600),
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 160 * (0.3 + _controller.value * 0.4),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        const Text(
          'Preparing your experience...',
          style: TextStyle(
            color: WbColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
