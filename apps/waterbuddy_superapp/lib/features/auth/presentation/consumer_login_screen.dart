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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back),
                      color: const Color(0xFF08111F),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1),

                  const SizedBox(height: 40),

                  // Header
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      color: Color(0xFF08111F),
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.08),

                  const SizedBox(height: 8),

                  const Text(
                    'Enter your mobile number to receive a verification code',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.08),

                  const SizedBox(height: 32),

                  // Phone input form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WbPremiumTextField(
                          controller: _phone,
                          label: 'Phone Number',
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          accentColor: WbColors.blue,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter your phone number';
                            }
                            if (v.trim().length < 10) {
                              return 'Enter a valid 10-digit number';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.08),
                        const SizedBox(height: 24),
                        LoadingFeedbackButton(
                          onPressed: _btnState == LoadingButtonState.idle
                              ? _sendOtp
                              : null,
                          label: 'Send OTP',
                          loadingLabel: 'Sending OTP...',
                          successLabel: 'OTP Sent!',
                          buttonState: _btnState,
                          backgroundColor: const Color(0xFF0EA5E9),
                          borderRadius: 18,
                        ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.08),
                        if (authState.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: Color(0xFFEF4444), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    authState.errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn().shake(),
                        ],
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Divider
                  const Row(
                    children: [
                      Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                    ],
                  ).animate().fadeIn(delay: 550.ms),

                  const SizedBox(height: 20),

                  // Google sign in
                  _GoogleButton(
                    loading: authState.isLoading,
                    onTap: _googleSignIn,
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.08),

                  const SizedBox(height: 24),

                  // Signup link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            context.push(RouteNames.authConsumerSignup),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Color(0xFF0EA5E9),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 700.ms),
                ],
              ),
            ),
          ),
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
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF08111F).withValues(alpha: 0.06),
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
                height: 22,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.g_mobiledata_rounded,
                    color: Colors.blue,
                    size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Continue with Google',
                style: TextStyle(
                  color: Color(0xFF08111F),
                  fontSize: 15,
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
