import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/order.dart';

class OrderService {
  OrderService(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<Order>> watchCustomerOrders(String customerId) {
    return _firestore
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Order.fromDocument).toList());
  }
}
