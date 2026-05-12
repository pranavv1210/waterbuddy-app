import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseInitializer {
  Future<FirebaseApp> initialize() async {
    try {
      final app = await Firebase.initializeApp();
      debugPrint('Firebase initialized successfully: ${app.name}');
      return app;
    } catch (e, stack) {
      debugPrint('Firebase initialization failed: $e');
      debugPrint('Stack trace: $stack');
      rethrow;
    }
  }
}
