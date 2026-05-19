import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_role.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedRole = ref.watch(selectedRoleProvider);
    final roles = AppRole.values;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          // Background ambient light orbs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0F766E),
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
                color: Color(0xFF14B8A6),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WaterBuddy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose your operations role below',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                  ),
                  const Spacer(), // Centering element top push
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(roles.length, (index) {
                      final role = roles[index];
                      final animation = CurvedAnimation(
                        parent: _controller,
                        curve: Interval(index * 0.12, 1, curve: Curves.easeOutCubic),
                      );
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
                              .animate(animation),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _RoleCard(
                              role: role,
                              selected: selectedRole == role,
                              onTap: () => ref.read(selectedRoleProvider.notifier).set(role),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const Spacer(), // Centering element bottom push
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: selectedRole == null
                            ? null
                            : const LinearGradient(
                                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                              ),
                        boxShadow: selectedRole == null
                            ? null
                            : [
                                BoxShadow(
                                  color: const Color(0xFF14B8A6).withOpacity(0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: FilledButton(
                        onPressed: selectedRole == null
                            ? null
                            : () {
                                switch (selectedRole) {
                                  case AppRole.consumer:
                                    context.go(RouteNames.authConsumer);
                                  case AppRole.seller:
                                    context.go(RouteNames.authSeller);
                                  case AppRole.driver:
                                    context.go(RouteNames.authDriver);
                                  case AppRole.admin:
                                    context.go(RouteNames.authAdmin);
                                }
                              },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          backgroundColor: selectedRole == null
                              ? Colors.white.withOpacity(0.04)
                              : Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: selectedRole == null
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                        child: Text(
                          'Continue',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: selectedRole == null
                                ? Colors.white.withOpacity(0.3)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final AppRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color activeColor = const Color(0xFF14B8A6);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.02),
            border: Border.all(
              color: selected ? activeColor : Colors.white.withOpacity(0.08),
              width: selected ? 1.8 : 1.0,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected ? activeColor.withOpacity(0.12) : Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _icon(role),
                    color: selected ? activeColor : Colors.white.withOpacity(0.6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.label,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white.withOpacity(0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitle(role),
                        style: TextStyle(
                          color: selected ? activeColor.withOpacity(0.8) : Colors.white.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedScale(
                  scale: selected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  child: Icon(Icons.check_circle_rounded, color: activeColor, size: 24),
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

  String _subtitle(AppRole role) {
    switch (role) {
      case AppRole.consumer:
        return 'Order tankers to your doorstep';
      case AppRole.seller:
        return 'Manage tanker fleets & listings';
      case AppRole.driver:
        return 'Accept dispatches & navigate routes';
      case AppRole.admin:
        return 'Supervise & approve accounts';
    }
  }
}
