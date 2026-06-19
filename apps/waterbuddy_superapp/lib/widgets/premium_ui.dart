import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class WaterBuddyDesignSystem {
  const WaterBuddyDesignSystem._();

  static const spacingXs = 6.0;
  static const spacingSm = 10.0;
  static const spacingMd = 16.0;
  static const spacingLg = 22.0;
  static const spacingXl = 30.0;

  static const radiusSm = 14.0;
  static const radiusMd = 20.0;
  static const radiusLg = 28.0;
  static const radiusPill = 999.0;

  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 460);

  static const spring = Curves.easeOutBack;
  static const ease = Curves.easeOutCubic;

  static List<BoxShadow> premiumShadow([Color color = WbColors.ink]) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.10),
        blurRadius: 28,
        offset: const Offset(0, 14),
      ),
    ];
  }
}

class WbSafeScaffold extends StatelessWidget {
  const WbSafeScaffold({
    super.key,
    required this.child,
    this.backgroundColor = WbColors.surface,
    this.resizeToAvoidBottomInset = true,
    this.bottomNavigationBar,
    this.drawer,
  });

  final Widget child;
  final Color backgroundColor;
  final bool resizeToAvoidBottomInset;
  final Widget? bottomNavigationBar;
  final Widget? drawer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        top: true,
        bottom: true,
        child: child,
      ),
    );
  }
}

class WbSkeletonCard extends StatelessWidget {
  const WbSkeletonCard({
    super.key,
    this.height = 112,
    this.padding = const EdgeInsets.all(18),
  });

  final double height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(WaterBuddyDesignSystem.radiusMd),
        boxShadow: WaterBuddyDesignSystem.premiumShadow(),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          WbShimmer(width: 190, height: 14, borderRadius: 999),
          SizedBox(height: 12),
          WbShimmer(width: 130, height: 12, borderRadius: 999),
        ],
      ),
    );
  }
}

class WbMapPlaceholder extends StatelessWidget {
  const WbMapPlaceholder({super.key, this.label = 'Preparing map'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const AbstractWaterBackground(),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.30),
                  WbColors.blue.withValues(alpha: 0.08),
                ],
              ),
            ),
          ),
        ),
        Center(
          child: GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            radius: 22,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const WbShimmer(width: 34, height: 34, borderRadius: 999),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: WbColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
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
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: borderOpacity),
              width: 1.2,
            ),
            boxShadow: shadow
                ? [
                    BoxShadow(
                      color: WbColors.ink.withValues(alpha: 0.10),
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
                color: WbColors.ink.withValues(alpha: 0.16),
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
                        color: color.withValues(alpha: 0.16),
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
                      color: color.withValues(alpha: 0.20),
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

class WaterBuddyLoader extends StatefulWidget {
  const WaterBuddyLoader({
    super.key,
    this.message = 'Loading WaterBuddy',
    this.compact = false,
  });

  final String message;
  final bool compact;

  @override
  State<WaterBuddyLoader> createState() => _WaterBuddyLoaderState();
}

class _WaterBuddyLoaderState extends State<WaterBuddyLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.compact ? 74.0 : 118.0;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedPulse(
            animation: _controller,
            color: WbColors.blue,
            icon: Icons.water_drop_rounded,
            size: size,
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: WaterBuddyDesignSystem.medium,
            child: Text(
              widget.message,
              key: ValueKey(widget.message),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: WbColors.ink,
                fontSize: widget.compact ? 13 : 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
      ..color = WbColors.blue.withValues(alpha: 0.12);

    for (var i = 0; i < 9; i++) {
      final progress = (t + i * 0.13) % 1;
      final x = size.width * ((i * 0.23 + progress * 0.15) % 1);
      final y = size.height * (0.12 + ((i * 0.19 + progress * 0.55) % 0.78));
      final radius = 8.0 + (i % 4) * 8;
      shapePaint.color =
          WbColors.blue.withValues(alpha: 0.045 + (i % 3) * 0.02);
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
    canvas.drawPath(
        path, Paint()..color = Colors.white.withValues(alpha: 0.58));
  }

  @override
  bool shouldRepaint(covariant _WaterBackgroundPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WbPremiumTextField – animated, focus-glowing, premium text field
// ─────────────────────────────────────────────────────────────────────────────

class WbPremiumTextField extends StatefulWidget {
  const WbPremiumTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.enabled = true,
    this.suffixIcon,
    this.onChanged,
    this.textInputAction,
    this.focusNode,
    this.maxLength,
    this.accentColor = WbColors.blue,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final bool enabled;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final int? maxLength;
  final Color accentColor;

  @override
  State<WbPremiumTextField> createState() => _WbPremiumTextFieldState();
}

class _WbPremiumTextFieldState extends State<WbPremiumTextField>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focus;
  bool _focused = false;
  bool _obscure = false;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
    _focus = widget.focusNode ?? FocusNode();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _focus.addListener(() {
      if (mounted) setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focus.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void shake() {
    HapticFeedback.lightImpact();
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.accentColor;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final offset = math.sin(_shakeAnimation.value * math.pi * 5) * 6;
        return Transform.translate(
          offset: Offset(offset * (1 - _shakeAnimation.value), 0),
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: WaterBuddyDesignSystem.fast,
        curve: WaterBuddyDesignSystem.ease,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(WaterBuddyDesignSystem.radiusSm),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  )
                ]
              : null,
        ),
        child: TextFormField(
          controller: widget.controller,
          focusNode: _focus,
          keyboardType: widget.keyboardType,
          obscureText: _obscure,
          enabled: widget.enabled,
          textInputAction: widget.textInputAction,
          maxLength: widget.maxLength,
          onChanged: widget.onChanged,
          validator: widget.validator,
          style: const TextStyle(
            color: WbColors.ink,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            counterText: '',
            labelStyle: TextStyle(
              color: _focused ? accentColor : WbColors.muted,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              widget.icon,
              color: _focused ? accentColor : WbColors.muted,
              size: 20,
            ),
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: WbColors.muted,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : widget.suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(WaterBuddyDesignSystem.radiusSm),
              borderSide: const BorderSide(color: WbColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(WaterBuddyDesignSystem.radiusSm),
              borderSide: const BorderSide(color: WbColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(WaterBuddyDesignSystem.radiusSm),
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(WaterBuddyDesignSystem.radiusSm),
              borderSide: const BorderSide(color: WbColors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(WaterBuddyDesignSystem.radiusSm),
              borderSide: const BorderSide(color: WbColors.red, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WbShimmer – shimmer loading placeholder
// ─────────────────────────────────────────────────────────────────────────────

class WbShimmer extends StatefulWidget {
  const WbShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<WbShimmer> createState() => _WbShimmerState();
}

class _WbShimmerState extends State<WbShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
              colors: const [
                Color(0xFFECF0F1),
                Color(0xFFF8FAFC),
                Color(0xFFECF0F1),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WbStepIndicator – step progress bar for multi-step forms
// ─────────────────────────────────────────────────────────────────────────────

class WbStepIndicator extends StatelessWidget {
  const WbStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.accentColor = WbColors.blue,
    this.stepLabels,
  });

  final int currentStep;
  final int totalSteps;
  final Color accentColor;
  final List<String>? stepLabels;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(totalSteps, (i) {
            final done = i < currentStep;
            final active = i == currentStep;
            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: WaterBuddyDesignSystem.medium,
                      curve: WaterBuddyDesignSystem.ease,
                      height: 4,
                      decoration: BoxDecoration(
                        color: done || active ? accentColor : WbColors.line,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  if (i < totalSteps - 1) const SizedBox(width: 4),
                ],
              ),
            );
          }),
        ),
        if (stepLabels != null && currentStep < stepLabels!.length) ...[
          const SizedBox(height: 8),
          Text(
            'Step ${currentStep + 1} of $totalSteps — ${stepLabels![currentStep]}',
            style: const TextStyle(
              color: WbColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WbAnimatedCounter – animated number counter
// ─────────────────────────────────────────────────────────────────────────────

class WbAnimatedCounter extends StatelessWidget {
  const WbAnimatedCounter({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 800),
    this.prefix = '',
    this.suffix = '',
  });

  final double value;
  final TextStyle style;
  final Duration duration;
  final String prefix;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, val, _) {
        final display = val >= 1000
            ? '${(val / 1000).toStringAsFixed(1)}K'
            : val.toInt().toString();
        return Text('$prefix$display$suffix', style: style);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WbGradientButton – premium gradient button with loading/success states
// ─────────────────────────────────────────────────────────────────────────────

enum WbButtonState { idle, loading, success, error }

class WbGradientButton extends StatefulWidget {
  const WbGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.state = WbButtonState.idle,
    this.icon,
    this.loadingLabel = 'Please wait...',
    this.successLabel = 'Done!',
    this.gradient,
    this.height = 56,
  });

  final String label;
  final String loadingLabel;
  final String successLabel;
  final VoidCallback? onPressed;
  final WbButtonState state;
  final IconData? icon;
  final Gradient? gradient;
  final double height;

  @override
  State<WbGradientButton> createState() => _WbGradientButtonState();
}

class _WbGradientButtonState extends State<WbGradientButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isIdle = widget.state == WbButtonState.idle;
    final isLoading = widget.state == WbButtonState.loading;
    final isSuccess = widget.state == WbButtonState.success;

    final gradient = widget.gradient ??
        const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF0369A1)],
        );

    String label;
    Widget child;
    if (isLoading) {
      label = widget.loadingLabel;
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _PremiumLoadingDots(color: Colors.white),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15)),
        ],
      );
    } else if (isSuccess) {
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(widget.successLabel,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15)),
        ],
      );
    } else {
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
          ],
          Text(widget.label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15)),
        ],
      );
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: (isIdle && widget.onPressed != null)
          ? () {
              HapticFeedback.mediumImpact();
              widget.onPressed!();
            }
          : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: WaterBuddyDesignSystem.medium,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: isSuccess
                ? const LinearGradient(
                    colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                  )
                : isIdle
                    ? gradient
                    : LinearGradient(
                        colors: [
                          gradient.colors.first.withValues(alpha: 0.6),
                          gradient.colors.last.withValues(alpha: 0.6),
                        ],
                      ),
            borderRadius:
                BorderRadius.circular(WaterBuddyDesignSystem.radiusPill),
            boxShadow: _pressed
                ? null
                : [
                    BoxShadow(
                      color: WbColors.blue.withValues(alpha: 0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PremiumLoadingDots extends StatefulWidget {
  const _PremiumLoadingDots({required this.color});

  final Color color;

  @override
  State<_PremiumLoadingDots> createState() => _PremiumLoadingDotsState();
}

class _PremiumLoadingDotsState extends State<_PremiumLoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
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
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final phase = ((_controller.value + index * 0.18) % 1);
            final scale = 0.62 + (1 - (phase - 0.5).abs() * 2) * 0.38;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.72 + scale * 0.28),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
