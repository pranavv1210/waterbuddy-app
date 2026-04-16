import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_profile_repository.dart';
import '../models/profile_dashboard.dart';

final profileRepositoryProvider = Provider<MockProfileRepository>(
  (ref) => MockProfileRepository(),
);

final profileDashboardProvider = FutureProvider<ProfileDashboard>(
  (ref) => ref.watch(profileRepositoryProvider).getProfileDashboard(),
);
