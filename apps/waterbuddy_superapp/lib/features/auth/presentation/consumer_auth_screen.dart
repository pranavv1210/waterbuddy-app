import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_role.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/kaveri_auth_layout.dart';

class ConsumerAuthScreen extends ConsumerStatefulWidget {
  const ConsumerAuthScreen({super.key});

  @override
  ConsumerState<ConsumerAuthScreen> createState() => _ConsumerAuthScreenState();
}

class _ConsumerAuthScreenState extends ConsumerState<ConsumerAuthScreen> with SingleTickerProviderStateMixin {
  bool _startedFlow = false;
  bool _isSignUp = false;
  
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 450))..forward();
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

  void _startFlow(bool isSignUp) {
    setState(() {
      _isSignUp = isSignUp;
      _startedFlow = true;
    });
    _animController.reset();
    _animController.forward();
  }

  void _resetFlow() {
    setState(() {
      _startedFlow = false;
    });
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_startedFlow) {
          _resetFlow();
        } else {
          context.go(RouteNames.roleSelection);
        }
      },
      child: KaveriAuthLayout(
        activeRole: AppRole.consumer,
        title: 'Login as Consumer',
        subtitle: _startedFlow ? (_isSignUp ? 'Create your consumer profile' : 'Enter mobile details to login') : '',
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: !_startedFlow
                ? Column(
                    key: const ValueKey('consumer_landing'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Sanchari Kaveri exact Buttons
                      ElevatedButton(
                        onPressed: () => _startFlow(false), // Login Mode
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0EA5E9),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        child: const Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: () => _startFlow(true), // Signup Mode
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0EA5E9),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        child: const Text('SIGNUP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      ),
                    ],
                  )
                : Container(
                    key: const ValueKey('consumer_fields'),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                              onPressed: _resetFlow,
                            ),
                            Text(
                              _isSignUp ? 'Create Account' : 'Welcome Back',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_isSignUp) ...[
                          _buildTextField(controller: _name, label: 'Full Name', icon: Icons.person_outline),
                          const SizedBox(height: 14),
                          _buildTextField(controller: _email, label: 'Email ID', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 14),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('OR', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                            ),
                            Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: authState.isLoading
                              ? null
                              : () async {
                                  await ref.read(authControllerProvider.notifier).signInWithGoogle(role: AppRole.consumer);
                                },
                          icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg', height: 18),
                          label: const Text('Continue with Google', style: TextStyle(color: Colors.white, fontSize: 14)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.white.withOpacity(0.15)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        if (authState.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(authState.errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center),
                        ],
                      ],
                    ),
                  ),
          ),
        ),
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
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF38BDF8)),
        ),
      ),
    );
  }
}
