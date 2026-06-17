import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseInitializer {
  Future<FirebaseApp> initialize() async {
    try {
      final app = await Firebase.initializeApp();
      
      // Enable Firestore offline persistence
      // This ensures cached data loads when the app is reopened without internet,
      // and automatically syncs when connectivity returns.
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      
      debugPrint('[FIREBASE] Initialized successfully: ${app.name}');
      debugPrint('[FIREBASE] Offline persistence enabled');
      return app;
    } catch (e, stack) {
      debugPrint('[FIREBASE] Initialization failed: $e');
      debugPrint('[FIREBASE] Stack trace: $stack');
      rethrow;
    }
  }
}