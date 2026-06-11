import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_role.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/premium_ui.dart';

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
        extendBodyBehindAppBar: true,
        backgroundColor: WbColors.surface,
        body: Stack(
          children: [
            const AbstractWaterBackground(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 108),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 126,
                        maxWidth: 620,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          const _PremiumLogoLockup()
                              .animate()
                              .fadeIn(duration: 450.ms)
                              .slideY(begin: -0.08, end: 0),
                          const SizedBox(height: 34),
                          const Text(
                            'Book water tankers instantly.',
                            style: TextStyle(
                              color: WbColors.ink,
                              fontSize: 38,
                              height: 1.02,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.08),
                          const SizedBox(height: 10),
                          const Text(
                            'Choose how you want to use WaterBuddy today.',
                            style: TextStyle(
                              color: WbColors.muted,
                              fontSize: 16,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                            ),
                          ).animate().fadeIn(delay: 180.ms),
                          const SizedBox(height: 28),
                          for (var i = 0; i < roles.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _RoleGlassCard(
                                role: roles[i],
                                selected: selectedRole == roles[i],
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  ref
                                      .read(selectedRoleProvider.notifier)
                                      .set(roles[i]);
                                },
                              )
                                  .animate()
                                  .fadeIn(delay: (220 + i * 70).ms)
                                  .slideY(begin: 0.08, end: 0),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: MediaQuery.paddingOf(context).bottom + 16,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: FilledButton(
                      onPressed: selectedRole == null
                          ? null
                          : () => _continue(context, selectedRole),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(58),
                        backgroundColor: WbColors.ink,
                        disabledBackgroundColor:
                            Colors.white.withOpacity(0.72),
                        disabledForegroundColor: WbColors.muted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      child: const Text('Continue'),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 420.ms).slideY(begin: 0.2, end: 0),
            ),
          ],
        ),
      ),
    );
  }

  void _continue(BuildContext context, AppRole selectedRole) {
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
  }
}
class _PremiumLogoLockup extends StatelessWidget {
  const _PremiumLogoLockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Hero(
          tag: 'waterbuddy-logo',
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF38BDF8), Color(0xFF0369A1)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: WbColors.blue.withOpacity(0.30),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(
              Icons.water_drop_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WaterBuddy',
              style: TextStyle(
                color: WbColors.ink,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Instant water logistics',
              style: TextStyle(
                color: WbColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoleGlassCard extends StatefulWidget {
  const _RoleGlassCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final AppRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_RoleGlassCard> createState() => _RoleGlassCardState();
}

class _RoleGlassCardState extends State<_RoleGlassCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final meta = _RoleMeta.forRole(widget.role);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : (widget.selected ? 1.015 : 1),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(1.4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: widget.selected
                ? LinearGradient(colors: [meta.color, WbColors.deepBlue])
                : null,
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: meta.color.withOpacity(0.22),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: GlassPanel(
            radius: 27,
            opacity: widget.selected ? 0.92 : 0.76,
            padding: const EdgeInsets.all(16),
            shadow: !widget.selected,
            child: Row(
              children: [
                Hero(
                  tag: 'role-${widget.role.name}',
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: meta.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(meta.icon, color: meta.color, size: 31),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.role.label,
                        style: const TextStyle(
                          color: WbColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meta.description,
                        style: const TextStyle(
                          color: WbColors.muted,
                          fontSize: 13,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: widget.selected ? meta.color : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.selected
                          ? meta.color
                          : WbColors.line,
                    ),
                  ),
                  child: Icon(
                    widget.selected
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                    color: widget.selected ? Colors.white : WbColors.muted,
                    size: 19,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleMeta {
  const _RoleMeta({
    required this.icon,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String description;
  final Color color;

  static _RoleMeta forRole(AppRole role) {
    switch (role) {
      case AppRole.consumer:
        return const _RoleMeta(
          icon: Icons.home_work_rounded,
          description: 'Order water in minutes',
          color: WbColors.blue,
        );
      case AppRole.seller:
        return const _RoleMeta(
          icon: Icons.local_shipping_rounded,
          description: 'Receive nearby tanker requests',
          color: Color(0xFF14B8A6),
        );
      case AppRole.driver:
        return const _RoleMeta(
          icon: Icons.route_rounded,
          description: 'Accept runs and deliver faster',
          color: WbColors.amber,
        );
      case AppRole.admin:
        return const _RoleMeta(
          icon: Icons.admin_panel_settings_rounded,
          description: 'Control operations in real time',
          color: Color(0xFF6366F1),
        );
    }
  }
}
