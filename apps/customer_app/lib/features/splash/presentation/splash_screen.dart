import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;

  bool _minDurationPassed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.8, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();

    // Ensure the splash screen is shown for at least 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _minDurationPassed = true;
        });
        _checkAndNavigate();
      }
    });
  }

  void _checkAndNavigate() {
    if (!_minDurationPassed) return;

    final authState = ref.read(authStateProvider);
    if (authState.isLoading) return; // Still waiting for firebase

    // Auth resolved and min duration passed
    context.go(RouteNames.auth);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes to navigate when ready
    ref.listen(authStateProvider, (previous, next) {
      if (!next.isLoading) {
        _checkAndNavigate();
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0F172A),
                Color(0xFF020617),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.water_drop_rounded,
                        color: Color(0xFF38BDF8),
                        size: 80,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => FadeTransition(
                  opacity: _logoFade,
                  child: const Column(
                    children: [
                      Text(
                        'WaterBuddy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Pure hydration, delivered.',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
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
