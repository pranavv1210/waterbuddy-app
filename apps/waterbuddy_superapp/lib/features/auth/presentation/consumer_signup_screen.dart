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

class ConsumerSignupScreen extends ConsumerStatefulWidget {
  const ConsumerSignupScreen({super.key});

  @override
  ConsumerState<ConsumerSignupScreen> createState() =>
      _ConsumerSignupScreenState();
}

class _ConsumerSignupScreenState extends ConsumerState<ConsumerSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  LoadingButtonState _btnState = LoadingButtonState.idle;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
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
          extra: {
            'fullName': _name.text.trim(),
            'email': _email.text.trim(),
            'phone': _phone.text.trim(),
          },
        );
        setState(() => _btnState = LoadingButtonState.idle);
      } else {
        setState(() => _btnState = LoadingButtonState.idle);
        if (mounted) {
          WaterBuddyToastService.error(context, 'Failed to send OTP.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _btnState = LoadingButtonState.idle);
        WaterBuddyToastService.error(context, 'Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (_, next) {
      if (next.isVerified && mounted) context.go(RouteNames.consumerHome);
    });

    return WaterBuddyAuthLayout(
      activeRole: AppRole.consumer,
      title: 'Create Account',
      subtitle: 'Get water delivered to your doorstep',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WbPremiumTextField(
              controller: _name,
              label: 'Full Name',
              icon: Icons.person_rounded,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
            ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.1),
            const SizedBox(height: 14),
            WbPremiumTextField(
              controller: _email,
              label: 'Email Address (optional)',
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ).animate().fadeIn(delay: 140.ms).slideY(begin: 0.1),
            const SizedBox(height: 14),
            WbPremiumTextField(
              controller: _phone,
              label: 'Mobile Number',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter phone number';
                if (v.trim().length < 10) return 'Enter valid 10-digit number';
                return null;
              },
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            const SizedBox(height: 22),
            LoadingFeedbackButton(
              onPressed: _btnState == LoadingButtonState.idle ? _sendOtp : null,
              label: 'Sign Up',
              loadingLabel: 'Sending OTP...',
              successLabel: 'OTP Sent!',
              buttonState: _btnState,
              backgroundColor: WbColors.ink,
            ).animate().fadeIn(delay: 260.ms).slideY(begin: 0.1),
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
                        fontWeight: FontWeight.w800),
                  ),
                ),
                const Expanded(child: Divider(color: WbColors.line)),
              ],
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 16),
            _GoogleSignupButton(
              loading: authState.isLoading,
              onTap: () async {
                setState(() => _btnState = LoadingButtonState.loading);
                try {
                  await ref
                      .read(authControllerProvider.notifier)
                      .signInWithGoogle(role: AppRole.consumer);
                } finally {
                  if (mounted) {
                    setState(() => _btnState = LoadingButtonState.idle);
                  }
                }
              },
            ).animate().fadeIn(delay: 340.ms),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account? ',
                  style: TextStyle(
                      color: WbColors.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Text(
                    'Log In',
                    style: TextStyle(
                      color: WbColors.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 380.ms),
            if (authState.errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: WbColors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  authState.errorMessage!,
                  style: const TextStyle(
                      color: WbColors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ).animate().fadeIn().shake(),
            ],
          ],
        ),
      ),
    );
  }
}

class _GoogleSignupButton extends StatefulWidget {
  const _GoogleSignupButton({required this.loading, required this.onTap});
  final bool loading;
  final VoidCallback onTap;

  @override
  State<_GoogleSignupButton> createState() => _GoogleSignupButtonState();
}

class _GoogleSignupButtonState extends State<_GoogleSignupButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.loading
          ? null
          : () {
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
            borderRadius:
                BorderRadius.circular(WaterBuddyDesignSystem.radiusPill),
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
