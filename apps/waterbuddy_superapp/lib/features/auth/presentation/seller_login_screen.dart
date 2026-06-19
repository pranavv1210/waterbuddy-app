import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_role.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/loading_feedback_button.dart';
import '../../../widgets/premium_ui.dart';
import '../../../widgets/waterbuddy_toast.dart';

class SellerLoginScreen extends ConsumerStatefulWidget {
  const SellerLoginScreen({super.key});

  @override
  ConsumerState<SellerLoginScreen> createState() => _SellerLoginScreenState();
}

class _SellerLoginScreenState extends ConsumerState<SellerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  LoadingButtonState _btnState = LoadingButtonState.idle;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

                  const SizedBox(height: 36),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.local_shipping_rounded,
                            color: Color(0xFF14B8A6), size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tanker Owner Login',
                            style: TextStyle(
                              color: Color(0xFF08111F),
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Enter your credentials to continue',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.08),

                  const SizedBox(height: 36),

                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WbPremiumTextField(
                          controller: _email,
                          label: 'Email Address',
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          accentColor: const Color(0xFF14B8A6),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter email'
                              : null,
                        ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.08),
                        const SizedBox(height: 16),
                        WbPremiumTextField(
                          controller: _password,
                          label: 'Password',
                          icon: Icons.lock_rounded,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          accentColor: const Color(0xFF14B8A6),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter password'
                              : null,
                        ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.08),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push(
                                '${RouteNames.passwordReset}?role=seller'),
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: Color(0xFF14B8A6),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ).animate().fadeIn(delay: 400.ms),
                        ),
                        const SizedBox(height: 12),
                        LoadingFeedbackButton(
                          onPressed: _btnState == LoadingButtonState.idle
                              ? _submit
                              : null,
                          label: 'Log In',
                          loadingLabel: 'Signing in...',
                          successLabel: 'Welcome back!',
                          buttonState: _btnState,
                          backgroundColor: const Color(0xFF14B8A6),
                          borderRadius: 18,
                        ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.08),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _btnState = LoadingButtonState.loading);

    try {
      final auth = ref.read(authServiceProvider);
      final email = _email.text.trim();
      final password = _password.text.trim();
      await auth.signInWithEmailPassword(email: email, password: password);
      unawaited(auth
          .upsertUserProfile(
            role: AppRole.seller,
            email: email,
            authProvider: 'email_password',
            isVerified: true,
          )
          .catchError((_) {}));

      if (!mounted) return;
      setState(() => _btnState = LoadingButtonState.success);
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) context.go(RouteNames.sellerDashboard);
    } on AuthFailure catch (e) {
      if (mounted) {
        setState(() => _btnState = LoadingButtonState.idle);
        WaterBuddyToastService.error(context, e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _btnState = LoadingButtonState.idle);
        WaterBuddyToastService.error(context, 'Unable to complete action.');
      }
    }
  }
}
