import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_providers.dart';
import '../../../widgets/async_state_view.dart';
import '../../../widgets/feature_placeholder.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) => AsyncStateView(
        isLoading: false,
        hasError: false,
        child: FeaturePlaceholder(
          title: 'Authentication',
          description: user == null
              ? 'OTP and Google sign-in flows attach here.'
              : 'Authenticated user session is active.',
        ),
      ),
      error: (_, __) => const AsyncStateView(
        isLoading: false,
        hasError: true,
        child: SizedBox.shrink(),
      ),
      loading: () => const AsyncStateView(
        isLoading: true,
        hasError: false,
        child: SizedBox.shrink(),
      ),
    );
  }
}
