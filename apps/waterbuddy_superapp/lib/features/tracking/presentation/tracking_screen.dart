import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../routes/route_names.dart';
import '../../../models/order.dart' as app_order;
import '../../../widgets/premium_ui.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderId = GoRouterState.of(context).uri.queryParameters['orderId'];
      if (orderId != null) {
        ref
            .read(trackingControllerProvider.notifier)
            .startWatchingOrder(orderId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingControllerProvider);
    final uiState = ref.watch(assignedOrderTrackingProvider);

    ref.listen(trackingControllerProvider, (previous, next) {
      if (next.orderStatus == 'DELIVERED') {
        final orderId = next.orderId;
        if (orderId != null) {
          context.go('${RouteNames.orderComplete}?orderId=$orderId');
        }
      }
    });

    if (trackingState.errorMessage != null) {
      return Scaffold(
        backgroundColor: WbColors.surface,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: WbColors.red.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.error_outline_rounded,
                        size: 48, color: WbColors.red),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Something went wrong',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: WbColors.ink,
                        letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    trackingState.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: WbColors.muted, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: () {
                        ref
                            .read(trackingControllerProvider.notifier)
                            .clearError();
                        context.go(RouteNames.home);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: WbColors.ink,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                WaterBuddyDesignSystem.radiusPill)),
                      ),
                      child: const Text('Back to Home',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final orderId = trackingState.orderId;
    final order = orderId != null
        ? ref.watch(orderStreamProvider(orderId)).valueOrNull
        : null;

    final body = uiState.when(
      data: (state) => _TrackingScreenBody(
          state: state, trackingState: trackingState, order: order),
      error: (err, __) =>
          _ErrorBody(onGoHome: () => context.go(RouteNames.home)),
      loading: () => _LoadingBody(),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go(RouteNames.home);
      },
      child: body,
    );
  }
}

class _LoadingBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: WbColors.surface,
      body: Center(
        child: WaterBuddyLoader(),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onGoHome});
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WbColors.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 52, color: WbColors.red),
            const SizedBox(height: 16),
            const Text('Error loading tracking',
                style: TextStyle(
                    color: WbColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onGoHome,
              style: FilledButton.styleFrom(backgroundColor: WbColors.ink),
              child: const Text('Go Home',
                  style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackingScreenBody extends StatefulWidget {
  const _TrackingScreenBody({
    required this.state,
    required this.trackingState,
    required this.order,
  });

  final AssignedOrderTracking state;
  final TrackingState trackingState;
  final app_order.Order? order;

  @override
  State<_TrackingScreenBody> createState() => _TrackingScreenBodyState();
}

class _TrackingScreenBodyState extends State<_TrackingScreenBody> {
  GoogleMapController? _googleMapController;
  BitmapDescriptor? _tankerIcon;

  @override
  void initState() {
    super.initState();
    _loadTankerIcon();
  }

  void _loadTankerIcon() {
    BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(32, 32)),
      'assets/ui/tanker.png',
    ).then((icon) {
      if (mounted) setState(() => _tankerIcon = icon);
    }).catchError((e) {
      debugPrint('Error loading tanker asset: $e');
    });
  }

  @override
  void didUpdateWidget(_TrackingScreenBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldTracking = oldWidget.trackingState.tracking;
    final newTracking = widget.trackingState.tracking;
    if (newTracking != null &&
        (oldTracking?.lat != newTracking.lat ||
            oldTracking?.lng != newTracking.lng)) {
      _googleMapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
            LatLng(newTracking.lat, newTracking.lng), 15.0),
      );
    }
  }

  Future<void> _callDriver(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    final statusTitle = _getStatusTitle(widget.trackingState.orderStatus);
    final statusSubtitle = _getStatusSubtitle(widget.trackingState.orderStatus);

    LatLng? consumerLatLng;
    if (widget.order != null) {
      consumerLatLng = LatLng(widget.order!.latitude, widget.order!.longitude);
    }

    LatLng? driverLatLng;
    if (widget.trackingState.tracking != null) {
      driverLatLng = LatLng(widget.trackingState.tracking!.lat,
          widget.trackingState.tracking!.lng);
    }

    final cameraTarget =
        driverLatLng ?? consumerLatLng ?? const LatLng(12.9716, 77.5946);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: WbColors.surface,
        body: Stack(
          children: [
            // ── Full-screen Google Map ──────────────────────────────
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: cameraTarget,
                  zoom: 15.0,
                ),
                onMapCreated: (controller) {
                  _googleMapController = controller;
                },
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                markers: {
                  if (consumerLatLng != null)
                    Marker(
                      markerId: const MarkerId('consumer_location'),
                      position: consumerLatLng,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed),
                      infoWindow: const InfoWindow(title: 'Your Location'),
                    ),
                  if (driverLatLng != null)
                    Marker(
                      markerId: const MarkerId('driver_location'),
                      position: driverLatLng,
                      icon: _tankerIcon ??
                          BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueCyan),
                      infoWindow: InfoWindow(
                        title: widget.state.driver.name,
                        snippet: widget.state.vehicle.plateLabel,
                      ),
                    ),
                },
                polylines: {
                  if (consumerLatLng != null && driverLatLng != null)
                    Polyline(
                      polylineId: const PolylineId('route'),
                      points: [consumerLatLng, driverLatLng],
                      color: const Color(0xFF007AFF),
                      width: 5,
                    ),
                },
              ),
            ),

            // ── Floating back button ──────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 14,
              left: 16,
              child: _FloatingButton(
                icon: Icons.arrow_back,
                onTap: () => context.go(RouteNames.home),
              ),
            ),

            // ── Floating title pill ──────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 14,
              left: 72,
              right: 72,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius:
                      BorderRadius.circular(WaterBuddyDesignSystem.radiusPill),
                  boxShadow: [
                    BoxShadow(
                      color: WbColors.ink.withValues(alpha: 0.10),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Text(
                  'Live Tracking',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: WbColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),

            // ── Bottom sheet ──────────────────────────────────────
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: WbColors.ink.withValues(alpha: 0.12),
                      blurRadius: 30,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: WbColors.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 4, 20,
                          MediaQuery.of(context).padding.bottom + 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status
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
                                        fontWeight: FontWeight.w900,
                                        color: WbColors.ink,
                                        letterSpacing: -0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      statusSubtitle,
                                      style: const TextStyle(
                                        color: WbColors.muted,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: WbColors.blue.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.water_drop_rounded,
                                    color: WbColors.blue),
                              ),
                            ],
                          ),

                          // Delivery PIN card
                          if (widget.order?.deliveryPin != null) ...[
                            const SizedBox(height: 14),
                            _DeliveryPinCard(pin: widget.order!.deliveryPin!),
                          ],

                          const SizedBox(height: 16),

                          // Driver card
                          _DriverCard(
                            state: widget.state,
                            onCall: () =>
                                _callDriver(widget.state.driver.phoneNumber),
                            onMessage: () => launchUrl(Uri(
                              scheme: 'sms',
                              path: widget.state.driver.phoneNumber,
                            )),
                          ),

                          const SizedBox(height: 16),

                          // Info chips
                          Row(
                            children: [
                              _InfoChip(
                                icon: Icons.water_damage_rounded,
                                label: widget.state.vehicle.capacityLabel,
                                title: 'Volume',
                              ),
                              const SizedBox(width: 10),
                              _InfoChip(
                                icon: Icons.timer_rounded,
                                label: widget.state.estimatedArrival,
                                title: 'ETA',
                              ),
                              const SizedBox(width: 10),
                              _InfoChip(
                                icon: Icons.payment_rounded,
                                label: widget.state.orderSummary.amountLabel,
                                title: 'Payment',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'ACCEPTED':
      case 'ASSIGNED':
      case 'DRIVER_ASSIGNED':
        return 'Partner Assigned';
      case 'ON_THE_WAY':
        return 'Tanker is on the way';
      case 'ARRIVED':
        return 'Tanker has arrived';
      case 'DELIVERED':
        return 'Water Delivered';
      case 'CANCELLED':
        return 'Order Cancelled';
      default:
        return 'Tracking Order';
    }
  }

  String _getStatusSubtitle(String status) {
    switch (status) {
      case 'ACCEPTED':
      case 'ASSIGNED':
      case 'DRIVER_ASSIGNED':
        return 'The driver is preparing your delivery';
      case 'ON_THE_WAY':
        return 'Heading towards your location now';
      case 'ARRIVED':
        return 'Please share delivery PIN with the driver';
      case 'DELIVERED':
        return 'Thank you for using WaterBuddy!';
      case 'CANCELLED':
        return 'This order was cancelled';
      default:
        return 'Real-time status updates';
    }
  }
}

// ── Floating icon button ────────────────────────────────────────────────────

class _FloatingButton extends StatefulWidget {
  const _FloatingButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_FloatingButton> createState() => _FloatingButtonState();
}

class _FloatingButtonState extends State<_FloatingButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: WbColors.ink.withValues(alpha: 0.14),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(widget.icon, color: WbColors.ink, size: 22),
        ),
      ),
    );
  }
}

// ── Delivery PIN card ───────────────────────────────────────────────────────

class _DeliveryPinCard extends StatelessWidget {
  const _DeliveryPinCard({required this.pin});
  final String pin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: WbColors.blue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WbColors.blue.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery PIN',
                  style: TextStyle(
                    fontSize: 11,
                    color: WbColors.blue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Share with driver on arrival',
                  style: TextStyle(
                    fontSize: 11,
                    color: WbColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WbColors.blue.withValues(alpha: 0.3)),
            ),
            child: Text(
              pin,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: WbColors.blue,
                letterSpacing: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Driver card ─────────────────────────────────────────────────────────────

class _DriverCard extends StatelessWidget {
  const _DriverCard({
    required this.state,
    required this.onCall,
    required this.onMessage,
  });
  final AssignedOrderTracking state;
  final VoidCallback onCall;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WbColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: WbColors.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: WbColors.line,
                backgroundImage: state.driver.avatarUrl.isNotEmpty
                    ? NetworkImage(state.driver.avatarUrl)
                    : null,
                child: state.driver.avatarUrl.isEmpty
                    ? const Icon(Icons.person_rounded, color: WbColors.muted)
                    : null,
              ),
              const SizedBox(width: 14),
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
                            fontWeight: FontWeight.w900,
                            color: WbColors.ink,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded,
                            size: 16, color: Color(0xFF22C55E)),
                      ],
                    ),
                    Text(
                      '${state.vehicle.typeLabel} · ${state.vehicle.plateLabel}',
                      style: const TextStyle(
                          color: WbColors.muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 13, color: WbColors.amber),
                        const SizedBox(width: 4),
                        Text(state.driver.ratingLabel,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 12)),
                        const SizedBox(width: 6),
                        Text(state.driver.deliveriesLabel,
                            style: const TextStyle(
                                color: WbColors.muted, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: WbColors.line),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call_rounded, size: 18),
                  label: const Text('Call Driver'),
                  style: FilledButton.styleFrom(
                    backgroundColor: WbColors.ink,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      state.driver.phoneNumber.isEmpty ? null : onMessage,
                  icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: WbColors.ink,
                    side: const BorderSide(color: WbColors.line),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Info chip ───────────────────────────────────────────────────────────────

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
          color: WbColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: WbColors.line),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: WbColors.muted),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: WbColors.ink),
            ),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 10,
                  color: WbColors.muted,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
