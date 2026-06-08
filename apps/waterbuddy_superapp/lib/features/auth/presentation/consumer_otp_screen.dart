import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_role.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/waterbuddy_auth_layout.dart';

class ConsumerOtpScreen extends ConsumerStatefulWidget {
  const ConsumerOtpScreen({super.key});

  @override
  ConsumerState<ConsumerOtpScreen> createState() => _ConsumerOtpScreenState();
}

class _ConsumerOtpScreenState extends ConsumerState<ConsumerOtpScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  Timer? _timer;
  int _countdown = 30;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450))
      ..forward();
    _fadeAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _startTimer();

    // Populate mock OTP 123456 by default for easier development
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mock = '123456';
      for (int i = 0; i < mock.length; i++) {
        _controllers[i].text = mock[i];
      }
      _focusNodes[5].requestFocus();
    });
  }

  void _startTimer() {
    setState(() => _countdown = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _resendOtp() {
    if (_countdown > 0) return;
    final extra =
        GoRouterState.of(context).extra as Map<String, dynamic>? ?? const {};
    final phoneNumber = (extra['phone'] as String?) ?? '';
    ref
        .read(authControllerProvider.notifier)
        .sendOtp(phoneNumber, role: AppRole.consumer);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    _animController.dispose();
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _submitOtp(String phoneNumber, String fullName, String email) async {
    final code = _otpCode;
    if (code.length < 6) return;

    final ok = await ref
        .read(authControllerProvider.notifier)
        .verifyOtp(
          code,
          role: AppRole.consumer,
          fullName: fullName,
          email: email,
          phoneNumber: phoneNumber,
        );
    if (!mounted) return;
    if (ok) {
      if (phoneNumber == '9876543210') {
        unawaited(ref
            .read(authServiceProvider)
            .seedTemporaryRoleData(role: AppRole.consumer)
            .catchError((_) {}));
      }
      context.go(RouteNames.consumerHome);
    }
  }

  void _onOtpBoxChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        final extra =
            GoRouterState.of(context).extra as Map<String, dynamic>? ?? const {};
        final phoneNumber = (extra['phone'] as String?) ?? '';
        final fullName = (extra['fullName'] as String?) ?? '';
        final email = (extra['email'] as String?) ?? '';
        _submitOtp(phoneNumber, fullName, email);
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final extra =
        GoRouterState.of(context).extra as Map<String, dynamic>? ?? const {};
    final phoneNumber = (extra['phone'] as String?) ?? '';
    final fullName = (extra['fullName'] as String?) ?? '';
    final email = (extra['email'] as String?) ?? '';

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
      child: WaterBuddyAuthLayout(
        activeRole: AppRole.consumer,
        title: 'Verify OTP',
        subtitle: 'Enter the 6-digit code sent to $phoneNumber',
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFF0F172A), size: 18),
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go(RouteNames.authConsumer),
                    ),
                    const Text('OTP Verification',
                        style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(RouteNames.authConsumer);
                    }
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_rounded, size: 14, color: Color(0xFF007AFF)),
                      SizedBox(width: 4),
                      Text(
                        'Change phone number',
                        style: TextStyle(
                          color: Color(0xFF007AFF),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF7FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDCEFFF)),
                  ),
                  child: const Text(
                    'Development OTP: 123456',
                    style: TextStyle(
                        color: Color(0xFF007AFF),
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 40,
                      height: 52,
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9), // Slate 100
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
                          ),
                        ),
                        onChanged: (val) => _onOtpBoxChanged(index, val),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: authState.isLoading
                      ? null
                      : () => _submitOtp(phoneNumber, fullName, email),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Verify OTP',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Didn\'t receive code? ',
                      style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14),
                    ),
                    TextButton(
                      onPressed: _countdown == 0 && !authState.isLoading
                          ? _resendOtp
                          : null,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF007AFF),
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _countdown > 0
                            ? 'Resend in ${_countdown}s'
                            : 'Resend OTP',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _countdown > 0
                              ? const Color(0xFF94A3B8) // Slate 400
                              : const Color(0xFF007AFF),
                        ),
                      ),
                    ),
                  ],
                ),
                if (authState.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(authState.errorMessage!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 13),
                      textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
