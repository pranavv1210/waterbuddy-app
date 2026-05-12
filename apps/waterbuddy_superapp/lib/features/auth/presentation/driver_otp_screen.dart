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
    return Scaffold(
      appBar: AppBar(title: const Text('Driver OTP Verification')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Align(alignment: Alignment.centerLeft, child: Text('Development OTP: 123456')),
            TextField(controller: _otp, decoration: const InputDecoration(labelText: 'OTP')),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() {
                        _loading = true;
                        _error = null;
                      });
                      try {
                        final auth = ref.read(authServiceProvider);
                        await auth.signInWithDevelopmentOtp(
                          phoneNumber: (extra['phoneNumber'] as String?) ?? '',
                          otpCode: _otp.text.trim(),
                        );
                        await auth.upsertDriverProfile(
                          fullName: (extra['fullName'] as String?) ?? '',
                          phoneNumber: (extra['phoneNumber'] as String?) ?? '',
                          email: (extra['email'] as String?) ?? '',
                          licenseNumber: (extra['licenseNumber'] as String?) ?? '',
                          aadhaarNumber: (extra['aadhaarNumber'] as String?) ?? '',
                          driverPhotoUrl: (extra['driverPhotoUrl'] as String?) ?? '',
                          licenseUploadUrl: (extra['licenseUploadUrl'] as String?) ?? '',
                          aadhaarUploadUrl: (extra['aadhaarUploadUrl'] as String?) ?? '',
                          address: (extra['address'] as String?) ?? '',
                          emergencyContact: (extra['emergencyContact'] as String?) ?? '',
                        );
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
              child: Text(_loading ? 'Verifying...' : 'Verify OTP'),
            ),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
