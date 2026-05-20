import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../routes/route_names.dart';
import '../../../providers/app_providers.dart';
import '../models/searching_tankers_state.dart';
import '../providers/searching_providers.dart';

class SearchingTankersScreen extends ConsumerStatefulWidget {
  const SearchingTankersScreen({super.key});

  @override
  ConsumerState<SearchingTankersScreen> createState() =>
      _SearchingTankersScreenState();
}

class _SearchingTankersScreenState extends ConsumerState<SearchingTankersScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderId = GoRouterState.of(context).uri.queryParameters['orderId'];
      if (orderId != null) {
        ref.read(searchingControllerProvider.notifier).startWatchingOrder(orderId);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchingState = ref.watch(searchingControllerProvider);
    final activeOrder = ref.watch(activeOrderProvider).value;

    ref.listen(searchingControllerProvider, (previous, next) {
      if (next.orderStatus == 'ASSIGNED' && next.orderId != null) {
        context.go('${RouteNames.tracking}?orderId=${next.orderId}');
      }
    });

    if (searchingState.hasTimedOut) {
      return _TimeoutView(onRetry: () => context.go(RouteNames.home));
    }

    final body = Scaffold(
      body: Stack(
        children: [
          // 1. Map Background
          FlutterMap(
            options: MapOptions(
              initialCenter: activeOrder?.location != null 
                ? LatLng(activeOrder!.location!['latitude'], activeOrder!.location!['longitude'])
                : const LatLng(12.9716, 77.5946),
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.waterbuddy.customer',
              ),
              if (activeOrder?.location != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(activeOrder!.location!['latitude'], activeOrder!.location!['longitude']),
                      width: 80,
                      height: 80,
                      child: _buildSearchingMarker(),
                    ),
                  ],
                ),
            ],
          ),

          // 2. Rapido-style Status Overlay (Top)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Waiting for Partner to accept',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: _controller.value,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Rapido-style Info Overlay (Bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Captains Progress
                  const Text(
                    '4 of 197 partners didn\'t accept your request',
                    style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.05, // Just a small progress for demo
                      backgroundColor: Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0EA5E9)),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Order Details Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      children: [
                        Image.asset('assets/ui/tanker.png', width: 40, height: 40, errorBuilder: (_, __, ___) => const Icon(Icons.water_drop, color: Colors.blue)),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Fare', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text('₹168', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFF1F5F9)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Order Details', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: TextButton(
                      onPressed: () async {
                        await ref.read(searchingControllerProvider.notifier).cancelOrder();
                        if (context.mounted) context.go(RouteNames.home);
                      },
                      child: const Text('Cancel Request', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await ref.read(searchingControllerProvider.notifier).cancelOrder();
        if (context.mounted) context.go(RouteNames.home);
      },
      child: body,
    );
  }

  Widget _buildSearchingMarker() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 60 * _controller.value,
              height: 60 * _controller.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.3 * (1 - _controller.value)),
              ),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TimeoutView extends StatelessWidget {
  const _TimeoutView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_off_rounded, size: 64, color: Colors.red),
            const SizedBox(height: 24),
            const Text('No partners available', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Please try again in a few minutes', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
