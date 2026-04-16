import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_completed_order_repository.dart';
import '../models/completed_order.dart';

final completedOrderRepositoryProvider = Provider<MockCompletedOrderRepository>(
  (ref) => MockCompletedOrderRepository(),
);

final completedOrderProvider = FutureProvider<CompletedOrder>(
  (ref) => ref.watch(completedOrderRepositoryProvider).getCompletedOrder(),
);

final selectedRatingProvider = StateProvider<int>((ref) => 0);
