import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_tracking_repository.dart';
import '../models/assigned_order_tracking.dart';

final trackingRepositoryProvider = Provider<MockTrackingRepository>(
  (ref) => MockTrackingRepository(),
);

final assignedOrderTrackingProvider = FutureProvider<AssignedOrderTracking>(
  (ref) => ref.watch(trackingRepositoryProvider).getAssignedOrder(),
);
