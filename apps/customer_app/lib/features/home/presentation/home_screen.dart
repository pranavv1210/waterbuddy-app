import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../routes/route_names.dart';
import '../models/home_dashboard.dart';
import '../providers/home_providers.dart';
import '../providers/order_creation_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(homeDashboardProvider);
    final selectedTankId = ref.watch(selectedTankIdProvider) ?? 'medium';

    return _HomeScreenBody(
      state: dashboard,
      selectedTankId: selectedTankId,
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
    required this.onTankSelected,
  });

  final HomeDashboard state;
  final String selectedTankId;
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

  void _onMapPositionChanged(MapPosition position, bool hasGesture) {
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
    const primary = Color(0xFF0F2B5B);
    const accent = Color(0xFF0EA5E9);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. FULL SCREEN MAP BACKGROUND
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation ?? _defaultLocation,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
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
                    ],
                  ),
              ],
            ),
          ),

          // 2. FIXED CENTER PIN (Uber-style selection)
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
                    Expanded(child: _buildLocationBar()),
                    const SizedBox(width: 12),
                    _buildActionsBar(user),
                  ],
                ),
              ),
            ),
          ),

          // 3. FLOATING LOCATION BUTTON
          Positioned(
            bottom: 310, // Adjusted to be above the bottom sheet
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
          _buildBottomSheet(user, primary, accent),
        ],
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
            onPressed: () {},
          ),
          const SizedBox(width: 4),
          Container(
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
        ],
      ),
    );
  }

  Widget _buildBottomSheet(User? user, Color primary, Color accent) {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.35,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _UserGreeting(user: user),
                        TextButton(
                          onPressed: () {
                            // Confirm logic: could save coordinates to a provider
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Location confirmed!')),
                            );
                          },
                          child: const Text('Confirm Location', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Choose Tank Size',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...tankOptionsData.map((data) => _buildTankListItem(data, primary)),
                    const SizedBox(height: 80), // Space for fixed button
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

  Widget _buildBookButton(Color primary) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () async {
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
            context.go('${RouteNames.searching}?orderId=$orderId');
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: const Text(
          'Book Water',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
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
