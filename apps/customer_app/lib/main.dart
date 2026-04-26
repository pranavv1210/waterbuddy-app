import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/widgets/app_initializer.dart';

void main() {
  print("[DEBUG] App starting...");

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      print("[DEBUG] Flutter bindings initialized");

      print("[DEBUG] Running app with AppInitializer...");
      runApp(
        ProviderScope(
          child: AppInitializer(
            child: const WaterBuddyCustomerApp(),
          ),
        ),
      );
    },
    (error, stack) {
      print('[DEBUG] Caught zone error: $error');
      print('[DEBUG] Stack trace: $stack');
    },
  );
}
