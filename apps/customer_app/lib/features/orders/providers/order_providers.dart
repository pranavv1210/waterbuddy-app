import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/order.dart';
import '../../../providers/app_providers.dart';

final completedOrdersProvider = StreamProvider.autoDispose<List<Order>>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final orderService = ref.watch(orderServiceProvider);
  final user = auth.currentUser;
  
  if (user == null) {
    return Stream.value([]);
  }
  
  return orderService.watchCustomerOrders(user.uid);
});

final selectedRatingProvider = StateProvider<int>((ref) => 0);
