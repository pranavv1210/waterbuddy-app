import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../services/crashlytics/crashlytics_service.dart';
import '../services/notifications/notification_service.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key, required this.child});

  final Widget child;

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _initialized = false;
  bool _error = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform)
          .timeout(const Duration(seconds: 15));

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
      debugPrint('[CRASHLYTICS] Initialized (reporting enabled: ${!kDebugMode})');

      // ── Analytics ───────────────────────────────────────────────────────
      await FirebaseAnalytics.instance
          .setAnalyticsCollectionEnabled(!kDebugMode);
      debugPrint('[ANALYTICS] Initialized');

      // ── Performance Monitoring ──────────────────────────────────────────
      await FirebasePerformance.instance
          .setPerformanceCollectionEnabled(!kDebugMode);
      debugPrint('[PERFORMANCE] Initialized');

      // ── Firestore Offline Persistence ──────────────────────────────────
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      debugPrint('[FIRESTORE] Offline persistence enabled');

      // ── FCM ────────────────────────────────────────────────────────────
      final fcm = FcmService(
        messaging: FirebaseMessaging.instance,
        firestore: FirebaseFirestore.instance,
        auth: FirebaseAuth.instance,
      );
      fcm.initialize().catchError((e, stack) {
        developer.log('FCM init warning',
            name: 'waterbuddy.superapp', error: e);
        CrashlyticsService.recordError(
          e,
          stack as StackTrace,
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
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading WaterBuddy...'),
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
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Error: $_errorMessage'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = false;
                      _errorMessage = null;
                    });
                    _initialize();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}