import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../login_screen.dart';
import '../../../widgets/async_state_view.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // Check KYC Status
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!context.mounted) return;
            
            try {
              final doc = await ref.read(firestoreProvider).collection('sellers').doc(user.uid).get();
              if (doc.exists && doc.data()?['kycStatus'] == 'VERIFIED') {
                if (context.mounted) context.go(RouteNames.home);
              } else {
                if (context.mounted) context.go(RouteNames.kyc);
              }
            } catch (e) {
              if (context.mounted) context.go(RouteNames.kyc); // Default to KYC on error
            }
          });
          // Show loading while navigating
          return const Scaffold(
            backgroundColor: Color(0xFF020617),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            ),
          );
        }

        return AsyncStateView(
          isLoading: false,
          hasError: false,
          child: const LoginScreen(),
        );
      },
      error: (error, stack) {
        print('[AUTH GATE ERROR] $error');
        print('[AUTH GATE STACK] $stack');
        return AsyncStateView(
          isLoading: false,
          hasError: true,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(authStateProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const AsyncStateView(
        isLoading: true,
        hasError: false,
        child: SizedBox.shrink(),
      ),
    );
  }
}
