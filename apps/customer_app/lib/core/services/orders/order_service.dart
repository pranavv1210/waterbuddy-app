import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/order.dart' as app_order;

class OrderService {
  OrderService(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<app_order.Order>> watchCustomerOrders(String customerId) {
    return _firestore
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(app_order.Order.fromDocument).toList());
  }
}
