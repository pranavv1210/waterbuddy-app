// ignore_for_file: subtype_of_sealed_class

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waterbuddy_superapp/core/auth/app_role.dart';
import 'package:waterbuddy_superapp/core/services/background/background_service.dart';
import 'package:waterbuddy_superapp/core/services/orders/order_service.dart';
import 'package:waterbuddy_superapp/core/services/session/session_restoration_service.dart';
import 'package:waterbuddy_superapp/models/order.dart' as app_order;

// Mocks for testing
class MockOrderService implements OrderService {
  MockOrderService({this.activeOrder});
  
  app_order.Order? activeOrder;
  int findActiveOrderCallCount = 0;

  @override
  Future<app_order.Order?> findActiveOrder({
    String? customerId,
    String? sellerId,
    String? driverId,
  }) async {
    findActiveOrderCallCount++;
    return activeOrder;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockDocumentSnapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  MockDocumentSnapshot(this._isFromCache, this._data);
  final bool _isFromCache;
  final Map<String, dynamic> _data;

  @override
  SnapshotMetadata get metadata => MockSnapshotMetadata(_isFromCache);

  @override
  Map<String, dynamic>? data() => _data;

  @override
  bool get exists => true;
}

class MockSnapshotMetadata extends Fake implements SnapshotMetadata {
  MockSnapshotMetadata(this._isFromCache);
  final bool _isFromCache;

  @override
  bool get isFromCache => _isFromCache;
}

class MockDocumentReference extends Fake implements DocumentReference<Map<String, dynamic>> {
  MockDocumentReference(this._snapshotsController);
  final StreamController<DocumentSnapshot<Map<String, dynamic>>> _snapshotsController;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #snapshots) {
      return _snapshotsController.stream;
    }
    return super.noSuchMethod(invocation);
  }
}

class MockCollectionReference extends Fake implements CollectionReference<Map<String, dynamic>> {
  MockCollectionReference(this._docRef);
  final MockDocumentReference _docRef;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => _docRef;
}

class MockFirestore extends Fake implements FirebaseFirestore {
  MockFirestore(this._colRef);
  final MockCollectionReference _colRef;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return _colRef;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Chaos Testing & Background Resilience', () {
    late StreamController<DocumentSnapshot<Map<String, dynamic>>> snapshotsController;
    late MockFirestore mockFirestore;
    late MockOrderService mockOrderService;
    late BackgroundService backgroundService;

    setUp(() {
      snapshotsController = StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();
      final mockDocRef = MockDocumentReference(snapshotsController);
      final mockColRef = MockCollectionReference(mockDocRef);
      mockFirestore = MockFirestore(mockColRef);
      mockOrderService = MockOrderService();
      backgroundService = BackgroundService(
        firestore: mockFirestore,
        orderService: mockOrderService,
      );
    });

    tearDown(() {
      snapshotsController.close();
      backgroundService.detach();
    });

    test('Network Disconnect & Reconnect triggers active order restoration', () async {
      backgroundService.attach();
      backgroundService.setUser('test_user', 'consumer');

      // Verify no restore attempts yet
      expect(mockOrderService.findActiveOrderCallCount, 0);

      // Simulate network disconnect (offline cache snapshot)
      snapshotsController.add(MockDocumentSnapshot(true, {}));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(mockOrderService.findActiveOrderCallCount, 0);

      // Simulate internet reconnect (online server snapshot)
      snapshotsController.add(MockDocumentSnapshot(false, {}));
      await Future.delayed(const Duration(milliseconds: 10));
      
      // Verification: order restoration was invoked on reconnect
      expect(mockOrderService.findActiveOrderCallCount, 1);
    });

    test('App transition from background -> foreground triggers re-sync', () async {
      backgroundService.attach();
      backgroundService.setUser('test_user', 'consumer');

      expect(mockOrderService.findActiveOrderCallCount, 0);

      // Simulate background state
      backgroundService.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(mockOrderService.findActiveOrderCallCount, 0);

      // Simulate foreground state
      backgroundService.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(mockOrderService.findActiveOrderCallCount, 1);
    });

    test('SessionRestorationService restores active state correctly for searching consumer', () async {
      final mockOrder = app_order.Order(
        id: 'order_123',
        customerId: 'customer_1',
        customerName: 'Test Customer',
        customerPhone: '9876543210',
        sellerId: null,
        status: 'SEARCHING',
        createdAt: Timestamp.now(),
        location: const {},
        configuredTankLabel: '500L Tanker',
        tankSize: 500,
        amount: 250,
        paymentType: 'ONLINE',
        paymentStatus: 'PENDING',
      );

      mockOrderService.activeOrder = mockOrder;
      const restorationService = SessionRestorationService();

      final result = await restorationService.restore(
        userId: 'customer_1',
        role: AppRole.consumer,
        orderService: mockOrderService,
      );

      expect(result, isNotNull);
      expect(result!.order.id, 'order_123');
      expect(result.targetRoute, '/consumer/searching');
    });

    test('SessionRestorationService restores active state correctly for assigned tracking consumer', () async {
      final mockOrder = app_order.Order(
        id: 'order_123',
        customerId: 'customer_1',
        customerName: 'Test Customer',
        customerPhone: '9876543210',
        sellerId: 'seller_1',
        status: 'ON_THE_WAY',
        createdAt: Timestamp.now(),
        location: const {},
        configuredTankLabel: '500L Tanker',
        tankSize: 500,
        amount: 250,
        paymentType: 'ONLINE',
        paymentStatus: 'PAID',
      );

      mockOrderService.activeOrder = mockOrder;
      const restorationService = SessionRestorationService();

      final result = await restorationService.restore(
        userId: 'customer_1',
        role: AppRole.consumer,
        orderService: mockOrderService,
      );

      expect(result, isNotNull);
      expect(result!.order.id, 'order_123');
      expect(result.targetRoute, '/consumer/tracking');
    });
  });
}
