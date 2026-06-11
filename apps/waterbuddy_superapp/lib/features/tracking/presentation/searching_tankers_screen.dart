import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../orders/presentation/cancellation_sheet.dart';
import '../providers/searching_providers.dart';

class SearchingTankersScreen extends ConsumerStatefulWidget {
  const SearchingTankersScreen({super.key});

  @override
  ConsumerState<SearchingTankersScreen> createState() =>
      _SearchingTankersScreenState();
}

class _SearchingTankersScreenState extends ConsumerState<SearchingTankersScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _radarController;
  Timer? _statusTimer;
  int _statusIndex = 0;
  bool _cancelOpen = false;

  static const _statuses = [
    'Searching nearby tankers...',
    'Matching with owners...',
    'Finding fastest delivery...',
    'Waiting for owner response...',
  ];

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _statusTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() => _statusIndex = (_statusIndex + 1) % _statuses.length);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderId = GoRouterState.of(context).uri.queryParameters['orderId'];
      if (orderId != null && orderId.isNotEmpty) {
        ref
            .read(searchingControllerProvider.notifier)
            .startWatchingOrder(orderId);
      }
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _confirmCancel(String status) async {
    if (_cancelOpen) return;
    _cancelOpen = true;
    final reason = await showCancellationReasonSheet(context, status: status);
    _cancelOpen = false;
    if (reason == null || !mounted) return;
    await ref.read(searchingControllerProvider.notifier).cancelOrder(
          reason: reason,
        );
    if (mounted) context.go(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    final searchingState = ref.watch(searchingControllerProvider);
    final activeOrder = ref.watch(activeOrderProvider).value;
    final status = searchingState.orderStatus;

    ref.listen(searchingControllerProvider, (previous, next) {
      final nextStatus = next.orderStatus;
      if (next.orderId == null) return;
      if (nextStatus == 'ACCEPTED' ||
          nextStatus == 'ASSIGNED' ||
          nextStatus == 'DRIVER_ASSIGNED' ||
          nextStatus == 'ON_THE_WAY' ||
          nextStatus == 'ARRIVED') {
        context.go('${RouteNames.tracking}?orderId=${next.orderId}');
      }
      if (nextStatus == 'CANCELLED') {
        context.go(RouteNames.home);
      }
    });

    if (searchingState.hasTimedOut) {
      return _TimeoutView(onRetry: () => context.go(RouteNames.home));
    }

    final location = activeOrder?.location;
    final lat = (location?['latitude'] as num?)?.toDouble() ?? 12.9716;
    final lng = (location?['longitude'] as num?)?.toDouble() ?? 77.5946;
    final address =
        (location?['address'] as String?) ?? 'Water delivery location';
    final tankSize = activeOrder?.tankSize.toInt();
    final nearbyCount = ref.watch(onlineSellersProvider).valueOrNull?.length ?? 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmCancel(status);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(lat, lng),
                zoom: 15,
              ),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
              tiltGesturesEnabled: false,
              rotateGesturesEnabled: false,
            ),
            Center(
              child: SizedBox(
                width: 150,
                height: 150,
                child: _RadarMarker(animation: _radarController),
              ),
            ),
            Container(color: Colors.white.withValues(alpha: 0.18)),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 14,
              left: 18,
              right: 18,
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.close_rounded,
                    onTap: () => _confirmCancel(status),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SearchingStatusCard(
                      animation: _radarController,
                      status: _statuses[_statusIndex],
                      address: address,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              top: MediaQuery.sizeOf(context).height * 0.30,
              child: _DispatchAnimation(animation: _radarController),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _SearchingBottomPanel(
                statusText: _statuses[_statusIndex],
                tankSize: tankSize,
                orderId: searchingState.orderId,
                nearbyCount: nearbyCount,
                onCancel: () => _confirmCancel(status),
                onDetails: searchingState.orderId == null
                    ? null
                    : () => context.push(
                          '${RouteNames.orderDetails}?orderId=${searchingState.orderId}',
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchingStatusCard extends StatelessWidget {
  const _SearchingStatusCard({
    required this.animation,
    required this.status,
    required this.address,
  });

  final Animation<double> animation;
  final String status;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop_rounded,
                  color: Color(0xFF0EA5E9), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    status,
                    key: ValueKey(status),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 4,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  return Stack(
                    children: [
                      Container(color: const Color(0xFFE0F2FE)),
                      FractionallySizedBox(
                        widthFactor: 0.32,
                        child: Transform.translate(
                          offset: Offset(
                            (MediaQuery.sizeOf(context).width - 80) *
                                animation.value,
                            0,
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF0095F6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DispatchAnimation extends StatelessWidget {
  const _DispatchAnimation({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                Transform.scale(
                  scale: 0.65 + ((animation.value + (i * 0.33)) % 1) * 1.65,
                  child: Opacity(
                    opacity: 1 - ((animation.value + (i * 0.33)) % 1),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0EA5E9),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.18),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(Icons.water_drop_rounded,
                    color: Color(0xFF0EA5E9), size: 42),
              ),
              for (var i = 0; i < 5; i++)
                Transform.translate(
                  offset: Offset(
                    math.cos((animation.value * math.pi * 2) +
                            (i * math.pi * 0.4)) *
                        105,
                    math.sin((animation.value * math.pi * 2) +
                            (i * math.pi * 0.4)) *
                        76,
                  ),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE0F2FE)),
                    ),
                    child: const Icon(Icons.local_shipping_rounded,
                        color: Color(0xFF0284C7), size: 20),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RadarMarker extends StatelessWidget {
  const _RadarMarker({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < 2; i++)
              Transform.scale(
                scale: 0.4 + ((animation.value + (i * 0.5)) % 1) * 1.2,
                child: Opacity(
                  opacity: 1 - ((animation.value + (i * 0.5)) % 1),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: Color(0x330EA5E9),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            const Icon(Icons.location_on_rounded,
                color: Color(0xFFEF4444), size: 52),
          ],
        );
      },
    );
  }
}

class _SearchingBottomPanel extends StatelessWidget {
  const _SearchingBottomPanel({
    required this.statusText,
    required this.tankSize,
    required this.orderId,
    required this.nearbyCount,
    required this.onCancel,
    required this.onDetails,
  });

  final String statusText;
  final int? tankSize;
  final String? orderId;
  final int nearbyCount;
  final VoidCallback onCancel;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.paddingOf(context).bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A0F172A),
            blurRadius: 30,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            statusText,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nearest tanker owners are being notified in real time.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.water_drop_rounded,
                      color: Color(0xFF0EA5E9)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tankSize == null
                            ? 'Water tanker request'
                            : '$tankSize L water tanker',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Estimated wait: 2-5 min',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: Text(
                      '$nearbyCount nearby',
                      key: ValueKey(nearbyCount),
                      style: const TextStyle(
                        color: Color(0xFF0369A1),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onDetails,
                  child: const Text('Details'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: const Text(
                'Cancel Request',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 54,
          height: 54,
          child: Icon(icon, color: const Color(0xFF0F172A)),
        ),
      ),
    );
  }
}

class _TimeoutView extends StatelessWidget {
  const _TimeoutView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_off_rounded,
                    size: 64, color: Color(0xFFEF4444)),
                const SizedBox(height: 24),
                const Text(
                  'No tanker available right now',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Try again in a few minutes or choose a different delivery address.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: onRetry,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Back to Home',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
