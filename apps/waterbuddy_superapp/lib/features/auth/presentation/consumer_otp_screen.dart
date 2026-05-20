import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_role.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/kaveri_auth_layout.dart';

class ConsumerOtpScreen extends ConsumerStatefulWidget {
  const ConsumerOtpScreen({super.key});

  @override
  ConsumerState<ConsumerOtpScreen> createState() => _ConsumerOtpScreenState();
}

class _ConsumerOtpScreenState extends ConsumerState<ConsumerOtpScreen> with SingleTickerProviderStateMixin {
  final _otp = TextEditingController();

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 450))..forward();
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _otp.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>? ?? const {};
    final phoneNumber = (extra['phone'] as String?) ?? '';
    
    ref.listen(authControllerProvider, (_, next) {
      if (next.isVerified && mounted) {
        context.go(RouteNames.consumerHome);
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(RouteNames.authConsumer);
        }
      },
      child: KaveriAuthLayout(
        activeRole: AppRole.consumer,
        title: 'Verify OTP',
        subtitle: 'Enter the 6-digit code sent to $phoneNumber',
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      onPressed: () => context.canPop() ? context.pop() : context.go(RouteNames.authConsumer),
                    ),
                    const Text('OTP Verification', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0EA5E9).withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Development OTP: 123456',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _otp,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '------',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), letterSpacing: 8),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: authState.isLoading
                      ? null
                      : () async {
                          final ok = await ref.read(authControllerProvider.notifier).verifyDevelopmentOtp(
                                otpCode: _otp.text.trim(),
                                role: AppRole.consumer,
                                fullName: (extra['fullName'] as String?) ?? '',
                                email: (extra['email'] as String?) ?? '',
                                phoneNumber: phoneNumber,
                              );
                          if (ok && mounted) context.go(RouteNames.consumerHome);
                        },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF0EA5E9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Verify OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                if (authState.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(authState.errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
