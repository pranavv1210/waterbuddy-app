import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../../models/order.dart' as app_order;
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../core/auth/app_role.dart';

class SellerDashboardScreen extends ConsumerStatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  ConsumerState<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends ConsumerState<SellerDashboardScreen> {
  int _activeTab = 0; // 0: Active, 1: Nearby, 2: Fleet, 3: Drivers, 4: Earnings

  final List<Map<String, dynamic>> _tabs = [
    {'label': 'Active Deliveries', 'icon': Icons.local_shipping_rounded},
    {'label': 'Nearby Feed', 'icon': Icons.radar_rounded},
    {'label': 'Fleet Management', 'icon': Icons.fire_truck_rounded},
    {'label': 'Driver Partners', 'icon': Icons.people_alt_rounded},
    {'label': 'Earnings & Reports', 'icon': Icons.analytics_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(sellerOnlineProvider);
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width > 800;

    const primaryColor = Color(0xFF0F172A); // Navy
    const accentColor = Color(0xFF0EA5E9); // Tealish Blue

    Widget buildHeader() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.water_drop_rounded, color: accentColor, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Partner Dashboard',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: primaryColor),
                    ),
                    Text(
                      online ? 'Online & Accepting Orders' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: online ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                // Switch to Driver Mode Button
                ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(selectedRoleProvider.notifier).set(AppRole.driver);
                    if (context.mounted) {
                      context.go(RouteNames.driverDashboard);
                    }
                  },
                  icon: const Icon(Icons.swap_horizontal_circle_rounded, size: 18, color: Colors.white),
                  label: const Text(
                    'Switch to Driver Mode',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 16),
                // Online/Offline Switch
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: online ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: online ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        online ? 'ONLINE' : 'GO ONLINE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: online ? const Color(0xFF047857) : const Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Switch(
                        value: online,
                        activeColor: const Color(0xFF10B981),
                        activeTrackColor: const Color(0xFFA7F3D0),
                        inactiveThumbColor: const Color(0xFF94A3B8),
                        inactiveTrackColor: const Color(0xFFE2E8F0),
                        onChanged: (value) => ref.read(sellerOnlineProvider.notifier).setOnline(value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  onPressed: () async {
                    final auth = ref.read(authServiceProvider);
                    final roleNotifier = ref.read(selectedRoleProvider.notifier);
                    await auth.signOut();
                    await roleNotifier.clear();
                    if (context.mounted) {
                      context.go(RouteNames.roleSelection);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }

    Widget buildBody() {
      switch (_activeTab) {
        case 0:
          return const _ActiveDeliveriesView();
        case 1:
          return const _NearbyOrdersView();
        case 2:
          return const _FleetManagementView();
        case 3:
          return const _DriverManagementView();
        case 4:
          return const _EarningsView();
        default:
          return const _ActiveDeliveriesView();
      }
    }

    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            buildHeader(),
            Expanded(
              child: Row(
                children: [
                  // Sidebar navigation
                  Container(
                    width: 280,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(_tabs.length, (index) {
                        final tab = _tabs[index];
                        final isSelected = _activeTab == index;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: InkWell(
                            onTap: () => setState(() => _activeTab = index),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isSelected ? accentColor.withOpacity(0.08) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected ? Border.all(color: accentColor.withOpacity(0.2)) : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(tab['icon'], color: isSelected ? accentColor : const Color(0xFF64748B), size: 20),
                                  const SizedBox(width: 14),
                                  Text(
                                    tab['label'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      color: isSelected ? accentColor : const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
                  // Content Pane
                  Expanded(child: buildBody()),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile / Tablet layout
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Partner Portal', style: TextStyle(fontWeight: FontWeight.w900, color: primaryColor)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              final auth = ref.read(authServiceProvider);
              final roleNotifier = ref.read(selectedRoleProvider.notifier);
              await auth.signOut();
              await roleNotifier.clear();
              if (context.mounted) {
                context.go(RouteNames.roleSelection);
              }
            },
          ),
        ],
      ),
      body: buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _activeTab,
        onTap: (index) => setState(() => _activeTab = index),
        selectedItemColor: accentColor,
        unselectedItemColor: const Color(0xFF94A3B8),
        showSelectedLabels: true,
        showUnselectedLabels: false,
        backgroundColor: Colors.white,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        items: _tabs.map((tab) {
          return BottomNavigationBarItem(
            icon: Icon(tab['icon']),
            label: tab['label'],
          );
        }).toList(),
      ),
    );
  }
}

// ---------------- ACTIVE DELIVERIES ----------------
class _ActiveDeliveriesView extends ConsumerWidget {
  const _ActiveDeliveriesView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrders = ref.watch(sellerActiveOrdersProvider);
    final drivers = ref.watch(driversProvider);
    final uid = ref.watch(currentUserProvider)?.uid;

    return activeOrders.when(
      data: (orders) {
        if (orders.isEmpty) {
          return _buildEmptyState(
            icon: Icons.local_shipping_rounded,
            title: 'No active deliveries',
            subtitle: 'Go online and accept order requests from the nearby feed.',
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 450,
            mainAxisExtent: 260,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  )
                ],
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          order.tankLabel,
                          style: const TextStyle(
                            color: Color(0xFF1D4ED8),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: order.status == 'ASSIGNED'
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          order.status,
                          style: TextStyle(
                            color: order.status == 'ASSIGNED'
                                ? const Color(0xFFD97706)
                                : const Color(0xFF059669),
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery Address',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.deliveryAddress ?? 'Address unavailable',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Payment: ${order.paymentType} • ${order.paymentStatus}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),
                  // Assign driver or view status
                  Row(
                    children: [
                      Expanded(
                        child: drivers.when(
                          data: (snapshot) {
                            final list = snapshot.docs.where((d) {
                              final data = d.data();
                              return data['sellerId'] == uid;
                            }).toList();

                            return DropdownButtonFormField<String>(
                              value: order.driverId,
                              hint: const Text('Assign Driver'),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                              ),
                              items: list
                                  .map((doc) => DropdownMenuItem(
                                        value: doc.id,
                                        child: Text(
                                          (doc.data()['fullName'] ?? doc.data()['driverName'] ?? doc.id).toString(),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (driverId) {
                                if (driverId == null) return;
                                ref.read(orderServiceProvider).assignDriver(
                                      orderId: order.id,
                                      sellerId: uid!,
                                      driverId: driverId,
                                    );
                              },
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // If owner wants to deliver it directly themselves
                      IconButton(
                        icon: const Icon(Icons.done_all_rounded, color: Color(0xFF10B981)),
                        tooltip: 'Transition Status',
                        onPressed: () {
                          final nextStatus = order.status == 'ASSIGNED'
                              ? 'ON_THE_WAY'
                              : order.status == 'ON_THE_WAY'
                                  ? 'ARRIVED'
                                  : 'DELIVERED';
                          ref.read(orderServiceProvider).updateOrderStatus(order.id, nextStatus);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
    );
  }
}

// ---------------- NEARBY ORDERS FEED ----------------
class _NearbyOrdersView extends ConsumerWidget {
  const _NearbyOrdersView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchingOrders = ref.watch(searchingOrdersProvider);
    final uid = ref.watch(currentUserProvider)?.uid;

    return searchingOrders.when(
      data: (orders) {
        if (orders.isEmpty) {
          return _buildEmptyState(
            icon: Icons.radar_rounded,
            title: 'No nearby requests',
            subtitle: 'Searching for consumers needing water delivery in your active radius...',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.water_drop_rounded, color: Color(0xFF0EA5E9), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.tankLabel,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.deliveryAddress ?? 'Address unavailable',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (uid != null) {
                        ref.read(orderServiceProvider).acceptOrder(order.id, uid);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Accept Order', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
    );
  }
}

// ---------------- FLEET MANAGEMENT ----------------
class _FleetManagementView extends ConsumerStatefulWidget {
  const _FleetManagementView();

  @override
  ConsumerState<_FleetManagementView> createState() => _FleetManagementViewState();
}

class _FleetManagementViewState extends ConsumerState<_FleetManagementView> {
  final _vehicleController = TextEditingController();
  final _capacityController = TextEditingController();

  void _addVehicle(String uid) {
    if (_vehicleController.text.isEmpty || _capacityController.text.isEmpty) return;

    FirebaseFirestore.instance.collection('sellers').doc(uid).update({
      'tankerVehicles': FieldValue.arrayUnion([
        {
          'vehicleNumber': _vehicleController.text,
          'capacity': int.parse(_capacityController.text),
          'vehicleRc': 'Uploaded',
        }
      ])
    });

    _vehicleController.clear();
    _capacityController.clear();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUserProvider)?.uid;

    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('sellers').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final list = data?['tankerVehicles'] as List<dynamic>? ?? [];

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Add Tanker Vehicle', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _vehicleController,
                        decoration: const InputDecoration(labelText: 'Vehicle Plate Number'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _capacityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Capacity (Litres)'),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () => _addVehicle(uid),
                      child: const Text('Add Vehicle'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Register Vehicle', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF0EA5E9),
          ),
          body: list.isEmpty
              ? _buildEmptyState(
                  icon: Icons.fire_truck_rounded,
                  title: 'No vehicles registered',
                  subtitle: 'Register your tanker truck capacity and plate number to start dispatching drivers.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final vehicle = list[index] as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.fire_truck_rounded, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vehicle['vehicleNumber'] ?? 'Unknown',
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Capacity: ${vehicle['capacity'] ?? 15000}L • Document: ${vehicle['vehicleRc']}',
                                    style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const Chip(
                              label: Text('Verified', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF047857), fontSize: 11)),
                              backgroundColor: Color(0xFFD1FAE5),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

// ---------------- DRIVER MANAGEMENT ----------------
class _DriverManagementView extends ConsumerStatefulWidget {
  const _DriverManagementView();

  @override
  ConsumerState<_DriverManagementView> createState() => _DriverManagementViewState();
}

class _DriverManagementViewState extends ConsumerState<_DriverManagementView> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  void _addDriver(String sellerId) {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) return;

    FirebaseFirestore.instance.collection('drivers').add({
      'fullName': _nameController.text,
      'phoneNumber': _phoneController.text,
      'email': _emailController.text,
      'sellerId': sellerId,
      'verificationStatus': 'approved',
      'createdAt': FieldValue.serverTimestamp(),
    });

    _nameController.clear();
    _phoneController.clear();
    _emailController.clear();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUserProvider)?.uid;
    final drivers = ref.watch(driversProvider);

    if (uid == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Register Driver Partner', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Mobile Number'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email Address (optional)'),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () => _addDriver(uid),
                  child: const Text('Add Driver'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Register Driver', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0EA5E9),
      ),
      body: drivers.when(
        data: (snapshot) {
          final list = snapshot.docs.where((d) => d.data()['sellerId'] == uid).toList();

          if (list.isEmpty) {
            return _buildEmptyState(
              icon: Icons.people_alt_rounded,
              title: 'No driver partners registered',
              subtitle: 'Add drivers under your business account to assign booking requests to them.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final doc = list[index];
              final driverData = doc.data();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person_rounded, color: Color(0xFF16A34A)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driverData['fullName'] ?? driverData['driverName'] ?? doc.id,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Phone: ${driverData['phoneNumber'] ?? 'No phone'} • Status: ${driverData['verificationStatus'] ?? 'approved'}',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const Chip(
                        label: Text('Active', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF047857), fontSize: 11)),
                        backgroundColor: Color(0xFFD1FAE5),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}

// ---------------- EARNINGS VIEW ----------------
class _EarningsView extends ConsumerWidget {
  const _EarningsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider)?.uid;

    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders')
          .where('sellerId', isEqualTo: uid)
          .where('status', isEqualTo: 'DELIVERED')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        int totalEarnings = 0;
        int totalLitres = 0;

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>?;
          final tankSize = data?['tankSize'] as num? ?? 15000;
          // Calculate approx earnings based on tankSize (e.g. ₹500 for small, ₹750 for medium, ₹1000 for large)
          int price = 750;
          if (tankSize <= 10000) price = 500;
          if (tankSize >= 20000) price = 1000;
          totalEarnings += price;
          totalLitres += tankSize.toInt();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Financial Performance',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 20),
              // Stats boxes
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      label: 'Total Payouts',
                      value: '₹$totalEarnings',
                      icon: Icons.account_balance_wallet_rounded,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      label: 'Water Delivered',
                      value: '${totalLitres.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}L',
                      icon: Icons.water_drop_rounded,
                      color: const Color(0xFF0EA5E9),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      label: 'Orders Complete',
                      value: '${docs.length}',
                      icon: Icons.assignment_turned_in_rounded,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Recent Completed Settlements',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              docs.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Center(
                        child: Text(
                          'No completed settlements yet.',
                          style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final orderData = doc.data() as Map<String, dynamic>;
                        final tankSize = orderData['tankSize'] as num? ?? 15000;
                        int price = 750;
                        if (tankSize <= 10000) price = 500;
                        if (tankSize >= 20000) price = 1000;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Settlement for order #${doc.id.substring(0, 8)}',
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Capacity: ${tankSize}L • COD cash collected',
                                    style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                              Text(
                                '+₹$price',
                                style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 16),
                              )
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({required String label, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -1.0),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ---------------- HELPER WIDGETS ----------------
Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: const Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    ),
  );
}
