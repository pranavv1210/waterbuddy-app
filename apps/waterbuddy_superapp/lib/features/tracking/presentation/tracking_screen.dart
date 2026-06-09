import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../routes/route_names.dart';
import '../../../models/order.dart' as app_order;
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

    // Listen for status changes to trigger navigation
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
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 64, color: Color(0xFFEF4444)),
                  const SizedBox(height: 24),
                  const Text(
                    'Something went wrong',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5),
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
                        ref
                            .read(trackingControllerProvider.notifier)
                            .clearError();
                        context.go(RouteNames.home);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        elevation: 0,
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

    final orderId = trackingState.orderId;
    final order = orderId != null
        ? ref.watch(orderStreamProvider(orderId)).valueOrNull
        : null;

    final body = uiState.when(
      data: (state) =>
          _TrackingScreenBody(state: state, trackingState: trackingState, order: order),
      error: (err, __) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading tracking: $err'),
              TextButton(
                  onPressed: () => context.go(RouteNames.home),
                  child: const Text('Go Home')),
            ],
          ),
        ),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
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
      if (mounted) {
        setState(() {
          _tankerIcon = icon;
        });
      }
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
      // Smoothly pan map to new location
      _googleMapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(newTracking.lat, newTracking.lng), 15.0),
      );
    }
  }

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
    const primaryColor = Color(0xFF0F172A);
    const accentColor = Color(0xFF0099FF);

    final statusTitle = _getStatusTitle(widget.trackingState.orderStatus);
    final statusSubtitle = _getStatusSubtitle(widget.trackingState.orderStatus);

    LatLng? consumerLatLng;
    if (widget.order != null) {
      consumerLatLng = LatLng(widget.order!.latitude, widget.order!.longitude);
    }

    LatLng? driverLatLng;
    if (widget.trackingState.tracking != null) {
      driverLatLng = LatLng(widget.trackingState.tracking!.lat, widget.trackingState.tracking!.lng);
    }

    // Determine initial camera target
    final cameraTarget = driverLatLng ?? consumerLatLng ?? const LatLng(12.9716, 77.5946);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Real Map
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
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    infoWindow: const InfoWindow(title: 'Your Location'),
                  ),
                if (driverLatLng != null)
                  Marker(
                    markerId: const MarkerId('driver_location'),
                    position: driverLatLng,
                    icon: _tankerIcon ??
                        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
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
                    color: const Color(0xFF007AFF), // Blue route
                    width: 5,
                  ),
              },
            ),
          ),

          // Header with Back Button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16,
                  right: 16,
                  bottom: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
                    onPressed: () => context.go(RouteNames.home),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Track Live Delivery',
                    style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 20,
                        fontWeight: FontWeight.w800),
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(40)),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
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
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: primaryColor,
                                      letterSpacing: -1.0,
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
                                color: const Color(0xFFEEF7FF),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.water_drop_rounded,
                                  color: accentColor),
                            ),
                          ],
                        ),

                        // Share PIN Card
                        if (widget.order?.deliveryPin != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF7FF), // Light Water Blue
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFDCEFFF)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Provide Delivery PIN to Driver',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF007AFF),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Share this PIN once tanker arrives',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF4DA6FF)),
                                  ),
                                  child: Text(
                                    widget.order!.deliveryPin!,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF007AFF),
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Driver & Vehicle Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: const Color(0xFFE2E8F0),
                                    backgroundImage:
                                        widget.state.driver.avatarUrl.isNotEmpty
                                            ? NetworkImage(
                                                widget.state.driver.avatarUrl)
                                            : null,
                                    child: widget.state.driver.avatarUrl.isEmpty
                                        ? const Icon(Icons.person_rounded,
                                            color: Color(0xFF64748B))
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              widget.state.driver.name,
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w900,
                                                color: primaryColor,
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(Icons.verified_rounded,
                                                size: 16,
                                                color: Color(0xFF22C55E)),
                                          ],
                                        ),
                                        Text(
                                          '${widget.state.vehicle.typeLabel} • ${widget.state.vehicle.plateLabel}',
                                          style: const TextStyle(
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.star_rounded,
                                                size: 14,
                                                color: Color(0xFFF59E0B)),
                                            const SizedBox(width: 4),
                                            Text(
                                              widget.state.driver.ratingLabel,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              widget
                                                  .state.driver.deliveriesLabel,
                                              style: const TextStyle(
                                                  color: Color(0xFF94A3B8),
                                                  fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(
                                  height: 24, color: Color(0xFFF1F5F9)),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _callDriver(
                                          widget.state.driver.phoneNumber),
                                      icon: const Icon(Icons.call_rounded,
                                          size: 20),
                                      label: const Text('Call Driver'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: widget
                                              .state.driver.phoneNumber.isEmpty
                                          ? null
                                          : () => launchUrl(Uri(
                                                scheme: 'sms',
                                                path: widget
                                                    .state.driver.phoneNumber,
                                              )),
                                      icon: const Icon(
                                          Icons.chat_bubble_rounded,
                                          size: 20),
                                      label: const Text('Message'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: primaryColor,
                                        side: const BorderSide(
                                            color: Color(0xFFE2E8F0)),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
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
                              label: widget.state.vehicle.capacityLabel,
                              title: 'Volume',
                            ),
                            const SizedBox(width: 12),
                            _InfoChip(
                              icon: Icons.timer_rounded,
                              label: widget.state.estimatedArrival,
                              title: 'ETA',
                            ),
                            const SizedBox(width: 12),
                            _InfoChip(
                              icon: Icons.payment_rounded,
                              label: widget.state.orderSummary.amountLabel,
                              title: 'Payment',
                            ),
                          ],
                        ),

                        // Safety buffer for bottom navigation if any
                        SizedBox(
                            height: MediaQuery.of(context).padding.bottom + 10),
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF64748B)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xFF0F172A)),
            ),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
