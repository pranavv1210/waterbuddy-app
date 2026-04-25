import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/order.dart' as app_order;

class OrderService {
  OrderService(this._firestore);

  final FirebaseFirestore _firestore;

  // Valid state transitions
  static const Map<String, Set<String>> _validTransitions = {
    'SEARCHING': {'ASSIGNED', 'CANCELLED'},
    'ASSIGNED': {'ON_THE_WAY', 'CANCELLED'},
    'ON_THE_WAY': {'DELIVERED', 'CANCELLED'},
    'DELIVERED': {}, // Terminal state
    'CANCELLED': {}, // Terminal state
  };

  bool _isValidTransition(String currentStatus, String newStatus) {
    final allowedNextStates = _validTransitions[currentStatus];
    return allowedNextStates != null && allowedNextStates.contains(newStatus);
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _firestore.runTransaction((transaction) async {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final snapshot = await transaction.get(orderRef);

      if (!snapshot.exists) {
        throw Exception('Order does not exist');
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final currentStatus = data['status'] as String? ?? 'SEARCHING';

      // Validate state transition
      if (!_isValidTransition(currentStatus, newStatus)) {
        throw Exception(
          'Invalid state transition: $currentStatus → $newStatus. '
          'Valid transitions from $currentStatus: ${_validTransitions[currentStatus]?.join(", ") ?? "none"}',
        );
      }

      // Update order atomically
      transaction.update(orderRef, {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<String> createOrder({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required num tankSize,
    required String tankLabel,
    required Map<String, dynamic> location,
    required String paymentType,
  }) async {
    final docRef = await _firestore.collection('orders').add({
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'tankSize': tankSize,
      'tankLabel': tankLabel,
      'location': location,
      'status': 'SEARCHING',
      'paymentType': paymentType,
      'paymentStatus': 'PENDING',
      'sellerId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Stream<app_order.Order?> watchOrder(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((snapshot) => snapshot.exists
            ? app_order.Order.fromDocument(snapshot)
            : null);
  }

  Stream<List<app_order.Order>> watchCustomerOrders(String customerId) {
    return _firestore
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(app_order.Order.fromDocument).toList());
  }
}
