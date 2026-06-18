import 'dart:math' as math;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/route_names.dart';
import '../../../widgets/premium_ui.dart';
import '../../../widgets/waterbuddy_toast.dart';
import '../providers/tracking_providers.dart';

class OrderCompleteScreen extends ConsumerStatefulWidget {
  const OrderCompleteScreen({super.key});

  @override
  ConsumerState<OrderCompleteScreen> createState() =>
      _OrderCompleteScreenState();
}

class _OrderCompleteScreenState extends ConsumerState<OrderCompleteScreen>
    with SingleTickerProviderStateMixin {
  int _rating = 0;
  bool _isSaving = false;
  late final AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  Future<void> _submitRating(String orderId) async {
    if (_rating == 0) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'rating': _rating});

      if (mounted) {
        WaterBuddyToastService.success(context, 'Thank you for your feedback!');
      }
    } catch (e) {
      if (mounted) {
        WaterBuddyToastService.error(context, 'Failed to save rating: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderId =
        GoRouterState.of(context).uri.queryParameters['orderId'];
    if (orderId == null) {
      return const Scaffold(
          body: Center(child: Text('Order ID missing')));
    }

    final orderAsync = ref.watch(orderStreamProvider(orderId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          context.go(RouteNames.orders);
        },
        child: Scaffold(
          backgroundColor: WbColors.surface,
          body: Stack(
            children: [
              // Premium background
              const AbstractWaterBackground(),

              // Sparkle particles on success
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _sparkleController,
                  builder: (context, _) => CustomPaint(
                    painter: _SparklePainter(_sparkleController.value),
                  ),
                ),
              ),

              // Content
              SafeArea(
                child: Column(
                  children: [
                    // Nav bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.go(RouteNames.orders),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: WbColors.line),
                                boxShadow: [
                                  BoxShadow(
                                    color: WbColors.ink.withValues(alpha: 0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: WbColors.ink,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Main body
                    Expanded(
                      child: orderAsync.when(
                        data: (order) {
                          if (order == null) {
                            return const Center(
                                child: Text('Order not found'));
                          }
                          return _buildSuccessContent(order, orderId);
                        },
                        loading: () => const Center(
                          child: WaterBuddyLoader(
                              message: 'Loading order details...'),
                        ),
                        error: (err, __) => Center(
                          child: Text(
                            'Error: $err',
                            style: const TextStyle(color: WbColors.red),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessContent(dynamic order, String orderId) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        children: [
          // Success hero
          _SuccessHero().animate().fadeIn(duration: 400.ms).scale(
              begin: const Offset(0.7, 0.7), curve: Curves.easeOutBack),

          const SizedBox(height: 20),

          const Text(
            'Order Complete!',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: WbColors.ink,
              letterSpacing: -1,
            ),
          ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),

          const SizedBox(height: 8),

          const Text(
            'Your water has been delivered successfully.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: WbColors.muted,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ).animate(delay: 300.ms).fadeIn(),

          const SizedBox(height: 32),

          // Order details glass card
          GlassPanel(
            radius: 28,
            opacity: 0.92,
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.location_on_rounded,
                  label: 'Delivery Location',
                  value: order.location['address'] ?? 'Unknown Address',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: WbColors.line),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _DetailRow(
                        icon: Icons.water_drop_rounded,
                        label: 'Tank Size',
                        value: '${order.tankSize} Litres',
                      ),
                    ),
                    Expanded(
                      child: _DetailRow(
                        icon: Icons.receipt_rounded,
                        label: 'Order ID',
                        value: order.id.length >= 8
                            ? order.id.substring(0, 8).toUpperCase()
                            : order.id.toUpperCase(),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: WbColors.line),
                ),
                _DetailRow(
                  icon: Icons.payments_rounded,
                  label: 'Payment Method',
                  value: order.paymentType,
                ),
              ],
            ),
          ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.08),

          const SizedBox(height: 28),

          // Rating section
          GlassPanel(
            radius: 24,
            opacity: 0.88,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Rate your experience',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: WbColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your feedback helps us improve',
                  style: TextStyle(
                    color: WbColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final filled = index < _rating;
                    return GestureDetector(
                      onTap: _isSaving
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              setState(() => _rating = index + 1);
                              _submitRating(orderId);
                            },
                      child: AnimatedScale(
                        scale: filled ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            filled
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: filled
                                ? WbColors.amber
                                : const Color(0xFFCBD5E1),
                            size: 38,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ).animate(delay: 520.ms).fadeIn().slideY(begin: 0.08),

          const SizedBox(height: 28),

          // CTA Buttons
          GestureDetector(
            onTap: () => context.go(RouteNames.home),
            child: Container(
              width: double.infinity,
              height: 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF0369A1)],
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: WbColors.blue.withValues(alpha: 0.30),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Back to Home',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ).animate(delay: 640.ms).fadeIn().slideY(begin: 0.12),

          const SizedBox(height: 12),

          GestureDetector(
            onTap: () => context.go(RouteNames.home),
            child: Container(
              width: double.infinity,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: WbColors.line, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: WbColors.ink.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded,
                      color: WbColors.ink, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Book Again',
                    style: TextStyle(
                      color: WbColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ).animate(delay: 700.ms).fadeIn().slideY(begin: 0.12),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SuccessHero extends StatefulWidget {
  @override
  State<_SuccessHero> createState() => _SuccessHeroState();
}

class _SuccessHeroState extends State<_SuccessHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
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
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -4 + math.sin(_controller.value * math.pi) * 4),
          child: child,
        );
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF22C55E).withValues(alpha: 0.35),
              blurRadius: 36,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 60,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: WbColors.blue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: WbColors.blue, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: WbColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: WbColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SparklePainter extends CustomPainter {
  const _SparklePainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final rng = math.Random(42);
    for (var i = 0; i < 15; i++) {
      final progress = (t + i * 0.073) % 1.0;
      final startX = rng.nextDouble();
      final startY = rng.nextDouble() * 0.5;
      final x = size.width * startX;
      final y = size.height * startY * (1 - progress);
      final r = 2.0 + rng.nextDouble() * 3;
      final opacity = (math.sin(progress * math.pi) * 0.15).clamp(0.0, 0.15);

      final colors = [WbColors.blue, WbColors.green, WbColors.amber];
      paint.color = colors[i % 3].withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.t != t;
}
