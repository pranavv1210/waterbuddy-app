import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_role.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';

class ConsumerAuthScreen extends ConsumerStatefulWidget {
  const ConsumerAuthScreen({super.key});

  @override
  ConsumerState<ConsumerAuthScreen> createState() => _ConsumerAuthScreenState();
}

class _ConsumerAuthScreenState extends ConsumerState<ConsumerAuthScreen> with SingleTickerProviderStateMixin {
  bool _isSignUp = true;
  
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() => _isSignUp = !_isSignUp);
    _animController.reset();
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (_, next) {
      if (next.isVerified && mounted) {
        context.go(RouteNames.consumerHome);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          // Background Gradient Orbs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0EA5E9),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF38BDF8),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
          // Form Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isSignUp ? 'Create Account' : 'Welcome Back',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isSignUp ? 'Sign up to get started as a Consumer' : 'Log in to continue as a Consumer',
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        if (_isSignUp) ...[
                          _buildTextField(controller: _name, label: 'Full Name', icon: Icons.person_outline),
                          const SizedBox(height: 16),
                          _buildTextField(controller: _email, label: 'Email ID', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 16),
                        ],
                        _buildTextField(controller: _phone, label: 'Mobile Number', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: authState.isLoading
                              ? null
                              : () async {
                                  if (_phone.text.trim().isEmpty) return;
                                  final ok = await ref.read(authControllerProvider.notifier).sendOtp(
                                        _phone.text.trim(),
                                        role: AppRole.consumer,
                                      );
                                  if (ok && mounted) {
                                    context.push(
                                      RouteNames.authConsumerOtp,
                                      extra: {
                                        'fullName': _name.text.trim(),
                                        'email': _email.text.trim(),
                                        'phone': _phone.text.trim(),
                                      },
                                    );
                                  }
                                },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF0EA5E9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: authState.isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(_isSignUp ? 'Sign Up' : 'Log In', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                          onPressed: authState.isLoading
                              ? null
                              : () async {
                                  await ref.read(authControllerProvider.notifier).signInWithGoogle(role: AppRole.consumer);
                                },
                          icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg', height: 20),
                          label: const Text('Continue with Google', style: TextStyle(color: Colors.white, fontSize: 15)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.white.withOpacity(0.1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                        if (authState.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(authState.errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isSignUp ? 'Already have an account?' : "Don't have an account?",
                              style: TextStyle(color: Colors.white.withOpacity(0.6)),
                            ),
                            TextButton(
                              onPressed: _toggleMode,
                              child: Text(
                                _isSignUp ? 'Log In' : 'Sign Up',
                                style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => context.pop(),
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
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.4)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF38BDF8)),
        ),
      ),
    );
  }
}

