import 'dart:ui';
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
    final phoneNumber = (extra['phone'] as String?) ?? '';
    
    ref.listen(authControllerProvider, (_, next) {
      if (next.isVerified && mounted) {
        context.go(RouteNames.consumerHome);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          Positioned(
            top: -100, left: -100,
            child: Container(width: 300, height: 300, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0EA5E9))),
          ),
          Positioned(
            bottom: -50, right: -100,
            child: Container(width: 250, height: 250, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF38BDF8))),
          ),
          Positioned.fill(
            child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => context.pop()),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Verify OTP',
                              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter the 6-digit code sent to\n$phoneNumber',
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0EA5E9).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF0EA5E9).withOpacity(0.3)),
                              ),
                              child: const Text('Development OTP: 123456', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
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
                                fillColor: Colors.white.withOpacity(0.03),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF38BDF8))),
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

