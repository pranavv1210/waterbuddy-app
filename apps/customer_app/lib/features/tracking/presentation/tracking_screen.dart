import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../routes/route_names.dart';
import '../../../widgets/async_state_view.dart';
import '../models/assigned_order_tracking.dart';
import '../providers/tracking_providers.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  @override
  void initState() {
    super.initState();
    
    // Get orderId from query params and start watching
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderId = GoRouterState.of(context).uri.queryParameters['orderId'];
      if (orderId != null) {
        ref.read(trackingControllerProvider.notifier).startWatchingOrder(orderId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingControllerProvider);
    final uiState = ref.watch(assignedOrderTrackingProvider);

    if (trackingState.errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 64, color: Color(0xFFEF4444)),
                  const SizedBox(height: 24),
                  const Text(
                    'Something went wrong',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F2B5B)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    trackingState.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(trackingControllerProvider.notifier).clearError();
                        context.go(RouteNames.home);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F2B5B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Back to Home'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return uiState.when(
      data: (state) => _TrackingScreenBody(state: state, trackingState: trackingState),
      error: (err, __) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading tracking: $err'),
              TextButton(onPressed: () => context.go(RouteNames.home), child: const Text('Go Home')),
            ],
          ),
        ),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _TrackingScreenBody extends StatelessWidget {
  const _TrackingScreenBody({required this.state, required this.trackingState});

  final AssignedOrderTracking state;
  final TrackingState trackingState;

  Future<void> _callDriver(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F2B5B);
    const accentColor = Color(0xFF0EA5E9);

    final statusTitle = _getStatusTitle(trackingState.orderStatus);
    final statusSubtitle = _getStatusSubtitle(trackingState.orderStatus);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Map Placeholder / Real Map
          Positioned.fill(
            child: Container(
              color: const Color(0xFFE2E8F0),
              child: const Center(
                child: Icon(Icons.map_rounded, size: 64, color: Color(0xFF94A3B8)),
              ),
            ),
          ),

          // Header with Back Button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 16, right: 16, bottom: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: primaryColor),
                      onPressed: () => context.go(RouteNames.home),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Order Status',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Content Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pull Handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    statusTitle,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: primaryColor,
                                    ),
                                  ),
                                  Text(
                                    statusSubtitle,
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.water_drop_rounded, color: accentColor),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Driver & Vehicle Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: const Color(0xFFE2E8F0),
                                    backgroundImage: state.driver.avatarUrl.isNotEmpty
                                        ? NetworkImage(state.driver.avatarUrl)
                                        : null,
                                    child: state.driver.avatarUrl.isEmpty
                                        ? const Icon(Icons.person_rounded, color: Color(0xFF64748B))
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
                                              state.driver.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: primaryColor,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF22C55E)),
                                          ],
                                        ),
                                        Text(
                                          '${state.vehicle.typeLabel} • ${state.vehicle.plateLabel}',
                                          style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                                            const SizedBox(width: 4),
                                            Text(
                                              state.driver.ratingLabel,
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              state.driver.deliveriesLabel,
                                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24, color: Color(0xFFF1F5F9)),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _callDriver(state.driver.phoneNumber),
                                      icon: const Icon(Icons.call_rounded, size: 20),
                                      label: const Text('Call Driver'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {}, // Chat placeholder
                                      icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                                      label: const Text('Message'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: primaryColor,
                                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Delivery Info
                        Row(
                          children: [
                            _InfoChip(
                              icon: Icons.water_damage_rounded,
                              label: state.vehicle.capacityLabel,
                              title: 'Volume',
                            ),
                            const SizedBox(width: 12),
                            _InfoChip(
                              icon: Icons.timer_rounded,
                              label: state.estimatedArrival,
                              title: 'ETA',
                            ),
                            const SizedBox(width: 12),
                            _InfoChip(
                              icon: Icons.payment_rounded,
                              label: state.orderSummary.amountLabel,
                              title: 'Payment',
                            ),
                          ],
                        ),
                        
                        // Safety buffer for bottom navigation if any
                        SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'ASSIGNED':
        return 'Partner Assigned';
      case 'ON_THE_WAY':
        return 'Tanker on the way';
      case 'DELIVERED':
        return 'Order Delivered';
      case 'CANCELLED':
        return 'Order Cancelled';
      default:
        return 'Tracking Order';
    }
  }

  String _getStatusSubtitle(String status) {
    switch (status) {
      case 'ASSIGNED':
        return 'The driver is preparing your delivery';
      case 'ON_THE_WAY':
        return 'Heading towards your location now';
      case 'DELIVERED':
        return 'Thank you for using WaterBuddy!';
      case 'CANCELLED':
        return 'This order was cancelled';
      default:
        return 'Real-time status updates';
    }
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.title,
  });

  final IconData icon;
  final String label;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF64748B)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F2B5B)),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
