import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waterbuddy_superapp/core/auth/app_role.dart';
import 'package:waterbuddy_superapp/core/services/orders/order_service.dart';
import 'package:waterbuddy_superapp/core/services/session/session_restoration_service.dart';
import 'package:waterbuddy_superapp/models/order.dart' as app_order;

class FakeOrderService implements OrderService {
  FakeOrderService({this.activeOrder});

  final app_order.Order? activeOrder;

  @override
  Future<app_order.Order?> findActiveOrder({
    String? customerId,
    String? sellerId,
    String? driverId,
  }) async {
    return activeOrder;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('SessionRestorationService Tests', () {
    const service = SessionRestorationService();

    test('Returns null if userId or role is null', () async {
      final result = await service.restore(
        userId: null,
        role: AppRole.consumer,
        orderService: FakeOrderService(),
      );
      expect(result, isNull);

      final result2 = await service.restore(
        userId: 'user123',
        role: null,
        orderService: FakeOrderService(),
      );
      expect(result2, isNull);
    });

    test('Returns null if no active order is found', () async {
      final result = await service.restore(
        userId: 'user123',
        role: AppRole.consumer,
        orderService: FakeOrderService(activeOrder: null),
      );
      expect(result, isNull);
    });

    test('Restores active order with SEARCHING status', () async {
      final mockOrder = app_order.Order(
        id: 'order_123',
        customerId: 'user123',
        customerName: 'Pranav',
        customerPhone: '1234567890',
        sellerId: null,
        status: 'SEARCHING',
        createdAt: Timestamp.now(),
        location: const {},
        configuredTankLabel: 'Main Tank',
        tankSize: 500,
        amount: 250,
        paymentType: 'ONLINE',
        paymentStatus: 'PENDING',
      );

      final result = await service.restore(
        userId: 'user123',
        role: AppRole.consumer,
        orderService: FakeOrderService(activeOrder: mockOrder),
      );

      expect(result, isNotNull);
      expect(result!.order.id, 'order_123');
      expect(result.targetRoute, '/consumer/searching');
    });

    test('Restores active order with ON_THE_WAY status', () async {
      final mockOrder = app_order.Order(
        id: 'order_123',
        customerId: 'user123',
        customerName: 'Pranav',
        customerPhone: '1234567890',
        sellerId: null,
        status: 'ON_THE_WAY',
        createdAt: Timestamp.now(),
        location: const {},
        configuredTankLabel: 'Main Tank',
        tankSize: 500,
        amount: 250,
        paymentType: 'ONLINE',
        paymentStatus: 'PENDING',
      );

      final result = await service.restore(
        userId: 'user123',
        role: AppRole.consumer,
        orderService: FakeOrderService(activeOrder: mockOrder),
      );

      expect(result, isNotNull);
      expect(result!.order.id, 'order_123');
      expect(result.targetRoute, '/consumer/tracking');
    });
  });
}
