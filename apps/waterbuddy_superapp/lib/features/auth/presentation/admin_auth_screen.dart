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
      appBar: AppBar(title: const Text('Admin Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loading ? null : _loginWithEmail, child: const Text('Login')),
            OutlinedButton(
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() {
                        _loading = true;
                        _error = null;
                      });
                      try {
                        final ok = await ref.read(authControllerProvider.notifier).signInWithGoogle(role: AppRole.admin);
                        if (ok && mounted) context.go(RouteNames.adminDashboard);
                      } finally {
                        if (mounted) setState(() => _loading = false);
                      }
                    },
              child: const Text('Continue with Google'),
            ),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Future<void> _loginWithEmail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = ref.read(authServiceProvider);
      final credential = await auth.signInWithEmailPassword(email: _email.text.trim(), password: _password.text.trim());
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

