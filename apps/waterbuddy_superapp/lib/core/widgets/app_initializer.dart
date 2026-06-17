import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
    try {
      await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform)
          .timeout(const Duration(seconds: 15));

      final fcm = FcmService(
        messaging: FirebaseMessaging.instance,
        firestore: FirebaseFirestore.instance,
        auth: FirebaseAuth.instance,
      );
      fcm.initialize().catchError((e) {
        developer.log('FCM init warning',
            name: 'waterbuddy.superapp', error: e);
      });

      if (!mounted) return;
      setState(() => _initialized = true);
    } catch (e) {
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
                Text('Loading...'),
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
