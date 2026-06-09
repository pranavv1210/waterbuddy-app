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

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _minDurationPassed = false;

  @override
  void initState() {
    super.initState();
    // Keep splash visible for 1 second minimum
    Future.delayed(const Duration(milliseconds: 1000), () {
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
    if (authState.isLoading) return; // Wait until auth state is resolved

    final user = authState.value;
    if (user == null) {
      context.go(RouteNames.roleSelection);
      return;
    }
    // Redirect logic in appRouterProvider will route the user based on role if logged in
    context.go(RouteNames.roleSelection);
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state to navigate when loaded
    ref.listen(authStateProvider, (previous, next) {
      if (!next.isLoading) {
        _checkAndNavigate();
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: const Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO
                Icon(
                  Icons.water_drop_rounded,
                  color: Color(0xFF0095F6),
                  size: 72,
                ),
                SizedBox(height: 16),
                // WaterBuddy
                Text(
                  'WaterBuddy',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 8),
                // Subtitle
                Text(
                  'Pure Water Delivered Fast',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 48),
                // Loading...
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0095F6)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
