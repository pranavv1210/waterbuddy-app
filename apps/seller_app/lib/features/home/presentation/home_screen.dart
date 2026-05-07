import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../../../models/order.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../providers/home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchingOrders = ref.watch(searchingOrdersProvider);
    final activeOrders = ref.watch(activeOrdersProvider);
    final isOnline = ref.watch(sellerAvailabilityProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark map background
      body: Stack(
        children: [
          // ── Simulated Map Layer ──
          Positioned.fill(
            child: _SimulatedMapBackground(isOnline: isOnline),
          ),

          // ── Top Online/Offline Toggle ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Align(
                alignment: Alignment.topCenter,
                child: _AvailabilityToggle(
                  isOnline: isOnline,
                  onChanged: (value) {
                    ref.read(sellerAvailabilityProvider.notifier).setOnline(value);
                  },
                ),
              ),
            ),
          ),

          // ── Bottom Sheet (Earnings / Status) ──
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusBottomSheet(
                  isOnline: isOnline,
                  activeOrders: activeOrders,
                ),
                _BottomNavBar(
                  currentRoute: RouteNames.home,
                  onTap: (route) {
                    if (route != RouteNames.home) {
                      context.go(route);
                    }
                  },
                ),
              ],
            ),
          ),

          // ── New Request Overlay (Uber Style) ──
          searchingOrders.when(
            data: (orders) {
              if (!isOnline || orders.isEmpty) return const SizedBox.shrink();
              final request = orders.first;
              return _NewRequestOverlay(order: request);
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Simulated Map Background
// ─────────────────────────────────────────────────────────────────────────────
class _SimulatedMapBackground extends StatefulWidget {
  final bool isOnline;
  const _SimulatedMapBackground({required this.isOnline});

  @override
  State<_SimulatedMapBackground> createState() => _SimulatedMapBackgroundState();
}

class _SimulatedMapBackgroundState extends State<_SimulatedMapBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MapGridPainter(),
      child: Center(
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: 32 * (widget.isOnline ? _pulseAnimation.value : 1.0),
              height: 32 * (widget.isOnline ? _pulseAnimation.value : 1.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isOnline
                    ? const Color(0xFF10B981).withOpacity(0.3)
                    : const Color(0xFFEF4444).withOpacity(0.3),
              ),
              child: Center(
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: widget.isOnline
                            ? const Color(0xFF10B981).withOpacity(0.5)
                            : const Color(0xFFEF4444).withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 4,
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const double spacing = 60;
    
    // Draw vertical lines
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    
    // Draw horizontal lines
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Draw some random "roads" to look like a map
    final roadPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.4), roadPaint);
    canvas.drawLine(Offset(size.width * 0.6, 0), Offset(size.width * 0.4, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.2, size.height * 0.6), Offset(size.width, size.height * 0.8), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Toggle (Online / Offline)
// ─────────────────────────────────────────────────────────────────────────────
class _AvailabilityToggle extends StatelessWidget {
  const _AvailabilityToggle({required this.isOnline, required this.onChanged});

  final bool isOnline;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isOnline),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: isOnline
                  ? const Color(0xFF10B981).withOpacity(0.4)
                  : const Color(0xFFEF4444).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOnline ? Icons.power_rounded : Icons.power_off_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isOnline ? 'YOU\'RE ONLINE' : 'YOU\'RE OFFLINE',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Sheet (Earnings / Status)
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBottomSheet extends StatelessWidget {
  const _StatusBottomSheet({required this.isOnline, required this.activeOrders});

  final bool isOnline;
  final AsyncValue<List<Order>> activeOrders;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          if (!isOnline)
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Text(
                'You are offline. Go online to start receiving water delivery requests.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  const Text(
                    'Finding Deliveries...',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  activeOrders.when(
                    data: (orders) {
                      if (orders.isEmpty) {
                        return const Center(
                          child: Text(
                            'No active deliveries. Wait for requests.',
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active Deliveries',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...orders.map((o) => _ActiveDeliveryTile(order: o)),
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActiveDeliveryTile extends ConsumerWidget {
  final Order order;
  const _ActiveDeliveryTile({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.water_drop, color: Color(0xFF0EA5E9)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${order.tankSize}L Delivery',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  order.location['address'] ?? 'Unknown location',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () {
              // Mark as delivered / start delivery logic
              final orderService = ref.read(orderServiceProvider);
              if (order.status == 'ASSIGNED') {
                orderService.updateOrderStatus(order.id, 'ON_THE_WAY');
              } else if (order.status == 'ON_THE_WAY') {
                orderService.updateOrderStatus(order.id, 'DELIVERED');
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF064E3B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(order.status == 'ASSIGNED' ? 'START' : 'DONE'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Nav Bar (Uber / Ola Style)
// ─────────────────────────────────────────────────────────────────────────────
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.currentRoute, required this.onTap});

  final String currentRoute;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 24, top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            isActive: currentRoute == RouteNames.home,
            onTap: () => onTap(RouteNames.home),
          ),
          _NavItem(
            icon: Icons.receipt_long_rounded,
            label: 'Earnings',
            isActive: currentRoute == RouteNames.earnings,
            onTap: () => onTap(RouteNames.earnings),
          ),
          _NavItem(
            icon: Icons.person_rounded,
            label: 'Account',
            isActive: currentRoute == RouteNames.profile,
            onTap: () => onTap(RouteNames.profile),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF064E3B) : const Color(0xFF94A3B8);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ride Request Overlay (Uber Style)
// ─────────────────────────────────────────────────────────────────────────────
class _NewRequestOverlay extends ConsumerStatefulWidget {
  const _NewRequestOverlay({required this.order});
  final Order order;

  @override
  ConsumerState<_NewRequestOverlay> createState() => _NewRequestOverlayState();
}

class _NewRequestOverlayState extends ConsumerState<_NewRequestOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _timerController;
  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // 15 seconds to accept
    )..reverse(from: 1.0);

    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        // Ignored request
      }
    });
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  Future<void> _acceptOrder() async {
    if (_isAccepting) return;
    setState(() => _isAccepting = true);

    try {
      final auth = ref.read(firebaseAuthProvider);
      final sellerId = auth.currentUser?.uid;
      if (sellerId != null) {
        await ref.read(orderServiceProvider).acceptOrder(widget.order.id, sellerId);
      }
    } catch (e) {
      setState(() => _isAccepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.6), // Dim background
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 32,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulse radar icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.settings_input_antenna, color: Color(0xFF10B981), size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'NEW REQUEST',
                style: TextStyle(
                  color: Color(0xFF064E3B),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              // Price estimation
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text('est. ', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
                  Text(
                    '₹${(widget.order.tankSize * 0.15).toStringAsFixed(0)}', // Rough dummy estimation for display
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF334155)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.order.tankSize}L Tanker Delivery',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.order.location['address'] ?? 'Customer Location',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Accept button with timer ring
              GestureDetector(
                onTap: _isAccepting ? null : _acceptOrder,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: AnimatedBuilder(
                        animation: _timerController,
                        builder: (context, child) {
                          return CircularProgressIndicator(
                            value: _timerController.value,
                            strokeWidth: 6,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                          );
                        },
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: _isAccepting
                          ? const Center(child: CircularProgressIndicator(color: Colors.white))
                          : const Center(
                              child: Text(
                                'TAP TO\nACCEPT',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  // Ignore logic (would normally call API to reject)
                },
                child: const Text(
                  'Decline',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
