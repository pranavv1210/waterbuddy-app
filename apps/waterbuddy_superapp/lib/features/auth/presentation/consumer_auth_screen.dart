import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_role.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';

class ConsumerAuthScreen extends ConsumerStatefulWidget {
  const ConsumerAuthScreen({super.key});

  @override
  ConsumerState<ConsumerAuthScreen> createState() => _ConsumerAuthScreenState();
}

class _ConsumerAuthScreenState extends ConsumerState<ConsumerAuthScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (_, next) {
      if (next.isVerified && mounted) {
        context.go(RouteNames.consumerHome);
      }
    });
    return Scaffold(
      appBar: AppBar(title: const Text('Consumer Login')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full Name')),
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email ID')),
          TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Mobile Number')),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: authState.isLoading
                ? null
                : () async {
                    final ok = await ref.read(authControllerProvider.notifier).sendOtp(
                          _phone.text.trim(),
                          role: AppRole.consumer,
                        );
                    if (ok && mounted) {
                      context.push(
                        RouteNames.authConsumerOtp,
                        extra: {
                          'fullName': _name.text.trim(),
                          'email': _email.text.trim(),
                          'phone': _phone.text.trim(),
                        },
                      );
                    }
                  },
            child: const Text('Send OTP'),
          ),
          OutlinedButton(
            onPressed: authState.isLoading
                ? null
                : () async {
                    await ref.read(authControllerProvider.notifier).signInWithGoogle(role: AppRole.consumer);
                  },
            child: const Text('Continue with Google'),
          ),
          if (authState.errorMessage != null) Text(authState.errorMessage!, style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}

