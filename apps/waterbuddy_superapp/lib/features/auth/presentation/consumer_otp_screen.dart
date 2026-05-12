import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_role.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';

class ConsumerOtpScreen extends ConsumerStatefulWidget {
  const ConsumerOtpScreen({super.key});

  @override
  ConsumerState<ConsumerOtpScreen> createState() => _ConsumerOtpScreenState();
}

class _ConsumerOtpScreenState extends ConsumerState<ConsumerOtpScreen> {
  final _otp = TextEditingController();

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>? ?? const {};
    ref.listen(authControllerProvider, (_, next) {
      if (next.isVerified && mounted) {
        context.go(RouteNames.consumerHome);
      }
    });
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Development OTP: 123456'),
            ),
            TextField(controller: _otp, decoration: const InputDecoration(labelText: 'Enter 6-digit OTP')),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: authState.isLoading
                  ? null
                  : () async {
                      final ok = await ref.read(authControllerProvider.notifier).verifyDevelopmentOtp(
                            otpCode: _otp.text.trim(),
                            role: AppRole.consumer,
                            fullName: (extra['fullName'] as String?) ?? '',
                            email: (extra['email'] as String?) ?? '',
                            phoneNumber: (extra['phone'] as String?) ?? '',
                          );
                      if (ok && mounted) context.go(RouteNames.consumerHome);
                    },
              child: const Text('Verify'),
            ),
            if (authState.errorMessage != null) Text(authState.errorMessage!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}

