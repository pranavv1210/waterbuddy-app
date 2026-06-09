import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../routes/route_names.dart';
import '../models/home_dashboard.dart';
import '../providers/home_providers.dart';
import '../providers/order_creation_provider.dart';
import '../../../providers/app_providers.dart';
import '../../../models/order.dart' as app_order;
import '../../../models/system_settings.dart';
import '../../../models/tank_category.dart';
import '../../tracking/providers/searching_providers.dart';
import '../../../widgets/waterbuddy_toast.dart';
import '../../../widgets/waterbuddy_bottom_sheet.dart';
import '../../../widgets/loading_feedback_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(homeDashboardProvider);
    final categories = ref.watch(activeTankCategoriesProvider);
    final categoriesLoading = ref.watch(tankCategoriesProvider).isLoading;
    final settings = ref.watch(systemSettingsProvider).valueOrNull ??
        SystemSettings.defaults();
    final selectedTankId = ref.watch(selectedTankIdProvider) ??
        (categories.isNotEmpty ? categories.first.id : '');
    final activeOrder = ref.watch(activeOrderProvider).value;

    // Redirect to tracking if there's already an active order
    ref.listen(activeOrderProvider, (previous, next) {
      final order = next.value;
      if (order != null) {
        if (order.status == 'ACCEPTED' ||
            order.status == 'ASSIGNED' ||
            order.status == 'DRIVER_ASSIGNED' ||
            order.status == 'ON_THE_WAY') {
          context.go('${RouteNames.tracking}?orderId=${order.id}');
        }
      }
    });

    return _HomeScreenBody(
      state: dashboard,
      selectedTankId: selectedTankId,
      tankCategories: categories,
      categoriesLoading: categoriesLoading,
      systemSettings: settings,
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
    required this.tankCategories,
    required this.categoriesLoading,
    required this.systemSettings,
    required this.activeOrder,
    required this.onTankSelected,
  });

  final HomeDashboard state;
  final String selectedTankId;
  final List<TankCategory> tankCategories;
  final bool categoriesLoading;
  final SystemSettings systemSettings;
  final app_order.Order? activeOrder;
  final ValueChanged<String> onTankSelected;

  @override
  ConsumerState<_HomeScreenBody> createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends ConsumerState<_HomeScreenBody> {
  GoogleMapController? _googleMapController;
  LatLng? _currentLocation;
  LatLng? _selectedLocation;
  String? _currentAddress;
  bool _isLoadingLocation = false;
  LoadingButtonState _bookingButtonState = LoadingButtonState.idle;
  BitmapDescriptor? _tankerIcon;

  static const LatLng _defaultLocation = LatLng(12.9716, 77.5946); // Bangalore

  @override
  void initState() {
    super.initState();
    _determinePosition();
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

  void _moveCamera(LatLng latLng) {
    _googleMapController?.animateCamera(
      CameraUpdate.newLatLngZoom(latLng, 15.5),
    );
  }

  Future<void> _determinePosition() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          WaterBuddyToast.show(context, 'Location services are disabled.', isError: true);
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            WaterBuddyToast.show(context, 'Location permission denied.', isError: true);
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          WaterBuddyToast.show(context, 'Location permissions permanently denied.', isError: true);
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _currentLocation = latLng;
          _selectedLocation = latLng;
        });
        _moveCamera(latLng);
        await _getAddressFromLatLng(latLng);
        WaterBuddyToast.show(context, 'Location updated successfully!');
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
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
        final parts = [
          place.name,
          place.subLocality,
          place.locality,
          place.postalCode
        ].where((p) => p != null && p.trim().isNotEmpty).toList();

        setState(() {
          _currentAddress = parts.isNotEmpty ? parts.join(', ') : "${place.locality ?? ''}";
        });
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
    }
  }

  Set<Marker> _buildGoogleMarkers(List<Map<String, dynamic>> onlineSellers) {
    final markers = <Marker>{};

    final centerLoc = _selectedLocation ?? _currentLocation ?? _defaultLocation;
    markers.add(
      Marker(
        markerId: const MarkerId('delivery_location'),
        position: centerLoc,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    for (final seller in onlineSellers) {
      final lat = seller['lat'];
      final lng = seller['lng'];
      if (lat != null && lng != null) {
        markers.add(
          Marker(
            markerId: MarkerId('seller_${seller['id']}'),
            position: LatLng(lat, lng),
            icon: _tankerIcon ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          ),
        );
      }
    }

    return markers;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final onlineSellers = ref.watch(onlineSellersProvider).valueOrNull ?? [];
    
    // UI Style details
    const scaffoldBg = Color(0xFFF8FAFC); // Off-White
    const inkSlate = Color(0xFF0F172A);
    const textSlateMuted = Color(0xFF64748B);
    const primaryBlue = Color(0xFF0095F6);

    return Scaffold(
      backgroundColor: scaffoldBg,
      drawer: _buildDrawer(user),
      appBar: AppBar(
        title: const Text(
          'WaterBuddy',
          style: TextStyle(
            color: inkSlate,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: inkSlate),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: inkSlate),
            onPressed: () {
              WaterBuddyToast.show(context, 'No new notifications');
            },
          ),
          GestureDetector(
            onTap: () => context.push(RouteNames.profile),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryBlue.withOpacity(0.18),
              ),
              child: ClipOval(
                child: user?.photoURL != null
                    ? Image.network(user!.photoURL!, fit: BoxFit.cover)
                    : const Icon(Icons.person_rounded, color: primaryBlue, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. GREETING HEADER (Compact)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: textSlateMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 1),
                          _UserGreeting(user: user),
                        ],
                      ),
                      if (onlineSellers.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green[200]!, width: 1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${onlineSellers.length} Tankers Online',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // 2. LARGE MAP SECTION WITH OVERLAY GLASS CARD (50-55% of screen)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(23),
                      child: Stack(
                        children: [
                          // The map dominates
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _selectedLocation ?? _currentLocation ?? _defaultLocation,
                              zoom: 15.5,
                            ),
                            onMapCreated: (controller) {
                              _googleMapController = controller;
                            },
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                            compassEnabled: false,
                            scrollGesturesEnabled: true,
                            zoomGesturesEnabled: true,
                            tiltGesturesEnabled: false,
                            rotateGesturesEnabled: false,
                            onCameraMove: (position) {
                              _selectedLocation = position.target;
                            },
                            onCameraIdle: () async {
                              if (_selectedLocation != null) {
                                await _getAddressFromLatLng(_selectedLocation!);
                              }
                            },
                            markers: _buildGoogleMarkers(onlineSellers),
                          ),

                          // Floating Glass Address Card
                          Positioned(
                            top: 14,
                            left: 14,
                            right: 14,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.82),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'DELIVERY ADDRESS',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                color: textSlateMuted,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _currentAddress ?? 'Pinpoint delivery location...',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: inkSlate,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Floating Change Location chip
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.2),
                                  ),
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      final result = await context.push(RouteNames.locationSelection,
                                          extra: _currentAddress);
                                      if (result != null && result is Map<String, dynamic> && mounted) {
                                        if (result.containsKey('location')) {
                                          final loc = result['location'] as Map<String, dynamic>;
                                          final lat = loc['latitude'] as double;
                                          final lng = loc['longitude'] as double;
                                          final latLng = LatLng(lat, lng);
                                          setState(() {
                                            _selectedLocation = latLng;
                                            _currentAddress = result['address'] as String?;
                                          });
                                          _moveCamera(latLng);
                                          WaterBuddyToast.show(context, 'Address updated!');
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.edit_location_alt_rounded, size: 14, color: primaryBlue),
                                    label: const Text(
                                      'Change Address',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: inkSlate,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      minimumSize: Size.zero,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Floating Current Location button
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: ClipOval(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.85),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.2),
                                  ),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: _isLoadingLocation
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue),
                                          )
                                        : const Icon(Icons.my_location_rounded, size: 18, color: primaryBlue),
                                    onPressed: _determinePosition,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. AVAILABLE TANKERS Horizontal Flow
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Select Water Tanker',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: inkSlate,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                if (widget.tankCategories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: widget.categoriesLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _NoTankCategoriesCard(
                            message: widget.systemSettings.serviceAvailable
                                ? 'No active water tank categories available currently.'
                                : 'Bookings are temporarily disabled by operations.',
                          ),
                  )
                else
                  SizedBox(
                    height: 124,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: widget.tankCategories.length,
                      itemBuilder: (context, index) {
                        final category = widget.tankCategories[index];
                        return _buildHorizontalTankCard(category, primaryBlue);
                      },
                    ),
                  ),

                const SizedBox(height: 16),

                // 4. BOOK NOW BOTTOM BAR WITH ANIMA-CTA
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
                  ),
                  child: LoadingFeedbackButton(
                    onPressed: _bookingButtonState == LoadingButtonState.idle ? _submitOrder : null,
                    label: 'Book Water Now',
                    loadingLabel: 'Contacting Tankers...',
                    successLabel: 'Order Booked successfully!',
                    buttonState: _bookingButtonState,
                    backgroundColor: primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalTankCard(TankCategory category, Color primary) {
    final isSelected = widget.selectedTankId == category.id;
    const inkSlate = Color(0xFF0F172A);
    const textSlateMuted = Color(0xFF64748B);
    const selectedBlueBorder = Color(0xFF0099FF);
    const selectedBlueBg = Color(0xFFEEF7FF);

    return GestureDetector(
      onTap: () => widget.onTankSelected(category.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 175,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? selectedBlueBg : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? selectedBlueBorder : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedBlueBorder.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? selectedBlueBorder : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _tankIcon(category.iconKey),
                    color: isSelected ? Colors.white : selectedBlueBorder,
                    size: 18,
                  ),
                ),
                Text(
                  '₹${category.effectivePrice}',
                  style: const TextStyle(
                    color: inkSlate,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: inkSlate,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${_formatLitres(category.litres)} Litres',
                  style: const TextStyle(
                    color: textSlateMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitOrder() async {
    setState(() => _bookingButtonState = LoadingButtonState.loading);
    try {
      final orderController = ref.read(orderCreationControllerProvider.notifier);
      if (!widget.systemSettings.serviceAvailable) {
        WaterBuddyToast.show(context, 'Water booking is currently disabled by operations.', isError: true);
        setState(() => _bookingButtonState = LoadingButtonState.idle);
        return;
      }
      if (widget.tankCategories.isEmpty) {
        WaterBuddyToast.show(context, 'No active tank categories available.', isError: true);
        setState(() => _bookingButtonState = LoadingButtonState.idle);
        return;
      }
      final selectedOption = widget.tankCategories.firstWhere(
        (t) => t.id == widget.selectedTankId,
        orElse: () => widget.tankCategories.first,
      );

      final orderId = await orderController.createOrder(
        tankCategory: selectedOption,
        location: {
          'latitude': _selectedLocation?.latitude ?? _currentLocation?.latitude ?? _defaultLocation.latitude,
          'longitude': _selectedLocation?.longitude ?? _currentLocation?.longitude ?? _defaultLocation.longitude,
          'address': _currentAddress ?? 'Selected Location',
        },
        paymentType: widget.systemSettings.codEnabled ? 'COD' : 'ONLINE',
      );

      if (orderId != null && mounted) {
        ref.read(searchingControllerProvider.notifier).startWatchingOrder(orderId);
        setState(() => _bookingButtonState = LoadingButtonState.success);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          context.go('${RouteNames.searching}?orderId=$orderId');
        }
      } else {
        setState(() => _bookingButtonState = LoadingButtonState.idle);
        if (mounted) {
          WaterBuddyToast.show(context, 'Unable to place booking.', isError: true);
        }
      }
    } catch (e) {
      setState(() => _bookingButtonState = LoadingButtonState.idle);
      if (mounted) {
        WaterBuddyToast.show(context, 'An error occurred: $e', isError: true);
      }
    }
  }

  IconData _tankIcon(String iconKey) {
    switch (iconKey) {
      case 'opacity':
      case 'water_drop':
      case 'drop':
        return Icons.opacity_rounded;
      case 'waves':
      case 'water':
        return Icons.waves_rounded;
      case 'truck':
      case 'tanker':
        return Icons.local_shipping_rounded;
      default:
        return Icons.water_drop_rounded;
    }
  }

  String _formatLitres(int litres) {
    return litres.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }

  Widget _buildDrawer(User? user) {
    const inkSlate = Color(0xFF0F172A);
    const primaryBlue = Color(0xFF0095F6);
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE2E8F0),
                  ),
                  child: ClipOval(
                    child: user?.photoURL != null
                        ? Image.network(user!.photoURL!, fit: BoxFit.cover)
                        : const Icon(Icons.person_rounded, color: primaryBlue, size: 30),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.displayName ?? 'WaterBuddy User',
                  style: const TextStyle(
                    color: inkSlate,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_work_rounded, color: primaryBlue),
            title: const Text('Saved Addresses',
                style: TextStyle(color: inkSlate, fontWeight: FontWeight.w700)),
            onTap: () {
              Navigator.pop(context);
              context.push(RouteNames.locationSelection, extra: _currentAddress);
            },
          ),
          ListTile(
            leading: const Icon(Icons.credit_card_rounded, color: primaryBlue),
            title: const Text('Payment Methods',
                style: TextStyle(color: inkSlate, fontWeight: FontWeight.w700)),
            onTap: () {
              Navigator.pop(context);
              context.push(RouteNames.payments);
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent_rounded, color: primaryBlue),
            title: const Text('Support',
                style: TextStyle(color: inkSlate, fontWeight: FontWeight.w700)),
            onTap: () {
              Navigator.pop(context);
              final settings = ref.read(systemSettingsProvider).valueOrNull;
              final support = settings?.supportNumber.isNotEmpty == true
                  ? settings!.supportNumber
                  : settings?.supportEmail ?? 'waterbuddyapp.wb@gmail.com';
              WaterBuddyToast.show(context, 'Support Contact: $support');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_rounded, color: primaryBlue),
            title: const Text('App Settings',
                style: TextStyle(color: inkSlate, fontWeight: FontWeight.w700)),
            onTap: () {
              Navigator.pop(context);
              context.push(RouteNames.appSettings);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text('Log Out',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }
}

class _NoTankCategoriesCard extends StatelessWidget {
  const _NoTankCategoriesCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2), // Light soft red
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bookings Temporarily Unavailable',
            style: TextStyle(
              color: Color(0xFF9F1239),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFFE11D48),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
    const inkSlate = Color(0xFF0F172A);

    if (uid == null) {
      return const Text(
        'Hi there!',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: inkSlate,
          letterSpacing: -0.5,
        ),
      );
    }

    final authName = user?.displayName;
    if (authName != null && authName.isNotEmpty) {
      return Text(
        'Hi, $authName 👋',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: inkSlate,
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
          'Hi, $name 👋',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: inkSlate,
            letterSpacing: -0.5,
          ),
        );
      },
    );
  }
}
