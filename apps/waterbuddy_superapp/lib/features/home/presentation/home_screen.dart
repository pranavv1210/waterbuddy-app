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
import '../../orders/providers/order_providers.dart';

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
        if (activeOrder.status == 'ASSIGNED' ||
            activeOrder.status == 'ON_THE_WAY') {
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
  bool _isManualSelection =
      false; // Added to track if user is explicitly selecting location

  // Default to Bangalore center if location not available
  static const LatLng _defaultLocation = LatLng(12.9716, 77.5946);

  final List<Map<String, dynamic>> tankOptionsData = [
    {
      'id': 'small',
      'size': 'Small Tank',
      'litres': 10000,
      'icon': Icons.opacity_rounded,
      'basePrice': 500
    },
    {
      'id': 'medium',
      'size': 'Medium Tank',
      'litres': 15000,
      'icon': Icons.water_drop_rounded,
      'basePrice': 750
    },
    {
      'id': 'large',
      'size': 'Large Tank',
      'litres': 20000,
      'icon': Icons.waves_rounded,
      'basePrice': 1000
    },
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
          _currentAddress =
              "${place.locality ?? ''}, ${place.subAdministrativeArea ?? place.locality ?? ''}";
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
      _isManualSelection = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final searchingState = ref.watch(searchingControllerProvider);
    final isSearching = searchingState.orderId != null &&
        (searchingState.orderStatus == 'SEARCHING' || searchingState.isLoading);

    // WaterBuddy light palette
    const primary = Color(0xFF0EA5E9);
    const accent = Color(0xFF14B8A6);
    const background = Color(0xFFFFFBF3);

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    if (isDesktop) {
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
          backgroundColor: background,
          body: Row(
            children: [
              // Left Pane: Booking controls
              Container(
                width: 420,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(4, 0),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.water_drop_rounded,
                                    color: Color(0xFF38BDF8), size: 28),
                                SizedBox(width: 8),
                                Text(
                                  'WaterBuddy',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            _buildActionsBar(user),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),

                      // Dynamic Control Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isSearching)
                                _SearchingBottomSheet(
                                    orderId: searchingState.orderId!)
                              else if (!_isLocationConfirmed) ...[
                                _isMovingMap ||
                                        (_selectedLocation != null &&
                                            _currentAddress != null &&
                                            !_isLocationConfirmed &&
                                            _isManualSelection)
                                    ? _buildConfirmLocationView(primary)
                                    : _buildDiscoveryView(
                                        user, primary, accent),
                              ] else ...[
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => setState(
                                          () => _isLocationConfirmed = false),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF1F5F9),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                            Icons.arrow_back_rounded,
                                            color: Color(0xFF0F172A),
                                            size: 20),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Choose Tank Size',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildLocationBar(),
                                const SizedBox(height: 20),
                                ...tankOptionsData.map((data) =>
                                    _buildTankListItem(data, primary)),
                                const SizedBox(height: 32),
                                _buildBookButton(primary),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Right Pane: Live Map
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _currentLocation ?? _defaultLocation,
                          initialZoom: 15,
                          interactionOptions: InteractionOptions(
                            flags: _isLocationConfirmed
                                ? InteractiveFlag.none
                                : InteractiveFlag.all,
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
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.waterbuddy.customer',
                          ),
                          if (_currentLocation != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _currentLocation!,
                                  width: 80,
                                  height: 80,
                                  child: _buildUserDot(),
                                ),
                                if (_isLocationConfirmed &&
                                    _selectedLocation != null)
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

                    // Fixed pin in map center
                    if (!_isLocationConfirmed)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: primary,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primary.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Confirm Water Delivery Location',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Icon(
                                Icons.location_on_rounded,
                                color: Color(0xFFEF4444),
                                size: 48,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Geolocate Floating button
                    Positioned(
                      bottom: 24,
                      right: 24,
                      child: FloatingActionButton(
                        onPressed: _determinePosition,
                        backgroundColor: Colors.white,
                        foregroundColor: primary,
                        elevation: 4,
                        mini: true,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: _isLoadingLocation
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.my_location_rounded, size: 20),
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

    // Mobile / Tablet full Stack layout
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
                    flags: _isLocationConfirmed
                        ? InteractiveFlag.none
                        : InteractiveFlag.all,
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
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Confirm Water Delivery Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFFEF4444),
                        size: 48,
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
                              width: 58,
                              height: 58,
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
                              child: const Icon(Icons.menu_rounded,
                                  color: Color(0xFF0F172A), size: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ] else ...[
                        GestureDetector(
                          onTap: () =>
                              setState(() => _isLocationConfirmed = false),
                          child: Container(
                            width: 58,
                            height: 58,
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
                            child: const Icon(Icons.arrow_back_rounded,
                                color: Color(0xFF0F172A), size: 24),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: _isLoadingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
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
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded,
              color: Color(0xFFEF4444), size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Water Delivery Location',
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  locText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
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
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: Color(0xFF64748B)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No new notifications'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          GestureDetector(
            onTap: () => context.go(RouteNames.profile),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0EA5E9).withOpacity(0.18),
              ),
              child: ClipOval(
                child: user?.photoURL != null
                    ? Image.network(user!.photoURL!, fit: BoxFit.cover)
                    : const Icon(Icons.person_rounded,
                        color: Color(0xFF0EA5E9), size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(
      User? user, Color primary, Color accent, app_order.Order? activeOrder) {
    final searchingState = ref.watch(searchingControllerProvider);
    final isSearching = searchingState.orderId != null &&
        (searchingState.orderStatus == 'SEARCHING' || searchingState.isLoading);

    if (isSearching) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('${RouteNames.searching}?orderId=${searchingState.orderId}');
      });
      return const SizedBox.shrink();
    }

    if (!_isLocationConfirmed) {
      // If we haven't confirmed location, show either Discovery (initial) or Confirm button (after selection)
      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0EA5E9).withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // If we have a selected location (from search or map move), show confirm button
              // instead of the full discovery view if we're in "selection mode"
              _isMovingMap ||
                      (_selectedLocation != null &&
                          _currentAddress != null &&
                          !_isLocationConfirmed &&
                          _isManualSelection)
                  ? _buildConfirmLocationView(primary)
                  : _buildDiscoveryView(user, primary, accent),
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
            color: Colors.white.withOpacity(0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0EA5E9).withOpacity(0.12),
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
                  color: const Color(0xFFCBD5E1),
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
                    ...tankOptionsData
                        .map((data) => _buildTankListItem(data, primary)),
                    const SizedBox(
                        height: 80), // Space for fixed button + nav bar
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE0F2FE) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF38BDF8) : const Color(0xFFE2E8F0),
            width: 1.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF38BDF8)
                    : const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                data['icon'],
                color: isSelected ? Colors.white : const Color(0xFF0EA5E9),
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['size'],
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${data['litres'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} Litres • Express',
                    style: TextStyle(
                      color: const Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${data['basePrice']}',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (isSelected)
                  const Text(
                    'Best Value',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isBooking = false;

  Widget _buildBookButton(Color primary) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isBooking
            ? null
            : () async {
                setState(() => _isBooking = true);
                try {
                  final orderController =
                      ref.read(orderCreationControllerProvider.notifier);
                  final selectedOption = tankOptionsData
                      .firstWhere((t) => t['id'] == widget.selectedTankId);

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
                    ref
                        .read(searchingControllerProvider.notifier)
                        .startWatchingOrder(orderId);
                    context.go('${RouteNames.searching}?orderId=$orderId');
                  }
                } finally {
                  if (mounted) setState(() => _isBooking = false);
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isBooking ? 'Starting Request' : 'Book Water Now',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5),
            ),
            SizedBox(width: 12),
            Icon(Icons.arrow_forward_rounded, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(User? user) {
    return Drawer(
      backgroundColor: const Color(0xFFFFFBF3),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.white,
              border:
                  const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
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
                    color: Color(0xFF0F172A),
                  ),
                  child: ClipOval(
                    child: user?.photoURL != null
                        ? Image.network(user!.photoURL!, fit: BoxFit.cover)
                        : const Icon(Icons.person_rounded,
                            color: Color(0xFF0EA5E9), size: 36),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.displayName ?? 'WaterBuddy User',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading:
                const Icon(Icons.home_work_rounded, color: Color(0xFF0EA5E9)),
            title: const Text('Saved addresses',
                style: TextStyle(
                    color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              context.push(RouteNames.locationSelection,
                  extra: _currentAddress);
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.credit_card_rounded, color: Color(0xFF0EA5E9)),
            title: const Text('Payment methods',
                style: TextStyle(
                    color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              context.push(RouteNames.payments);
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent_rounded,
                color: Color(0xFF0EA5E9)),
            title: const Text('Support',
                style: TextStyle(
                    color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Support: waterbuddyapp.wb@gmail.com')),
              );
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.settings_rounded, color: Color(0xFF0EA5E9)),
            title: const Text('App settings',
                style: TextStyle(
                    color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              context.push(RouteNames.appSettings);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryView(User? user, Color primary, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UserGreeting(user: user),
          const SizedBox(height: 24),
          // Search Bar (Rapido style)
          GestureDetector(
            onTap: () async {
              final result = await context.push(RouteNames.locationSelection,
                  extra: _currentAddress);
              if (result != null && result is Map<String, dynamic>) {
                if (result.containsKey('location')) {
                  final loc = result['location'] as Map<String, dynamic>;
                  final lat = loc['latitude'] as double;
                  final lng = loc['longitude'] as double;
                  _selectedLocation = LatLng(lat, lng);
                  _mapController.move(_selectedLocation!, 15);
                  _currentAddress = result['address'] as String?;
                  setState(() {
                    _isManualSelection = true;
                  });
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      color: Color(0xFF0EA5E9), size: 22),
                  const SizedBox(width: 12),
                  Text(
                    'Where do you need water?',
                    style: TextStyle(
                      color: const Color(0xFF64748B),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Recent water deliveries',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Consumer(
            builder: (context, ref, child) {
              final history = ref.watch(orderHistoryProvider);
              return history.when(
                data: (orders) {
                  if (orders.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'No previous orders yet',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                    );
                  }

                  // Limit to 5 recent orders for the home screen
                  final recentOrders = orders.take(5).toList();

                  return Column(
                    children: recentOrders.map((order) {
                      return _RecentDeliveryTile(
                        address: order.deliveryAddress ?? 'Unknown Address',
                        date: order.createdAt?.toDate(),
                        onTap: () {
                          // Set the location from previous order
                          if (order.location != null) {
                            final lat = order.location!['latitude'] as double;
                            final lng = order.location!['longitude'] as double;
                            _selectedLocation = LatLng(lat, lng);
                            _mapController.move(_selectedLocation!, 15);
                            _currentAddress = order.deliveryAddress;
                            setState(() => _isLocationConfirmed = true);
                          }
                        },
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                    child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )),
                error: (e, s) => const Text('Failed to load history'),
              );
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
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 2),
          builder: (context, value, child) {
            return Container(
              width: 40 * value,
              height: 40 * value,
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withOpacity(0.2 * (1 - value)),
                shape: BoxShape.circle,
              ),
            );
          },
          onEnd: () {}, // Repeat logic could be added here
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
                color: Color(0xFF38BDF8),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmLocationView(Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  color: Color(0xFFEF4444), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirm water delivery location',
                      style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _currentAddress ?? 'Selecting location...',
                      style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Confirm Location',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _isManualSelection = false;
              });
            },
            child: const Text('Change',
                style: TextStyle(
                    color: Color(0xFF0EA5E9), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String imagePath;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: 10,
              child: Opacity(
                opacity: 0.9,
                child: Image.asset(
                  imagePath,
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

class _RecentDeliveryTile extends StatelessWidget {
  const _RecentDeliveryTile(
      {required this.address, this.date, required this.onTap});

  final String address;
  final DateTime? date;
  final VoidCallback onTap;

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Last delivered recently';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Last delivered today';
    if (diff.inDays == 1) return 'Last delivered yesterday';
    return 'Last delivered ${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_rounded,
                  color: Color(0xFF0EA5E9), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _formatDate(date),
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
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
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        String name = 'there';
        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.exists) {
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
  ConsumerState<_SearchingBottomSheet> createState() =>
      _SearchingBottomSheetState();
}

class _SearchingBottomSheetState extends ConsumerState<_SearchingBottomSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentOrderId = ref.read(searchingControllerProvider).orderId;
      if (currentOrderId != widget.orderId) {
        ref
            .read(searchingControllerProvider.notifier)
            .startWatchingOrder(widget.orderId);
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
    final isDesktop = MediaQuery.of(context).size.width > 800;

    const primaryColor = Color(0xFF0F172A);
    const accentColor = Color(0xFF38BDF8);

    if (searchingState.hasTimedOut) {
      final timedOutContent = Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.timer_off_rounded,
                  size: 48, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 24),
            const Text(
              'No tankers available',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            const Text(
              'All our partners are currently busy in your area. Please try again in a few minutes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  await ref
                      .read(searchingControllerProvider.notifier)
                      .cancelOrder();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: const Text('Try Again',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      );

      if (isDesktop) {
        return timedOutContent;
      } else {
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: timedOutContent,
        );
      }
    }

    final searchingContent = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern progress line
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: LinearProgressIndicator(
              backgroundColor: accentColor.withOpacity(0.1),
              color: accentColor,
              minHeight: 6,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Finding your tanker...',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 3, color: Color(0xFF38BDF8)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Broadcasting your request to 5 nearby partners.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                const WaterDropSearchAnimation(),
                const SizedBox(height: 16),
                // Order details card (Modern style)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.water_drop_rounded,
                            color: Color(0xFF38BDF8), size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getTankLabel(activeOrder?.tankSize ?? 15000),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${activeOrder?.tankSize?.toInt() ?? 15000} Litres • COD',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: const Text(
                          'SEARCHING',
                          style: TextStyle(
                            color: Color(0xFF0369A1),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Cancel Button (Modern outlined)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () async {
                      await ref
                          .read(searchingControllerProvider.notifier)
                          .cancelOrder();
                      if (context.mounted) {
                        context.go(RouteNames.home);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side:
                          const BorderSide(color: Color(0xFFF1F5F9), width: 2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text('Cancel Request',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isDesktop) {
      return searchingContent;
    } else {
      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: searchingContent,
      );
    }
  }
}

class WaterDropSearchAnimation extends StatefulWidget {
  const WaterDropSearchAnimation({super.key});

  @override
  State<WaterDropSearchAnimation> createState() =>
      _WaterDropSearchAnimationState();
}

class _WaterDropSearchAnimationState extends State<WaterDropSearchAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _rippleController;
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Concentric water wave ripples
          ...List.generate(3, (index) {
            final delayFraction = index / 3.0;
            return AnimatedBuilder(
              animation: _rippleController,
              builder: (context, child) {
                double progress = _rippleController.value - delayFraction;
                if (progress < 0) progress += 1.0;

                final scale = 1.0 + (progress * 2.2);
                final opacity = (1.0 - progress).clamp(0.0, 1.0);

                return Container(
                  width: 54,
                  height: 54,
                  transform: Matrix4.identity()..scale(scale),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF38BDF8).withOpacity(opacity * 0.4),
                      width: 2.0 - (progress * 1.2),
                    ),
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF38BDF8).withOpacity(opacity * 0.12),
                        const Color(0xFF0EA5E9).withOpacity(opacity * 0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            );
          }),

          // Outer orbiting tiny water droplets representing signal search
          AnimatedBuilder(
            animation: _rippleController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rippleController.value * 2 * 3.14159,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 18,
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0EA5E9),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 18,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF38BDF8),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Central premium floating water droplet
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              final yOffset = _floatController.value * -10.0;
              final scale = 1.0 + (_floatController.value * 0.04);
              return Transform.translate(
                offset: Offset(0, yOffset),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0EA5E9).withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 1,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFF38BDF8).withOpacity(0.25),
                        width: 2.0,
                      ),
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.water_drop_rounded,
                        size: 34,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
