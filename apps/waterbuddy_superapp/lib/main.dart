import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/widgets/app_initializer.dart';

void main() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    developer.log(
      'FlutterError',
      name: 'waterbuddy.superapp',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    developer.log(
      'PlatformDispatcherError',
      name: 'waterbuddy.superapp',
      error: error,
      stackTrace: stack,
    );
    return true;
  };

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
      developer.log(
        'ZoneError',
        name: 'waterbuddy.superapp',
        error: error,
        stackTrace: stack,
      );
    },
  );
}
