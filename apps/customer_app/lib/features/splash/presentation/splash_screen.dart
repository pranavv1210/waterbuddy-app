import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/route_names.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const _backgroundImage =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAZihfvaiHypnL9i0whAXRKnpn0_AxDYiGPlr-X0w8OAkG-6JcTQ3znt0VDmliSgTsLmVDWJT84L78BWvDGjHfTSwcCGJ42g9z4WhMAUEApIkanYpxxZTwaTmHm4nm45F6QeJoEOlJPRZMpeFV8ZbuWuA7T9h6xxnSbdZkQ4Ojz-9oEB9WkF5ogsm9CQgNRFlFh_qPI9SgxhK2UzO1tWsF4K_9Q_tizkmUV3dfjNhJZbLa755QrUeMtJr9cRC2DwnexHPoZCvnNljM';

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00236F),
              Color(0xFF1E3A8A),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: 0.3,
              child: Image.network(
                _backgroundImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const _BlurOrb(
              alignment: Alignment(0.95, -0.9),
              color: Color(0xFF57DFFE),
              width: 320,
              height: 260,
              blurSigma: 70,
            ),
            const _BlurOrb(
              alignment: Alignment(-0.95, 0.95),
              color: Color(0xFF004941),
              width: 280,
              height: 220,
              blurSigma: 60,
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _BrandMark(size: screenHeight < 700 ? 96 : 120),
                              const SizedBox(height: 36),
                              const Text(
                                'WaterBuddy',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.2,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Water, when you need it.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFFB7CAFF).withOpacity(0.82),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              onPressed: () => context.go(RouteNames.auth),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF123B97),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Get Started',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: () => context.go(RouteNames.auth),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                                backgroundColor: Colors.white.withOpacity(0.05),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 28 + safeBottom),
                          Text(
                            '© 2024 WaterBuddy Global',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF93A8E5).withOpacity(0.42),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
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

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final outerSize = size;
    final innerSize = size * 0.74;

    return SizedBox(
      width: outerSize + 28,
      height: outerSize + 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: outerSize + 14,
            height: outerSize + 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.06),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF71F8E4).withOpacity(0.18),
                  blurRadius: 44,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          Transform.rotate(
            angle: 0.785398,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: outerSize,
                  height: outerSize,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: -0.785398,
                      child: Icon(
                        Icons.water_drop_rounded,
                        color: Colors.white,
                        size: innerSize * 0.66,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({
    required this.alignment,
    required this.color,
    required this.width,
    required this.height,
    required this.blurSigma,
  });

  final Alignment alignment;
  final Color color;
  final double width;
  final double height;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
