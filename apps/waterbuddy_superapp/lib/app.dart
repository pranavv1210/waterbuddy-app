import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'core/services/notifications/notification_service.dart';
import 'providers/app_providers.dart';
import 'routes/app_router.dart';
import 'routes/route_names.dart';
import 'widgets/premium_ui.dart';

class WaterBuddySuperApp extends ConsumerStatefulWidget {
  const WaterBuddySuperApp({super.key});

  @override
  ConsumerState<WaterBuddySuperApp> createState() => _WaterBuddySuperAppState();
}

class _WaterBuddySuperAppState extends ConsumerState<WaterBuddySuperApp> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

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
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: GestureDetector(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: child ??
                const Scaffold(
                  backgroundColor: Color(0xFFF8FAFC),
                  body: WaterBuddyLoader(message: 'Starting WaterBuddy'),
                ),
          ),
        );
      },
    );
  }
}
