import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/services/notifications/notification_service.dart';
import 'providers/app_providers.dart';
import 'routes/app_router.dart';
import 'routes/route_names.dart';

class WaterBuddyCustomerApp extends ConsumerStatefulWidget {
  const WaterBuddyCustomerApp({super.key});

  @override
  ConsumerState<WaterBuddyCustomerApp> createState() =>
      _WaterBuddyCustomerAppState();
}

class _WaterBuddyCustomerAppState
    extends ConsumerState<WaterBuddyCustomerApp> {
  @override
  void initState() {
    super.initState();

    // Handle notification taps → navigate to relevant screen
    FcmService.onNotificationTap((data) {
      final router = ref.read(appRouterProvider);
      final screen = data['screen'] as String? ?? '';
      final orderId = data['orderId'] as String? ?? '';

      if (orderId.isEmpty) return;

      switch (screen) {
        case 'tracking':
          router.go('${RouteNames.tracking}?orderId=$orderId');
          break;
        case 'searching':
          router.go(RouteNames.home);
          break;
        case 'order_complete':
          router.go('${RouteNames.orderComplete}?orderId=$orderId');
          break;
        default:
          router.go('${RouteNames.tracking}?orderId=$orderId');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'WaterBuddy',
      theme: AppTheme.light(),
      routerConfig: router,
      builder: (context, child) {
        return child ??
            const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
      },
    );
  }
}
