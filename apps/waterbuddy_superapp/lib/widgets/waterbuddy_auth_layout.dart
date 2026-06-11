import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/app_role.dart';
import 'premium_ui.dart';

class WaterBuddyAuthLayout extends ConsumerStatefulWidget {
  const WaterBuddyAuthLayout({
    super.key,
    required this.activeRole,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final AppRole activeRole;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  ConsumerState<WaterBuddyAuthLayout> createState() =>
      _WaterBuddyAuthLayoutState();
}

class _WaterBuddyAuthLayoutState extends ConsumerState<WaterBuddyAuthLayout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final compact = MediaQuery.sizeOf(context).height < 720 || keyboard > 0;
    final meta = _AuthRoleMeta.forRole(widget.activeRole);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: WbColors.surface,
        body: Stack(
          children: [
            const AbstractWaterBackground(),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _motion,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _AuthParallaxPainter(
                      t: _motion.value,
                      accent: meta.color,
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      22,
                      compact ? 16 : 28,
                      22,
                      keyboard + 24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 520,
                          minHeight: constraints.maxHeight -
                              (compact ? 32 : 56) -
                              keyboard,
                        ),
                        child: Column(
                          mainAxisAlignment: compact
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _AuthHero(
                              title: widget.title,
                              subtitle: widget.subtitle,
                              meta: meta,
                              compact: compact,
                            )
                                .animate()
                                .fadeIn(duration: 360.ms)
                                .slideY(begin: -0.08),
                            SizedBox(height: compact ? 18 : 28),
                            GlassPanel(
                              radius: 30,
                              opacity: 0.84,
                              padding: EdgeInsets.all(compact ? 18 : 22),
                              child: widget.child,
                            )
                                .animate(delay: 120.ms)
                                .fadeIn(duration: 360.ms)
                                .slideY(begin: 0.08),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final _AuthRoleMeta meta;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Hero(
          tag: 'waterbuddy-logo',
          child: Container(
            width: compact ? 66 : 82,
            height: compact ? 66 : 82,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [meta.color.withOpacity(0.82), WbColors.deepBlue],
              ),
              borderRadius: BorderRadius.circular(compact ? 22 : 28),
              boxShadow: WaterBuddyDesignSystem.premiumShadow(meta.color),
            ),
            child: Icon(meta.icon, color: Colors.white, size: compact ? 34 : 42),
          ),
        ),
        SizedBox(height: compact ? 12 : 18),
        const Text(
          'WaterBuddy',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: WbColors.ink,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          meta.tagline,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: WbColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (title.isNotEmpty || subtitle.isNotEmpty) ...[
          SizedBox(height: compact ? 18 : 26),
          if (title.isNotEmpty)
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: WbColors.ink,
                fontSize: 24,
                height: 1.08,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: WbColors.muted,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _AuthRoleMeta {
  const _AuthRoleMeta({
    required this.icon,
    required this.color,
    required this.tagline,
  });

  final IconData icon;
  final Color color;
  final String tagline;

  static _AuthRoleMeta forRole(AppRole role) {
    switch (role) {
      case AppRole.consumer:
        return const _AuthRoleMeta(
          icon: Icons.water_drop_rounded,
          color: WbColors.blue,
          tagline: 'Water Delivered Fast',
        );
      case AppRole.seller:
        return const _AuthRoleMeta(
          icon: Icons.local_shipping_rounded,
          color: Color(0xFF14B8A6),
          tagline: 'Deliver water smarter',
        );
      case AppRole.driver:
        return const _AuthRoleMeta(
          icon: Icons.route_rounded,
          color: WbColors.amber,
          tagline: 'Ready for deliveries',
        );
      case AppRole.admin:
        return const _AuthRoleMeta(
          icon: Icons.security_rounded,
          color: Color(0xFF1D4ED8),
          tagline: 'Secure operations control',
        );
    }
  }
}

class _AuthParallaxPainter extends CustomPainter {
  const _AuthParallaxPainter({required this.t, required this.accent});

  final double t;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 7; i++) {
      final progress = (t + i * 0.17) % 1;
      final x = size.width * ((i * 0.29 + math.sin(progress * math.pi) * 0.08) % 1);
      final y = size.height * (0.08 + ((i * 0.13 + progress * 0.32) % 0.58));
      paint.color = accent.withOpacity(0.035 + (i % 3) * 0.018);
      canvas.drawCircle(Offset(x, y), 18 + (i % 4) * 9, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuthParallaxPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.accent != accent;
  }
}

