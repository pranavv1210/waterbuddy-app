import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/route_names.dart';
import '../../../widgets/async_state_view.dart';
import '../models/payment_checkout.dart';
import '../providers/payment_providers.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkout = ref.watch(paymentCheckoutProvider);

    return checkout.when(
      data: (state) => _PaymentsScreenBody(state: state),
      error: (_, __) => const AsyncStateView(
        isLoading: false,
        hasError: true,
        child: SizedBox.shrink(),
      ),
      loading: () => const AsyncStateView(
        isLoading: true,
        hasError: false,
        child: SizedBox.shrink(),
      ),
    );
  }
}

class _PaymentsScreenBody extends ConsumerWidget {
  const _PaymentsScreenBody({required this.state});

  final PaymentCheckout state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMethod = ref.watch(selectedPaymentMethodProvider) ?? state.methods.first.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: _GlowBlob(
              width: 260,
              height: 260,
              color: const Color(0xFFDBEAFE).withOpacity(0.3),
            ),
          ),
          Positioned(
            top: 320,
            left: -80,
            child: _GlowBlob(
              width: 220,
              height: 220,
              color: const Color(0xFF71F8E4).withOpacity(0.12),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(Icons.arrow_back_rounded),
                              color: const Color(0xFF00236F),
                            ),
                            Text(
                              state.title,
                              style: const TextStyle(
                                color: Color(0xFF00236F),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: Color(0xFF00236F)),
                            const SizedBox(width: 12),
                            Container(
                              width: 32,
                              height: 32,
                              clipBehavior: Clip.antiAlias,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFE6E8EA),
                              ),
                              child: Image.network(
                                state.userAvatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.person_rounded, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        _SummaryCard(summary: state.summary),
                        const SizedBox(height: 24),
                        const _SectionTitle(title: 'Choose Payment Method'),
                        const SizedBox(height: 12),
                        ...state.methods.map(
                          (method) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PaymentMethodTile(
                              option: method,
                              selected: method.id == selectedMethod,
                              onTap: () {
                                ref.read(selectedPaymentMethodProvider.notifier).state = method.id;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.verified_user_rounded,
                              size: 18,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              state.securityLabel.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
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
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.88),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: const Color(0xFFE2E8F0).withOpacity(0.7)),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 35, 111, 0.06),
                    blurRadius: 24,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Total to pay',
                            style: TextStyle(
                              color: Color(0xFF757682),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.totalLabel,
                            style: const TextStyle(
                              color: Color(0xFF00236F),
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 58,
                        child: FilledButton(
                          onPressed: () {
                            context.go(RouteNames.orders);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF004941),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                state.payButtonLabel,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded),
                            ],
                          ),
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
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final PaymentSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Order Summary'),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(15, 23, 42, 0.05),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.productTitle,
                          style: const TextStyle(
                            color: Color(0xFF00236F),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          summary.deliveryLabel,
                          style: const TextStyle(
                            color: Color(0xFF757682),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF71F8E4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      summary.statusLabel.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF005048),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              ...summary.lineItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.label,
                        style: const TextStyle(
                          color: Color(0xFF444651),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        item.value,
                        style: TextStyle(
                          color: item.highlight ? const Color(0xFF00687A) : const Color(0xFF191C1E),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: Color(0xFFE6E8EA)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      color: Color(0xFF191C1E),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    summary.totalAmount,
                    style: const TextStyle(
                      color: Color(0xFF00236F),
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethodOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? const Color(0xFF1E3A8A) : Colors.black.withOpacity(0.05),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _iconBackground(option.iconKey),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _iconFor(option.iconKey),
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: const TextStyle(
                        color: Color(0xFF191C1E),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF757682),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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
                    color: selected ? const Color(0xFF1E3A8A) : const Color(0xFFC5C5D3),
                    width: 2,
                  ),
                  color: selected ? const Color(0xFF00236F) : Colors.transparent,
                ),
                child: selected
                    ? const Center(
                        child: SizedBox(
                          width: 8,
                          height: 8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF191C1E),
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

IconData _iconFor(String iconKey) {
  switch (iconKey) {
    case 'card':
      return Icons.credit_card_rounded;
    case 'cash':
      return Icons.payments_rounded;
    case 'wallet':
    default:
      return Icons.account_balance_wallet_rounded;
  }
}

Color _iconBackground(String iconKey) {
  switch (iconKey) {
    case 'card':
      return const Color(0xFF00687A);
    case 'cash':
      return const Color(0xFF444651);
    case 'wallet':
    default:
      return const Color(0xFF1E3A8A);
  }
}
