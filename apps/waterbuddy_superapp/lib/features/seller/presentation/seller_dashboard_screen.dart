import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/order.dart' as app_order;
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/operations_ui.dart';

class SellerDashboardScreen extends ConsumerStatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  ConsumerState<SellerDashboardScreen> createState() =>
      _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends ConsumerState<SellerDashboardScreen> {
  int _tab = 0;

  static const _tabs = [
    OpsTab(label: 'Orders', icon: Icons.assignment_rounded),
    OpsTab(label: 'Fleet', icon: Icons.local_shipping_rounded),
    OpsTab(label: 'Drivers', icon: Icons.groups_rounded),
    OpsTab(label: 'Payouts', icon: Icons.payments_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(sellerOnlineProvider);

    return OpsScaffold(
      title: 'Tanker Owner',
      subtitle: online ? 'Online for water requests' : 'Offline',
      accent: OpsColors.blue,
      tabs: _tabs,
      activeIndex: _tab,
      onTabChanged: (index) => setState(() => _tab = index),
      actions: [
        _OnlineSwitch(
          online: online,
          onChanged: (value) =>
              ref.read(sellerOnlineProvider.notifier).setOnline(value),
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
          _SellerOrdersView(),
          _FleetView(),
          _DriversView(),
          _SellerPayoutsView(),
        ],
      ),
    );
  }
}

class _OnlineSwitch extends StatelessWidget {
  const _OnlineSwitch({required this.online, required this.onChanged});

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
            online ? 'ONLINE' : 'OFFLINE',
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

class _SellerOrdersView extends ConsumerWidget {
  const _SellerOrdersView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(sellerOnlineProvider);
    final active = ref.watch(sellerActiveOrdersProvider);
    final nearby = ref.watch(searchingOrdersProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _SectionHeader(
          title: 'Active deliveries',
          subtitle: 'Orders accepted by this seller account.',
          icon: Icons.route_rounded,
        ),
        active.when(
          data: (orders) => orders.isEmpty
              ? const OpsCard(
                  child: Text(
                    'No active delivery. Accepted orders appear here.',
                    style: TextStyle(
                      color: OpsColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : _OrderWrap(
                  orders: orders,
                  builder: (order) => _SellerOrderCard(order: order),
                ),
          loading: () => const _LoadingLine(),
          error: (error, _) => _ErrorLine(message: error.toString()),
        ),
        const SizedBox(height: 28),
        _SectionHeader(
          title: 'Nearby request feed',
          subtitle: online
              ? 'Live requests available for acceptance.'
              : 'Go online to receive nearby requests.',
          icon: Icons.radar_rounded,
        ),
        if (!online)
          const OpsCard(
            child: Text(
              'You are offline. Turn on availability from the top bar to accept requests.',
              style: TextStyle(
                  color: OpsColors.muted, fontWeight: FontWeight.w600),
            ),
          )
        else
          nearby.when(
            data: (orders) => orders.isEmpty
                ? const OpsCard(
                    child: Text(
                      'No nearby requests right now.',
                      style: TextStyle(
                        color: OpsColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : _OrderWrap(
                    orders: orders,
                    builder: (order) => _NearbyOrderCard(order: order),
                  ),
            loading: () => const _LoadingLine(),
            error: (error, _) => _ErrorLine(message: error.toString()),
          ),
      ],
    );
  }
}

class _OrderWrap extends StatelessWidget {
  const _OrderWrap({required this.orders, required this.builder});

  final List<app_order.Order> orders;
  final Widget Function(app_order.Order order) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 920
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final order in orders)
              SizedBox(width: width, child: builder(order)),
          ],
        );
      },
    );
  }
}

class _NearbyOrderCard extends ConsumerWidget {
  const _NearbyOrderCard({required this.order});

  final app_order.Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider)?.uid;
    return OpsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OrderTitle(order: order),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: uid == null
                  ? null
                  : () async {
                      await ref
                          .read(orderServiceProvider)
                          .acceptOrder(order.id, uid);
                    },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Accept request'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SellerOrderCard extends ConsumerWidget {
  const _SellerOrderCard({required this.order});

  final app_order.Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider)?.uid;
    final drivers = ref.watch(driversProvider);
    return OpsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OrderTitle(order: order),
          const SizedBox(height: 14),
          drivers.when(
            data: (snapshot) {
              final sellerDrivers = snapshot.docs.where((doc) {
                final data = doc.data();
                return data['sellerId'] == uid || doc.id == uid;
              }).toList();

              if (order.driverId != null) {
                return _DriverAssignedLine(driverId: order.driverId!);
              }

              return Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: _fieldDecoration('Assign driver'),
                      items: [
                        for (final doc in sellerDrivers)
                          DropdownMenuItem(
                            value: doc.id,
                            child: Text(
                              (doc.data()['driverName'] ??
                                      doc.data()['fullName'] ??
                                      doc.id)
                                  .toString(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: uid == null
                          ? null
                          : (driverId) async {
                              if (driverId == null) return;
                              await ref.read(orderServiceProvider).assignDriver(
                                    orderId: order.id,
                                    sellerId: uid,
                                    driverId: driverId,
                                  );
                            },
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: uid == null
                        ? null
                        : () async {
                            await ref.read(orderServiceProvider).assignDriver(
                                  orderId: order.id,
                                  sellerId: uid,
                                  driverId: uid,
                                );
                          },
                    child: const Text('Self-drive'),
                  ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (_, __) => const Text(
              'Unable to load drivers.',
              style: TextStyle(color: OpsColors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverAssignedLine extends StatelessWidget {
  const _DriverAssignedLine({required this.driverId});

  final String driverId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.person_pin_circle_rounded, color: OpsColors.green),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Driver assigned: $driverId',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: OpsColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderTitle extends StatelessWidget {
  const _OrderTitle({required this.order});

  final app_order.Order order;

  @override
  Widget build(BuildContext context) {
    final address = order.deliveryAddress ?? 'Address unavailable';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                order.tankLabel,
                style: const TextStyle(
                  color: OpsColors.ink,
                  fontSize: 18,
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
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.location_on_rounded,
                color: OpsColors.muted, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: OpsColors.muted,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${order.paymentType}  |  ${order.paymentStatus}',
          style: const TextStyle(
            color: OpsColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FleetView extends ConsumerStatefulWidget {
  const _FleetView();

  @override
  ConsumerState<_FleetView> createState() => _FleetViewState();
}

class _FleetViewState extends ConsumerState<_FleetView> {
  final _vehicle = TextEditingController();
  final _capacity = TextEditingController();

  @override
  void dispose() {
    _vehicle.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _addVehicle(String sellerId) async {
    if (_vehicle.text.trim().isEmpty || _capacity.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('sellers').doc(sellerId).set({
      'tankerVehicles': FieldValue.arrayUnion([
        {
          'vehicleNumber': _vehicle.text.trim().toUpperCase(),
          'capacity':
              int.tryParse(_capacity.text.trim()) ?? _capacity.text.trim(),
          'status': 'available',
          'createdAt': Timestamp.now(),
        }
      ]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    _vehicle.clear();
    _capacity.clear();
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUserProvider)?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection('sellers').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final vehicles =
            snapshot.data?.data()?['tankerVehicles'] as List<dynamic>? ?? [];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionHeader(
              title: 'Fleet management',
              subtitle: 'Only vehicles saved in Firestore are shown.',
              icon: Icons.local_shipping_rounded,
              action: FilledButton.icon(
                onPressed: () => _showVehicleDialog(context, uid),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add tanker'),
              ),
            ),
            if (vehicles.isEmpty)
              const OpsEmptyState(
                icon: Icons.local_shipping_outlined,
                title: 'No tankers registered',
                message:
                    'Add tanker vehicles to make assignment and capacity tracking operational.',
              )
            else
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final item in vehicles)
                    SizedBox(
                      width: 360,
                      child: OpsCard(
                        child: _VehicleTile(
                          data: Map<String, dynamic>.from(item as Map),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  void _showVehicleDialog(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add tanker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _vehicle,
              textCapitalization: TextCapitalization.characters,
              decoration: _fieldDecoration('Vehicle number'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _capacity,
              keyboardType: TextInputType.number,
              decoration: _fieldDecoration('Capacity in litres'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await _addVehicle(uid);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? 'available').toString();
    return Row(
      children: [
        const Icon(Icons.local_shipping_rounded,
            color: OpsColors.blue, size: 32),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (data['vehicleNumber'] ?? 'Vehicle').toString(),
                style: const TextStyle(
                  color: OpsColors.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              Text(
                '${data['capacity'] ?? '-'} litres',
                style: const TextStyle(color: OpsColors.muted),
              ),
            ],
          ),
        ),
        OpsStatusPill(
            label: status.toUpperCase(), color: orderStatusColor(status)),
      ],
    );
  }
}

class _DriversView extends ConsumerStatefulWidget {
  const _DriversView();

  @override
  ConsumerState<_DriversView> createState() => _DriversViewState();
}

class _DriversViewState extends ConsumerState<_DriversView> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _addDriver(String sellerId) async {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('drivers').add({
      'driverName': _name.text.trim(),
      'phone': _phone.text.trim(),
      'email': _email.text.trim(),
      'sellerId': sellerId,
      'verificationStatus': 'pending',
      'isOnline': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _name.clear();
    _phone.clear();
    _email.clear();
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUserProvider)?.uid;
    final drivers = ref.watch(driversProvider);
    if (uid == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionHeader(
          title: 'Driver management',
          subtitle: 'Drivers linked to this seller account.',
          icon: Icons.groups_rounded,
          action: FilledButton.icon(
            onPressed: () => _showDriverDialog(context, uid),
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Add driver'),
          ),
        ),
        drivers.when(
          data: (snapshot) {
            final list = snapshot.docs
                .where((doc) => doc.data()['sellerId'] == uid)
                .toList();
            if (list.isEmpty) {
              return const OpsEmptyState(
                icon: Icons.groups_outlined,
                title: 'No drivers added',
                message:
                    'Add drivers to assign accepted water deliveries to your fleet.',
              );
            }
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final doc in list)
                  SizedBox(width: 360, child: _DriverTile(doc: doc)),
              ],
            );
          },
          loading: () => const _LoadingLine(),
          error: (error, _) => _ErrorLine(message: error.toString()),
        ),
      ],
    );
  }

  void _showDriverDialog(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add driver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _name, decoration: _fieldDecoration('Full name')),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: _fieldDecoration('Mobile number'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: _fieldDecoration('Email optional'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await _addDriver(uid);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _DriverTile extends StatelessWidget {
  const _DriverTile({required this.doc});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final status = (data['verificationStatus'] ?? 'pending').toString();
    return OpsCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: OpsColors.blue.withValues(alpha: 0.12),
            child: const Icon(Icons.person_rounded, color: OpsColors.blue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (data['driverName'] ?? data['fullName'] ?? doc.id).toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: OpsColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  (data['phone'] ?? data['phoneNumber'] ?? 'No phone')
                      .toString(),
                  style: const TextStyle(color: OpsColors.muted),
                ),
              ],
            ),
          ),
          OpsStatusPill(
              label: status.toUpperCase(), color: orderStatusColor(status)),
        ],
      ),
    );
  }
}

class _SellerPayoutsView extends ConsumerWidget {
  const _SellerPayoutsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider)?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('sellerId', isEqualTo: uid)
          .where('status', isEqualTo: 'DELIVERED')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final amounts = docs
            .map((doc) => _recordedAmount(doc.data()))
            .whereType<num>()
            .toList();
        final total = amounts.fold<num>(0, (total, amount) => total + amount);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _SectionHeader(
              title: 'Payouts',
              subtitle:
                  'Only delivered orders and recorded amount fields are shown.',
              icon: Icons.payments_rounded,
            ),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 280,
                  child: OpsCard(
                    child: _Metric(
                      label: 'Delivered orders',
                      value: '${docs.length}',
                      icon: Icons.check_circle_rounded,
                    ),
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: OpsCard(
                    child: _Metric(
                      label: 'Recorded payout',
                      value: amounts.isEmpty
                          ? 'Not recorded'
                          : 'Rs ${total.toInt()}',
                      icon: Icons.account_balance_wallet_rounded,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (docs.isEmpty)
              const OpsEmptyState(
                icon: Icons.receipt_long_rounded,
                title: 'No delivered orders',
                message:
                    'Completed deliveries will appear here once orders are delivered.',
              )
            else
              for (final doc in docs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OpsCard(
                    child: _PayoutRow(id: doc.id, data: doc.data()),
                  ),
                ),
          ],
        );
      },
    );
  }

  static num? _recordedAmount(Map<String, dynamic> data) {
    return data['amount'] as num? ??
        data['totalAmount'] as num? ??
        data['price'] as num?;
  }
}

class _PayoutRow extends StatelessWidget {
  const _PayoutRow({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final amount = _SellerPayoutsView._recordedAmount(data);
    return Row(
      children: [
        const Icon(Icons.receipt_long_rounded, color: OpsColors.green),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Order ${id.substring(0, id.length < 8 ? id.length : 8).toUpperCase()}',
            style: const TextStyle(
              color: OpsColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          amount == null ? 'Amount not recorded' : 'Rs ${amount.toInt()}',
          style: const TextStyle(
            color: OpsColors.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: OpsColors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: OpsColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: OpsColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.action,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: OpsColors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: OpsColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: OpsColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class _LoadingLine extends StatelessWidget {
  const _LoadingLine();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: LinearProgressIndicator(minHeight: 2),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return OpsCard(
      child: Text(
        message,
        style:
            const TextStyle(color: OpsColors.red, fontWeight: FontWeight.w700),
      ),
    );
  }
}

InputDecoration _fieldDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: OpsColors.line),
    ),
  );
}
