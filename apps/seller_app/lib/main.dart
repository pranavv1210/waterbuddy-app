import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/widgets/app_initializer.dart';

void main() {
  print("[SELLER DEBUG] App starting...");

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      print("[SELLER DEBUG] Flutter bindings initialized");

      print("[SELLER DEBUG] Running app with AppInitializer...");
      runApp(
        ProviderScope(
          child: AppInitializer(
            child: const WaterBuddySellerApp(),
          ),
        ),
      );
    },
    (error, stack) {
      print('[SELLER DEBUG] Caught zone error: $error');
      print('[SELLER DEBUG] Stack trace: $stack');
    },
  );
}
