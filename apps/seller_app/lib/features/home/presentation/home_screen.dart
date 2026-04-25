import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/order.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/async_state_view.dart';
import '../models/seller_dashboard.dart';
import '../providers/home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(sellerDashboardProvider);
    final searchingOrders = ref.watch(searchingOrdersProvider);

    return dashboardState.when(
      data: (dashboard) => _SellerDashboardView(
        dashboard: dashboard,
        searchingOrders: searchingOrders,
      ),
      loading: () => const Scaffold(
        body: SafeArea(
          child: AsyncStateView(
            isLoading: true,
            hasError: false,
            child: SizedBox.shrink(),
          ),
        ),
      ),
      error: (_, __) => const Scaffold(
        body: SafeArea(
          child: AsyncStateView(
            isLoading: false,
            hasError: true,
            child: SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _SellerDashboardView extends ConsumerWidget {
  const _SellerDashboardView({
    required this.dashboard,
    required this.searchingOrders,
  });

  final SellerDashboard dashboard;
  final AsyncValue<List<Order>> searchingOrders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(sellerAvailabilityProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final currentDashboard = dashboard.copyWith(
      isOnline: isOnline,
      statusTitle: isOnline ? dashboard.statusTitle : 'You are offline',
      statusMessage: isOnline
          ? dashboard.statusMessage
          : 'Turn availability back on to receive nearby tanker requests.',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 128),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(dashboard: currentDashboard),
                  const SizedBox(height: 24),
                  _AvailabilityToggle(
                    isOnline: isOnline,
                    onChanged: (value) {
                      ref.read(sellerAvailabilityProvider.notifier).setOnline(value);
                    },
                  ),
                  const SizedBox(height: 20),
                  _EarningsOverview(dashboard: currentDashboard, colors: colors),
                  const SizedBox(height: 28),
                  _StatusArea(dashboard: currentDashboard),
                  const SizedBox(height: 28),
                  _SearchingOrdersSection(searchingOrders: searchingOrders),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _BottomNavBar(
              currentRoute: RouteNames.home,
              onTap: (route) {
                if (route == RouteNames.home) {
                  return;
                }
                context.go(route);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.dashboard});

  final SellerDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Image.network(
            dashboard.avatarUrl,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dashboard.businessName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dashboard.sellerName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F2E74),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF71F8E4).withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF71F8E4),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dashboard.isOnline ? 'ONLINE' : 'OFFLINE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: dashboard.isOnline
                      ? const Color(0xFF005048)
                      : const Color(0xFF757682),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const Icon(
          Icons.sensors_outlined,
          color: Color(0xFF0F2E74),
        ),
      ],
    );
  }
}

class _AvailabilityToggle extends StatelessWidget {
  const _AvailabilityToggle({
    required this.isOnline,
    required this.onChanged,
  });

  final bool isOnline;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F6),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleButton(
              label: 'Go Online',
              selected: isOnline,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _ToggleButton(
              label: 'Go Offline',
              selected: !isOnline,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF00236F), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(28),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x3300236F),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : const Color(0xFF757682),
          ),
        ),
      ),
    );
  }
}

class _EarningsOverview extends StatelessWidget {
  const _EarningsOverview({
    required this.dashboard,
    required this.colors,
  });

  final SellerDashboard dashboard;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 24,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Today's Earnings",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF00687A),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Text(
                    dashboard.todaysEarnings,
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF191C1E),
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      dashboard.earningsChangeLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4FDBC8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Divider(height: 1, color: Color(0xFFF2F4F6)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _MetaStat(
                      label: 'Active Time',
                      value: dashboard.activeTime,
                      alignEnd: false,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: const Color(0xFFE6E8EA),
                  ),
                  Expanded(
                    child: _MetaStat(
                      label: 'Efficiency',
                      value: dashboard.efficiencyLabel,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MiniStatCard(
                icon: Icons.local_shipping,
                iconColor: colors.primary,
                iconBackground: colors.primary.withValues(alpha: 0.06),
                value: dashboard.completedOrders.toString(),
                label: 'Orders Completed',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MiniStatCard(
                icon: Icons.star,
                iconColor: colors.secondary,
                iconBackground: colors.secondary.withValues(alpha: 0.06),
                value: dashboard.ratingToday.toStringAsFixed(1),
                label: 'Rating Today',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetaStat extends StatelessWidget {
  const _MetaStat({
    required this.label,
    required this.value,
    required this.alignEnd,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF757682),
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF191C1E),
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: iconColor),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF757682),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class _StatusArea extends StatelessWidget {
  const _StatusArea({required this.dashboard});

  final SellerDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFBFD4FF).withValues(alpha: 0.55),
                  blurRadius: 28,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.water_drop,
                  size: 42,
                  color: dashboard.isOnline
                      ? const Color(0xFF0F2E74)
                      : const Color(0xFF757682),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            dashboard.statusTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F2E74),
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              dashboard.statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF757682),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.currentRoute,
    required this.onTap,
  });

  final String currentRoute;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 18),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              label: 'Home',
              icon: Icons.home,
              active: currentRoute == RouteNames.home,
              onTap: () => onTap(RouteNames.home),
            ),
            _NavItem(
              label: 'Orders',
              icon: Icons.local_shipping,
              active: currentRoute == RouteNames.orders,
              onTap: () => onTap(RouteNames.orders),
            ),
            _NavItem(
              label: 'Earnings',
              icon: Icons.payments,
              active: currentRoute == RouteNames.earnings,
              onTap: () => onTap(RouteNames.earnings),
            ),
            _NavItem(
              label: 'Profile',
              icon: Icons.person,
              active: currentRoute == RouteNames.profile,
              onTap: () => onTap(RouteNames.profile),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFDCEBFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: active ? const Color(0xFF0F2E74) : const Color(0xFF6B7280),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color:
                    active ? const Color(0xFF0F2E74) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchingOrdersSection extends ConsumerWidget {
  const _SearchingOrdersSection({required this.searchingOrders});

  final AsyncValue<List<Order>> searchingOrders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(sellerAvailabilityProvider);

    return searchingOrders.when(
      data: (orders) {
        if (!isOnline) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 24,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.offline_bolt,
                        color: Color(0xFFDC2626),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Go online to receive orders',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        if (orders.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 24,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF71F8E4).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: Color(0xFF00687A),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'New Orders',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F2E74),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF71F8E4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${orders.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF004E5C),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...orders.take(3).map((order) => _OrderCard(order: order)),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _OrderCard extends ConsumerStatefulWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  ConsumerState<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<_OrderCard> {
  bool _isAccepting = false;
  bool _isUpdating = false;
  String? _errorMessage;

  Future<void> _acceptOrder() async {
    setState(() {
      _isAccepting = true;
      _errorMessage = null;
    });

    try {
      final auth = ref.watch(firebaseAuthProvider);
      final sellerId = auth.currentUser?.uid;
      if (sellerId == null) {
        setState(() {
          _isAccepting = false;
          _errorMessage = 'Seller not authenticated';
        });
        return;
      }

      // Check if seller is online before accepting
      final isOnline = ref.read(sellerAvailabilityProvider);
      if (!isOnline) {
        setState(() {
          _isAccepting = false;
          _errorMessage = 'You must be online to accept orders';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Go online to accept orders'),
              backgroundColor: Color(0xFFDC2626),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final orderService = ref.watch(orderServiceProvider);
      await orderService.acceptOrder(widget.order.id, sellerId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order accepted successfully!'),
            backgroundColor: Color(0xFF71F8E4),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isAccepting = false;
        _errorMessage = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'Failed to accept order'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _startDelivery() async {
    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      final orderService = ref.watch(orderServiceProvider);
      await orderService.updateOrderStatus(widget.order.id, 'ON_THE_WAY');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery started!'),
            backgroundColor: Color(0xFF71F8E4),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUpdating = false;
        _errorMessage = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'Failed to start delivery'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _markDelivered() async {
    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      final orderService = ref.watch(orderServiceProvider);
      await orderService.updateOrderStatus(widget.order.id, 'DELIVERED');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as delivered!'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUpdating = false;
        _errorMessage = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'Failed to mark as delivered'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.order.status;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECEEF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.order.tankSize}L Tank',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F2E74),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Payment: ${widget.order.paymentType}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF757682),
            ),
          ),
          const SizedBox(height: 12),
          _buildActionButton(status),
        ],
      ),
    );
  }

  Widget _buildActionButton(String status) {
    switch (status) {
      case 'SEARCHING':
        return FilledButton(
          onPressed: _isAccepting ? null : _acceptOrder,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00236F),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isAccepting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Accept Order',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        );
      case 'ASSIGNED':
        return FilledButton(
          onPressed: _isUpdating ? null : _startDelivery,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isUpdating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Start Delivery',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        );
      case 'ON_THE_WAY':
        return FilledButton(
          onPressed: _isUpdating ? null : _markDelivered,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isUpdating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Mark Delivered',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        );
      case 'DELIVERED':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Completed',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF10B981),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'SEARCHING':
        return const Color(0xFF71F8E4);
      case 'ASSIGNED':
        return const Color(0xFF3B82F6);
      case 'ON_THE_WAY':
        return const Color(0xFFF59E0B);
      case 'DELIVERED':
        return const Color(0xFF10B981);
      case 'CANCELLED':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
