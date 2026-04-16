import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_home_repository.dart';
import '../models/home_dashboard.dart';

final homeRepositoryProvider = Provider<MockHomeRepository>(
  (ref) => MockHomeRepository(),
);

final homeDashboardProvider = FutureProvider<HomeDashboard>(
  (ref) => ref.watch(homeRepositoryProvider).getDashboard(),
);

final selectedTankIdProvider = StateProvider<String?>((ref) => null);
