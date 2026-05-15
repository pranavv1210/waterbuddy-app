import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/auth/auth_service.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';

class DriverOtpScreen extends ConsumerStatefulWidget {
  const DriverOtpScreen({super.key});

  @override
  ConsumerState<DriverOtpScreen> createState() => _DriverOtpScreenState();
}

class _DriverOtpScreenState extends ConsumerState<DriverOtpScreen> {
  final _otp = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>? ?? const {};
    final isSignUp = extra['isSignUp'] as bool? ?? true;
    final phoneNumber = (extra['phoneNumber'] as String?) ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          Positioned(
            top: -100, left: -100,
            child: Container(width: 300, height: 300, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF8B5CF6))),
          ),
          Positioned(
            bottom: -50, right: -100,
            child: Container(width: 250, height: 250, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF6D28D9))),
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
                                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                              ),
                              child: const Text('Development OTP: 123456', style: TextStyle(color: Color(0xFFA78BFA), fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
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
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFA78BFA))),
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: _loading
                                  ? null
                                  : () async {
                                      setState(() { _loading = true; _error = null; });
                                      try {
                                        final auth = ref.read(authServiceProvider);
                                        await auth.signInWithDevelopmentOtp(
                                          phoneNumber: phoneNumber,
                                          otpCode: _otp.text.trim(),
                                        );
                                        if (isSignUp) {
                                          await auth.upsertDriverProfile(
                                            fullName: (extra['fullName'] as String?) ?? '',
                                            phoneNumber: phoneNumber,
                                            email: (extra['email'] as String?) ?? '',
                                            licenseNumber: (extra['licenseNumber'] as String?) ?? '',
                                            aadhaarNumber: (extra['aadhaarNumber'] as String?) ?? '',
                                            panNumber: (extra['panNumber'] as String?) ?? '',
                                            driverPhotoUrl: (extra['driverPhotoUrl'] as String?) ?? '',
                                            licenseUploadUrl: (extra['licenseUploadUrl'] as String?) ?? '',
                                            aadhaarUploadUrl: (extra['aadhaarUploadUrl'] as String?) ?? '',
                                            panUploadUrl: (extra['panUploadUrl'] as String?) ?? '',
                                            address: (extra['address'] as String?) ?? '',
                                            emergencyContact: (extra['emergencyContact'] as String?) ?? '',
                                          );
                                        }
                                        if (!mounted) return;
                                        context.go(RouteNames.driverDashboard);
                                      } on AuthFailure catch (e) {
                                        setState(() => _error = e.message);
                                      } catch (_) {
                                        setState(() => _error = 'Unable to verify driver OTP.');
                                      } finally {
                                        if (mounted) setState(() => _loading = false);
                                      }
                                    },
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: const Color(0xFF8B5CF6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: _loading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Verify OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center),
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
