import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/session_actions.dart';
import '../../../models/order.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/operations_ui.dart';
import '../../../widgets/waterbuddy_bottom_sheet.dart';

class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  ConsumerState<DriverDashboardScreen> createState() =>
      _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen> {
  int _tab = 0;

  static const _tabs = [
    OpsTab(label: 'Home', icon: Icons.map_rounded),
    OpsTab(label: 'Orders', icon: Icons.route_rounded),
    OpsTab(label: 'History', icon: Icons.history_rounded),
    OpsTab(label: 'Profile', icon: Icons.badge_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OpsColors.surface,
      body: IndexedStack(
        index: _tab,
        children: const [
          _DriverHomeView(),
          _DriverRunsView(),
          _DriverHistoryView(),
          _DriverProfileView(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        indicatorColor: OpsColors.amber.withValues(alpha: 0.15),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon, color: OpsColors.muted),
              selectedIcon: Icon(tab.icon, color: OpsColors.amber),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}

class _DriverHomeView extends ConsumerWidget {
  const _DriverHomeView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(driverOnlineProvider);
    final orders =
        ref.watch(driverAssignedOrdersProvider).valueOrNull ?? const <Order>[];
    final activeOrders = orders
        .where((order) =>
            order.status != 'COMPLETED' && order.status != 'CANCELLED')
        .toList();
    final primaryOrder = activeOrders.isEmpty ? null : activeOrders.first;
    final center = primaryOrder == null
        ? const LatLng(12.9716, 77.5946)
        : LatLng(
            primaryOrder.latitude == 0 ? 12.9716 : primaryOrder.latitude,
            primaryOrder.longitude == 0 ? 77.5946 : primaryOrder.longitude,
          );

    return Stack(
      children: [
        Positioned.fill(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: center, zoom: 14),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
            markers: {
              for (final order in activeOrders)
                if (order.latitude != 0 || order.longitude != 0)
                  Marker(
                    markerId: MarkerId('delivery_${order.id}'),
                    position: LatLng(order.latitude, order.longitude),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueYellow,
                    ),
                    infoWindow: InfoWindow(
                      title: order.tankLabel,
                      snippet: order.deliveryAddress,
                    ),
                  ),
            },
            polylines: {
              if (primaryOrder != null &&
                  primaryOrder.latitude != 0 &&
                  primaryOrder.longitude != 0)
                Polyline(
                  polylineId: PolylineId('route_${primaryOrder.id}'),
                  points: [
                    center,
                    LatLng(primaryOrder.latitude, primaryOrder.longitude),
                  ],
                  color: OpsColors.amber,
                  width: 5,
                ),
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _DriverMapHeader(
              online: online,
              activeOrders: activeOrders.length,
              onToggle: (value) =>
                  ref.read(driverOnlineProvider.notifier).setOnline(value),
            ),
          ),
        ),
        _DriverWorkSheet(activeOrders: activeOrders),
      ],
    );
  }
}

class _DriverMapHeader extends StatelessWidget {
  const _DriverMapHeader({
    required this.online,
    required this.activeOrders,
    required this.onToggle,
  });

  final bool online;
  final int activeOrders;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OpsColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFFFF7ED),
            child: Icon(Icons.badge_rounded, color: OpsColors.amber),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Driver',
                  style: TextStyle(
                    color: OpsColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  online ? 'Rating 4.8 - $activeOrders active' : 'Offline',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: OpsColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const _DriverWalletLabel(),
          const SizedBox(width: 10),
          _DutySwitch(online: online, onChanged: onToggle),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
    );
  }
}

class _DriverWalletLabel extends StatelessWidget {
  const _DriverWalletLabel();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Wallet',
          style: TextStyle(
            color: OpsColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          'Rs 0',
          style: TextStyle(
            color: OpsColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _DriverWorkSheet extends StatelessWidget {
  const _DriverWorkSheet({required this.activeOrders});

  final List<Order> activeOrders;

  @override
  Widget build(BuildContext context) {
    final current = activeOrders.isEmpty ? null : activeOrders.first;
    return DraggableScrollableSheet(
      initialChildSize: 0.30,
      minChildSize: 0.20,
      maxChildSize: 0.58,
      builder: (context, controller) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 24,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: OpsColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _DriverTinyMetric(
                      label: 'Current',
                      value: current == null ? '0' : '1',
                    ),
                  ),
                  const Expanded(
                    child: _DriverTinyMetric(label: 'History', value: 'Live'),
                  ),
                  const Expanded(
                    child: _DriverTinyMetric(label: 'Earnings', value: 'Rs 0'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (current == null)
                const _DriverSheetMessage(
                  icon: Icons.route_outlined,
                  title: 'Waiting for delivery',
                  message: 'Go online to receive assigned tanker runs.',
                )
              else
                _DriverSheetMessage(
                  icon: Icons.navigation_rounded,
                  title: formatOrderStatus(current.status),
                  message: current.deliveryAddress ?? current.tankLabel,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DriverTinyMetric extends StatelessWidget {
  const _DriverTinyMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: OpsColors.ink,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: OpsColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _DriverSheetMessage extends StatelessWidget {
  const _DriverSheetMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: OpsColors.amber.withValues(alpha: 0.12),
          child: Icon(icon, color: OpsColors.amber),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: OpsColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: OpsColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DutySwitch extends StatelessWidget {
  const _DutySwitch({required this.online, required this.onChanged});

  final bool online;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: online ? 'Go off duty' : 'Go on duty',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onChanged(!online),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: online ? OpsColors.green : const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                online ? 'Online' : 'Offline',
                style: TextStyle(
                  color: online ? Colors.white : OpsColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DriverRunsView extends ConsumerWidget {
  const _DriverRunsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(driverOnlineProvider);
    final orders = ref.watch(driverAssignedOrdersProvider);

    if (!online) {
      return OpsEmptyState(
        icon: Icons.power_settings_new_rounded,
        title: 'You are off duty',
        message: 'Go on duty to see assigned tanker delivery runs.',
        action: FilledButton.icon(
          onPressed: () =>
              ref.read(driverOnlineProvider.notifier).setOnline(true),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Go on duty'),
        ),
      );
    }

    return orders.when(
      data: (list) {
        final active = list
            .where((order) =>
                order.status != 'DELIVERED' && order.status != 'CANCELLED')
            .toList();

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _DriverMapPanel(activeOrders: active),
            const SizedBox(height: 18),
            if (active.isEmpty)
              const OpsEmptyState(
                icon: Icons.route_outlined,
                title: 'Waiting for delivery run',
                message:
                    'Assigned water tanker deliveries will appear here in real time.',
              )
            else
              for (final order in active)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _RunCard(order: order),
                ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
    );
  }
}

class _DriverMapPanel extends StatelessWidget {
  const _DriverMapPanel({required this.activeOrders});

  final List<Order> activeOrders;

  @override
  Widget build(BuildContext context) {
    final primaryOrder = activeOrders.isEmpty ? null : activeOrders.first;
    final center = primaryOrder == null
        ? const LatLng(12.9716, 77.5946)
        : LatLng(
            primaryOrder.latitude == 0 ? 12.9716 : primaryOrder.latitude,
            primaryOrder.longitude == 0 ? 77.5946 : primaryOrder.longitude,
          );

    final mapHeight = MediaQuery.sizeOf(context).height * 0.62;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: mapHeight.clamp(420.0, 620.0),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: center,
                zoom: activeOrders.isEmpty ? 12.5 : 14,
              ),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              markers: {
                for (final order in activeOrders)
                  if (order.latitude != 0 || order.longitude != 0)
                    Marker(
                      markerId: MarkerId('order_${order.id}'),
                      position: LatLng(order.latitude, order.longitude),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueYellow),
                      infoWindow: InfoWindow(
                        title: order.tankLabel,
                        snippet: order.deliveryAddress,
                      ),
                    ),
              },
            ),
            Positioned(
              left: 14,
              right: 14,
              top: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: OpsColors.line),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.navigation_rounded,
                        color: OpsColors.amber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        activeOrders.isEmpty
                            ? 'On duty - waiting for assigned water delivery'
                            : '${activeOrders.length} active water delivery run${activeOrders.length == 1 ? '' : 's'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: OpsColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    OpsStatusPill(
                      label: activeOrders.isEmpty ? 'READY' : 'LIVE',
                      color: activeOrders.isEmpty
                          ? OpsColors.amber
                          : OpsColors.green,
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
}

class _DriverHistoryView extends ConsumerWidget {
  const _DriverHistoryView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(driverAssignedOrdersProvider);
    return orders.when(
      data: (list) {
        final completed = list
            .where((order) =>
                order.status == 'COMPLETED' || order.status == 'DELIVERED')
            .toList();
        if (completed.isEmpty) {
          return const OpsEmptyState(
            icon: Icons.history_rounded,
            title: 'No completed runs',
            message: 'Completed deliveries will appear here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemBuilder: (context, index) {
            final order = completed[index];
            return OpsCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  order.tankLabel,
                  style: const TextStyle(
                    color: OpsColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: Text(
                  order.deliveryAddress ?? 'Address unavailable',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  'Rs ${order.amount.toInt()}',
                  style: const TextStyle(
                    color: OpsColors.green,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: completed.length,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
    );
  }
}

class _RunCard extends ConsumerWidget {
  const _RunCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = _nextStatus(order.status);
    final phone = order.customerPhone;

    return OpsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.tankLabel,
                  style: const TextStyle(
                    color: OpsColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              OpsStatusPill(
                label: formatOrderStatus(order.status),
                color: orderStatusColor(order.status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.deliveryAddress ?? 'Delivery address unavailable',
            style: const TextStyle(
              color: OpsColors.muted,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(height: 180, child: _RunMap(order: order)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: phone.isEmpty
                      ? null
                      : () => launchUrl(Uri(scheme: 'tel', path: phone)),
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('Call customer'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: order.latitude == 0 && order.longitude == 0
                      ? null
                      : () {
                          final uri = Uri.parse(
                            'https://www.google.com/maps/dir/?api=1&destination=${order.latitude},${order.longitude}',
                          );
                          launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
                  icon: const Icon(Icons.navigation_rounded),
                  label: const Text('Navigate'),
                ),
              ),
            ],
          ),
          if (next != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (next == 'COMPLETED') {
                    final pinConfirmed = await _showPinVerificationDialog(
                        context, order.deliveryPin);
                    if (!pinConfirmed) return;
                  }
                  await _updateLocationAndStatus(ref, order, next);
                },
                child: Text(_actionLabel(next)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<bool> _showPinVerificationDialog(
    BuildContext context,
    String? expectedPin,
  ) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showWaterBuddyBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 2, 22, 24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter delivery PIN',
                style: TextStyle(
                  color: OpsColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ask the customer for the 4-digit PIN to complete this delivery.',
                style: TextStyle(
                  color: OpsColors.muted,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: OpsColors.ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 10,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '0000',
                  hintStyle: TextStyle(
                    color: OpsColors.muted.withValues(alpha: 0.38),
                    letterSpacing: 6,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: OpsColors.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: OpsColors.line),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().length != 4) {
                    return 'Enter a 4-digit PIN';
                  }
                  if (expectedPin != null && value.trim() != expectedPin) {
                    return 'Incorrect PIN. Try again.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        if (formKey.currentState?.validate() ?? false) {
                          Navigator.pop(context, true);
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: OpsColors.amber,
                        foregroundColor: OpsColors.ink,
                      ),
                      child: const Text('Verify PIN'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
    return result ?? false;
  }

  static String? _nextStatus(String status) {
    switch (status) {
      case 'DRIVER_ASSIGNED':
      case 'ASSIGNED':
        return 'EN_ROUTE';
      case 'EN_ROUTE':
      case 'ON_THE_WAY':
        return 'ARRIVED';
      case 'ARRIVED':
        return 'DELIVERING';
      case 'DELIVERING':
        return 'COMPLETED';
      default:
        return null;
    }
  }

  static String _actionLabel(String status) {
    switch (status) {
      case 'EN_ROUTE':
      case 'ON_THE_WAY':
        return 'Mark arrived';
      case 'ARRIVED':
        return 'Start delivery';
      case 'DELIVERING':
      case 'COMPLETED':
        return 'Complete delivery';
      default:
        return 'Update status';
    }
  }

  Future<void> _updateLocationAndStatus(
    WidgetRef ref,
    Order order,
    String status,
  ) async {
    Position? position;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        position = await Geolocator.getCurrentPosition();
      }
    } catch (_) {
      position = null;
    }

    final service = ref.read(orderServiceProvider);
    await service.updateOrderStatus(
      orderId: order.id,
      newStatus: status,
    );
    if (position != null) {
      await service.updateOrderTracking(
        orderId: order.id,
        latitude: position.latitude,
        longitude: position.longitude,
        heading: position.heading,
        speed: position.speed,
        accuracy: position.accuracy,
      );
    }
  }
}

class _RunMap extends StatelessWidget {
  const _RunMap({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final tracking = order.tracking;
    final center = tracking != null
        ? LatLng(tracking.lat, tracking.lng)
        : LatLng(order.latitude == 0 ? 12.9716 : order.latitude,
            order.longitude == 0 ? 77.5946 : order.longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: center,
          zoom: 14,
        ),
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        markers: {
          if (order.latitude != 0 || order.longitude != 0)
            Marker(
              markerId: const MarkerId('destination'),
              position: LatLng(order.latitude, order.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed),
            ),
          if (tracking != null)
            Marker(
              markerId: const MarkerId('driver_tracking'),
              position: LatLng(tracking.lat, tracking.lng),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue),
            ),
        },
      ),
    );
  }
}

class _DriverProfileView extends ConsumerWidget {
  const _DriverProfileView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentDriverProfileProvider);
    return profileAsync.when(
      data: (snapshot) {
        final data = snapshot?.data() ?? {};
        final name =
            (data['driverName'] ?? data['fullName'] ?? 'Driver').toString();
        final phone =
            (data['phone'] ?? data['phoneNumber'] ?? 'Not recorded').toString();
        final license =
            (data['driverLicenseNumber'] ?? 'Not recorded').toString();
        final status = (data['verificationStatus'] ?? 'pending').toString();

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            OpsCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: OpsColors.amber.withValues(alpha: 0.14),
                    child: const Icon(Icons.person_rounded,
                        color: OpsColors.amber),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: OpsColors.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(phone,
                            style: const TextStyle(color: OpsColors.muted)),
                      ],
                    ),
                  ),
                  OpsStatusPill(
                    label: status.toUpperCase(),
                    color: orderStatusColor(status),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OpsCard(
              child: Column(
                children: [
                  _ProfileRow(label: 'License', value: license),
                  const Divider(height: 24),
                  _ProfileRow(
                    label: 'Emergency contact',
                    value:
                        (data['emergencyContact'] ?? 'Not recorded').toString(),
                  ),
                  const Divider(height: 24),
                  _ProfileRow(
                    label: 'Address',
                    value: (data['address'] ?? 'Not recorded').toString(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OpsCard(
              child: Column(
                children: [
                  _DriverSettingsRow(
                    icon: Icons.settings_rounded,
                    title: 'Duty settings',
                    subtitle: 'Navigation, delivery alerts, and availability.',
                    onTap: () => context.push(RouteNames.appSettings),
                  ),
                  const Divider(height: 24),
                  const _DriverSettingsRow(
                    icon: Icons.health_and_safety_rounded,
                    title: 'Emergency details',
                    subtitle: 'Emergency contact and verified address.',
                  ),
                  const Divider(height: 24),
                  _DriverSettingsRow(
                    icon: Icons.support_agent_rounded,
                    title: 'Support',
                    subtitle: 'waterbuddyapp.wb@gmail.com',
                    onTap: () {
                      launchUrl(Uri(
                        scheme: 'mailto',
                        path: 'waterbuddyapp.wb@gmail.com',
                        query: 'subject=WaterBuddy driver support',
                      ));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await signOutToRoleSelection(context: context, ref: ref);
                },
                icon: const Icon(Icons.logout_rounded, color: OpsColors.red),
                label: const Text('Logout'),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
    );
  }
}

class _DriverSettingsRow extends StatelessWidget {
  const _DriverSettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Icon(icon, color: OpsColors.amber),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: OpsColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: OpsColors.muted),
              ),
            ],
          ),
        ),
        if (onTap != null)
          const Icon(Icons.chevron_right_rounded, color: OpsColors.muted),
      ],
    );

    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: row,
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              color: OpsColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: OpsColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
