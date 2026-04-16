import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_searching_repository.dart';
import '../models/searching_tankers_state.dart';

final searchingRepositoryProvider = Provider<MockSearchingRepository>(
  (ref) => MockSearchingRepository(),
);

final searchingTankersProvider = FutureProvider<SearchingTankersState>(
  (ref) => ref.watch(searchingRepositoryProvider).getSearchingState(),
);
