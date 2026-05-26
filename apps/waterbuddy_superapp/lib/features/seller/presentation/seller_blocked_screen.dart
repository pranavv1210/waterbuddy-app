import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_actions.dart';

class SellerBlockedScreen extends ConsumerWidget {
  const SellerBlockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Seller account is blocked. Contact support.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async =>
                    signOutToRoleSelection(context: context, ref: ref),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
