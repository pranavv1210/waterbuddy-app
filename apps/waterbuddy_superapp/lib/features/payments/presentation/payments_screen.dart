import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/route_names.dart';
import '../../../widgets/premium_ui.dart';
import '../providers/payment_providers.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  String? _orderId;
  int _amountInPaise = 0; // extracted from query params

  @override
  void initState() {
    super.initState();

    // Init Razorpay SDK
    ref.read(razorpayServiceProvider).init();

    // Get orderId + amount from query params
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final params = GoRouterState.of(context).uri.queryParameters;
      final orderId = params['orderId'];
      final amount = int.tryParse(params['amount'] ?? '') ?? 0;
      setState(() {
        _orderId = orderId;
        _amountInPaise = amount * 100; // convert ₹ → paise
      });
    });
  }

  @override
  void dispose() {
    ref.read(razorpayServiceProvider).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentControllerProvider);
    final selectedMethod = ref.watch(selectedPaymentMethodProvider) ?? 'upi';

    // Navigate to tracking after payment is completed
    if (paymentState.paymentCompleted && _orderId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('${RouteNames.tracking}?orderId=$_orderId');
      });
    }

    // Show error state
    if (paymentState.errorMessage != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _goBack();
        },
        child: Scaffold(
          backgroundColor: WbColors.surface,
          body: Stack(
            children: [
              const AbstractWaterBackground(),
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: WbColors.red.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: WbColors.red.withValues(alpha: 0.20)),
                          ),
                          child: const Icon(Icons.payment_rounded,
                              size: 38, color: WbColors.red),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Payment Failed',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: WbColors.ink,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          paymentState.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: WbColors.muted, fontSize: 14, height: 1.4),
                        ),
                        const SizedBox(height: 32),
                        GestureDetector(
                          onTap: () {
                            ref
                                .read(paymentControllerProvider.notifier)
                                .clearError();
                          },
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0EA5E9), Color(0xFF0369A1)],
                              ),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: WbColors.blue.withValues(alpha: 0.28),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh_rounded,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Try Again',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _goBack();
        },
        child: Scaffold(
          backgroundColor: WbColors.surface,
          body: Stack(
            children: [
              const AbstractWaterBackground(),
              SafeArea(
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _goBack,
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
                          const SizedBox(width: 16),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Checkout',
                                style: TextStyle(
                                  color: WbColors.ink,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'Complete your water booking',
                                style: TextStyle(
                                  color: WbColors.muted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1),
                    ),
                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Amount card
                            GlassPanel(
                              radius: 28,
                              opacity: 0.94,
                              padding: const EdgeInsets.all(24),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF22C55E),
                                          Color(0xFF16A34A)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.water_drop_rounded,
                                        color: Colors.white, size: 26),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Order Total',
                                        style: TextStyle(
                                          color: WbColors.muted,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₹${(_amountInPaise / 100).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: WbColors.ink,
                                          fontSize: 36,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ).animate(delay: 80.ms).fadeIn().slideY(begin: 0.06),
                            const SizedBox(height: 24),
                            const Text(
                              'Payment Method',
                              style: TextStyle(
                                color: WbColors.ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ).animate(delay: 140.ms).fadeIn(),
                            const SizedBox(height: 12),
                            _PaymentMethodCard(
                              icon: Icons.qr_code_2_rounded,
                              title: 'UPI / QR',
                              subtitle: 'Google Pay, PhonePe, Paytm',
                              isSelected: selectedMethod == 'upi',
                              onTap: () => ref
                                  .read(selectedPaymentMethodProvider.notifier)
                                  .state = 'upi',
                            ).animate(delay: 180.ms).fadeIn().slideY(begin: 0.05),
                            const SizedBox(height: 10),
                            _PaymentMethodCard(
                              icon: Icons.credit_card_rounded,
                              title: 'Credit / Debit Card',
                              subtitle: 'Visa, Mastercard, RuPay',
                              isSelected: selectedMethod == 'card',
                              onTap: () => ref
                                  .read(selectedPaymentMethodProvider.notifier)
                                  .state = 'card',
                            ).animate(delay: 220.ms).fadeIn().slideY(begin: 0.05),
                            const SizedBox(height: 10),
                            _PaymentMethodCard(
                              icon: Icons.payments_rounded,
                              title: 'Cash on Delivery',
                              subtitle: 'Pay when your order arrives',
                              isSelected: selectedMethod == 'cash',
                              onTap: () => ref
                                  .read(selectedPaymentMethodProvider.notifier)
                                  .state = 'cash',
                            ).animate(delay: 260.ms).fadeIn().slideY(begin: 0.05),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Floating CTA
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: const Border(
                        top: BorderSide(color: WbColors.line)),
                    boxShadow: [
                      BoxShadow(
                        color: WbColors.ink.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    MediaQuery.paddingOf(context).bottom + 16,
                  ),
                  child: GestureDetector(
                    onTap: paymentState.isProcessing || _orderId == null
                        ? null
                        : () async {
                            HapticFeedback.mediumImpact();
                            final controller =
                                ref.read(paymentControllerProvider.notifier);
                            final user = FirebaseAuth.instance.currentUser;

                            if (selectedMethod == 'cash') {
                              await controller.selectCod(_orderId!);
                            } else {
                              final method =
                                  selectedMethod == 'card' ? 'card' : 'upi';
                              await controller.startOnlinePayment(
                                orderId: _orderId!,
                                amountInPaise: _amountInPaise > 0
                                    ? _amountInPaise
                                    : 50000,
                                method: method,
                                customerName:
                                    user?.displayName ?? 'Customer',
                                customerPhone: user?.phoneNumber ?? '',
                                customerEmail: user?.email ?? '',
                                description: 'Water Delivery Order',
                              );
                            }
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: paymentState.isProcessing
                            ? LinearGradient(
                                colors: [
                                  WbColors.blue.withValues(alpha: 0.6),
                                  WbColors.deepBlue.withValues(alpha: 0.6),
                                ],
                              )
                            : const LinearGradient(
                                colors: [
                                  Color(0xFF0EA5E9),
                                  Color(0xFF0369A1)
                                ],
                              ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: paymentState.isProcessing
                            ? null
                            : [
                                BoxShadow(
                                  color: WbColors.blue.withValues(alpha: 0.30),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                      ),
                      child: Center(
                        child: paymentState.isProcessing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                selectedMethod == 'cash'
                                    ? 'Confirm Order'
                                    : 'Pay ₹${(_amountInPaise / 100).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.home);
    }
  }
}

class _PaymentMethodCard extends StatefulWidget {
  const _PaymentMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_PaymentMethodCard> createState() => _PaymentMethodCardState();
}

class _PaymentMethodCardState extends State<_PaymentMethodCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 130),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? WbColors.blue.withValues(alpha: 0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: widget.isSelected
                  ? WbColors.blue
                  : WbColors.line,
              width: widget.isSelected ? 1.8 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: WbColors.blue.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: WbColors.ink.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? WbColors.blue.withValues(alpha: 0.12)
                      : WbColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.isSelected ? WbColors.blue : WbColors.muted,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: widget.isSelected ? WbColors.ink : WbColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        color: WbColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isSelected ? WbColors.blue : Colors.transparent,
                  border: Border.all(
                    color: widget.isSelected ? WbColors.blue : WbColors.line,
                    width: 2,
                  ),
                ),
                child: widget.isSelected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
