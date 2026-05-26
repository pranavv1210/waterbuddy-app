import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/session_actions.dart';
import '../../../models/order.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/operations_ui.dart';

class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  ConsumerState<DriverDashboardScreen> createState() =>
      _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen> {
  int _tab = 0;

  static const _tabs = [
    OpsTab(label: 'Runs', icon: Icons.route_rounded),
    OpsTab(label: 'Profile', icon: Icons.badge_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(driverOnlineProvider);

    return OpsScaffold(
      title: 'Driver',
      subtitle: online ? 'On duty' : 'Off duty',
      accent: OpsColors.amber,
      tabs: _tabs,
      activeIndex: _tab,
      onTabChanged: (index) => setState(() => _tab = index),
      actions: [
        _DutySwitch(
          online: online,
          onChanged: (value) =>
              ref.read(driverOnlineProvider.notifier).setOnline(value),
        ),
        const _DriverNotificationButton(),
      ],
      body: IndexedStack(
        index: _tab,
        children: const [
          _DriverRunsView(),
          _DriverProfileView(),
        ],
      ),
    );
  }
}

class _DutySwitch extends StatelessWidget {
  const _DutySwitch({required this.online, required this.onChanged});

  final bool online;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    return Container(
      margin: EdgeInsets.only(right: compact ? 4 : 8),
      padding: EdgeInsets.only(left: compact ? 8 : 12),
      decoration: BoxDecoration(
        color: online
            ? OpsColors.green.withValues(alpha: 0.1)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              online ? OpsColors.green.withValues(alpha: 0.25) : OpsColors.line,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            compact
                ? (online ? 'ON' : 'OFF')
                : (online ? 'ON DUTY' : 'OFF DUTY'),
            style: TextStyle(
              color: online ? OpsColors.green : OpsColors.muted,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          Transform.scale(
            scale: compact ? 0.78 : 0.92,
            child: Switch(value: online, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

class _DriverNotificationButton extends StatelessWidget {
  const _DriverNotificationButton();

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: 'Notifications',
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        backgroundColor: Colors.white,
        builder: (context) => const SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    color: OpsColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 14),
                OpsCard(
                  child: Text(
                    'Assigned delivery runs, route updates, and payout alerts will appear here.',
                    style: TextStyle(
                      color: OpsColors.muted,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      icon: const Icon(Icons.notifications_none_rounded),
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
            primaryOrder!.latitude == 0 ? 12.9716 : primaryOrder.latitude,
            primaryOrder.longitude == 0 ? 77.5946 : primaryOrder.longitude,
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 250,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: activeOrders.isEmpty ? 12.5 : 14,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.waterbuddy.driver',
                ),
                MarkerLayer(
                  markers: [
                    for (final order in activeOrders)
                      if (order.latitude != 0 || order.longitude != 0)
                        Marker(
                          point: LatLng(order.latitude, order.longitude),
                          width: 42,
                          height: 42,
                          child: Container(
                            decoration: BoxDecoration(
                              color: OpsColors.amber,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(
                              Icons.water_drop_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                  ],
                ),
              ],
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
                onPressed: () => _updateLocationAndStatus(ref, order, next),
                child: Text(_actionLabel(next)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String? _nextStatus(String status) {
    switch (status) {
      case 'DRIVER_ASSIGNED':
      case 'ASSIGNED':
        return 'ON_THE_WAY';
      case 'ON_THE_WAY':
        return 'ARRIVED';
      case 'ARRIVED':
        return 'DELIVERED';
      default:
        return null;
    }
  }

  static String _actionLabel(String status) {
    switch (status) {
      case 'ON_THE_WAY':
        return 'Start delivery';
      case 'ARRIVED':
        return 'Mark arrived';
      case 'DELIVERED':
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

    await ref.read(orderServiceProvider).updateOrderStatus(order.id, status);

    if (position != null) {
      await FirebaseFirestore.instance.collection('orders').doc(order.id).set({
        'tracking': {
          'lat': position.latitude,
          'lng': position.longitude,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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
      child: FlutterMap(
        options: MapOptions(initialCenter: center, initialZoom: 14),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.waterbuddy.customer',
          ),
          MarkerLayer(
            markers: [
              if (order.latitude != 0 || order.longitude != 0)
                Marker(
                  point: LatLng(order.latitude, order.longitude),
                  width: 44,
                  height: 44,
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: OpsColors.red,
                    size: 40,
                  ),
                ),
              if (tracking != null)
                Marker(
                  point: LatLng(tracking.lat, tracking.lng),
                  width: 44,
                  height: 44,
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: OpsColors.blue,
                    size: 34,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DriverProfileView extends ConsumerWidget {
  const _DriverProfileView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider)?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection('drivers').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
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
