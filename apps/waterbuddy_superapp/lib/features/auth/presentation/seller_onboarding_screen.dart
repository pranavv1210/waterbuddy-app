import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/app_role.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/waterbuddy_auth_layout.dart';

class SellerAuthLandingScreen extends StatelessWidget {
  const SellerAuthLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go(RouteNames.roleSelection);
      },
      child: WaterBuddyAuthLayout(
        activeRole: AppRole.seller,
        title: 'Login as Tanker Owner',
        subtitle: 'Select an option to continue',
        child: Column(
          key: const ValueKey('seller_landing'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => context.push(RouteNames.authSellerLogin),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0891B2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: const Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => context.push(RouteNames.authSellerSignup),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0891B2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: const Text('SIGNUP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

