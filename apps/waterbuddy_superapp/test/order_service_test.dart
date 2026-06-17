import 'package:flutter_test/flutter_test.dart';
import 'package:waterbuddy_superapp/core/services/orders/order_state_validator.dart';

void main() {
  group('OrderStateValidator Tests', () {
    test('Valid Transitions', () {
      expect(OrderStateValidator.isValid('SEARCHING', 'ASSIGNED'), isTrue);
      expect(OrderStateValidator.isValid('SEARCHING', 'CANCELLED'), isTrue);
      expect(OrderStateValidator.isValid('ASSIGNED', 'EN_ROUTE'), isTrue);
      expect(OrderStateValidator.isValid('ASSIGNED', 'CANCELLED'), isTrue);
      expect(OrderStateValidator.isValid('EN_ROUTE', 'COMPLETED'), isTrue);
      expect(OrderStateValidator.isValid('EN_ROUTE', 'CANCELLED'), isTrue);
    });

    test('Illegal Transitions', () {
      expect(OrderStateValidator.isValid('SEARCHING', 'COMPLETED'), isFalse);
      expect(OrderStateValidator.isValid('COMPLETED', 'SEARCHING'), isFalse);
      expect(OrderStateValidator.isValid('CANCELLED', 'SEARCHING'), isFalse);
      expect(OrderStateValidator.isValid('COMPLETED', 'ASSIGNED'), isFalse);
    });

    test('validateTransition throws on illegal transitions', () {
      expect(
        () => OrderStateValidator.validateTransition('SEARCHING', 'COMPLETED'),
        throwsA(isA<OrderStateException>()),
      );
    });
  });

  group('Double Booking Prevention Simulation', () {
    test('Simulate double-booking prevention', () {
      // Simulate two drivers trying to accept the same order
      var orderAccepted = false;
      var acceptCount = 0;

      void attemptAcceptOrder(String driverId) {
        if (orderAccepted) {
          throw const OrderStateException(
            'Order already accepted by another driver',
            currentStatus: 'ASSIGNED',
            attemptedStatus: 'ASSIGNED',
          );
        }
        orderAccepted = true;
        acceptCount++;
      }

      // First attempt succeeds
      attemptAcceptOrder('driver_1');
      expect(orderAccepted, isTrue);
      expect(acceptCount, 1);

      // Second attempt fails
      expect(
        () => attemptAcceptOrder('driver_2'),
        throwsA(isA<OrderStateException>()),
      );
      expect(acceptCount, 1);
    });
  });
}
