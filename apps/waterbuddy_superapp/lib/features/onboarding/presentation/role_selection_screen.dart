import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_role.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRole = ref.watch(selectedRoleProvider);
    final roles = AppRole.values;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'WaterBuddy',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose Account Type',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(roles.length, (index) {
                    final role = roles[index];
                    final isSelected = selectedRole == role;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          ref.read(selectedRoleProvider.notifier).set(role);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0095F6) // Blue selected state
                                : const Color(0xFFF1F5F9), // Grey unselected state
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF0095F6)
                                  : const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _icon(role),
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                                size: 24,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  role.label,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF111827),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: selectedRole == null
                        ? null
                        : () {
                            switch (selectedRole) {
                              case AppRole.consumer:
                                context.push(RouteNames.authConsumer);
                                break;
                              case AppRole.seller:
                                context.push(RouteNames.authSeller);
                                break;
                              case AppRole.driver:
                                context.push(RouteNames.authDriver);
                                break;
                              case AppRole.admin:
                                context.push(RouteNames.authAdmin);
                                break;
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0095F6),
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                      disabledForegroundColor: const Color(0xFF9CA3AF),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _icon(AppRole role) {
    switch (role) {
      case AppRole.consumer:
        return Icons.water_drop_rounded;
      case AppRole.seller:
        return Icons.storefront_rounded;
      case AppRole.driver:
        return Icons.local_shipping_rounded;
      case AppRole.admin:
        return Icons.admin_panel_settings_rounded;
    }
  }
}
