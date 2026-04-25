import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/order.dart' as app_order;

class OrderService {
  OrderService(this._firestore);

  final FirebaseFirestore _firestore;

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
