import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../routes/route_names.dart';
import '../models/home_dashboard.dart';
import '../providers/home_providers.dart';
import '../providers/order_creation_provider.dart';
import '../../../providers/app_providers.dart';
import '../../../models/order.dart' as app_order;
import '../../tracking/providers/searching_providers.dart';
import '../../tracking/models/searching_tankers_state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(homeDashboardProvider);
    final selectedTankId = ref.watch(selectedTankIdProvider) ?? 'medium';
    final activeOrder = ref.watch(activeOrderProvider).value;

    // Listen for active orders to redirect if app was closed or user navigated away
    ref.listen(activeOrderProvider, (previous, next) {
      final activeOrder = next.value;
      if (activeOrder != null) {
        if (activeOrder.status == 'ASSIGNED' || activeOrder.status == 'ON_THE_WAY') {
          context.go('${RouteNames.tracking}?orderId=${activeOrder.id}');
        }
      }
    });

    return _HomeScreenBody(
      state: dashboard,
      selectedTankId: selectedTankId,
      activeOrder: activeOrder,
      onTankSelected: (tankId) {
        ref.read(selectedTankIdProvider.notifier).state = tankId;
      },
    );
  }
}

class _HomeScreenBody extends ConsumerStatefulWidget {
  const _HomeScreenBody({
    required this.state,
    required this.selectedTankId,
    required this.activeOrder,
    required this.onTankSelected,
  });

  final HomeDashboard state;
  final String selectedTankId;
  final app_order.Order? activeOrder;
  final ValueChanged<String> onTankSelected;

  @override
  ConsumerState<_HomeScreenBody> createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends ConsumerState<_HomeScreenBody> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation; // User's real GPS position
  LatLng? _selectedLocation; // Location selected via map center
  String? _currentAddress;
  bool _isLoadingLocation = false;
  bool _isMovingMap = false;
  bool _isLocationConfirmed = false;

  // Default to Bangalore center if location not available
  static const LatLng _defaultLocation = LatLng(12.9716, 77.5946);

  final List<Map<String, dynamic>> tankOptionsData = [
    {'id': 'small', 'size': 'Small Tank', 'litres': 10000, 'icon': Icons.opacity_rounded, 'basePrice': 500},
    {'id': 'medium', 'size': 'Medium Tank', 'litres': 15000, 'icon': Icons.water_drop_rounded, 'basePrice': 750},
    {'id': 'large', 'size': 'Large Tank', 'litres': 20000, 'icon': Icons.waves_rounded, 'basePrice': 1000},
  ];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      
      if (mounted) {
        setState(() {
          _currentLocation = latLng;
          _selectedLocation = latLng;
        });
        _mapController.move(latLng, 15);
        await _getAddressFromLatLng(latLng);
        setState(() => _isLoadingLocation = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentAddress = "${place.locality ?? ''}, ${place.subAdministrativeArea ?? place.locality ?? ''}";
          _currentAddress = _currentAddress!.replaceAll(RegExp(r'^, |, $'), '');
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _onMapPositionChanged(MapCamera position, bool hasGesture) {
    if (hasGesture) {
      if (!_isMovingMap) {
        setState(() => _isMovingMap = true);
      }
      _selectedLocation = position.center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final searchingState = ref.watch(searchingControllerProvider);
    final isSearching = searchingState.orderId != null && (searchingState.orderStatus == 'SEARCHING' || searchingState.isLoading);
    const primary = Color(0xFF0F2B5B);
    const accent = Color(0xFF0EA5E9);

    return PopScope(
      canPop: !_isLocationConfirmed && !isSearching,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        if (isSearching) {
           await ref.read(searchingControllerProvider.notifier).cancelOrder();
        } else if (_isLocationConfirmed) {
           setState(() => _isLocationConfirmed = false);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        drawer: _buildDrawer(user),
        body: Stack(
          children: [
          // 1. FULL SCREEN MAP BACKGROUND
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation ?? _defaultLocation,
                initialZoom: 15,
                interactionOptions: InteractionOptions(
                  flags: _isLocationConfirmed ? InteractiveFlag.none : InteractiveFlag.all,
                ),
                onPositionChanged: _onMapPositionChanged,
                onMapEvent: (event) async {
                  if (event is MapEventMoveEnd) {
                    setState(() => _isMovingMap = false);
                    if (_selectedLocation != null) {
                      await _getAddressFromLatLng(_selectedLocation!);
                    }
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.waterbuddy.customer',
                ),
                if (_currentLocation != null)
                  MarkerLayer(
                    markers: [
                      // User Current Location Dot (Real GPS)
                      Marker(
                        point: _currentLocation!,
                        width: 80,
                        height: 80,
                        child: _buildUserDot(),
                      ),
                      if (_isLocationConfirmed && _selectedLocation != null)
                        Marker(
                          point: _selectedLocation!,
                          width: 80,
                          height: 80,
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFFEF4444),
                            size: 44,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),

          // 2. FIXED CENTER PIN (Uber-style selection)
          if (!_isLocationConfirmed)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40), // Shift up slightly to point at exact center
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Delivery Here',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFFEF4444),
                      size: 44,
                    ),
                  ],
                ),
              ),
            ),

          // 2. TOP LOCATION BAR (Uber style)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    if (!_isLocationConfirmed) ...[
                      Builder(
                        builder: (context) => GestureDetector(
                          onTap: () => Scaffold.of(context).openDrawer(),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A), size: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ] else ...[
                      GestureDetector(
                        onTap: () => setState(() => _isLocationConfirmed = false),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(child: _buildLocationBar()),
                    if (!_isLocationConfirmed) ...[
                      const SizedBox(width: 12),
                      _buildActionsBar(user),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 3. FLOATING LOCATION BUTTON
          Positioned(
            bottom: 380, // Above bottom sheet + nav bar
            right: 16,
            child: FloatingActionButton(
              onPressed: _determinePosition,
              backgroundColor: Colors.white,
              foregroundColor: primary,
              elevation: 4,
              mini: true,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: _isLoadingLocation 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location_rounded, size: 20),
            ),
          ),

          // 4. BOTTOM SHEET (Uber Style)
          _buildBottomSheet(user, primary, accent, widget.activeOrder),
        ],
      ),
    ),
  );
}

  Widget _buildLocationBar() {
    final locText = _isMovingMap 
        ? 'Updating location...' 
        : (_currentAddress ?? 'Fetching location...');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Delivery Location',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  locText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsBar(User? user) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No new notifications'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => context.go(RouteNames.profile),
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0EA5E9).withOpacity(0.1),
              ),
              child: ClipOval(
                child: user?.photoURL != null
                    ? Image.network(user!.photoURL!, fit: BoxFit.cover)
                    : const Icon(Icons.person_rounded, color: Color(0xFF0EA5E9), size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(User? user, Color primary, Color accent, app_order.Order? activeOrder) {
    final searchingState = ref.watch(searchingControllerProvider);
    final isSearching = searchingState.orderId != null && (searchingState.orderStatus == 'SEARCHING' || searchingState.isLoading);

    if (isSearching) {
      return _SearchingBottomSheet(orderId: searchingState.orderId!);
    }

    if (!_isLocationConfirmed) {
      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 25,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: _UserGreeting(user: user)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLocationConfirmed = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Confirm Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.45,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 25,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  children: [
                    const Text(
                      'Choose Tank Size',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...tankOptionsData.map((data) => _buildTankListItem(data, primary)),
                    const SizedBox(height: 80), // Space for fixed button + nav bar
                  ],
                ),
              ),
              
              // Fixed Book Button at bottom of sheet
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: _buildBookButton(primary),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTankListItem(Map<String, dynamic> data, Color primary) {
    final isSelected = widget.selectedTankId == data['id'];
    
    return GestureDetector(
      onTap: () => widget.onTankSelected(data['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? primary.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primary : const Color(0xFFF1F5F9),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? primary : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                data['icon'],
                color: isSelected ? Colors.white : primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['size'],
                    style: TextStyle(
                      color: primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${data['litres'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} Litres',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '₹${data['basePrice']}',
              style: TextStyle(
                color: primary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isBooking = false;

  Widget _buildBookButton(Color primary) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isBooking ? null : () async {
          setState(() => _isBooking = true);
          try {
            final orderController = ref.read(orderCreationControllerProvider.notifier);
            final selectedOption = tankOptionsData.firstWhere((t) => t['id'] == widget.selectedTankId);
            
            final orderId = await orderController.createOrder(
              tankSize: (selectedOption['litres'] as int).toDouble(),
              tankLabel: selectedOption['size'],
              location: {
                'latitude': _selectedLocation?.latitude ?? 0.0,
                'longitude': _selectedLocation?.longitude ?? 0.0,
                'address': _currentAddress ?? '',
              },
              paymentType: 'COD',
            );
            
            if (orderId != null && mounted) {
              ref.read(searchingControllerProvider.notifier).startWatchingOrder(orderId);
            }
          } finally {
            if (mounted) setState(() => _isBooking = false);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isBooking 
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text(
            'Book Water',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
      ),
    );
  }

  Widget _buildDrawer(User? user) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF0F2B5B), // primary
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: ClipOval(
                    child: user?.photoURL != null
                        ? Image.network(user!.photoURL!, fit: BoxFit.cover)
                        : const Icon(Icons.person_rounded, color: Color(0xFF0EA5E9), size: 36),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.displayName ?? 'WaterBuddy User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_rounded, color: Color(0xFF64748B)),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_rounded, color: Color(0xFF64748B)),
            title: const Text('History'),
            onTap: () {
              Navigator.pop(context);
              context.go(RouteNames.orders);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_rounded, color: Color(0xFF64748B)),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              context.go(RouteNames.profile);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserDot() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF0EA5E9).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Color(0xFF0EA5E9),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF64748B)),
        onPressed: onPressed,
      ),
    );
  }
}

class _UserGreeting extends StatelessWidget {
  const _UserGreeting({this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final uid = user?.uid;

    if (uid == null) {
      return const Text(
        'Hi there!',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
          letterSpacing: -0.5,
        ),
      );
    }

    final authName = user?.displayName;
    if (authName != null && authName.isNotEmpty) {
      return Text(
        'Hi, $authName',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
          letterSpacing: -0.5,
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        String name = 'there';
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          name = data?['name'] as String? ?? 'there';
        }

        return Text(
          'Hi, $name',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        );
      },
    );
  }
}

class _SearchingBottomSheet extends ConsumerStatefulWidget {
  const _SearchingBottomSheet({required this.orderId});

  final String orderId;

  @override
  ConsumerState<_SearchingBottomSheet> createState() => _SearchingBottomSheetState();
}

class _SearchingBottomSheetState extends ConsumerState<_SearchingBottomSheet> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentOrderId = ref.read(searchingControllerProvider).orderId;
      if (currentOrderId != widget.orderId) {
        ref.read(searchingControllerProvider.notifier).startWatchingOrder(widget.orderId);
      }
    });
  }

  String _getTankLabel(num size) {
    if (size <= 10000) return 'Small Tank';
    if (size <= 15000) return 'Medium Tank';
    return 'Large Tank';
  }

  @override
  Widget build(BuildContext context) {
    final searchingState = ref.watch(searchingControllerProvider);
    final activeOrder = ref.watch(activeOrderProvider).value;

    const primaryColor = Color(0xFF0F2B5B);

    if (searchingState.hasTimedOut) {
      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 25,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_off_rounded, size: 48, color: Color(0xFFEF4444)),
              const SizedBox(height: 20),
              const Text(
                'No tankers available',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              const Text(
                'All our partners are currently busy. Please try again in a few minutes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref.read(searchingControllerProvider.notifier).cancelOrder();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Try Again', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linear progress indicator at the very top, clipped to corners
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: const LinearProgressIndicator(
                backgroundColor: Color(0xFFF1F5F9),
                color: primaryColor,
                minHeight: 4,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Finding your tanker...',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Broadcasting your request to nearby partners.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Order details card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Icon(Icons.water_drop_rounded, color: primaryColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getTankLabel(activeOrder?.tankSize ?? 15000),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${activeOrder?.tankSize ?? 15000} Litres',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'SEARCHING',
                            style: TextStyle(
                              color: Color(0xFF0369A1),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () async {
                        await ref.read(searchingControllerProvider.notifier).cancelOrder();
                        if (context.mounted) {
                          context.go(RouteNames.home);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Cancel Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

