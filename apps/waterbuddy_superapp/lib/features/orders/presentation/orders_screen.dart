import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/order.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/premium_ui.dart';
import '../providers/order_providers.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(orderHistoryProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: WbColors.surface,
        body: Stack(
          children: [
            // Subtle ambient background
            const AbstractWaterBackground(),

            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.go(RouteNames.home),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order History',
                                style: TextStyle(
                                  color: WbColors.ink,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const Text(
                                'All your water deliveries',
                                style: TextStyle(
                                  color: WbColors.muted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1),
                  ),

                  const SizedBox(height: 16),

                  // Body content
                  Expanded(
                    child: historyAsync.when(
                      data: (orders) => orders.isEmpty
                          ? const _EmptyState()
                          : _OrderList(orders: orders),
                      loading: () => const _LoadingState(),
                      error: (e, _) => _ErrorState(error: e.toString()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _OrderList extends StatelessWidget {
  const _OrderList({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    // Group orders by date
    final Map<String, List<Order>> grouped = {};
    for (final order in orders) {
      final label = _dateLabel(order.createdAt);
      grouped.putIfAbsent(label, () => []).add(order);
    }

    final sections = grouped.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: sections.length,
      itemBuilder: (context, sectionIndex) {
        final sectionLabel = sections[sectionIndex].key;
        final sectionOrders = sections[sectionIndex].value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: WbColors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    sectionLabel.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: WbColors.muted,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (sectionIndex * 80).ms),
            ...sectionOrders.asMap().entries.map((e) {
              return _OrderCard(order: e.value)
                  .animate()
                  .fadeIn(delay: (sectionIndex * 80 + e.key * 60).ms)
                  .slideY(begin: 0.06, end: 0);
            }),
          ],
        );
      },
    );
  }

  String _dateLabel(Timestamp? ts) {
    if (ts == null) return 'Unknown date';
    final dt = ts.toDate().toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final orderDay = DateTime(dt.year, dt.month, dt.day);

    if (orderDay == today) return 'Today';
    if (orderDay == yesterday) return 'Yesterday';

    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _OrderCard extends StatefulWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(widget.order.status);
    final statusIcon = _statusIcon(widget.order.status);
    final address =
        widget.order.location['address'] as String? ?? 'Unknown location';
    final timeStr = _formatTime(widget.order.createdAt);
    final isActive = widget.order.status == 'SEARCHING' ||
        widget.order.status == 'ASSIGNED' ||
        widget.order.status == 'ON_THE_WAY';

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.selectionClick();
        context.push(
            '${RouteNames.orderDetails}?orderId=${widget.order.id}');
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isActive
                  ? statusColor.withValues(alpha: 0.30)
                  : WbColors.line,
              width: isActive ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? statusColor.withValues(alpha: 0.10)
                    : WbColors.ink.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    // Icon container
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.order.tankSize.toInt()}L Water Tank',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: WbColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeStr,
                            style: const TextStyle(
                              fontSize: 12,
                              color: WbColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.20)),
                      ),
                      child: Text(
                        _statusLabel(widget.order.status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Divider(height: 1, color: WbColors.line),
              ),

              // Bottom row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 13, color: WbColors.muted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: WbColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: WbColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: WbColors.line),
                      ),
                      child: Text(
                        widget.order.paymentType,
                        style: const TextStyle(
                          fontSize: 10,
                          color: WbColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: WbColors.muted),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'SEARCHING':
        return 'Searching';
      case 'ASSIGNED':
        return 'Assigned';
      case 'ON_THE_WAY':
        return 'On the Way';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'SEARCHING':
        return WbColors.blue;
      case 'ASSIGNED':
        return const Color(0xFF8B5CF6);
      case 'ON_THE_WAY':
        return WbColors.amber;
      case 'DELIVERED':
        return WbColors.green;
      case 'CANCELLED':
        return WbColors.red;
      default:
        return WbColors.muted;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'SEARCHING':
        return Icons.search_rounded;
      case 'ASSIGNED':
        return Icons.person_pin_circle_rounded;
      case 'ON_THE_WAY':
        return Icons.local_shipping_rounded;
      case 'DELIVERED':
        return Icons.check_circle_rounded;
      case 'CANCELLED':
        return Icons.cancel_rounded;
      default:
        return Icons.water_drop_rounded;
    }
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate().toLocal();
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $period';
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with glass effect
            ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: WbColors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                        color: WbColors.blue.withValues(alpha: 0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: WbColors.blue.withValues(alpha: 0.10),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    size: 52,
                    color: WbColors.blue,
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).scale(
                begin: const Offset(0.85, 0.85),
                curve: Curves.easeOutBack),
            const SizedBox(height: 28),
            const Text(
              'No orders yet',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: WbColors.ink,
                letterSpacing: -0.5,
              ),
            ).animate(delay: 120.ms).fadeIn().slideY(begin: 0.08),
            const SizedBox(height: 10),
            const Text(
              'Your water delivery history\nwill appear here once you place an order.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: WbColors.muted,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 36),
            GestureDetector(
              onTap: () => context.go(RouteNames.home),
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 28),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.water_drop_rounded,
                        color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Book Water Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.12),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: List.generate(
        5,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: WbColors.line),
            ),
            child: const WbShimmer(
              width: double.infinity,
              height: 100,
              borderRadius: 24,
            ),
          ).animate(delay: (i * 60).ms).fadeIn(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: WbColors.red.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(color: WbColors.red.withValues(alpha: 0.20)),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: WbColors.red, size: 34),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load orders',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: WbColors.ink,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: WbColors.muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
