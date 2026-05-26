import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../routes/route_names.dart';

Future<void> signOutToRoleSelection({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  await ref.read(selectedRoleProvider.notifier).clear();
  await ref.read(authServiceProvider).signOut();
  if (context.mounted) {
    context.go(RouteNames.roleSelection);
  }
}
