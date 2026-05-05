import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../firebase_options.dart';
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
    print('[APP INITIALIZER] Starting initialization...');

    try {
      await Future.delayed(const Duration(milliseconds: 100));

      print('[APP INITIALIZER] Initializing Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('[APP INITIALIZER] Firebase initialized!');

      // ── FCM ──────────────────────────────────────────────────────────────
      try {
        final fcm = FcmService(
          messaging: FirebaseMessaging.instance,
          firestore: FirebaseFirestore.instance,
          auth: FirebaseAuth.instance,
        );
        await fcm.initialize();
        print('[APP INITIALIZER] FCM initialized');
      } catch (e) {
        // Non-fatal — app works without push notifications
        print('[APP INITIALIZER] FCM init warning: $e');
      }

      if (mounted) {
        setState(() => _initialized = true);
      }
    } catch (e) {
      print('[APP INITIALIZER] Error: $e');
      if (mounted) {
        setState(() {
          _error = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while Firebase initializes
    if (!_initialized && !_error) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading...'),
              ],
            ),
          ),
        ),
      );
    }
    
    // Show error if Firebase failed
    if (_error) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text('Error: $_errorMessage'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = false;
                      _errorMessage = null;
                    });
                    _initialize();
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Firebase ready - show actual app
    return widget.child;
  }
}
