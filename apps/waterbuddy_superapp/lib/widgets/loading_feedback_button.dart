import 'package:flutter/material.dart';

import 'premium_ui.dart';

enum LoadingButtonState { idle, loading, success }

class LoadingFeedbackButton extends StatelessWidget {
  const LoadingFeedbackButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.loadingLabel,
    required this.successLabel,
    required this.buttonState,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 54.0,
    this.borderRadius = 16.0,
  });

  final VoidCallback? onPressed;
  final String label;
  final String loadingLabel;
  final String successLabel;
  final LoadingButtonState buttonState;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final primaryBg = backgroundColor ?? const Color(0xFF0095F6);
    final textFg = foregroundColor ?? Colors.white;

    Color bg;
    Widget content;

    switch (buttonState) {
      case LoadingButtonState.idle:
        bg = primaryBg;
        content = Text(
          label,
          key: const ValueKey('idle'),
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        );
        break;
      case LoadingButtonState.loading:
        bg = primaryBg.withValues(alpha: 0.8);
        content = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          key: const ValueKey('loading'),
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeInOut,
                builder: (context, value, _) {
                  return CircularProgressIndicator(
                    value: value,
                    strokeWidth: 2.5,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    valueColor: AlwaysStoppedAnimation<Color>(textFg),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Text(
              loadingLabel,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5),
            ),
          ],
        );
        break;
      case LoadingButtonState.success:
        bg = const Color(0xFF22C55E); // Success Green
        content = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          key: const ValueKey('success'),
          children: [
            Icon(Icons.check_circle_outline_rounded, color: textFg, size: 22),
            const SizedBox(width: 10),
            Text(
              successLabel,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5),
            ),
          ],
        );
        break;
    }

    return SizedBox(
      width: double.infinity,
      height: height,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: WaterBuddyDesignSystem.ease,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: buttonState == LoadingButtonState.idle
              ? WaterBuddyDesignSystem.premiumShadow(primaryBg)
              : null,
        ),
        child: FilledButton(
          onPressed: buttonState == LoadingButtonState.idle ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: textFg,
            disabledBackgroundColor: bg,
            disabledForegroundColor: textFg,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: content,
          ),
        ),
      ),
    );
  }
}
