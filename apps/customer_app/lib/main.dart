import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/firebase/firebase_initializer.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await FirebaseInitializer().initialize();
      runApp(const ProviderScope(child: WaterBuddyCustomerApp()));
    },
    (error, stack) {
      debugPrint('Caught error: $error');
      debugPrint('Stack trace: $stack');
    },
  );
}
