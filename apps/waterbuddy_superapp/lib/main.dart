import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/crashlytics/crashlytics_service.dart';
import 'core/widgets/app_initializer.dart';

void main() {
  // Wire Crashlytics before runApp so startup crashes are caught.
  // The actual FirebaseCrashlytics.instance is initialized in AppInitializer
  // after Firebase.initializeApp(); this handler is just a safety net.
  FlutterError.onError = CrashlyticsService.recordFlutterError;

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(
        const ProviderScope(
          child: AppInitializer(
            child: WaterBuddySuperApp(),
          ),
        ),
      );
    },
    (error, stack) {
      // Uncaught async errors in the zone
      CrashlyticsService.recordError(
        error,
        stack,
        fatal: true,
        context: 'runZonedGuarded',
      );
    },
  );
}
