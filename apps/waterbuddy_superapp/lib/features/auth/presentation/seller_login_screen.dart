import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_role.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/waterbuddy_auth_layout.dart';

class SellerLoginScreen extends ConsumerStatefulWidget {
  const SellerLoginScreen({super.key});

  @override
  ConsumerState<SellerLoginScreen> createState() => _SellerLoginScreenState();
}

class _SellerLoginScreenState extends ConsumerState<SellerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(text: AuthService.testSellerEmail);
  final _password = TextEditingController(text: AuthService.testSellerPassword);

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WaterBuddyAuthLayout(
      activeRole: AppRole.seller,
      title: 'Tanker Owner Login',
      subtitle: 'Enter your credentials to login',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF111827), size: 18),
                  onPressed: () => context.pop(),
                ),
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _field(_email, 'Email Address', Icons.email_outlined,
                keyboardType: TextInputType.emailAddress),
            _field(_password, 'Password', Icons.lock_outline, obscure: true),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _loading ? null : _forgotPassword,
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: Color(0xFF0095F6),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF0095F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Log In',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!,
                  style:
                      const TextStyle(color: Colors.redAccent, fontSize: 13),
                  textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
    bool requiredField = true,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600),
        validator: requiredField
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF374151)),
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
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      final email = _email.text.trim();
      final password = _password.text.trim();
      if (email == AuthService.testSellerEmail &&
          password == AuthService.testSellerPassword) {
        await auth.signInOrCreateTestSeller();
        if (!mounted) return;
        context.go(RouteNames.sellerDashboard);
        return;
      }

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
      context.go(RouteNames.sellerDashboard);
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Unable to complete action.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    context.push('${RouteNames.passwordReset}?role=seller');
  }
}
