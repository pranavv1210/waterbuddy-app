import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/auth/app_role.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/loading_feedback_button.dart';
import '../../../widgets/premium_ui.dart';
import '../../../widgets/waterbuddy_auth_layout.dart';
import '../../../widgets/waterbuddy_toast.dart';

class AdminAuthScreen extends ConsumerStatefulWidget {
  const AdminAuthScreen({super.key});

  @override
  ConsumerState<AdminAuthScreen> createState() => _AdminAuthScreenState();
}

class _AdminAuthScreenState extends ConsumerState<AdminAuthScreen> {
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go(RouteNames.roleSelection);
      },
      child: WaterBuddyAuthLayout(
        activeRole: AppRole.admin,
        title: 'Admin Login',
        subtitle: 'Secure administrative access',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Security badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D4ED8).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF1D4ED8).withOpacity(0.18)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_rounded,
                        color: Color(0xFF1D4ED8), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Authorized personnel only',
                      style: TextStyle(
                        color: Color(0xFF1D4ED8),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 60.ms),
              const SizedBox(height: 20),
              WbPremiumTextField(
                controller: _email,
                label: 'Admin Email',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                accentColor: const Color(0xFF1D4ED8),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter email' : null,
              ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.1),
              const SizedBox(height: 14),
              WbPremiumTextField(
                controller: _password,
                label: 'Password',
                icon: Icons.lock_rounded,
                obscureText: true,
                textInputAction: TextInputAction.done,
                accentColor: const Color(0xFF1D4ED8),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter password' : null,
              ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.1),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      context.push('${RouteNames.passwordReset}?role=admin'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1D4ED8),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Forgot password?',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ).animate().fadeIn(delay: 220.ms),
              const SizedBox(height: 8),
              LoadingFeedbackButton(
                onPressed: _btnState == LoadingButtonState.idle
                    ? _loginWithEmail
                    : null,
                label: 'Access Dashboard',
                loadingLabel: 'Authenticating...',
                successLabel: 'Access Granted!',
                buttonState: _btnState,
                backgroundColor: const Color(0xFF1D4ED8),
              ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.1),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _btnState = LoadingButtonState.loading);

    try {
      final auth = ref.read(authServiceProvider);
      final emailInput = _email.text.trim();
      final passwordInput = _password.text.trim();

      UserCredential credential;
      try {
        credential = await auth.signInWithEmailPassword(
            email: emailInput, password: passwordInput);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' &&
            (emailInput.toLowerCase() == 'waterbuddyapp.wb@gmail.com' ||
                emailInput.toLowerCase() == 'admin@waterbuddy.com')) {
          credential = await auth.signUpWithEmailPassword(
              email: emailInput, password: passwordInput);
        } else {
          rethrow;
        }
      }

      final user = credential.user;
      if (user == null || !await auth.isAuthorizedAdmin(user)) {
        await auth.signOut();
        throw const AuthFailure('Unauthorized access');
      }

      unawaited(auth
          .upsertUserProfile(
            role: AppRole.admin,
            fullName: user.displayName ?? 'Admin',
            email: user.email ?? _email.text.trim(),
            phoneNumber: user.phoneNumber,
            authProvider: 'email_password',
            isVerified: true,
          )
          .catchError((_) {}));

      setState(() => _btnState = LoadingButtonState.success);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) context.go(RouteNames.adminDashboard);
    } on AuthFailure catch (e) {
      setState(() => _btnState = LoadingButtonState.idle);
      if (mounted) WaterBuddyToastService.error(context, e.message);
    } catch (e) {
      setState(() => _btnState = LoadingButtonState.idle);
      if (mounted) WaterBuddyToastService.error(context, 'Login failed: $e');
    }
  }
}
