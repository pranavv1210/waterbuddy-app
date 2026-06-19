import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_role.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/loading_feedback_button.dart';
import '../../../widgets/premium_ui.dart';
import '../../../widgets/waterbuddy_auth_layout.dart';
import '../../../widgets/waterbuddy_toast.dart';

class ConsumerOtpScreen extends ConsumerStatefulWidget {
  const ConsumerOtpScreen({super.key});

  @override
  ConsumerState<ConsumerOtpScreen> createState() => _ConsumerOtpScreenState();
}

class _ConsumerOtpScreenState extends ConsumerState<ConsumerOtpScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _countdown = 30;
  LoadingButtonState _btnState = LoadingButtonState.idle;

  late final AnimationController _successController;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _startTimer();
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

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    _successController.dispose();
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  void _onBoxChanged(int index, String value, String phoneNumber,
      String fullName, String email) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _submitOtp(phoneNumber, fullName, email);
      }
    } else if (index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _submitOtp(
      String phoneNumber, String fullName, String email) async {
    final code = _otpCode;
    if (code.length < 6) {
      WaterBuddyToastService.warning(
          context, 'Enter the complete 6-digit OTP.');
      return;
    }
    if (_btnState != LoadingButtonState.idle) return;

    setState(() => _btnState = LoadingButtonState.loading);
    try {
      final ok = await ref.read(authControllerProvider.notifier).verifyOtp(
            code,
            role: AppRole.consumer,
            fullName: fullName,
            email: email,
            phoneNumber: phoneNumber,
          );
      if (!mounted) return;
      if (ok) {
        setState(() => _btnState = LoadingButtonState.success);
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) context.go(RouteNames.consumerHome);
      } else {
        setState(() => _btnState = LoadingButtonState.idle);
        WaterBuddyToastService.error(context, 'Invalid OTP. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _btnState = LoadingButtonState.idle);
        WaterBuddyToastService.error(context, 'Verification failed: $e');
      }
    }
  }

  void _resendOtp(String phoneNumber) {
    if (_countdown > 0) return;
    HapticFeedback.selectionClick();
    ref
        .read(authControllerProvider.notifier)
        .sendOtp(phoneNumber, role: AppRole.consumer);
    _startTimer();
    WaterBuddyToastService.success(context, 'OTP resent successfully');
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
        title: 'Verify Phone Number',
        subtitle: phoneNumber.isNotEmpty
            ? 'OTP sent to +91 $phoneNumber'
            : 'Enter the 6-digit OTP',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Phone display + edit
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back),
                      color: WbColors.blue,
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go(RouteNames.authConsumer),
                    ),
                    Text(
                      phoneNumber.isNotEmpty ? '+91 $phoneNumber' : 'Back',
                      style: const TextStyle(
                        color: WbColors.blue,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => context.canPop()
                      ? context.pop()
                      : context.go(RouteNames.authConsumer),
                  child: const Row(
                    children: [
                      Icon(Icons.edit_rounded, color: WbColors.muted, size: 15),
                      SizedBox(width: 4),
                      Text(
                        'Change',
                        style: TextStyle(
                          color: WbColors.muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 60.ms),
            const SizedBox(height: 24),

            // OTP boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return _OtpBox(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  onChanged: (val) =>
                      _onBoxChanged(index, val, phoneNumber, fullName, email),
                );
              }),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

            const SizedBox(height: 28),

            // Verify button
            LoadingFeedbackButton(
              onPressed: _btnState == LoadingButtonState.idle
                  ? () => _submitOtp(phoneNumber, fullName, email)
                  : null,
              label: 'Verify & Continue',
              loadingLabel: 'Verifying...',
              successLabel: 'Verified!',
              buttonState: _btnState,
              backgroundColor: WbColors.ink,
            ).animate().fadeIn(delay: 160.ms).slideY(begin: 0.1),

            const SizedBox(height: 20),

            // Resend row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Didn't receive code? ",
                  style: TextStyle(
                      color: WbColors.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
                GestureDetector(
                  onTap: _countdown == 0 && !authState.isLoading
                      ? () => _resendOtp(phoneNumber)
                      : null,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: _countdown > 0 ? WbColors.muted : WbColors.blue,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                    child: Text(
                      _countdown > 0
                          ? 'Resend in ${_countdown}s'
                          : 'Resend OTP',
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 220.ms),

            if (authState.errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: WbColors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: WbColors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        authState.errorMessage!,
                        style: const TextStyle(
                            color: WbColors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().shake(),
            ],
          ],
        ),
      ),
    );
  }
}

class _OtpBox extends StatefulWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: 48,
      height: 60,
      decoration: BoxDecoration(
        color: _focused ? const Color(0xFFEEF7FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focused ? WbColors.blue : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Center(
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            color: WbColors.ink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: 1.3,
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}
