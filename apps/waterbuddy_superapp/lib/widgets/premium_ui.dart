import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class WbColors {
  const WbColors._();

  static const ink = Color(0xFF08111F);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE2E8F0);
  static const blue = Color(0xFF0EA5E9);
  static const deepBlue = Color(0xFF0369A1);
  static const green = Color(0xFF16A34A);
  static const red = Color(0xFFEF4444);
  static const amber = Color(0xFFF59E0B);
  static const surface = Color(0xFFF8FAFC);
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.opacity = 0.86,
    this.borderOpacity = 0.55,
    this.shadow = true,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double opacity;
  final double borderOpacity;
  final bool shadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withOpacity(borderOpacity),
              width: 1.2,
            ),
            boxShadow: shadow
                ? [
                    BoxShadow(
                      color: WbColors.ink.withOpacity(0.10),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class MapPillButton extends StatelessWidget {
  const MapPillButton({
    super.key,
    required this.icon,
    this.label,
    required this.onTap,
    this.color = WbColors.ink,
  });

  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 999,
      padding: EdgeInsets.symmetric(
        horizontal: label == null ? 13 : 14,
        vertical: 12,
      ),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          if (label != null) ...[
            const SizedBox(width: 8),
            Text(
              label!,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PremiumBottomPanel extends StatelessWidget {
  const PremiumBottomPanel({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth = 640,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          width: double.infinity,
          padding: padding ??
              EdgeInsets.fromLTRB(
                20,
                10,
                20,
                MediaQuery.paddingOf(context).bottom + 18,
              ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: const Border(top: BorderSide(color: WbColors.line)),
            boxShadow: [
              BoxShadow(
                color: WbColors.ink.withOpacity(0.16),
                blurRadius: 34,
                offset: const Offset(0, -14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedPulse extends StatelessWidget {
  const AnimatedPulse({
    super.key,
    required this.animation,
    this.color = WbColors.blue,
    this.size = 112,
    this.icon = Icons.location_on_rounded,
  });

  final Animation<double> animation;
  final Color color;
  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                Transform.scale(
                  scale: 0.35 + ((animation.value + i * 0.28) % 1) * 1.05,
                  child: Opacity(
                    opacity: 1 - ((animation.value + i * 0.28) % 1),
                    child: Container(
                      width: size * 0.74,
                      height: size * 0.74,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.16),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.20),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 30),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AbstractWaterBackground extends StatefulWidget {
  const AbstractWaterBackground({super.key});

  @override
  State<AbstractWaterBackground> createState() =>
      _AbstractWaterBackgroundState();
}

class _AbstractWaterBackgroundState extends State<AbstractWaterBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _WaterBackgroundPainter(_controller.value),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _WaterBackgroundPainter extends CustomPainter {
  const _WaterBackgroundPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF8FBFF),
          Color(0xFFE0F2FE),
          Color(0xFFF8FAFC),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    final shapePaint = Paint()..style = PaintingStyle.fill;
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = WbColors.blue.withOpacity(0.12);

    for (var i = 0; i < 9; i++) {
      final progress = (t + i * 0.13) % 1;
      final x = size.width * ((i * 0.23 + progress * 0.15) % 1);
      final y = size.height * (0.12 + ((i * 0.19 + progress * 0.55) % 0.78));
      final radius = 8.0 + (i % 4) * 8;
      shapePaint.color = WbColors.blue.withOpacity(0.045 + (i % 3) * 0.02);
      canvas.drawCircle(Offset(x, y), radius, shapePaint);
      canvas.drawCircle(Offset(x, y), radius * (1.6 + progress), wavePaint);
    }

    final path = Path();
    final base = size.height * 0.72;
    path.moveTo(0, base);
    for (double x = 0; x <= size.width; x += 14) {
      final y = base +
          math.sin((x / size.width * math.pi * 2) + t * math.pi * 2) * 16;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = Colors.white.withOpacity(0.58));
  }

  @override
  bool shouldRepaint(covariant _WaterBackgroundPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}

