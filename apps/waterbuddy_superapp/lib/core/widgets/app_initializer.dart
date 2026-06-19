import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/crashlytics/crashlytics_service.dart';
import '../services/notifications/notification_service.dart';
import '../services/performance/performance_service.dart';
import '../../firebase_options.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key, required this.child});

  final Widget child;

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer>
    with SingleTickerProviderStateMixin {
  bool _initialized = false;
  bool _error = false;
  String? _errorMessage;
  FcmService? _fcm;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    _fcm?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
          .timeout(const Duration(seconds: 15));

      await PerformanceService.traceAppStartup(() async {});

      // ── Crashlytics ─────────────────────────────────────────────────────
      FlutterError.onError = CrashlyticsService.recordFlutterError;
      PlatformDispatcher.instance.onError = (error, stack) {
        CrashlyticsService.recordError(
          error,
          stack,
          fatal: true,
          context: 'PlatformDispatcher',
        );
        return true;
      };
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);
      debugPrint(
          '[CRASHLYTICS] Initialized (reporting enabled: ${!kDebugMode})');

      // ── FCM ──────────────────────────────────────────────────────────────
      _fcm = FcmService(
        messaging: FirebaseMessaging.instance,
        firestore: FirebaseFirestore.instance,
        auth: FirebaseAuth.instance,
      );
      await _fcm!.initialize().catchError((Object e, StackTrace stack) {
        developer.log('FCM init warning (non-fatal)',
            name: 'waterbuddy.superapp', error: e);
        CrashlyticsService.recordError(
          e,
          stack,
          context: 'FcmService.initialize',
        );
      });

      // ── Set Crashlytics log breadcrumb ─────────────────────────────────
      await CrashlyticsService.log('App initialized successfully');

      if (!mounted) return;
      setState(() => _initialized = true);
    } catch (e, stack) {
      CrashlyticsService.recordError(
        e,
        stack,
        fatal: true,
        context: 'AppInitializer._initialize',
      );
      developer.log('App initialization error',
          name: 'waterbuddy.superapp', error: e);
      if (!mounted) return;
      setState(() {
        _error = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized && !_error) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: Stack(
              children: [
                // Animated background
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => CustomPaint(
                      painter: _InitBgPainter(_controller.value),
                    ),
                  ),
                ),
                // Center content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          final pulse =
                              0.96 + 0.04 * _controller.value;
                          return Transform.scale(
                            scale: pulse,
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF38BDF8),
                                    Color(0xFF0369A1)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0EA5E9)
                                        .withValues(alpha: 0.30 + 0.12 * _controller.value),
                                    blurRadius: 36,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.water_drop_rounded,
                                color: Colors.white,
                                size: 52,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'WaterBuddy',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF08111F),
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Delivering fresh water to your door',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _PremiumLoadingDots(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_error) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFFCA5A5), width: 1.5),
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        color: Color(0xFFEF4444),
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Connection Failed',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF08111F),
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage != null
                          ? 'WaterBuddy couldn\'t reach the server.\n\n$_errorMessage'
                          : 'WaterBuddy couldn\'t reach the server.\nCheck your connection and try again.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF64748B),
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _error = false;
                          _errorMessage = null;
                        });
                        _initialize();
                      },
                      child: Container(
                        height: 54,
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0EA5E9), Color(0xFF0369A1)],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0EA5E9)
                                  .withValues(alpha: 0.28),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.refresh_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Try Again',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
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
          ),
        ),
      );
    }

    return widget.child;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium Loading Dots
// ─────────────────────────────────────────────────────────────────────────────

class _PremiumLoadingDots extends StatefulWidget {
  @override
  State<_PremiumLoadingDots> createState() => _PremiumLoadingDotsState();
}

class _PremiumLoadingDotsState extends State<_PremiumLoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final delay = i / 3.0;
            final t = ((_ctrl.value - delay) % 1.0 + 1.0) % 1.0;
            final scale = 0.7 + 0.3 * (1 - (t * 2 - 1).abs().clamp(0, 1));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0EA5E9),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Background Painter
// ─────────────────────────────────────────────────────────────────────────────

class _InitBgPainter extends CustomPainter {
  _InitBgPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Light blue gradient base
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE), Color(0xFFF8FAFC)],
    ).createShader(rect);
    canvas.drawRect(rect, paint);

    // Floating blobs
    _drawBlob(canvas, size, paint,
        dx: 0.15 + 0.06 * _sin(t * 2.0),
        dy: 0.18 + 0.04 * _cos(t * 1.7),
        r: size.width * 0.28,
        color: const Color(0xFF38BDF8).withValues(alpha: 0.08));

    _drawBlob(canvas, size, paint,
        dx: 0.80 + 0.04 * _cos(t * 2.3),
        dy: 0.30 + 0.05 * _sin(t * 1.5),
        r: size.width * 0.22,
        color: const Color(0xFF0EA5E9).withValues(alpha: 0.06));

    _drawBlob(canvas, size, paint,
        dx: 0.50 + 0.08 * _sin(t * 1.9),
        dy: 0.70 + 0.05 * _cos(t * 2.1),
        r: size.width * 0.32,
        color: const Color(0xFF0284C7).withValues(alpha: 0.05));

    _drawBlob(canvas, size, paint,
        dx: 0.85 + 0.03 * _sin(t * 1.3),
        dy: 0.80 + 0.04 * _cos(t * 1.8),
        r: size.width * 0.20,
        color: const Color(0xFF38BDF8).withValues(alpha: 0.07));
  }

  void _drawBlob(Canvas canvas, Size size, Paint paint,
      {required double dx,
      required double dy,
      required double r,
      required Color color}) {
    paint.shader = null;
    paint.color = color;
    canvas.drawCircle(
        Offset(size.width * dx, size.height * dy), r, paint);
  }

  double _sin(double v) => (v * 6.28318).abs() % 6.28318 < 3.14159
      ? (v * 6.28318 % 6.28318) / 3.14159 * 2 - 1
      : -((v * 6.28318 % 6.28318 - 3.14159) / 3.14159 * 2 - 1);

  double _cos(double v) => _sin(v + 0.25);

  @override
  bool shouldRepaint(_InitBgPainter old) => old.t != t;
}
