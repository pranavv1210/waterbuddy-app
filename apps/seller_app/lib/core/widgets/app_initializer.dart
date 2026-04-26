import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../firebase_options.dart';

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
    print('[SELLER APP INITIALIZER] Starting initialization...');
    
    try {
      // Small delay to ensure UI renders first
      await Future.delayed(const Duration(milliseconds: 100));
      
      print('[SELLER APP INITIALIZER] Initializing Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('[SELLER APP INITIALIZER] Firebase initialized!');
      
      if (mounted) {
        setState(() => _initialized = true);
      }
    } catch (e) {
      print('[SELLER APP INITIALIZER] Error: $e');
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
    // Always show child immediately - Firebase runs in background
    return widget.child;
  }
}
