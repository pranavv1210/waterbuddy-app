import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/order.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import 'cancellation_sheet.dart';
import '../../tracking/providers/tracking_providers.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Provider
// ──────────────────────────────────────────────────────────────────────────────

final _sellerDataProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, String>(
  (ref, sellerId) async {
    final snap = await FirebaseFirestore.instance
        .collection('sellers')
        .doc(sellerId)
        .get();
    return snap.data();
  },
);

// ──────────────────────────────────────────────────────────────────────────────
// Screen
// ──────────────────────────────────────────────────────────────────────────────

class OrderDetailsScreen extends ConsumerWidget {
  const OrderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderId =
        GoRouterState.of(context).uri.queryParameters['orderId'] ?? '';

    if (orderId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Order ID missing')),
      );
    }

    final orderAsync = ref.watch(orderStreamProvider(orderId));

    return orderAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8))),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (order) {
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Order Details')),
            body: const Center(child: Text('Order not found')),
          );
        }
        return _OrderDetailsBody(order: order);
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Body
// ──────────────────────────────────────────────────────────────────────────────

class _OrderDetailsBody extends ConsumerWidget {
  const _OrderDetailsBody({required this.order});

  final Order order;

  static const _primary = Color(0xFF0F172A);
  static const _accent = Color(0xFF38BDF8);
  static const _bg = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerAsync = order.sellerId != null
        ? ref.watch(_sellerDataProvider(order.sellerId!))
        : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(RouteNames.orders);
        }
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(context, order),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),

                  // ── Order Info ───────────────────────────────────────────────
                  _SectionCard(
                    title: 'Order Info',
                    icon: Icons.water_drop_rounded,
                    iconColor: _accent,
                    children: [
                      _InfoRow(
                        label: 'Tank Size',
                        value: '${order.tankSize.toInt()} Litres',
                      ),
                      _InfoRow(
                        label: 'Payment Method',
                        value: order.paymentType,
                      ),
                      if (order.amount > 0)
                        _InfoRow(
                          label: 'Order Amount',
                          value: 'Rs ${order.amount.toInt()}',
                        ),
                      _InfoRow(
                        label: 'Payment Status',
                        value: order.paymentStatus,
                      ),
                      _InfoRow(
                        label: 'Order ID',
                        value: '#${order.id.substring(0, 8).toUpperCase()}',
                        trailing: IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.copy_rounded,
                              size: 16, color: Color(0xFF94A3B8)),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: order.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Order ID copied'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Delivery Details ─────────────────────────────────────────
                  _SectionCard(
                    title: 'Delivery Details',
                    icon: Icons.location_on_rounded,
                    iconColor: const Color(0xFFEF4444),
                    children: [
                      _InfoRow(
                        label: 'Address',
                        value: order.location['address'] as String? ??
                            'Unknown location',
                      ),
                      if (order.createdAt != null)
                        _InfoRow(
                          label: 'Ordered At',
                          value: _formatDateTime(order.createdAt!.toDate()),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Driver Info ──────────────────────────────────────────────
                  if (order.sellerId != null)
                    sellerAsync!.when(
                      data: (seller) => seller != null
                          ? _DriverCard(seller: seller)
                          : const SizedBox.shrink(),
                      loading: () => const _LoadingCard(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                  if (order.sellerId != null) const SizedBox(height: 16),

                  // ── Timeline ─────────────────────────────────────────────────
                  _TimelineCard(status: order.status),

                  const SizedBox(height: 16),

                  // ── CTA Buttons ──────────────────────────────────────────────
                  _CtaButtons(order: order),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Order order) {
    final statusColor = _statusColor(order.status);

    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: _primary,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () =>
            context.canPop() ? context.pop() : context.go(RouteNames.orders),
      ),
      title: const Text(
        'Order Details',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0095F6),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 64, 24, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${order.tankSize.toInt()}L Water Tank',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '#${order.id.substring(0, 8).toUpperCase()}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.5),
                          width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(order.status),
                            color: statusColor, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          _statusLabel(order.status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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

  // Helpers
  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
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
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final min = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.day} ${months[local.month]} ${local.year}, $hour:$min $period';
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'SEARCHING':
        return const Color(0xFF38BDF8);
      case 'ACCEPTED':
      case 'ASSIGNED':
        return const Color(0xFF8B5CF6);
      case 'DRIVER_ASSIGNED':
        return const Color(0xFF6366F1);
      case 'ON_THE_WAY':
        return const Color(0xFFF59E0B);
      case 'ARRIVED':
        return const Color(0xFF14B8A6);
      case 'DELIVERED':
        return const Color(0xFF10B981);
      case 'CANCELLED':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  static IconData _statusIcon(String status) {
    switch (status) {
      case 'SEARCHING':
        return Icons.search_rounded;
      case 'ACCEPTED':
      case 'ASSIGNED':
        return Icons.handshake_rounded;
      case 'DRIVER_ASSIGNED':
        return Icons.person_pin_circle_rounded;
      case 'ON_THE_WAY':
        return Icons.local_shipping_rounded;
      case 'ARRIVED':
        return Icons.location_on_rounded;
      case 'DELIVERED':
        return Icons.check_circle_rounded;
      case 'CANCELLED':
        return Icons.cancel_rounded;
      default:
        return Icons.water_drop_rounded;
    }
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'SEARCHING':
        return 'Searching';
      case 'ACCEPTED':
      case 'ASSIGNED':
        return 'Accepted';
      case 'DRIVER_ASSIGNED':
        return 'Driver Assigned';
      case 'ON_THE_WAY':
        return 'On the Way';
      case 'ARRIVED':
        return 'Arrived';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Driver Card
// ──────────────────────────────────────────────────────────────────────────────

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.seller});

  final Map<String, dynamic> seller;

  @override
  Widget build(BuildContext context) {
    final name = seller['name'] as String? ?? 'Unknown Driver';
    final phone = seller['phone'] as String? ?? '';
    final rating = seller['rating'];
    final ratingStr = rating != null ? rating.toString() : '—';
    final photoUrl = seller['photoUrl'] as String?;
    final totalOrders = seller['totalOrders'] as int?;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Driver',
            icon: Icons.person_pin_circle_rounded,
            iconColor: Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    const Color(0xFF0F172A).withValues(alpha: 0.08),
                backgroundImage:
                    photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? const Icon(Icons.person_rounded,
                        color: Color(0xFF0F172A), size: 28)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded,
                            size: 16, color: Color(0xFF22C55E)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 4),
                        Text(
                          ratingStr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (totalOrders != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '$totalOrders+ deliveries',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (phone.isNotEmpty)
                IconButton(
                  onPressed: () async {
                    final uri = Uri(scheme: 'tel', path: phone);
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.call_rounded,
                        color: Color(0xFF10B981), size: 20),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Timeline Card
// ──────────────────────────────────────────────────────────────────────────────

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.status});

  final String status;

  static const _steps = [
    (icon: Icons.search_rounded, label: 'Order placed', status: 'SEARCHING'),
    (
      icon: Icons.handshake_rounded,
      label: 'Tanker accepted',
      status: 'ACCEPTED'
    ),
    (
      icon: Icons.person_pin_circle_rounded,
      label: 'Driver assigned',
      status: 'DRIVER_ASSIGNED'
    ),
    (
      icon: Icons.local_shipping_rounded,
      label: 'On the way',
      status: 'ON_THE_WAY'
    ),
    (icon: Icons.location_on_rounded, label: 'Arrived', status: 'ARRIVED'),
    (icon: Icons.check_circle_rounded, label: 'Delivered', status: 'DELIVERED'),
  ];

  static const _order = [
    'SEARCHING',
    'ACCEPTED',
    'DRIVER_ASSIGNED',
    'ON_THE_WAY',
    'ARRIVED',
    'DELIVERED',
  ];

  String _normalizedStatus(String value) {
    if (value == 'ASSIGNED') return 'ACCEPTED';
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = status == 'CANCELLED';
    final currentIndex = _order.indexOf(_normalizedStatus(status));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: isCancelled ? 'Order Cancelled' : 'Order Timeline',
            icon: isCancelled ? Icons.cancel_rounded : Icons.timeline_rounded,
            iconColor:
                isCancelled ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
          ),
          const SizedBox(height: 20),
          if (isCancelled)
            const _CancelledBanner()
          else
            Column(
              children: List.generate(_steps.length, (i) {
                final step = _steps[i];
                final isDone = currentIndex >= i;
                final isActive = currentIndex == i;
                final isLast = i == _steps.length - 1;

                return _TimelineStep(
                  icon: step.icon,
                  label: step.label,
                  isDone: isDone,
                  isActive: isActive,
                  isLast: isLast,
                );
              }),
            ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.icon,
    required this.label,
    required this.isDone,
    required this.isActive,
    required this.isLast,
  });

  final IconData icon;
  final String label;
  final bool isDone;
  final bool isActive;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    const doneColor = Color(0xFF10B981);
    const activeColor = Color(0xFF38BDF8);
    const pendingColor = Color(0xFFE2E8F0);

    final circleColor =
        isDone ? (isActive ? activeColor : doneColor) : pendingColor;
    final lineColor = isDone ? doneColor : pendingColor;
    final textColor =
        isDone ? const Color(0xFF0F172A) : const Color(0xFF94A3B8);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
                boxShadow: isDone
                    ? [
                        BoxShadow(
                          color: circleColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon,
                  color: isDone ? Colors.white : const Color(0xFFCBD5E1),
                  size: 18),
            ),
            if (!isLast)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 2,
                height: 32,
                color: lineColor,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Padding(
          padding: EdgeInsets.only(top: 10, bottom: isLast ? 0 : 32),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
        if (isActive) ...[
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'CURRENT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF38BDF8),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CancelledBanner extends StatelessWidget {
  const _CancelledBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFFEF4444), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'This order was cancelled and will not be fulfilled.',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// CTA Buttons
// ──────────────────────────────────────────────────────────────────────────────

class _CtaButtons extends ConsumerWidget {
  const _CtaButtons({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cancellable = {
      'SEARCHING',
      'ACCEPTED',
      'ASSIGNED',
      'DRIVER_ASSIGNED',
      'ON_THE_WAY',
      'ARRIVED',
    }.contains(order.status);
    final trackable = {
      'ACCEPTED',
      'ASSIGNED',
      'DRIVER_ASSIGNED',
      'ON_THE_WAY',
      'ARRIVED',
    }.contains(order.status);
    final delivered = order.status == 'DELIVERED';
    final settings = ref.watch(systemSettingsProvider).valueOrNull;

    return Column(
      children: [
        if (order.status == 'SEARCHING')
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {
                context.go('${RouteNames.searching}?orderId=${order.id}');
              },
              icon: const Icon(Icons.radar_rounded, size: 18),
              label: const Text('View Search',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        if (trackable)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {
                context.go('${RouteNames.tracking}?orderId=${order.id}');
              },
              icon: const Icon(Icons.map_rounded, size: 18),
              label: const Text('Track Order',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        if (cancellable) const SizedBox(height: 12),
        if (cancellable)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () async {
                final reason = await showCancellationReasonSheet(context,
                    status: order.status,
                    cancellationCharge: settings?.cancellationCharge ?? 0);
                if (reason == null || !context.mounted) return;
                await ref
                    .read(orderServiceProvider)
                    .cancelOrder(orderId: order.id, reason: reason);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order cancelled')),
                  );
                  context.go(RouteNames.orders);
                }
              },
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Cancel Request',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        if (delivered) ...[
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Invoice details are on this order.')),
                );
              },
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: const Text('View Invoice',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed: () => context.go(RouteNames.home),
            icon: const Icon(Icons.water_drop_rounded, size: 18),
            label: const Text('Book Again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F2B5B),
              side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Reusable components
// ──────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title, icon: icon, iconColor: iconColor),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      alignment: Alignment.center,
      decoration: _cardDecoration(),
      child: const CircularProgressIndicator(
          color: Color(0xFF0F2B5B), strokeWidth: 2),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Helper
// ──────────────────────────────────────────────────────────────────────────────

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
