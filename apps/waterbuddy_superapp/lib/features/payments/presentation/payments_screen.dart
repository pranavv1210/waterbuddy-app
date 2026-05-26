import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/route_names.dart';
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

    // Show error if any
    if (paymentState.errorMessage != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _goBack();
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: _buildAppBar(),
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Color(0xFFE53E3E)),
                    const SizedBox(height: 24),
                    Text(
                      'Payment Failed',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      paymentState.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFF486581), fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: () {
                          ref
                              .read(paymentControllerProvider.notifier)
                              .clearError();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          elevation: 0,
                        ),
                        child: const Text('Try Again',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Order Total',
                                  style: TextStyle(
                                    color: Color(0xFF829AB1),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₹${(_amountInPaise / 100).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 44,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Select Payment Method',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _PaymentMethodCard(
                            icon: Icons.qr_code_2_rounded,
                            title: 'UPI / QR',
                            subtitle: 'Google Pay, PhonePe, Paytm',
                            isSelected: selectedMethod == 'upi',
                            onTap: () => ref
                                .read(selectedPaymentMethodProvider.notifier)
                                .state = 'upi',
                          ),
                          const SizedBox(height: 12),
                          _PaymentMethodCard(
                            icon: Icons.credit_card_rounded,
                            title: 'Credit / Debit Card',
                            subtitle: 'Visa, Mastercard, RuPay',
                            isSelected: selectedMethod == 'card',
                            onTap: () => ref
                                .read(selectedPaymentMethodProvider.notifier)
                                .state = 'card',
                          ),
                          const SizedBox(height: 12),
                          _PaymentMethodCard(
                            icon: Icons.payments_rounded,
                            title: 'Cash on Delivery',
                            subtitle: 'Pay when your order arrives',
                            isSelected: selectedMethod == 'cash',
                            onTap: () => ref
                                .read(selectedPaymentMethodProvider.notifier)
                                .state = 'cash',
                          ),
                          const SizedBox(
                              height: 120), // padding for bottom button
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: FilledButton(
                      onPressed: paymentState.isProcessing || _orderId == null
                          ? null
                          : () async {
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
                                  customerName: user?.displayName ?? 'Customer',
                                  customerPhone: user?.phoneNumber ?? '',
                                  customerEmail: user?.email ?? '',
                                  description: 'Water Delivery Order',
                                );
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        elevation: 0,
                      ),
                      child: paymentState.isProcessing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              selectedMethod == 'cash'
                                  ? 'Confirm Order'
                                  : 'Pay ₹${(_amountInPaise / 100).toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
        onPressed: _goBack,
      ),
      title: const Text(
        'Checkout',
        style: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.0,
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

class _PaymentMethodCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF0F172A);
    final accentColor = const Color(0xFF38BDF8);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.black.withOpacity(0.05),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? accentColor : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon,
                  color: isSelected ? Colors.white : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF829AB1),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? accentColor : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
