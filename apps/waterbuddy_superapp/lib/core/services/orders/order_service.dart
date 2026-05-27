import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/order.dart' as app_order;

class OrderService {
  OrderService(this._firestore);
  final FirebaseFirestore _firestore;

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

  bool _isValidTransition(String currentStatus, String newStatus) {
    final allowed = _validTransitions[currentStatus];
    return allowed != null && allowed.contains(newStatus);
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
      'status': 'SEARCHING',
      'paymentType': paymentType,
      'paymentStatus': 'PENDING',
      'sellerId': null,
      'driverId': null,
      'assignedAt': null,
      'startedAt': null,
      'deliveredAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
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
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(app_order.Order.fromDocument).toList());
  }

  Stream<List<app_order.Order>> watchSearchingOrders() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: 'SEARCHING')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(app_order.Order.fromDocument).toList());
  }

  Stream<List<app_order.Order>> watchSellerOrders(String sellerId) {
    return _firestore
        .collection('orders')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(app_order.Order.fromDocument).toList());
  }

  Stream<List<app_order.Order>> watchDriverOrders(String driverId) {
    return _firestore
        .collection('orders')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(app_order.Order.fromDocument).toList());
  }

  Future<void> acceptOrder(String orderId, String sellerId) async {
    await _firestore.runTransaction((transaction) async {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final snapshot = await transaction.get(orderRef);
      if (!snapshot.exists) throw Exception('Order does not exist');
      final data = snapshot.data() as Map<String, dynamic>;
      if ((data['status'] as String? ?? 'SEARCHING') != 'SEARCHING') {
        throw Exception('Order is no longer available for acceptance');
      }
      transaction.update(orderRef, {
        'status': 'ACCEPTED',
        'sellerId': sellerId,
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

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
      final status = data['status'] as String? ?? 'SEARCHING';
      if (status != 'ACCEPTED' &&
          status != 'ASSIGNED' &&
          status != 'DRIVER_ASSIGNED') {
        throw Exception('Order is not in assignable state');
      }
      transaction.update(orderRef, {
        'driverId': driverId,
        'status': 'DRIVER_ASSIGNED',
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _firestore.runTransaction((transaction) async {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final snapshot = await transaction.get(orderRef);
      if (!snapshot.exists) throw Exception('Order does not exist');
      final data = snapshot.data() as Map<String, dynamic>;
      final currentStatus = data['status'] as String? ?? 'SEARCHING';
      if (!_isValidTransition(currentStatus, newStatus)) {
        throw Exception(
            'Invalid state transition: $currentStatus -> $newStatus');
      }
      final patch = <String, dynamic>{
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (newStatus == 'ON_THE_WAY') {
        patch['startedAt'] = FieldValue.serverTimestamp();
      }
      if (newStatus == 'DELIVERED') {
        patch['deliveredAt'] = FieldValue.serverTimestamp();
      }
      transaction.update(orderRef, patch);
    });
  }

  Future<void> cancelOrder({
    required String orderId,
    required String reason,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final snapshot = await transaction.get(orderRef);
      if (!snapshot.exists) throw Exception('Order does not exist');
      final data = snapshot.data() as Map<String, dynamic>;
      final currentStatus = data['status'] as String? ?? 'SEARCHING';
      if (!_isValidTransition(currentStatus, 'CANCELLED')) {
        throw Exception('This order can no longer be cancelled.');
      }
      transaction.update(orderRef, {
        'status': 'CANCELLED',
        'cancellationReason': reason,
        'cancelledBy': 'customer',
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
