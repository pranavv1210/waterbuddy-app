import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_role.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/waterbuddy_auth_layout.dart';

class ConsumerLoginScreen extends ConsumerStatefulWidget {
  const ConsumerLoginScreen({super.key});

  @override
  ConsumerState<ConsumerLoginScreen> createState() => _ConsumerLoginScreenState();
}

class _ConsumerLoginScreenState extends ConsumerState<ConsumerLoginScreen> {
  final _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
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
      title: 'Consumer Login',
      subtitle: 'Enter your mobile number to login',
      child: Container(
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
                  onPressed: () => context.pop(),
                ),
                const Text(
                  'Welcome Back',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
                  : const Text('Log In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
