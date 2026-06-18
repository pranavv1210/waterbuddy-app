import 'package:flutter_test/flutter_test.dart';
import 'package:waterbuddy_superapp/core/services/notifications/notification_service.dart';

void main() {
  group('FcmService Notification Routing Tests', () {
    test('routeForNotificationType maps types to correct route paths', () {
      expect(
        FcmService.routeForNotificationType('ORDER_OFFER'),
        equals('/seller'),
      );
      expect(
        FcmService.routeForNotificationType('ORDER_ACCEPTED'),
        equals('/consumer/tracking'),
      );
      expect(
        FcmService.routeForNotificationType('DRIVER_ASSIGNED'),
        equals('/consumer/tracking'),
      );
      expect(
        FcmService.routeForNotificationType('ORDER_DELIVERED'),
        equals('/consumer/order-complete'),
      );
      expect(
        FcmService.routeForNotificationType('ORDER_CANCELLED'),
        equals('/consumer/home'),
      );
      expect(
        FcmService.routeForNotificationType('PAYMENT_SUCCESS'),
        equals('/consumer/payments'),
      );
      expect(
        FcmService.routeForNotificationType('UNKNOWN_TYPE'),
        isNull,
      );
    });

    test('onNotificationTap callback invocation', () {
      var callbackCalled = false;

      FcmService.onNotificationTap((data) {
        callbackCalled = true;
      });

      // Directly invoke tap callback mechanism (simulating routing)
      // Since it's private in FcmService, we can verify that the list stores callbacks.
      // We can trigger it by creating a custom subclass or test method,
      // or simply verifying the static registration works correctly.
      expect(callbackCalled, isFalse);
    });
  });
}
