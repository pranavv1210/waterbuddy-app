import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../../models/order.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/auth/app_role.dart';

class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  ConsumerState<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen> {
  int _activeTab = 0; // 0: Dispatch, 1: Earnings, 2: Profile
  Order? _selectedOrder; // Selected active order on desktop for detailed view
  LatLng? _driverSimulatedLocation;
  Timer? _simulationTimer;

  final List<Map<String, dynamic>> _tabs = [
    {'label': 'Active Dispatch', 'icon': Icons.radar_rounded},
    {'label': 'Earnings & Payouts', 'icon': Icons.payments_rounded},
    {'label': 'Shift Profile', 'icon': Icons.person_pin_rounded},
  ];

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  // Set up a simple simulation of driver moving towards destination when ON_THE_WAY
  void _setupSimulation(LatLng destination) {
    _simulationTimer?.cancel();
    // Default starting point slightly offset from destination (e.g., ~1.5km away)
    _driverSimulatedLocation = LatLng(
      destination.latitude - 0.008,
      destination.longitude - 0.008,
    );

    _simulationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || _driverSimulatedLocation == null) {
        timer.cancel();
        return;
      }
      final double latDiff = destination.latitude - _driverSimulatedLocation!.latitude;
      final double lngDiff = destination.longitude - _driverSimulatedLocation!.longitude;

      if (latDiff.abs() < 0.0005 && lngDiff.abs() < 0.0005) {
        // Arrived at destination
        setState(() {
          _driverSimulatedLocation = destination;
        });
        timer.cancel();
      } else {
        setState(() {
          _driverSimulatedLocation = LatLng(
            _driverSimulatedLocation!.latitude + latDiff * 0.15,
            _driverSimulatedLocation!.longitude + lngDiff * 0.15,
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(driverOnlineProvider);
    final assignedOrdersAsync = ref.watch(driverAssignedOrdersProvider);
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width > 800;

    const primaryColor = Color(0xFF0F172A); // Navy
    const accentColor = Color(0xFFF59E0B); // Amber / Yellow for driver feel
    const cardBgColor = Colors.white;

    // Monitor assigned orders to automatically select the first active order
    assignedOrdersAsync.whenData((orders) {
      if (orders.isNotEmpty) {
        final activeOrders = orders.where((o) => o.status != 'DELIVERED' && o.status != 'CANCELLED').toList();
        if (activeOrders.isNotEmpty) {
          final isSelectedStillActive = activeOrders.any((o) => o.id == _selectedOrder?.id);
          if (!isSelectedStillActive || _selectedOrder == null) {
            setState(() {
              _selectedOrder = activeOrders.first;
            });
            final lat = _selectedOrder!.location['latitude'] as num?;
            final lng = _selectedOrder!.location['longitude'] as num?;
            if (lat != null && lng != null) {
              _setupSimulation(LatLng(lat.toDouble(), lng.toDouble()));
            }
          }
        } else {
          setState(() {
            _selectedOrder = null;
            _simulationTimer?.cancel();
            _driverSimulatedLocation = null;
          });
        }
      } else {
        setState(() {
          _selectedOrder = null;
          _simulationTimer?.cancel();
          _driverSimulatedLocation = null;
        });
      }
    });

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
                  child: const Icon(Icons.local_shipping_rounded, color: accentColor, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Driver Dispatch Portal',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: primaryColor),
                    ),
                    Text(
                      online ? 'On Duty • Accepting Runs' : 'Off Duty • Offline',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: online ? const Color(0xFF10B981) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                // Shift On/Off Switch
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
                        online ? 'ON DUTY' : 'GO ON DUTY',
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
                        onChanged: (value) => ref.read(driverOnlineProvider.notifier).setOnline(value),
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
          return _DriverDispatchView(
            online: online,
            ordersAsync: assignedOrdersAsync,
            selectedOrder: _selectedOrder,
            driverSimulatedLocation: _driverSimulatedLocation,
            onOrderSelected: (order) {
              setState(() {
                _selectedOrder = order;
              });
              final lat = order.location['latitude'] as num?;
              final lng = order.location['longitude'] as num?;
              if (lat != null && lng != null) {
                _setupSimulation(LatLng(lat.toDouble(), lng.toDouble()));
              }
            },
          );
        case 1:
          return const _DriverEarningsView();
        case 2:
          return const _DriverProfileSettingsView();
        default:
          return const SizedBox.shrink();
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

    // Mobile Navigation view
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Driver Shift', style: TextStyle(fontWeight: FontWeight.w900, color: primaryColor)),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05))),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (index) {
                final tab = _tabs[index];
                final isSelected = _activeTab == index;
                return InkWell(
                  onTap: () => setState(() => _activeTab = index),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab['icon'],
                          color: isSelected ? accentColor : const Color(0xFF64748B),
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab['label'].split(' ')[0],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? accentColor : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- DISPATCH VIEW ----------------
class _DriverDispatchView extends ConsumerWidget {
  const _DriverDispatchView({
    required this.online,
    required this.ordersAsync,
    required this.selectedOrder,
    required this.driverSimulatedLocation,
    required this.onOrderSelected,
  });

  final bool online;
  final AsyncValue<List<Order>> ordersAsync;
  final Order? selectedOrder;
  final LatLng? driverSimulatedLocation;
  final ValueChanged<Order> onOrderSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width > 800;

    if (!online) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2), width: 2),
                ),
                child: const Icon(Icons.power_settings_new_rounded, size: 56, color: Color(0xFFF59E0B)),
              ),
              const SizedBox(height: 24),
              const Text(
                'You are Offline',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Turn on your shift to go online, accept deliveries,\nand track your earnings live.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.5),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => ref.read(driverOnlineProvider.notifier).setOnline(true),
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                label: const Text('GO ON DUTY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ordersAsync.when(
      data: (orders) {
        final activeOrders = orders.where((o) => o.status != 'DELIVERED' && o.status != 'CANCELLED').toList();

        if (activeOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildScanningRadar(),
                const SizedBox(height: 24),
                const Text(
                  'On Patrol & Scanning...',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Waiting for booking assignment from seller control.\nMake sure to stay online to catch incoming runs.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
                ),
              ],
            ),
          );
        }

        final current = selectedOrder ?? activeOrders.first;
        final lat = current.location['latitude'] as num?;
        final lng = current.location['longitude'] as num?;
        final destLatLng = lat != null && lng != null ? LatLng(lat.toDouble(), lng.toDouble()) : null;

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left pane: active list + selected detail card
              Container(
                width: 420,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Column(
                  children: [
                    // Active order selector header
                    if (activeOrders.length > 1)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Active Tasks (${activeOrders.length})',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 48,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: activeOrders.length,
                                itemBuilder: (context, idx) {
                                  final order = activeOrders[idx];
                                  final isSel = order.id == current.id;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      selected: isSel,
                                      onSelected: (_) => onOrderSelected(order),
                                      label: Text('Trip #${order.id.substring(0, 6).toUpperCase()}'),
                                      selectedColor: const Color(0xFFFEF3C7),
                                      labelStyle: TextStyle(
                                        color: isSel ? const Color(0xFFD97706) : const Color(0xFF334155),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _DriverOrderControlPane(order: current, ref: ref),
                      ),
                    ),
                  ],
                ),
              ),
              // Right pane: Map overview
              Expanded(
                child: Stack(
                  children: [
                    if (destLatLng != null)
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: driverSimulatedLocation ?? destLatLng,
                          initialZoom: 14,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.waterbuddy.driver',
                          ),
                          MarkerLayer(
                            markers: [
                              // Destination Marker
                              Marker(
                                point: destLatLng,
                                width: 80,
                                height: 80,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                      ),
                                      child: const Text('Client', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                    const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 40),
                                  ],
                                ),
                              ),
                              // Driver Simulated Marker
                              if (driverSimulatedLocation != null)
                                Marker(
                                  point: driverSimulatedLocation!,
                                  width: 60,
                                  height: 60,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: [
                                        BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.5), blurRadius: 10, spreadRadius: 2)
                                      ],
                                    ),
                                    child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 20),
                                  ),
                                ),
                            ],
                          ),
                          if (driverSimulatedLocation != null)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: [driverSimulatedLocation!, destLatLng],
                                  color: const Color(0xFF3B82F6),
                                  strokeWidth: 4,
                                ),
                              ],
                            ),
                        ],
                      )
                    else
                      const Center(child: Text('Map preview unavailable for this location.')),
                    
                    // Simulated status badge
                    if (current.status == 'ON_THE_WAY')
                      Positioned(
                        top: 24,
                        left: 24,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.24), blurRadius: 10)],
                          ),
                          child: const Row(
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6)),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'En Route: Simulated tracking GPS is active...',
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        }

        // Mobile layout: Full map screen with overlay bottom sheet controls
        return Stack(
          children: [
            Positioned.fill(
              child: destLatLng != null
                  ? FlutterMap(
                      options: MapOptions(
                        initialCenter: driverSimulatedLocation ?? destLatLng,
                        initialZoom: 14,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.waterbuddy.driver',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: destLatLng,
                              width: 80,
                              height: 80,
                              child: const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 44),
                            ),
                            if (driverSimulatedLocation != null)
                              Marker(
                                point: driverSimulatedLocation!,
                                width: 50,
                                height: 50,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.24), blurRadius: 6)],
                                  ),
                                  child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 18),
                                ),
                              ),
                          ],
                        ),
                      ],
                    )
                  : const Center(child: Text('Map preview unavailable.')),
            ),
            
            // Dispatch details sheet
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          current.tankLabel ?? 'Water delivery',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            current.status.replaceAll('_', ' '),
                            style: const TextStyle(color: Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      current.location['address'] as String? ?? 'No address',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const Divider(height: 24),
                    _DriverOrderControlPane(order: current, ref: ref),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B))),
      error: (e, _) => Center(child: Text('Error loading assignments: $e')),
    );
  }

  Widget _buildScanningRadar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Color(0xFFF59E0B),
          ),
        ),
      ),
    );
  }
}

// ---------------- ORDER CONTROL COMPONENT ----------------
class _DriverOrderControlPane extends StatelessWidget {
  const _DriverOrderControlPane({required this.order, required this.ref});
  final Order order;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final address = order.location['address'] as String? ?? 'Delivery location unavailable';
    final lat = order.location['latitude'] as num?;
    final lng = order.location['longitude'] as num?;
    final customerPhone = order.location['customerPhone'] as String? ?? order.location['phoneNumber'] as String? ?? '';
    final customerName = order.location['customerName'] as String? ?? 'WaterBuddy Buyer';
    
    final isAssigned = order.status == 'DRIVER_ASSIGNED' || order.status == 'ASSIGNED';
    final isOnTheWay = order.status == 'ON_THE_WAY';
    final isArrived = order.status == 'ARRIVED';

    String actionBtnLabel = '';
    Color actionBtnColor = const Color(0xFF10B981);
    String nextStatus = '';

    if (isAssigned) {
      actionBtnLabel = 'START DISPATCH';
      actionBtnColor = const Color(0xFF3B82F6);
      nextStatus = 'ON_THE_WAY';
    } else if (isOnTheWay) {
      actionBtnLabel = 'MARK AS ARRIVED';
      actionBtnColor = const Color(0xFFF59E0B);
      nextStatus = 'ARRIVED';
    } else if (isArrived) {
      actionBtnLabel = 'COMPLETE DELIVERY';
      actionBtnColor = const Color(0xFF10B981);
      nextStatus = 'DELIVERED';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Client Info Header
        Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFF1F5F9),
              child: Text(customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customerName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1E293B))),
                  Text('Active Client', style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Destination Info
        const Text('DELIVERY DESTINATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_pin, color: Colors.redAccent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                address,
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w600, height: 1.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Utility details (Tank size, instructions)
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TANK SIZE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    Text(order.tankLabel ?? '${order.tankSize} Litres', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TRIP ESTIMATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    const Text('₹250.00 Fixed', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF10B981))),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Contacts & Navigation
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: customerPhone.isEmpty
                    ? null
                    : () async {
                        await launchUrl(Uri(scheme: 'tel', path: customerPhone));
                      },
                icon: const Icon(Icons.call_rounded, size: 16),
                label: const Text('Call Client'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E293B),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: lat == null || lng == null
                    ? null
                    : () async {
                        final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${lat.toDouble()},${lng.toDouble()}');
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                icon: const Icon(Icons.navigation_rounded, size: 16),
                label: const Text('Open GPS'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E293B),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Emergency Assist Contact Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              await launchUrl(Uri(scheme: 'tel', path: '112')); // Emergency contact
            },
            icon: const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.redAccent),
            label: const Text('Emergency Assistance (112)', style: TextStyle(color: Colors.redAccent)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.redAccent.withOpacity(0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Action Button
        if (actionBtnLabel.isNotEmpty)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                ref.read(orderServiceProvider).updateOrderStatus(order.id, nextStatus);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: actionBtnColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                actionBtnLabel,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white, letterSpacing: 0.5),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------- DRIVER EARNINGS VIEW ----------------
class _DriverEarningsView extends ConsumerWidget {
  const _DriverEarningsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider)?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders')
          .where('driverId', isEqualTo: uid)
          .where('status', isEqualTo: 'DELIVERED')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)));
        }

        final docs = snapshot.data?.docs ?? [];
        int completedTripsCount = docs.length;
        int tripPayout = 250; // ₹250 flat fee per driver run
        int totalEarned = completedTripsCount * tripPayout;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Shift Earnings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: _buildMetricBox(
                      title: 'Total Earned',
                      value: '₹$totalEarned',
                      icon: Icons.payments_rounded,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricBox(
                      title: 'Trips Done',
                      value: '$completedTripsCount',
                      icon: Icons.checklist_rtl_rounded,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              const Text(
                'Trip History log',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 12),

              if (docs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.history_rounded, size: 48, color: Color(0xFF94A3B8)),
                        SizedBox(height: 12),
                        Text(
                          'No completed runs yet.',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Complete delivery assignments to see payout receipts.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final orderDoc = docs[index];
                    final data = orderDoc.data() as Map<String, dynamic>;
                    final address = data['location']?['address'] as String? ?? 'Delivered location';
                    final tankSize = data['tankSize'] as num? ?? 15000;
                    final completedAt = (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.white,
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981)),
                        ),
                        title: Text(
                          'Trip #${orderDoc.id.substring(0, 6).toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                        subtitle: Text(
                          '$address\n${completedAt.hour}:${completedAt.minute.toString().padLeft(2, '0')} • ${tankSize.toInt()}L Tanker',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                        trailing: const Text(
                          '+₹250.00',
                          style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 15),
                        ),
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

  Widget _buildMetricBox({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }
}

// ---------------- DRIVER PROFILE & SETTINGS ----------------
class _DriverProfileSettingsView extends ConsumerWidget {
  const _DriverProfileSettingsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider)?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('drivers').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)));
        }

        final driverData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final name = driverData['driverName'] ?? driverData['fullName'] ?? 'Active Driver';
        final phone = driverData['phone'] ?? driverData['phoneNumber'] ?? 'Unavailable';
        final license = driverData['driverLicenseNumber'] ?? 'DL-9843-WB';
        final aadhaar = driverData['aadhaarNumber'] ?? 'XXXX-XXXX-8943';
        final emergency = driverData['emergencyContact'] ?? 'Not set';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Shift Profile & Info',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 20),
              
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFFFEF3C7),
                        child: Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A))),
                            const SizedBox(height: 4),
                            Text('Role: Registered Driver Agent', style: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Onboarding KYC Credentials',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
              ),
              const SizedBox(height: 12),
              
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildInfoTile('Mobile Number', phone, Icons.phone_android_rounded),
                    _buildDivider(),
                    _buildInfoTile('Driver License Number', license, Icons.badge_rounded),
                    _buildDivider(),
                    _buildInfoTile('Aadhaar UID number', aadhaar, Icons.perm_identity_rounded),
                    _buildDivider(),
                    _buildInfoTile('Emergency Dispatch contact', emergency, Icons.emergency_share_rounded),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),

              // Switch to Seller Mode Button if owner is also a driver
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(selectedRoleProvider.notifier).set(AppRole.seller);
                    if (context.mounted) {
                      context.go(RouteNames.sellerDashboard);
                    }
                  },
                  icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
                  label: const Text('SWITCH TO SELLER MODE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Logout Action
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final auth = ref.read(authServiceProvider);
                    final roleNotifier = ref.read(selectedRoleProvider.notifier);
                    await auth.signOut();
                    await roleNotifier.clear();
                    if (context.mounted) {
                      context.go(RouteNames.roleSelection);
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  label: const Text('SIGN OUT ACCOUNT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.redAccent)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(String label, String val, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF64748B)),
      title: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
      subtitle: Text(val, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9));
}
