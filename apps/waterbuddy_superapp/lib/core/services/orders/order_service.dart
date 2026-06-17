import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/order.dart' as app_order;

/// Order State Machine with atomic transitions
///
/// Flow:
///   CREATED → SEARCHING → OWNER_ACCEPTED → DRIVER_ASSIGNED → DRIVER_EN_ROUTE → ARRIVED → FILLING → DELIVERING → COMPLETED
///   Any state → CANCELLED
///   SEARCHING → OWNER_ACCEPTED (if no driver flow)
enum OrderState {
  created,
  searching,
  ownerAccepted,
  driverAssigned,
  driverEnRoute,
  arrived,
  filling,
  delivering,
  completed,
  cancelled,
}

class OrderService {
  OrderService(this._firestore);
  final FirebaseFirestore _firestore;

  /// Complete state machine definition
  static const Map<OrderState, Set<OrderState>> _stateMachine = {
    OrderState.created: {OrderState.searching, OrderState.cancelled},
    OrderState.searching: {OrderState.ownerAccepted, OrderState.cancelled},
    OrderState.ownerAccepted: {OrderState.driverAssigned, OrderState.cancelled},
    OrderState.driverAssigned: {OrderState.driverEnRoute, OrderState.cancelled},
    OrderState.driverEnRoute: {OrderState.arrived, OrderState.cancelled},
    OrderState.arrived: {OrderState.filling, OrderState.cancelled},
    OrderState.filling: {OrderState.delivering, OrderState.cancelled},
    OrderState.delivering: {OrderState.completed, OrderState.cancelled},
    OrderState.completed: {},
    OrderState.cancelled: {},
  };

  /// Legacy string-based transitions for backward compatibility
  static const Map<String, Set<String>> _validTransitions = {
    'SEARCHING': {'ACCEPTED', 'ASSIGNED', 'CANCELLED'},
    'ACCEPTED': {'DRIVER_ASSIGNED', 'ON_THE_WAY', 'CANCELLED'},
    'ASSIGNED': {'DRIVER_ASSIGNED', 'ON_THE_WAY', 'CANCELLED'},
    'DRIVER_ASSIGNED': {'ON_THE_WAY', 'CANCELLED'},
    'ON_THE_WAY': {'ARRIVED', 'DELIVERED', 'CANCELLED'},
    'ARRIVED': {'DELIVERED', 'CANCELLED'},
    'DELIVERED': {},
    'CANCELLED': {},
  };

  // New state string constants
  static const String statusCreated = 'CREATED';
  static const String statusSearching = 'SEARCHING';
  static const String statusOwnerAccepted = 'OWNER_ACCEPTED';
  static const String statusDriverAssigned = 'DRIVER_ASSIGNED';
  static const String statusDriverEnRoute = 'DRIVER_EN_ROUTE';
  static const String statusArrived = 'ARRIVED';
  static const String statusFilling = 'FILLING';
  static const String statusDelivering = 'DELIVERING';
  static const String statusCompleted = 'COMPLETED';
  static const String statusCancelled = 'CANCELLED';

  static OrderState _stringToState(String status) {
    switch (status) {
      case 'CREATED':
        return OrderState.created;
      case 'SEARCHING':
        return OrderState.searching;
      case 'OWNER_ACCEPTED':
        return OrderState.ownerAccepted;
      case 'DRIVER_ASSIGNED':
        return OrderState.driverAssigned;
      case 'DRIVER_EN_ROUTE':
        return OrderState.driverEnRoute;
      case 'ARRIVED':
        return OrderState.arrived;
      case 'FILLING':
        return OrderState.filling;
      case 'DELIVERING':
        return OrderState.delivering;
      case 'COMPLETED':
        return OrderState.completed;
      case 'CANCELLED':
        return OrderState.cancelled;
      default:
        return OrderState.searching;
    }
  }

  bool _isValidTransition(String currentStatus, String newStatus) {
    // Check legacy first
    final allowedLegacy = _validTransitions[currentStatus];
    if (allowedLegacy != null && allowedLegacy.contains(newStatus)) {
      return true;
    }
    // Check new state machine
    final current = _stringToState(currentStatus);
    final next = _stringToState(newStatus);
    final allowed = _stateMachine[current];
    return allowed != null && allowed.contains(next);
  }

  Future<String> createOrder({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required num tankSize,
    required String tankLabel,
    required String tankId,
    required num amount,
    required Map<String, dynamic> pricingSnapshot,
    required Map<String, dynamic> location,
    required String paymentType,
  }) async {
    final pin = (1000 + Random().nextInt(9000)).toString();
    final docRef = await _firestore.collection('orders').add({
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'tankSize': tankSize,
      'tankLabel': tankLabel,
      'tankId': tankId,
      'amount': amount,
      'pricingSnapshot': pricingSnapshot,
      'location': location,
      'status': statusSearching,
      'paymentType': paymentType,
      'paymentStatus': 'PENDING',
      'deliveryPin': pin,
      'sellerId': null,
      'driverId': null,
      'assignedAt': null,
      'startedAt': null,
      'deliveredAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'stateHistory': [
        {
          'status': statusSearching,
          'timestamp': FieldValue.serverTimestamp(),
        }
      ],
    });
    return docRef.id;
  }

  /// Atomic state transition with Firestore transaction
  /// Prevents race conditions and duplicate transitions
  Future<void> _atomicTransition({
    required String orderId,
    required String newStatus,
    Map<String, dynamic>? additionalFields,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final snapshot = await transaction.get(orderRef);
      if (!snapshot.exists) throw Exception('Order does not exist');

      final data = snapshot.data() as Map<String, dynamic>;
      final currentStatus = data['status'] as String? ?? statusSearching;

      if (!_isValidTransition(currentStatus, newStatus)) {
        throw Exception(
            'Invalid state transition: $currentStatus -> $newStatus');
      }

      final patch = <String, dynamic>{
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        ...?additionalFields,
      };

      // Timestamp fields for specific transitions
      if (newStatus == statusDriverEnRoute) {
        patch['startedAt'] = FieldValue.serverTimestamp();
      }
      if (newStatus == statusCompleted) {
        patch['deliveredAt'] = FieldValue.serverTimestamp();
      }

      // Append to state history (limited to last 20)
      final history = (data['stateHistory'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      history.add({
        'status': newStatus,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (history.length > 20) {
        history.removeRange(0, history.length - 20);
      }
      patch['stateHistory'] = history;

      transaction.update(orderRef, patch);
    });
  }

  Stream<app_order.Order?> watchOrder(String orderId) {
    return _firestore.collection('orders').doc(orderId).snapshots().map(
        (snapshot) =>
            snapshot.exists ? app_order.Order.fromDocument(snapshot) : null);
  }

  Stream<List<app_order.Order>> watchCustomerOrders(String customerId) {
    return _firestore
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(app_order.Order.fromDocument).toList());
  }

  Stream<List<app_order.Order>> watchSearchingOrders() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: statusSearching)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(app_order.Order.fromDocument).toList());
  }

  Stream<List<app_order.Order>> watchSellerOrders(String sellerId) {
    return _firestore
        .collection('orders')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(app_order.Order.fromDocument).toList());
  }

  Stream<List<app_order.Order>> watchDriverOrders(String driverId) {
    return _firestore
        .collection('orders')
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(app_order.Order.fromDocument).toList());
  }

  /// Accept order by seller - atomic with duplicate prevention
  Future<void> acceptOrder(String orderId, String sellerId) async {
    await _firestore.runTransaction((transaction) async {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final snapshot = await transaction.get(orderRef);
      if (!snapshot.exists) throw Exception('Order does not exist');

      final data = snapshot.data() as Map<String, dynamic>;
      final status = data['status'] as String? ?? statusSearching;

      if (status != statusSearching) {
        throw Exception('Order is no longer available for acceptance');
      }
      // Prevent duplicate seller acceptance
      if (data['sellerId'] != null && data['sellerId'].toString().isNotEmpty) {
        throw Exception('Order already accepted by another seller');
      }

      transaction.update(orderRef, {
        'status': 'ACCEPTED',
        'sellerId': sellerId,
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> acceptOffer({
    required String offerId,
    String? driverId,
  }) async {
    await _firestore.collection('order_offers').doc(offerId).set({
      'status': 'accepted',
      if (driverId != null) 'driverId': driverId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> rejectOffer({required String offerId}) async {
    await _firestore.collection('order_offers').doc(offerId).set({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Assign driver with atomic check - prevents double assignment
  Future<void> assignDriver({
    required String orderId,
    required String sellerId,
    required String driverId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final snapshot = await transaction.get(orderRef);
      if (!snapshot.exists) throw Exception('Order does not exist');

      final data = snapshot.data() as Map<String, dynamic>;
      if ((data['sellerId'] as String?) != sellerId) {
        throw Exception('Seller is not assigned to this order');
      }
      final status = data['status'] as String? ?? statusSearching;
      if (status != 'ACCEPTED' && status != 'ASSIGNED') {
        throw Exception('Order is not in assignable state');
      }
      // Prevent double driver assignment
      if (data['driverId'] != null && data['driverId'].toString().isNotEmpty) {
        throw Exception('Driver already assigned to this order');
      }

      transaction.update(orderRef, {
        'driverId': driverId,
        'status': statusDriverAssigned,
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Standard order status update with full state machine validation
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _atomicTransition(orderId: orderId, newStatus: newStatus);
  }

  /// Cancel order with atomic validation and charge calculation
  Future<void> cancelOrder({
    required String orderId,
    required String reason,
    String cancelledBy = 'customer',
  }) async {
    await _firestore.runTransaction((transaction) async {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final settingsRef =
          _firestore.collection('system_settings').doc('config');
      final snapshot = await transaction.get(orderRef);
      final settingsSnapshot = await transaction.get(settingsRef);
      if (!snapshot.exists) throw Exception('Order does not exist');

      final data = snapshot.data() as Map<String, dynamic>;
      final settings = settingsSnapshot.data() ?? const <String, dynamic>{};
      final cancellationCharge = settings['cancellationCharge'] as num? ?? 0;
      final currentStatus = data['status'] as String? ?? statusSearching;

      if (!_isValidTransition(currentStatus, statusCancelled)) {
        throw Exception('This order can no longer be cancelled.');
      }

      transaction.update(orderRef, {
        'status': statusCancelled,
        'cancellationReason': reason,
        'cancellationCharge': cancellationCharge,
        'cancelledBy': cancelledBy,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateOrderPayment(String orderId, String paymentType) async {
    await _firestore.collection('orders').doc(orderId).update({
      'paymentType': paymentType,
      'paymentStatus': 'PENDING',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
