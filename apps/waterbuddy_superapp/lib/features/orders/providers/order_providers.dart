import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/order.dart';
import '../../../providers/app_providers.dart';

// All orders for current user, newest first — used by History screen
final orderHistoryProvider = StreamProvider.autoDispose<List<Order>>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  final user = auth.currentUser;

  if (user == null) return Stream.value([]);

  return firestore
      .collection('orders')
      .where('customerId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(Order.fromDocument).toList());
});

// Legacy provider kept for backwards compat (active order checks)
final completedOrdersProvider = StreamProvider.autoDispose<List<Order>>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final orderService = ref.watch(orderServiceProvider);
  final user = auth.currentUser;

  if (user == null) return Stream.value([]);

  return orderService.watchCustomerOrders(user.uid);
});

final selectedRatingProvider = StateProvider<int>((ref) => 0);
