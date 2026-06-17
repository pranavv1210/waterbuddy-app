import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_role.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/waterbuddy_auth_layout.dart';

class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpNodes = List.generate(6, (_) => FocusNode());

  int _step = 0;
  int _seconds = 30;
  bool _loading = false;
  String? _error;
  Timer? _timer;

  AppRole get _role {
    final role = GoRouterState.of(context).uri.queryParameters['role'];
    return switch (role) {
      'seller' => AppRole.seller,
      'driver' => AppRole.driver,
      'admin' => AppRole.admin,
      _ => AppRole.consumer,
    };
  }

  String get _loginRoute {
    return switch (_role) {
      AppRole.seller => RouteNames.authSellerLogin,
      AppRole.driver => RouteNames.authDriverLogin,
      AppRole.admin => RouteNames.authAdmin,
      AppRole.consumer => RouteNames.authConsumerLogin,
    };
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_seconds <= 1) {
        timer.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds--);
      }
    });
  }

  void _sendOtp() {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      setState(() => _error = 'Enter a valid mobile number.');
      return;
    }
    setState(() {
      _error = null;
      _step = 1;
    });
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _otpNodes.first.requestFocus();
    });
  }

  void _verifyOtp() {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp != AuthService.devOtpCode) {
      setState(() => _error = 'Invalid OTP. Enter 123456 for testing.');
      return;
    }
    setState(() {
      _error = null;
      _step = 2;
    });
  }

  Future<void> _savePassword() async {
    final password = _password.text.trim();
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (password != _confirmPassword.text.trim()) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).resetDevelopmentOtpPassword(
            phoneNumber: _phone.text.trim(),
            otpCode: AuthService.devOtpCode,
            newPassword: password,
          );
      if (!mounted) return;
      setState(() => _step = 3);
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Unable to reset password right now.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WaterBuddyAuthLayout(
      activeRole: _role,
      title: 'Reset Password',
      subtitle: _subtitle,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: Padding(
          key: ValueKey(_step),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _stepBody(context),
        ),
      ),
    );
  }

  String get _subtitle {
    return switch (_step) {
      0 => 'Enter your registered mobile number',
      1 => 'Verify OTP sent to ${_phone.text.trim()}',
      2 => 'Create a new secure password',
      _ => 'Password updated successfully',
    };
  }

  Widget _stepBody(BuildContext context) {
    final title = switch (_step) {
      0 => 'Find your account',
      1 => 'OTP Verification',
      2 => 'New password',
      _ => 'Password reset done',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
              onPressed: () {
                if (_step == 0 || _step == 3) {
                  context.go(_loginRoute);
                } else {
                  setState(() => _step--);
                }
              },
            ),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_step == 0) _phoneStep(),
        if (_step == 1) _otpStep(),
        if (_step == 2) _passwordStep(),
        if (_step == 3) _successStep(),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  Widget _phoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(
          controller: _phone,
          label: 'Registered mobile number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 24),
        _primaryButton(label: 'Send OTP', onPressed: _sendOtp),
      ],
    );
  }

  Widget _otpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF7FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCEFFF)),
          ),
          child: const Text(
            'Development OTP: 123456',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF0095F6),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 40,
              height: 52,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Color(0xFF0095F6), width: 2),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    _otpNodes[index + 1].requestFocus();
                  }
                  if (value.isEmpty && index > 0) {
                    _otpNodes[index - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            TextButton(
              onPressed: () => setState(() => _step = 0),
              child: const Text('Edit mobile',
                  style: TextStyle(color: Color(0xFF0095F6))),
            ),
            const Spacer(),
            TextButton(
              onPressed: _seconds == 0 ? _startTimer : null,
              child: Text(
                _seconds == 0 ? 'Resend OTP' : 'Resend in ${_seconds}s',
                style: TextStyle(
                  color: _seconds == 0
                      ? const Color(0xFF0095F6)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _primaryButton(label: 'Verify OTP', onPressed: _verifyOtp),
      ],
    );
  }

  Widget _passwordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(
          controller: _password,
          label: 'New password',
          icon: Icons.lock_outline,
          obscure: true,
        ),
        const SizedBox(height: 12),
        _field(
          controller: _confirmPassword,
          label: 'Confirm password',
          icon: Icons.verified_user_outlined,
          obscure: true,
        ),
        const SizedBox(height: 24),
        _primaryButton(
          label: _loading ? 'Saving...' : 'Save New Password',
          onPressed: _loading ? null : _savePassword,
        ),
      ],
    );
  }

  Widget _successStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded,
              color: Color(0xFF22C55E), size: 58),
        ),
        const SizedBox(height: 20),
        const Text(
          'Use your new password the next time this account asks for one.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 26),
        _primaryButton(
          label: 'Back to Login',
          onPressed: () => context.go(_loginRoute),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(
          color: Color(0xFF111827), fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
        prefixIcon: Icon(icon, color: const Color(0xFF6B7280)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF0095F6), width: 2),
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF0095F6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ),
    );
  }
}
