import 'package:flutter/material.dart';

import '../design_tokens/wb_tokens.dart';

class WbFadeSlide extends StatelessWidget {
  const WbFadeSlide({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 0.06),
  });

  final Widget child;
  final Duration delay;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: WbTokens.medium + delay,
      curve: WbTokens.ease,
      builder: (context, value, child) {
        final eased = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(offset.dx * (1 - eased), offset.dy * (1 - eased)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class WbPressable extends StatefulWidget {
  const WbPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<WbPressable> createState() => _WbPressableState();
}

class _WbPressableState extends State<WbPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:
          widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapUp:
          widget.onTap == null ? null : (_) => setState(() => _pressed = false),
      onTapCancel:
          widget.onTap == null ? null : () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: WbTokens.fast,
        curve: WbTokens.ease,
        child: widget.child,
      ),
    );
  }
}
