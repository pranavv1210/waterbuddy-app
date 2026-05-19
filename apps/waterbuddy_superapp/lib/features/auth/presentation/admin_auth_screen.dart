import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_role.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';

class AdminAuthScreen extends ConsumerStatefulWidget {
  const AdminAuthScreen({super.key});

  @override
  ConsumerState<AdminAuthScreen> createState() => _AdminAuthScreenState();
}

class _AdminAuthScreenState extends ConsumerState<AdminAuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
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
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          Positioned(
            top: -100, left: -100,
            child: Container(width: 300, height: 300, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0F766E))),
          ),
          Positioned(
            bottom: -50, right: -100,
            child: Container(width: 250, height: 250, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF14B8A6))),
          ),
          Positioned.fill(
            child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => context.go(RouteNames.roleSelection)),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF14B8A6), size: 64),
                            const SizedBox(height: 16),
                            const Text(
                              'Admin Portal',
                              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Secure access for administrators',
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            
                            _buildTextField(controller: _email, label: 'Admin Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 16),
                            _buildTextField(controller: _password, label: 'Password', icon: Icons.lock_outline, obscure: true),
                            
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: _loading ? null : _loginWithEmail,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: const Color(0xFF0F766E),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: _loading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Access Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('OR', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                                ),
                                Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                              ],
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton.icon(
                              onPressed: _loading
                                  ? null
                                  : () async {
                                      setState(() { _loading = true; _error = null; });
                                      try {
                                        final ok = await ref.read(authControllerProvider.notifier).signInWithGoogle(role: AppRole.admin);
                                        if (ok && mounted) context.go(RouteNames.adminDashboard);
                                      } finally {
                                        if (mounted) setState(() => _loading = false);
                                      }
                                    },
                              icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg', height: 20),
                              label: const Text('Admin Login with Google', style: TextStyle(color: Colors.white, fontSize: 15)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: Colors.white.withOpacity(0.1)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.4)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF14B8A6))),
      ),
    );
  }

  Future<void> _loginWithEmail() async {
    setState(() { _loading = true; _error = null; });
    try {
      final auth = ref.read(authServiceProvider);
      final emailInput = _email.text.trim();
      final passwordInput = _password.text.trim();
      
      UserCredential credential;
      try {
        credential = await auth.signInWithEmailPassword(email: emailInput, password: passwordInput);
      } catch (e) {
        if (emailInput.toLowerCase() == 'waterbuddyapp.wb@gmail.com' || emailInput.toLowerCase() == 'admin@waterbuddy.com') {
          credential = await auth.signUpWithEmailPassword(email: emailInput, password: passwordInput);
        } else {
          rethrow;
        }
      }
      final user = credential.user;
      if (user == null || !await auth.isAuthorizedAdmin(user)) {
        await auth.signOut();
        throw const AuthFailure('Unauthorized access');
      }
      await auth.upsertUserProfile(
        role: AppRole.admin,
        fullName: user.displayName ?? 'Admin',
        email: user.email ?? _email.text.trim(),
        phoneNumber: user.phoneNumber,
        authProvider: 'email_password',
        isVerified: true,
      );
      if (!mounted) return;
      context.go(RouteNames.adminDashboard);
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Admin login failed.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

