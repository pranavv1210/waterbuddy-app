import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'providers/app_providers.dart';
import 'routes/app_router.dart';

class WaterBuddySellerApp extends ConsumerWidget {
  const WaterBuddySellerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'WaterBuddy Partner',
      theme: AppTheme.light(),
      routerConfig: router,
      builder: (context, child) {
        // Ensure we always have a child to display
        return child ?? const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
