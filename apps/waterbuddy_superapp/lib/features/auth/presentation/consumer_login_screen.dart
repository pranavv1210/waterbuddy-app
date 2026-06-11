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

class ConsumerLoginScreen extends ConsumerStatefulWidget {
  const ConsumerLoginScreen({super.key});

  @override
  ConsumerState<ConsumerLoginScreen> createState() =>
      _ConsumerLoginScreenState();
}

class _ConsumerLoginScreenState extends ConsumerState<ConsumerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController(text: '9876543210');
  LoadingButtonState _btnState = LoadingButtonState.idle;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_btnState != LoadingButtonState.idle) return;

    setState(() => _btnState = LoadingButtonState.loading);
    try {
      final ok = await ref
          .read(authControllerProvider.notifier)
          .sendOtp(_phone.text.trim(), role: AppRole.consumer);

      if (!mounted) return;
      if (ok) {
        setState(() => _btnState = LoadingButtonState.success);
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        context.push(
          RouteNames.authConsumerOtp,
          extra: {'phone': _phone.text.trim()},
        );
        setState(() => _btnState = LoadingButtonState.idle);
      } else {
        setState(() => _btnState = LoadingButtonState.idle);
        if (mounted) {
          WaterBuddyToastService.error(
              context, 'Could not send OTP. Try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _btnState = LoadingButtonState.idle);
        WaterBuddyToastService.error(context, 'Error: $e');
      }
    }
  }

  Future<void> _googleSignIn() async {
    final phone = _phone.text.trim();
    if (phone.isEmpty) {
      WaterBuddyToastService.warning(context, 'Enter your phone number first.');
      return;
    }
    setState(() => _btnState = LoadingButtonState.loading);
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle(
            role: AppRole.consumer,
            phoneNumber: phone,
          );
    } finally {
      if (mounted) setState(() => _btnState = LoadingButtonState.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (_, next) {
      if (next.isVerified && mounted) {
        context.go(RouteNames.consumerHome);
      }
    });

    return WaterBuddyAuthLayout(
      activeRole: AppRole.consumer,
      title: 'Water Delivered To Your Doorstep',
      subtitle: '',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WbPremiumTextField(
              controller: _phone,
              label: 'Mobile Number',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              accentColor: WbColors.blue,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter phone number';
                if (v.trim().length < 10) return 'Enter valid 10-digit number';
                return null;
              },
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.08),
            const SizedBox(height: 20),
            LoadingFeedbackButton(
              onPressed: _btnState == LoadingButtonState.idle ? _sendOtp : null,
              label: 'Continue',
              loadingLabel: 'Sending OTP...',
              successLabel: 'OTP Sent!',
              buttonState: _btnState,
              backgroundColor: WbColors.ink,
            ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.08),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(child: Divider(color: WbColors.line)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: WbColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: WbColors.line)),
              ],
            ).animate().fadeIn(delay: 240.ms),
            const SizedBox(height: 18),
            _GoogleButton(
              loading: authState.isLoading,
              onTap: _googleSignIn,
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.08),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(
                      color: WbColors.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
                GestureDetector(
                  onTap: () => context.push(RouteNames.authConsumerSignup),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: WbColors.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 360.ms),
            if (authState.errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: WbColors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: WbColors.red.withOpacity(0.18)),
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

class _GoogleButton extends StatefulWidget {
  const _GoogleButton({required this.loading, required this.onTap});
  final bool loading;
  final VoidCallback onTap;

  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.loading ? null : () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(WaterBuddyDesignSystem.radiusPill),
            border: Border.all(color: WbColors.line, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: WbColors.ink.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                height: 20,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.g_mobiledata_rounded,
                    color: Colors.blue,
                    size: 22),
              ),
              const SizedBox(width: 10),
              const Text(
                'Continue with Google',
                style: TextStyle(
                  color: WbColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
