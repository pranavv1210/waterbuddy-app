import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

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
        IconButton(
          tooltip: 'Sign out',
          onPressed: () async {
            await ref.read(authServiceProvider).signOut();
            await ref.read(selectedRoleProvider.notifier).clear();
            if (context.mounted) context.go(RouteNames.roleSelection);
          },
          icon: const Icon(Icons.logout_rounded, color: OpsColors.red),
        ),
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
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.only(left: 12),
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
            online ? 'ON DUTY' : 'OFF DUTY',
            style: TextStyle(
              color: online ? OpsColors.green : OpsColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          Switch(value: online, onChanged: onChanged),
        ],
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

        if (active.isEmpty) {
          return const OpsEmptyState(
            icon: Icons.route_outlined,
            title: 'No assigned delivery',
            message:
                'Accepted orders assigned by the tanker owner will appear here in real time.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: active.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) => _RunCard(order: active[index]),
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
          ],
        );
      },
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
