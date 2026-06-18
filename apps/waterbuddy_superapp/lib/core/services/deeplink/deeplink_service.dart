import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../observability/observability_service.dart';

class DeeplinkService {
  DeeplinkService._();

  static void handleLink(BuildContext context, String link) {
    try {
      final uri = Uri.parse(link);
      if (uri.scheme != 'waterbuddy') return;

      ObservabilityService.info(
        LogTag.analytics,
        'Handling deep link: $link',
        context: {'path': uri.path, 'query': uri.queryParameters},
      );

      final router = GoRouter.of(context);
      final host = uri.host;
      
      switch (host) {
        case 'tracking':
          // Path segments: tracking/{orderId}
          final segments = uri.pathSegments;
          if (segments.isNotEmpty) {
            final orderId = segments.first;
            router.go('/consumer/tracking?orderId=$orderId');
          } else {
            router.go('/consumer/home');
          }
          break;
        case 'orders':
          router.go('/consumer/orders');
          break;
        case 'wallet':
        case 'refunds':
          router.go('/consumer/payments');
          break;
        case 'profile':
          router.go('/consumer/profile');
          break;
        case 'reviews':
          router.go('/consumer/orders');
          break;
        default:
          router.go('/consumer/home');
      }
    } catch (e, stack) {
      ObservabilityService.error(
        LogTag.analytics,
        'Failed to parse deep link: $link',
        error: e,
        stack: stack,
      );
    }
  }

  /// Triggered when an FCM notification payload contains a routing click action
  static void handleFcmNotificationPayload(BuildContext context, Map<String, dynamic> data) {
    final link = data['click_action'] as String?;
    if (link != null && link.startsWith('waterbuddy://')) {
      handleLink(context, link);
    }
  }
}
