import 'package:flutter/foundation.dart';

import '../../auth/app_role.dart';
import '../../../models/order.dart' as app_order;
import '../../../providers/app_providers.dart';
import '../orders/order_service.dart';

/// Session Restoration Service
/// 
/// On app startup (after kill/restart/reboot), this service:
/// 1. Checks if the user was authenticated
/// 2. Finds any active order for the user's role
/// 3. Returns the order so the navigator can redirect to the correct screen
/// 
/// This ensures the app picks up exactly where it left off.
class SessionRestorationService {
  const SessionRestorationService();

  /// Find the active order to restore after app restart/crash
  /// Returns the order and the target route name
  Future<RestorationResult?> restore({
    required String? userId,
    required AppRole? role,
    required OrderService orderService,
  }) async {
    if (userId == null || role == null) return null;

    debugPrint('[SESSION] Restoring session for user=$userId role=$role');

    try {
      String? fieldName;
      switch (role) {
        case AppRole.consumer:
          fieldName = 'customerId';
          break;
        case AppRole.seller:
          fieldName = 'sellerId';
          break;
        case AppRole.driver:
          fieldName = 'driverId';
          break;
        case AppRole.admin:
          return null; // Admin doesn't need session restoration
      }

      final activeOrder = await orderService.findActiveOrder(
        customerId: role == AppRole.consumer ? userId : null,
        sellerId: role == AppRole.seller ? userId : null,
        driverId: role == AppRole.driver ? userId : null,
      );

      if (activeOrder == null) {
        debugPrint('[SESSION] No active order found');
        return null;
      }

      debugPrint(
        '[SESSION] Found active order: ${activeOrder.id} status=${activeOrder.status}',
      );

      // Determine the target screen based on status
      String targetRoute;
      switch (activeOrder.status) {
        case 'SEARCHING':
        case 'OFFER_SENT':
          targetRoute = '/consumer/searching';
          break;
        case 'ACCEPTED':
        case 'ASSIGNED':
        case 'DRIVER_ASSIGNED':
        case 'EN_ROUTE':
        case 'ON_THE_WAY':
        case 'ARRIVED':
        case 'DELIVERING':
          targetRoute = '/consumer/tracking';
          break;
        default:
          return null;
      }

      return RestorationResult(
        order: activeOrder,
        targetRoute: targetRoute,
      );
    } catch (e) {
      debugPrint('[SESSION] Restoration error: $e');
      return null;
    }
  }
}

class RestorationResult {
  const RestorationResult({
    required this.order,
    required this.targetRoute,
  });

  final app_order.Order order;
  final String targetRoute;
}